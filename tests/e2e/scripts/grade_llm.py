#!/usr/bin/env python3
"""LLM grader for E2E plugin tests.

Runs qualitative rubric checks via claude -p with Haiku model.
Reads the rubric's llm_graded section, constructs evaluation prompts
with actual skill output, parses 0-10 scores.

Outputs JSON matching the deterministic grader format.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

import yaml


def load_output_file(output_dir: Path, filename: str) -> str:
    """Load a file from the output directory, return empty string if missing."""
    path = output_dir / filename
    if path.exists():
        return path.read_text()
    return ""


def build_grading_prompt(check: dict, output_dir: Path, fixture: dict | None) -> str:
    """Build a grading prompt for a single LLM check."""
    # Load all output files for context
    output_files = {}
    for f in output_dir.iterdir():
        if f.is_file() and f.suffix in (".yml", ".yaml", ".md"):
            output_files[f.name] = f.read_text()

    fixture_text = ""
    if fixture:
        fixture_text = f"\n## Brand Brief (Input)\n```yaml\n{yaml.dump(fixture, default_flow_style=False)}```\n"

    files_text = ""
    for name, content in output_files.items():
        files_text += f"\n### {name}\n```\n{content}\n```\n"

    return f"""You are a quality grader for brand skill output. Score this check on a 0-10 scale.

## Check
{check['description']}

## Grading Criteria
{check['prompt']}
{fixture_text}
## Skill Output Files
{files_text}

## Instructions
- Score 0-10 where 10 is perfect
- Respond with ONLY a JSON object: {{"score": <number>, "reasoning": "<one sentence>"}}
- Be strict but fair. A score of 7+ means genuinely good quality.
- Do not be generous — if the output is generic or could apply to any brand, score low.
"""


def run_llm_check(prompt: str, timeout: int = 60) -> dict:
    """Execute a single LLM grading check via claude -p with Haiku."""
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    cmd = [
        "claude",
        "-p", prompt,
        "--output-format", "text",
        "--model", "claude-haiku-4-5-20251001",
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env,
        )
        if result.returncode != 0:
            return {"score": 0, "reasoning": f"claude -p failed: {result.stderr[:200]}"}

        # Parse JSON from response (may have surrounding text)
        output = result.stdout.strip()
        json_match = re.search(r'\{[^}]*"score"\s*:\s*\d+[^}]*\}', output)
        if json_match:
            return json.loads(json_match.group())
        return {"score": 0, "reasoning": f"Could not parse score from: {output[:200]}"}

    except subprocess.TimeoutExpired:
        return {"score": 0, "reasoning": "LLM grading timed out"}
    except Exception as e:
        return {"score": 0, "reasoning": str(e)}


def grade(rubric_path: Path, output_dir: Path, fixture_path: Path | None = None,
          timeout: int = 60) -> dict:
    """Run all LLM-graded checks from a rubric against an output directory."""
    rubric = yaml.safe_load(rubric_path.read_text())
    llm_checks = rubric.get("checks", {}).get("llm_graded", [])

    if not llm_checks:
        return {
            "rubric": rubric["skill"],
            "rubric_version": rubric["version"],
            "output_dir": str(output_dir),
            "checks": [],
            "summary": {
                "llm_score": 0,
                "llm_max": 0,
                "checks_graded": 0,
            },
        }

    fixture = None
    if fixture_path and fixture_path.exists():
        fixture = yaml.safe_load(fixture_path.read_text())

    results = []
    for check in llm_checks:
        prompt = build_grading_prompt(check, output_dir, fixture)
        llm_result = run_llm_check(prompt, timeout=timeout)

        raw_score = llm_result.get("score", 0)
        # Scale 0-10 score to check's point value
        scaled_score = round(raw_score / 10.0 * check["points"], 1)

        results.append({
            "id": check["id"],
            "description": check["description"],
            "type": "llm_graded",
            "raw_score": raw_score,
            "points_earned": scaled_score,
            "points_possible": check["points"],
            "reasoning": llm_result.get("reasoning", ""),
        })

    total_earned = sum(r["points_earned"] for r in results)
    total_possible = sum(r["points_possible"] for r in results)

    return {
        "rubric": rubric["skill"],
        "rubric_version": rubric["version"],
        "output_dir": str(output_dir),
        "checks": results,
        "summary": {
            "llm_score": total_earned,
            "llm_max": total_possible,
            "checks_graded": len(results),
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Run LLM-graded quality checks")
    parser.add_argument("--rubric", required=True, help="Path to rubric YAML file")
    parser.add_argument("--output-dir", required=True, help="Path to skill output directory")
    parser.add_argument("--fixture", default=None, help="Path to brand fixture (for context)")
    parser.add_argument("--timeout", type=int, default=60, help="Timeout per LLM check in seconds")
    parser.add_argument("--verbose", action="store_true", help="Print per-check details to stderr")
    args = parser.parse_args()

    rubric_path = Path(args.rubric)
    output_dir = Path(args.output_dir)
    fixture_path = Path(args.fixture) if args.fixture else None

    if not rubric_path.exists():
        print(f"Error: Rubric not found: {rubric_path}", file=sys.stderr)
        sys.exit(1)
    if not output_dir.exists():
        print(f"Error: Output directory not found: {output_dir}", file=sys.stderr)
        sys.exit(1)

    result = grade(rubric_path, output_dir, fixture_path, timeout=args.timeout)

    if args.verbose:
        s = result["summary"]
        print(f"LLM Score: {s['llm_score']}/{s['llm_max']} "
              f"({s['checks_graded']} checks)", file=sys.stderr)
        for check in result["checks"]:
            print(f"  [{check['raw_score']}/10] {check['points_earned']}/{check['points_possible']} "
                  f"{check['description']}: {check['reasoning']}", file=sys.stderr)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
