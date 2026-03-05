# Trace Protocol

Single source of truth for structured trace capture across all agency skills.

## Activation

Only trace when `state.yml` contains:
```yaml
trace:
  enabled: true
  mode: full        # full | decision-only
  traces_dir: ".ai/projects/[name]/traces/"
```

If `trace.enabled` is false or absent, skip all trace behavior.

## File Naming

Write trace to: `{traces_dir}/{skill-name}-{ISO-timestamp}.yml`

Example: `.ai/projects/blick/traces/feature-decomposer-2026-03-04T14-23-01Z.yml`

Use dashes (not colons) in the filename timestamp for filesystem safety.

## Schema Modes

### Full Mode (`trace.mode: full`)

Capture all fields per step:
- `step` — must match the `## Step N:` heading from process.md exactly
- `started_at` — write `"[HOOK_TS]"` (replaced by hook with real UTC timestamp)
- `inputs_read` — list of `{ path, summary }` for each file read
- `decision` — what was decided at this step
- `reasoning` — why this decision was made
- `alternatives_considered` — list of alternatives evaluated and why rejected
- `uncertainty` — float 0.0 (certain) to 1.0 (guessing)
- `quality_assessment` — brief self-assessment of output quality
- `observation` — what actually happened vs expected; captures surprises, gaps, or confirmations
- `improvement_idea` — actionable suggestion for improving the skill, schema, or pipeline
- `design_decision` — choices with lasting impact beyond this run (architecture, defaults, conventions)
- `flags` — list of concern tags: `missing_input`, `ambiguous_spec`, `low_confidence`, `schema_mismatch`, `fallback_used`
- `token_estimate_step` — estimated tokens consumed in this step

### Decision-Only Mode (`trace.mode: decision-only`)

Capture per step: `step`, `decision`, `uncertainty` only.

## Writing Cadence

Write or update the trace file **every 2 process.md steps** (mirrors the 2-Action Rule for findings.md). After the final step and checkpoint, write the complete file.

## Timestamps

**Preferred:** Write real UTC timestamps directly in ISO 8601 format (e.g. `2026-03-05T14:23:01Z`).
Use the current date/time known to the session.

**Fallback (hook-based):** Write `"[HOOK_TS]"` as a placeholder. The PostToolUse hook (`inject-trace-timestamp.sh`) replaces `[HOOK_TS]` with real UTC timestamps after writes to `traces/` paths. Note: This requires the hook to be properly registered and may not work in all sessions.

## Token Estimation Table

Use these estimates when reporting `token_estimate_step`:

| Operation | Est. Tokens |
|-----------|-------------|
| Read YAML < 50 lines | ~100 |
| Read YAML 50-200 lines | ~300 |
| Read markdown < 100 lines | ~150 |
| Write YAML output | ~400-800 |
| Dispatch subagent (task + response) | ~800-1500 |
| User interaction round | ~200 |
| Checkpoint evaluation | ~150 |

## Trace File Structure

```yaml
_meta:
  schema: "trace"
  version: "1.0.0"
  skill: "{skill-name}"
  module: "{module}"
  project: "{project}"
  started_at: "[HOOK_TS]"
  ended_at: "[HOOK_TS]"
  duration_seconds: null          # filled after completion if timestamps available
  token_estimate: 0               # sum of all step estimates
  trace_mode: "full"              # full | decision-only

steps:
  - step: "Step 1: ..."
    started_at: "[HOOK_TS]"
    inputs_read: []
    decision: ""
    reasoning: ""
    alternatives_considered: []
    observation: ""               # what happened vs expected
    improvement_idea: ""          # actionable fix for the plugin/skill
    design_decision: ""           # lasting choice (omit if none)
    uncertainty: 0.0
    quality_assessment: ""
    flags: []
    token_estimate_step: 0

checkpoint_result:
  status: "passed"                # passed | failed
  checks_run: 0
  checks_passed: 0
  failure_details: []

quality_summary:
  avg_uncertainty: 0.0
  lowest_confidence_step: ""
  flags_raised: []
  recommendation: ""

reflections:                      # trace-level learning loop
  observations: []                # patterns, surprises, gaps across the full run
  improvement_ideas: []           # actionable suggestions for plugin/pipeline
  design_decisions: []            # significant choices affecting future work

errors_during_run: []             # copied from state.yml errors added during this run
```

## Recovery

If `/compact` fires mid-skill, the trace file on disk persists. On resume:
1. Read the existing trace file from `traces_dir`
2. Identify the last completed step
3. Continue appending subsequent steps

## Reflections: Step-Level vs Trace-Level

Use **step-level** `observation`, `improvement_idea`, and `design_decision` for insights tied to a specific step — e.g. "brand-loader should detect missing brand-summary.yml" belongs on the brand-loader step.

Use **trace-level** `reflections` for cross-cutting insights that span multiple steps or affect the pipeline as a whole — e.g. "the pipeline always restarts from brand because auto-detect checks the wrong module" is a pipeline-level observation.

A trace with no reflections at either level is a missed opportunity. Every run teaches something — even "everything worked as expected" is worth noting in `reflections.observations`.

## Rules

1. Never trace when `trace.enabled` is not `true`
2. Step names must match process.md headings exactly
3. Uncertainty of 0.0 means all inputs present and clear; 1.0 means guessing with no supporting data
4. Always write `quality_summary` after the checkpoint completes
5. Always write `reflections` after the checkpoint — at minimum one observation
6. Keep trace files — never delete or overwrite a previous run's trace
