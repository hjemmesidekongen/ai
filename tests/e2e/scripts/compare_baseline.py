#!/usr/bin/env python3
"""Baseline comparison for E2E test results.

Compares a test run's results against baseline.yml.
Output: skill/brand: score (baseline) -> score (run) -> delta

Usage:
    python compare_baseline.py --run-dir runs/20260311-120000
    python compare_baseline.py --set-baseline runs/20260311-120000
"""

import argparse
import sys
from pathlib import Path

import yaml

E2E_ROOT = Path(__file__).resolve().parent.parent
BASELINE_PATH = E2E_ROOT / "baseline.yml"


def load_baseline() -> dict:
    """Load baseline.yml, return empty baselines if missing."""
    if not BASELINE_PATH.exists():
        return {"baselines": {}}
    data = yaml.safe_load(BASELINE_PATH.read_text())
    return data if data and "baselines" in data else {"baselines": {}}


def collect_run_results(run_dir: Path) -> dict:
    """Collect all result.yml files from a run directory."""
    results = {}
    for result_file in run_dir.rglob("result.yml"):
        data = yaml.safe_load(result_file.read_text())
        if data and "skill" in data and "brand" in data:
            key = f"{data['skill']}--{data['brand']}"
            results[key] = {
                "total_score": data.get("total_score", 0),
                "total_max": data.get("total_max", 0),
                "deterministic_score": data.get("deterministic_score", 0),
                "llm_score": data.get("llm_score", 0),
                "rubric_version": data.get("rubric_version", "unknown"),
                "timestamp": data.get("timestamp", ""),
            }
    return results


def compare(baseline: dict, run_results: dict) -> list[dict]:
    """Compare run results against baseline, return comparison rows."""
    all_keys = sorted(set(list(baseline.get("baselines", {}).keys()) + list(run_results.keys())))
    comparisons = []

    for key in all_keys:
        base = baseline.get("baselines", {}).get(key)
        run = run_results.get(key)

        row = {"test": key}

        if base and run:
            base_score = base["total_score"]
            run_score = run["total_score"]
            max_score = run["total_max"]
            delta = run_score - base_score
            row["baseline_score"] = base_score
            row["run_score"] = run_score
            row["max_score"] = max_score
            row["delta"] = delta
            row["rubric_match"] = base.get("rubric_version") == run.get("rubric_version")
            if not row["rubric_match"]:
                row["warning"] = f"Rubric version changed: {base.get('rubric_version')} -> {run.get('rubric_version')}"
        elif run and not base:
            row["baseline_score"] = None
            row["run_score"] = run["total_score"]
            row["max_score"] = run["total_max"]
            row["delta"] = None
            row["note"] = "New test — no baseline"
        elif base and not run:
            row["baseline_score"] = base["total_score"]
            row["run_score"] = None
            row["delta"] = None
            row["note"] = "Missing from this run"

        comparisons.append(row)

    return comparisons


def print_comparison(comparisons: list[dict]):
    """Print comparison table to stdout."""
    print(f"{'Test':<40} {'Baseline':>10} {'Current':>10} {'Delta':>8} {'Notes'}")
    print("-" * 80)
    for row in comparisons:
        test = row["test"]
        base = f"{row['baseline_score']}" if row.get("baseline_score") is not None else "—"
        run = f"{row['run_score']}" if row.get("run_score") is not None else "—"
        delta = ""
        if row.get("delta") is not None:
            d = row["delta"]
            delta = f"+{d}" if d > 0 else f"{d}" if d < 0 else "="
        notes = row.get("warning", row.get("note", ""))
        print(f"{test:<40} {base:>10} {run:>10} {delta:>8} {notes}")


def set_baseline(run_results: dict):
    """Save run results as the new baseline."""
    baseline = {
        "baselines": run_results,
    }
    BASELINE_PATH.write_text(
        "# E2E Test Baseline Scores\n"
        "# Set by compare_baseline.py --set-baseline\n"
        + yaml.dump(baseline, default_flow_style=False, sort_keys=False)
    )
    print(f"Baseline updated with {len(run_results)} entries at {BASELINE_PATH}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Compare test results against baseline")
    parser.add_argument("--run-dir", required=True, help="Path to run directory")
    parser.add_argument("--set-baseline", action="store_true", help="Save this run as the new baseline")
    parser.add_argument("--output", choices=["table", "yaml"], default="table", help="Output format")
    args = parser.parse_args()

    run_dir = Path(args.run_dir)
    if not run_dir.exists():
        print(f"Error: Run directory not found: {run_dir}", file=sys.stderr)
        sys.exit(1)

    run_results = collect_run_results(run_dir)
    if not run_results:
        print(f"No result.yml files found in {run_dir}", file=sys.stderr)
        sys.exit(1)

    if args.set_baseline:
        set_baseline(run_results)
        return

    baseline = load_baseline()
    comparisons = compare(baseline, run_results)

    if args.output == "yaml":
        print(yaml.dump(comparisons, default_flow_style=False))
    else:
        print_comparison(comparisons)


if __name__ == "__main__":
    main()
