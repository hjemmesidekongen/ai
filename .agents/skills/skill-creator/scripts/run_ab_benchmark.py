#!/usr/bin/env python3
"""Run A/B content effectiveness benchmark for a skill.

Compares Claude's output with and without skill context loaded.
Uses `claude -p` for both execution and grading (no SDK needed).
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

from scripts.utils import parse_skill_md


def read_skill_content(skill_path: Path) -> str:
    """Read SKILL.md and process.md content."""
    content_parts = []

    skill_md = skill_path / "SKILL.md"
    if skill_md.exists():
        content_parts.append(f"# SKILL.md\n\n{skill_md.read_text()}")

    process_md = skill_path / "references" / "process.md"
    if process_md.exists():
        content_parts.append(f"# references/process.md\n\n{process_md.read_text()}")

    return "\n\n---\n\n".join(content_parts)


def find_project_root() -> Path:
    """Find the project root by walking up from cwd looking for .claude/."""
    current = Path.cwd()
    for parent in [current, *current.parents]:
        if (parent / ".claude").is_dir():
            return parent
    return current


def run_claude(prompt: str, output_dir: Path, model: str | None = None, timeout: int = 120) -> dict:
    """Run claude -p and capture output."""
    output_dir.mkdir(parents=True, exist_ok=True)

    cmd = ["claude", "-p", prompt, "--output-format", "text"]
    if model:
        cmd.extend(["--model", model])

    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
    project_root = find_project_root()

    start = time.time()
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout, env=env,
            cwd=str(project_root),
        )
        duration = time.time() - start
        response_text = result.stdout.strip()

        # Save transcript
        (output_dir / "transcript.md").write_text(
            f"# Execution Transcript\n\n"
            f"## Prompt\n\n{prompt[:500]}...\n\n"
            f"## Response\n\n{response_text}\n\n"
            f"## Stderr\n\n{result.stderr[:500] if result.stderr else 'None'}\n"
        )

        # Save raw output
        (output_dir / "output.txt").write_text(response_text)

        # Save timing
        timing = {"executor_duration_seconds": duration, "total_duration_seconds": duration}
        (output_dir / "timing.json").write_text(json.dumps(timing, indent=2))

        return {
            "success": result.returncode == 0,
            "response": response_text,
            "duration": duration,
            "output_chars": len(response_text),
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "response": "", "duration": timeout, "output_chars": 0}


def grade_output(
    expectations: list[str],
    transcript_path: Path,
    outputs_dir: Path,
    model: str | None = None,
    timeout: int = 120,
) -> dict:
    """Grade execution output using claude -p as grader."""
    transcript = transcript_path.read_text() if transcript_path.exists() else "No transcript"
    output_text = ""
    output_file = outputs_dir / "output.txt"
    if output_file.exists():
        output_text = output_file.read_text()

    expectations_text = "\n".join(f"- {e}" for e in expectations)

    grading_prompt = f"""You are a strict grader evaluating execution output against expectations.

## Expectations to evaluate:
{expectations_text}

## Execution Transcript:
{transcript[:3000]}

## Output:
{output_text[:3000]}

## Instructions:
For each expectation, determine PASS or FAIL with evidence.
PASS only when clear evidence exists. FAIL when evidence is absent or contradicts.

Return ONLY valid JSON (no markdown code blocks):
{{
  "expectations": [
    {{"text": "expectation text", "passed": true/false, "evidence": "specific evidence"}}
  ],
  "summary": {{"passed": N, "failed": N, "total": N, "pass_rate": 0.0-1.0}}
}}"""

    cmd = ["claude", "-p", grading_prompt, "--output-format", "text"]
    if model:
        cmd.extend(["--model", model])

    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, env=env, cwd=str(find_project_root()))

        # Extract JSON from response
        response = result.stdout.strip()
        try:
            outer = json.loads(response)
            response = outer.get("result", response)
        except json.JSONDecodeError:
            pass

        # Find JSON in response
        try:
            grading = json.loads(response)
        except json.JSONDecodeError:
            # Try to find JSON object in response
            start = response.find("{")
            end = response.rfind("}") + 1
            if start >= 0 and end > start:
                grading = json.loads(response[start:end])
            else:
                grading = {
                    "expectations": [{"text": e, "passed": False, "evidence": "Grading failed"} for e in expectations],
                    "summary": {"passed": 0, "failed": len(expectations), "total": len(expectations), "pass_rate": 0.0},
                }

        # Save grading
        grading_path = outputs_dir.parent / "grading.json"
        grading_path.write_text(json.dumps(grading, indent=2))

        return grading
    except Exception as e:
        grading = {
            "expectations": [{"text": e_text, "passed": False, "evidence": f"Grading error: {e}"} for e_text in expectations],
            "summary": {"passed": 0, "failed": len(expectations), "total": len(expectations), "pass_rate": 0.0},
        }
        (outputs_dir.parent / "grading.json").write_text(json.dumps(grading, indent=2))
        return grading


def run_benchmark(
    skill_path: Path,
    evals_path: Path,
    output_dir: Path,
    model: str | None = None,
    exec_timeout: int = 120,
    grade_timeout: int = 120,
) -> dict:
    """Run full A/B benchmark for a skill."""
    name, description, _ = parse_skill_md(skill_path)
    skill_content = read_skill_content(skill_path)

    with open(evals_path) as f:
        evals_data = json.load(f)

    evals = evals_data.get("evals", [])
    all_results = []

    for eval_case in evals:
        eval_id = eval_case["id"]
        prompt = eval_case["prompt"]
        expectations = eval_case.get("expectations", [])

        eval_dir = output_dir / f"eval-{eval_id}"
        print(f"\n{'='*60}", file=sys.stderr)
        print(f"Eval {eval_id}: {prompt[:80]}...", file=sys.stderr)
        print(f"{'='*60}", file=sys.stderr)

        # With skill
        print(f"  Running WITH skill...", file=sys.stderr)
        with_prompt = (
            f"You are executing the '{name}' skill. Follow these instructions:\n\n"
            f"{skill_content}\n\n"
            f"---\n\n"
            f"TASK: {prompt}"
        )
        with_dir = eval_dir / "with_skill" / "run-1" / "outputs"
        with_result = run_claude(with_prompt, with_dir, model, exec_timeout)
        print(f"  WITH: {with_result['output_chars']} chars, {with_result['duration']:.1f}s", file=sys.stderr)

        # Without skill
        print(f"  Running WITHOUT skill...", file=sys.stderr)
        without_dir = eval_dir / "without_skill" / "run-1" / "outputs"
        without_result = run_claude(prompt, without_dir, model, exec_timeout)
        print(f"  WITHOUT: {without_result['output_chars']} chars, {without_result['duration']:.1f}s", file=sys.stderr)

        # Grade both
        print(f"  Grading WITH skill...", file=sys.stderr)
        with_grading = grade_output(
            expectations, with_dir / "transcript.md", with_dir, model, grade_timeout
        )

        print(f"  Grading WITHOUT skill...", file=sys.stderr)
        without_grading = grade_output(
            expectations, without_dir / "transcript.md", without_dir, model, grade_timeout
        )

        with_rate = with_grading.get("summary", {}).get("pass_rate", 0)
        without_rate = without_grading.get("summary", {}).get("pass_rate", 0)
        delta = with_rate - without_rate

        print(f"  WITH pass_rate={with_rate:.2f} WITHOUT pass_rate={without_rate:.2f} delta={delta:+.2f}", file=sys.stderr)

        all_results.append({
            "eval_id": eval_id,
            "with_skill": {"pass_rate": with_rate, "chars": with_result["output_chars"], "duration": with_result["duration"]},
            "without_skill": {"pass_rate": without_rate, "chars": without_result["output_chars"], "duration": without_result["duration"]},
            "delta": delta,
        })

    # Aggregate
    avg_with = sum(r["with_skill"]["pass_rate"] for r in all_results) / len(all_results) if all_results else 0
    avg_without = sum(r["without_skill"]["pass_rate"] for r in all_results) / len(all_results) if all_results else 0
    avg_delta = avg_with - avg_without

    summary = {
        "skill_name": name,
        "skill_path": str(skill_path),
        "model": model,
        "evals_run": len(all_results),
        "avg_with_skill_pass_rate": round(avg_with, 3),
        "avg_without_skill_pass_rate": round(avg_without, 3),
        "avg_delta": round(avg_delta, 3),
        "per_eval": all_results,
    }

    (output_dir / "benchmark.json").write_text(json.dumps(summary, indent=2))

    print(f"\n{'='*60}", file=sys.stderr)
    print(f"SUMMARY: {name}", file=sys.stderr)
    print(f"  With skill:    {avg_with:.1%} pass rate", file=sys.stderr)
    print(f"  Without skill: {avg_without:.1%} pass rate", file=sys.stderr)
    print(f"  Delta:         {avg_delta:+.1%}", file=sys.stderr)
    print(f"{'='*60}", file=sys.stderr)

    # Output JSON to stdout
    json.dump(summary, sys.stdout, indent=2)
    return summary


def main():
    parser = argparse.ArgumentParser(description="Run A/B content effectiveness benchmark")
    parser.add_argument("--skill-path", required=True, help="Path to skill directory")
    parser.add_argument("--evals", required=True, help="Path to evals.json")
    parser.add_argument("--output-dir", required=True, help="Output directory for results")
    parser.add_argument("--model", default=None, help="Model to use")
    parser.add_argument("--exec-timeout", type=int, default=120, help="Execution timeout per run")
    parser.add_argument("--grade-timeout", type=int, default=120, help="Grading timeout per run")
    args = parser.parse_args()

    run_benchmark(
        skill_path=Path(args.skill_path),
        evals_path=Path(args.evals),
        output_dir=Path(args.output_dir),
        model=args.model,
        exec_timeout=args.exec_timeout,
        grade_timeout=args.grade_timeout,
    )


if __name__ == "__main__":
    main()
