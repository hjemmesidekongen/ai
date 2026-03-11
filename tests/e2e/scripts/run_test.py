#!/usr/bin/env python3
"""E2E test runner for plugin skills.

Orchestrates a single test case:
1. Read fixture (brand brief)
2. Construct skill prompt with fixture as input
3. Execute via claude -p
4. Capture output files to runs/{timestamp}/{skill}--{brand}/
5. Run deterministic grader
6. Run LLM grader (unless --skip-llm)
7. Write result.yml with combined scores

Usage:
    python tests/e2e/scripts/run_test.py --skill brand-audit --brand cloudmetrics
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import yaml

# Resolve paths relative to the e2e test root
E2E_ROOT = Path(__file__).resolve().parent.parent
FIXTURES_DIR = E2E_ROOT / "fixtures" / "brands"
RUBRICS_DIR = E2E_ROOT / "rubrics"
RUNS_DIR = E2E_ROOT / "runs"
SCRIPTS_DIR = E2E_ROOT / "scripts"

# Map skill names to their plugin locations
SKILL_REGISTRY = {
    "brand-audit": {
        "plugin": "brand",
        "path": "plugins/brand/skills/brand-audit",
        "output_pattern": ".ai/brand/{brand_name}",
        "expected_files": ["guideline.yml", "voice.yml", "values.yml", "audit-sources.md", "dos-and-donts.md"],
    },
    "visual-identity": {
        "plugin": "design",
        "path": "plugins/design/skills/visual-identity",
        "output_pattern": ".ai/design/{brand_name}",
        "expected_files": ["identity.yml", "tokens.yml"],
    },
    "content-strategy-patterns": {
        "plugin": "dev-engine",
        "path": "plugins/dev-engine/skills/content-strategy-patterns",
        "output_pattern": ".ai/content/{brand_name}",
        "expected_files": [],
    },
    "web-copywriting": {
        "plugin": "dev-engine",
        "path": "plugins/dev-engine/skills/web-copywriting",
        "output_pattern": ".ai/content/{brand_name}",
        "expected_files": [],
    },
    "sitemap-planning": {
        "plugin": "dev-engine",
        "path": "plugins/dev-engine/skills/sitemap-planning",
        "output_pattern": ".ai/design/{brand_name}",
        "expected_files": ["sitemap.yml"],
    },
    "design-tokens": {
        "plugin": "design",
        "path": "plugins/design/skills/design-tokens",
        "output_pattern": ".ai/design/{brand_name}/tokens",
        "expected_files": [],
    },
    "design-loader": {
        "plugin": "design",
        "path": "plugins/design/skills/design-loader",
        "output_pattern": ".ai/design/{brand_name}",
        "expected_files": [],
    },
}


def find_project_root() -> Path:
    """Find the project root by walking up from cwd looking for .claude/."""
    current = Path.cwd()
    for parent in [current, *current.parents]:
        if (parent / ".claude").is_dir():
            return parent
    return current


def load_fixture(brand: str) -> dict:
    """Load a brand fixture file."""
    fixture_path = FIXTURES_DIR / f"{brand}.yml"
    if not fixture_path.exists():
        print(f"Error: Fixture not found: {fixture_path}", file=sys.stderr)
        sys.exit(1)
    return yaml.safe_load(fixture_path.read_text())


def build_prompt(skill: str, fixture: dict) -> str:
    """Construct the skill execution prompt from a fixture."""
    brand_name = fixture["name"]
    brief = yaml.dump(fixture, default_flow_style=False)

    return f"""You are testing the {skill} skill. Process this brand brief and produce all expected output files.

Brand Brief:
{brief}

Instructions:
- Run the {skill} skill with this brand input
- Use brand name "{brand_name}" for all output paths
- Do NOT ask for user confirmation — treat this as an automated test
- Write all output files to their expected locations
- Be thorough but stay within the skill's defined scope
"""


def run_skill(prompt: str, project_root: Path, timeout: int = 300) -> tuple[bool, str]:
    """Execute a skill via claude -p and return (success, stderr)."""
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    cmd = [
        "claude",
        "-p", prompt,
        "--output-format", "text",
        "--verbose",
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=str(project_root),
            env=env,
        )
        return result.returncode == 0, result.stderr
    except subprocess.TimeoutExpired:
        return False, f"Timeout after {timeout}s"
    except Exception as e:
        return False, str(e)


def collect_output(skill: str, brand_name: str, project_root: Path, run_dir: Path) -> Path:
    """Copy skill output files to the run directory."""
    skill_info = SKILL_REGISTRY.get(skill, {})
    output_pattern = skill_info.get("output_pattern", "")
    output_path = project_root / output_pattern.format(brand_name=brand_name.lower().replace(" ", "-"))

    dest = run_dir / f"{skill}--{brand_name.lower().replace(' ', '-')}"
    dest.mkdir(parents=True, exist_ok=True)

    if output_path.exists():
        for item in output_path.iterdir():
            if item.is_file():
                shutil.copy2(item, dest / item.name)
            elif item.is_dir():
                shutil.copytree(item, dest / item.name, dirs_exist_ok=True)

    return dest


def run_llm_grader(rubric_path: Path, output_dir: Path, fixture_path: Path | None = None) -> dict | None:
    """Run the LLM grader and return parsed results."""
    grader_script = SCRIPTS_DIR / "grade_llm.py"
    if not grader_script.exists():
        return None

    cmd = [sys.executable, str(grader_script), "--rubric", str(rubric_path), "--output-dir", str(output_dir)]
    if fixture_path:
        cmd.extend(["--fixture", str(fixture_path)])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        if result.returncode == 0:
            return json.loads(result.stdout)
    except Exception:
        pass
    return None


def run_deterministic_grader(rubric_path: Path, output_dir: Path) -> dict | None:
    """Run the deterministic grader and return parsed results."""
    grader_script = SCRIPTS_DIR / "grade_deterministic.py"
    if not grader_script.exists():
        return None

    try:
        result = subprocess.run(
            [sys.executable, str(grader_script), "--rubric", str(rubric_path), "--output-dir", str(output_dir)],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
    except Exception:
        pass
    return None


def write_result(run_dir: Path, skill: str, brand: str,
                  det_grading: dict | None, llm_grading: dict | None,
                  success: bool, duration: float):
    """Write result.yml for this test run with combined scores."""
    result_path = run_dir / f"{skill}--{brand}" / "result.yml"
    result_path.parent.mkdir(parents=True, exist_ok=True)

    result = {
        "skill": skill,
        "brand": brand,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "duration_seconds": round(duration, 1),
        "execution_success": success,
    }

    det_score = 0
    det_max = 0
    llm_score = 0
    llm_max = 0

    if det_grading:
        result["rubric_version"] = det_grading.get("rubric_version", "unknown")
        det_score = det_grading["summary"]["deterministic_score"]
        det_max = det_grading["summary"]["deterministic_max"]
        result["deterministic_score"] = det_score
        result["deterministic_max"] = det_max
        result["deterministic_checks_passed"] = det_grading["summary"]["checks_passed"]
        result["deterministic_checks_total"] = det_grading["summary"]["checks_total"]
        result["deterministic_details"] = [
            {
                "id": c["id"],
                "passed": c["passed"],
                "points": f"{c['points_earned']}/{c['points_possible']}",
                "detail": c["detail"],
            }
            for c in det_grading["checks"]
        ]

    if llm_grading:
        llm_score = llm_grading["summary"]["llm_score"]
        llm_max = llm_grading["summary"]["llm_max"]
        result["llm_score"] = llm_score
        result["llm_max"] = llm_max
        result["llm_details"] = [
            {
                "id": c["id"],
                "raw_score": c["raw_score"],
                "points": f"{c['points_earned']}/{c['points_possible']}",
                "reasoning": c["reasoning"],
            }
            for c in llm_grading["checks"]
        ]

    result["total_score"] = det_score + llm_score
    result["total_max"] = det_max + llm_max

    if not det_grading and not llm_grading:
        result["rubric_version"] = "n/a"
        result["error"] = "No grading completed"

    result_path.write_text(yaml.dump(result, default_flow_style=False, sort_keys=False))
    return result


def main():
    parser = argparse.ArgumentParser(description="Run an E2E plugin skill test")
    parser.add_argument("--skill", required=True, help="Skill name (e.g., brand-audit)")
    parser.add_argument("--brand", required=True, help="Brand fixture name (e.g., cloudmetrics)")
    parser.add_argument("--timeout", type=int, default=300, help="Skill execution timeout in seconds")
    parser.add_argument("--run-id", default=None, help="Override run directory name (default: timestamp)")
    parser.add_argument("--skip-llm", action="store_true", help="Skip LLM grading (deterministic only)")
    parser.add_argument("--dry-run", action="store_true", help="Print prompt without executing")
    args = parser.parse_args()

    if args.skill not in SKILL_REGISTRY:
        print(f"Error: Unknown skill '{args.skill}'. Known skills: {', '.join(SKILL_REGISTRY.keys())}", file=sys.stderr)
        sys.exit(1)

    fixture = load_fixture(args.brand)
    prompt = build_prompt(args.skill, fixture)

    if args.dry_run:
        print(prompt)
        return

    project_root = find_project_root()
    run_id = args.run_id or datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    run_dir = RUNS_DIR / run_id

    print(f"Running: {args.skill} with {args.brand}", file=sys.stderr)
    print(f"Run dir: {run_dir}", file=sys.stderr)

    start = time.time()
    success, stderr = run_skill(prompt, project_root, timeout=args.timeout)
    duration = time.time() - start

    print(f"Execution: {'success' if success else 'failed'} ({duration:.1f}s)", file=sys.stderr)
    if not success:
        print(f"Stderr: {stderr[:500]}", file=sys.stderr)

    brand_name = fixture["name"]
    output_dir = collect_output(args.skill, brand_name, project_root, run_dir)
    print(f"Output collected to: {output_dir}", file=sys.stderr)

    rubric_path = RUBRICS_DIR / f"{args.skill}.yml"
    fixture_path = FIXTURES_DIR / f"{args.brand}.yml"
    det_grading = None
    llm_grading = None

    if rubric_path.exists():
        det_grading = run_deterministic_grader(rubric_path, output_dir)
        if det_grading:
            s = det_grading["summary"]
            print(f"Deterministic: {s['deterministic_score']}/{s['deterministic_max']} "
                  f"({s['checks_passed']}/{s['checks_total']} checks)", file=sys.stderr)

        if not args.skip_llm:
            llm_grading = run_llm_grader(rubric_path, output_dir, fixture_path)
            if llm_grading:
                s = llm_grading["summary"]
                print(f"LLM: {s['llm_score']}/{s['llm_max']} "
                      f"({s['checks_graded']} checks)", file=sys.stderr)
    else:
        print(f"No rubric found at {rubric_path}, skipping grading", file=sys.stderr)

    result = write_result(run_dir, args.skill, args.brand, det_grading, llm_grading, success, duration)
    print(json.dumps(result, indent=2, default=str))


if __name__ == "__main__":
    main()
