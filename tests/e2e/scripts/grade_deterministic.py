#!/usr/bin/env python3
"""Deterministic grader for E2E plugin tests.

Reads skill output directory + rubric YAML, runs all deterministic checks,
outputs JSON with per-check pass/fail and total score.

Reusable across rubrics — not skill-specific.
"""

import argparse
import json
import sys
from pathlib import Path

import yaml


def resolve_nested_field(data: dict, field_path: str):
    """Resolve a dotted field path like 'positioning.category' in nested dicts."""
    parts = field_path.split(".")
    current = data
    for part in parts:
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return current


def check_file_exists(output_dir: Path, check: dict) -> dict:
    """Check that a file exists in the output directory."""
    path = output_dir / check["path"]
    passed = path.exists()
    return {
        "id": check["id"],
        "description": check["description"],
        "type": check["type"],
        "passed": passed,
        "points_earned": check["points"] if passed else 0,
        "points_possible": check["points"],
        "detail": f"{'Found' if passed else 'Missing'}: {check['path']}",
    }


def check_file_not_empty(output_dir: Path, check: dict) -> dict:
    """Check that a file exists and has non-whitespace content."""
    path = output_dir / check["path"]
    passed = False
    detail = f"Missing: {check['path']}"
    if path.exists():
        content = path.read_text().strip()
        passed = len(content) > 0
        detail = f"{'Has content' if passed else 'Empty'}: {check['path']} ({len(content)} chars)"
    return {
        "id": check["id"],
        "description": check["description"],
        "type": check["type"],
        "passed": passed,
        "points_earned": check["points"] if passed else 0,
        "points_possible": check["points"],
        "detail": detail,
    }


def load_yaml_file(output_dir: Path, rel_path: str) -> dict | None:
    """Load and parse a YAML file, return None on failure."""
    path = output_dir / rel_path
    if not path.exists():
        return None
    try:
        return yaml.safe_load(path.read_text())
    except yaml.YAMLError:
        return None


def check_yaml_field_exists(output_dir: Path, check: dict) -> dict:
    """Check that a YAML field exists (supports dotted paths)."""
    data = load_yaml_file(output_dir, check["path"])
    if data is None:
        return {
            "id": check["id"],
            "description": check["description"],
            "type": check["type"],
            "passed": False,
            "points_earned": 0,
            "points_possible": check["points"],
            "detail": f"Could not load {check['path']}",
        }

    value = resolve_nested_field(data, check["field"])
    passed = value is not None
    return {
        "id": check["id"],
        "description": check["description"],
        "type": check["type"],
        "passed": passed,
        "points_earned": check["points"] if passed else 0,
        "points_possible": check["points"],
        "detail": f"{'Found' if passed else 'Missing'}: {check['field']}",
    }


def check_yaml_value_range(output_dir: Path, check: dict) -> dict:
    """Check that a YAML numeric value falls within a range."""
    data = load_yaml_file(output_dir, check["path"])
    if data is None:
        return {
            "id": check["id"],
            "description": check["description"],
            "type": check["type"],
            "passed": False,
            "points_earned": 0,
            "points_possible": check["points"],
            "detail": f"Could not load {check['path']}",
        }

    value = resolve_nested_field(data, check["field"])
    if value is None:
        passed = False
        detail = f"Missing field: {check['field']}"
    elif not isinstance(value, (int, float)):
        passed = False
        detail = f"Not numeric: {check['field']} = {value}"
    else:
        passed = check["min"] <= value <= check["max"]
        detail = f"{check['field']} = {value} ({'in' if passed else 'out of'} range [{check['min']}, {check['max']}])"

    return {
        "id": check["id"],
        "description": check["description"],
        "type": check["type"],
        "passed": passed,
        "points_earned": check["points"] if passed else 0,
        "points_possible": check["points"],
        "detail": detail,
    }


def check_yaml_array_min_length(output_dir: Path, check: dict) -> dict:
    """Check that a YAML array has at least N items."""
    data = load_yaml_file(output_dir, check["path"])
    if data is None:
        return {
            "id": check["id"],
            "description": check["description"],
            "type": check["type"],
            "passed": False,
            "points_earned": 0,
            "points_possible": check["points"],
            "detail": f"Could not load {check['path']}",
        }

    value = resolve_nested_field(data, check["field"])
    if value is None:
        passed = False
        detail = f"Missing field: {check['field']}"
    elif not isinstance(value, list):
        passed = False
        detail = f"Not an array: {check['field']}"
    else:
        passed = len(value) >= check["min_length"]
        detail = f"{check['field']} has {len(value)} items (min: {check['min_length']})"

    return {
        "id": check["id"],
        "description": check["description"],
        "type": check["type"],
        "passed": passed,
        "points_earned": check["points"] if passed else 0,
        "points_possible": check["points"],
        "detail": detail,
    }


CHECK_HANDLERS = {
    "file_exists": check_file_exists,
    "file_not_empty": check_file_not_empty,
    "yaml_field_exists": check_yaml_field_exists,
    "yaml_value_range": check_yaml_value_range,
    "yaml_array_min_length": check_yaml_array_min_length,
}


def grade(rubric_path: Path, output_dir: Path) -> dict:
    """Run all deterministic checks from a rubric against an output directory."""
    rubric = yaml.safe_load(rubric_path.read_text())

    results = []
    for check in rubric["checks"]["deterministic"]:
        handler = CHECK_HANDLERS.get(check["type"])
        if handler is None:
            results.append({
                "id": check["id"],
                "description": check["description"],
                "type": check["type"],
                "passed": False,
                "points_earned": 0,
                "points_possible": check["points"],
                "detail": f"Unknown check type: {check['type']}",
            })
            continue
        results.append(handler(output_dir, check))

    total_earned = sum(r["points_earned"] for r in results)
    total_possible = sum(r["points_possible"] for r in results)
    passed_count = sum(1 for r in results if r["passed"])

    return {
        "rubric": rubric["skill"],
        "rubric_version": rubric["version"],
        "output_dir": str(output_dir),
        "checks": results,
        "summary": {
            "deterministic_score": total_earned,
            "deterministic_max": total_possible,
            "checks_passed": passed_count,
            "checks_total": len(results),
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Run deterministic grading checks")
    parser.add_argument("--rubric", required=True, help="Path to rubric YAML file")
    parser.add_argument("--output-dir", required=True, help="Path to skill output directory")
    parser.add_argument("--verbose", action="store_true", help="Print per-check details to stderr")
    args = parser.parse_args()

    rubric_path = Path(args.rubric)
    output_dir = Path(args.output_dir)

    if not rubric_path.exists():
        print(f"Error: Rubric not found: {rubric_path}", file=sys.stderr)
        sys.exit(1)
    if not output_dir.exists():
        print(f"Error: Output directory not found: {output_dir}", file=sys.stderr)
        sys.exit(1)

    result = grade(rubric_path, output_dir)

    if args.verbose:
        s = result["summary"]
        print(f"Score: {s['deterministic_score']}/{s['deterministic_max']} "
              f"({s['checks_passed']}/{s['checks_total']} checks passed)", file=sys.stderr)
        for check in result["checks"]:
            status = "PASS" if check["passed"] else "FAIL"
            print(f"  [{status}] {check['points_earned']}/{check['points_possible']} {check['detail']}", file=sys.stderr)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
