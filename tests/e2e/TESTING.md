# E2E Plugin Testing Infrastructure

End-to-end evaluation suite for plugin skills. Tests individual skills against
brand fixtures, scores output with deterministic + LLM graders, and tracks
quality over time via baseline comparison.

## Architecture

```
fixture (brand brief) -> run skill via claude -p -> capture output -> grade -> result.yml
```

Each test case: ~8k tokens, 30-60 seconds. Individual skill tests, not pipelines.

## Directory Structure

```
tests/e2e/
  fixtures/brands/     # Minimal brand briefs (5-10 lines each)
  rubrics/             # Versioned scoring rubrics per skill
  scripts/             # Runner and grader scripts
  runs/{timestamp}/    # Timestamped test results
  test-matrix.yml      # Which skill x brand combinations to run
  baseline.yml         # Canonical comparison point
```

## Brands

| Brand | Type | Fixture |
|-------|------|---------|
| CloudMetrics | SaaS B2B (global) | `cloudmetrics.yml` |
| Klip & Co | Local hairdresser (hyperlocal) | `klip-co.yml` |
| DanskBolig | National real estate (nationwide) | `danskbolig.yml` |
| Nordic Essentials | Nationwide webshop (e-commerce) | `nordic-essentials.yml` |

## Running Tests

### Single test

```bash
# Full test (deterministic + LLM grading)
python3 tests/e2e/scripts/run_test.py --skill brand-audit --brand cloudmetrics

# Deterministic grading only (faster, no API calls)
python3 tests/e2e/scripts/run_test.py --skill brand-audit --brand cloudmetrics --skip-llm

# Dry run (print prompt without executing)
python3 tests/e2e/scripts/run_test.py --skill brand-audit --brand cloudmetrics --dry-run
```

### All tests

```bash
# Run everything in test-matrix.yml
python3 tests/e2e/scripts/run_all.py

# Skip LLM grading
python3 tests/e2e/scripts/run_all.py --skip-llm

# Run and set as new baseline
python3 tests/e2e/scripts/run_all.py --set-baseline
```

### Standalone grading

```bash
# Deterministic grading on existing output
python3 tests/e2e/scripts/grade_deterministic.py \
  --rubric tests/e2e/rubrics/brand-audit.yml \
  --output-dir tests/e2e/runs/20260311-120000/brand-audit--cloudmetrics \
  --verbose

# LLM grading on existing output
python3 tests/e2e/scripts/grade_llm.py \
  --rubric tests/e2e/rubrics/brand-audit.yml \
  --output-dir tests/e2e/runs/20260311-120000/brand-audit--cloudmetrics \
  --fixture tests/e2e/fixtures/brands/cloudmetrics.yml \
  --verbose
```

## Baseline Comparison

```bash
# Compare a run against baseline
python3 tests/e2e/scripts/compare_baseline.py --run-dir tests/e2e/runs/20260311-120000

# Set a run as the new baseline
python3 tests/e2e/scripts/compare_baseline.py --run-dir tests/e2e/runs/20260311-120000 --set-baseline

# YAML output
python3 tests/e2e/scripts/compare_baseline.py --run-dir tests/e2e/runs/20260311-120000 --output yaml
```

Output format:
```
Test                                     Baseline    Current    Delta Notes
--------------------------------------------------------------------------------
brand-audit--cloudmetrics                      72         78       +6
brand-audit--klip-co                           —         65        — New test
```

## Grading

Two-tier grading (D-005):
- **Deterministic (~70%)**: Schema compliance, required fields, value ranges, file existence
- **LLM-graded (~30%)**: Qualitative dimensions scored by Haiku against rubric prompts

## Rubric Format

```yaml
version: "1.0.0"
skill: brand-audit
max_score: 100

checks:
  deterministic:
    - id: check_name
      description: "What this checks"
      type: file_exists | file_not_empty | yaml_field_exists | yaml_value_range | yaml_array_min_length
      path: "relative/path"
      points: 5

  llm_graded:
    - id: check_name
      description: "What this evaluates"
      prompt: "Grading instructions for Haiku"
      points: 10
```

## Rubric Versioning

Every rubric has a `version` field. Every result records which version was used.
When a rubric changes, re-run baseline so comparisons remain valid (D-006).
The comparison script warns when rubric versions don't match.

## Test Matrix

`test-matrix.yml` defines which skill x brand combinations to run:
- Generative skills: all 4 brands (full matrix)
- Transformation skills: single brand (cloudmetrics only)

## Decisions

All architectural decisions in `.ai/brainstorm/plugin-testing-infrastructure/decisions.yml`.
