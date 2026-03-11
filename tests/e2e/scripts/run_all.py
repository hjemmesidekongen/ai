#!/usr/bin/env python3
"""Batch runner for E2E plugin tests.

Reads test-matrix.yml and runs all configured test cases.
Creates a single timestamped run directory, then optionally
compares results against baseline.

Usage:
    python run_all.py
    python run_all.py --skip-llm
    python run_all.py --set-baseline
"""

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml

E2E_ROOT = Path(__file__).resolve().parent.parent
MATRIX_PATH = E2E_ROOT / "test-matrix.yml"
SCRIPTS_DIR = E2E_ROOT / "scripts"
RUNS_DIR = E2E_ROOT / "runs"


def load_matrix() -> list[dict]:
    """Load test matrix and expand to individual test cases."""
    matrix = yaml.safe_load(MATRIX_PATH.read_text())
    cases = []
    for entry in matrix.get("test_cases", []):
        skill = entry["skill"]
        for brand in entry["brands"]:
            cases.append({"skill": skill, "brand": brand})
    return cases


def run_single_test(skill: str, brand: str, run_id: str, skip_llm: bool) -> dict | None:
    """Run a single test via run_test.py."""
    cmd = [
        sys.executable,
        str(SCRIPTS_DIR / "run_test.py"),
        "--skill", skill,
        "--brand", brand,
        "--run-id", run_id,
    ]
    if skip_llm:
        cmd.append("--skip-llm")

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        if result.stderr:
            print(result.stderr, file=sys.stderr, end="")
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout)
    except Exception as e:
        print(f"Error running {skill}/{brand}: {e}", file=sys.stderr)
    return None


def run_comparison(run_dir: str, set_baseline: bool = False):
    """Run baseline comparison."""
    compare_script = SCRIPTS_DIR / "compare_baseline.py"
    cmd = [sys.executable, str(compare_script), "--run-dir", run_dir]
    if set_baseline:
        cmd.append("--set-baseline")

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")


def main():
    parser = argparse.ArgumentParser(description="Run all E2E tests from test matrix")
    parser.add_argument("--skip-llm", action="store_true", help="Skip LLM grading")
    parser.add_argument("--set-baseline", action="store_true", help="Set this run as new baseline")
    parser.add_argument("--run-id", default=None, help="Override run ID (default: timestamp)")
    args = parser.parse_args()

    if not MATRIX_PATH.exists():
        print(f"Error: Test matrix not found: {MATRIX_PATH}", file=sys.stderr)
        sys.exit(1)

    cases = load_matrix()
    if not cases:
        print("No test cases found in matrix", file=sys.stderr)
        sys.exit(1)

    run_id = args.run_id or datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    run_dir = RUNS_DIR / run_id
    print(f"Running {len(cases)} test cases (run: {run_id})", file=sys.stderr)
    print(f"{'='*60}", file=sys.stderr)

    results = []
    for i, case in enumerate(cases, 1):
        print(f"\n[{i}/{len(cases)}] {case['skill']} x {case['brand']}", file=sys.stderr)
        result = run_single_test(case["skill"], case["brand"], run_id, args.skip_llm)
        if result:
            results.append(result)
            score = result.get("total_score", "?")
            max_s = result.get("total_max", "?")
            print(f"  Score: {score}/{max_s}", file=sys.stderr)
        else:
            print(f"  FAILED", file=sys.stderr)

    print(f"\n{'='*60}", file=sys.stderr)
    print(f"Completed: {len(results)}/{len(cases)} tests", file=sys.stderr)

    if results:
        print(f"\n--- Baseline Comparison ---", file=sys.stderr)
        run_comparison(str(run_dir), set_baseline=args.set_baseline)

    # Write summary
    summary_path = run_dir / "summary.yml"
    if run_dir.exists():
        summary = {
            "run_id": run_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "tests_run": len(cases),
            "tests_passed": len(results),
            "tests_failed": len(cases) - len(results),
            "results": results,
        }
        summary_path.write_text(yaml.dump(summary, default_flow_style=False, sort_keys=False))


if __name__ == "__main__":
    main()
