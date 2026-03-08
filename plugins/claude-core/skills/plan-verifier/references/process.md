# plan-verifier — Process

## Stage 1: Spec Compliance

Five mechanical checks. All must pass for Stage 1 to pass.

### Check 1: File Existence

For every file in the wave's tasks' `files_written`:
- Exact files: must exist on disk
- Section refs (`file.yml#section`): parent file must exist
- Globs (`dir/*`): at least one matching file must exist

### Check 2: Schema Presence

For YAML files in the output:
- File must parse as valid YAML
- Expected top-level keys must be present (derived from task description or skill checkpoint)
- Non-YAML files: skip this check

### Check 3: Non-Empty

No output should be a stub or placeholder:
- File size > 0 bytes
- YAML values not null, empty string, empty array, or empty object
- Markdown files have substantive content (not just headings or TODOs)

### Check 4: File Ownership

Tasks only wrote to files they own (per the plan's file-ownership assignments):
- Check actual file modifications against the plan's `files_written` declarations
- Flag any file that was modified but not in the task's ownership list
- Read-only files (`files_read`) must not have been modified

### Check 5: State Consistency

`state.yml` reflects the wave's execution:
- Wave status is `in_progress` or `completed`
- Task statuses match their actual state
- `current_phase` matches the wave being verified
- `updated_at` is recent

### Stage 1 output

```yaml
spec_compliance:
  wave: 1
  status: pass | fail
  checks:
    file_existence: { status: pass|fail, missing: [] }
    schema_presence: { status: pass|fail|skipped, issues: [] }
    non_empty: { status: pass|fail, empty_files: [] }
    file_ownership: { status: pass|fail, violations: [] }
    state_consistency: { status: pass|fail, issues: [] }
  failed_count: 0
```

## Stage 2: Quality Review

Only runs when:
- Stage 1 passed
- Wave has `qa_review: true` (always true for final wave)

Quality review is judgment-based, not mechanical. Evaluate:

### Content quality
- Does the output match the task description?
- Is the content complete, not just structurally valid?
- Are there logical errors, inconsistencies, or missing pieces?

### Cross-wave consistency
- Does the output align with prior waves' outputs?
- Are naming conventions consistent?
- Do references to other files/sections resolve correctly?

### Completeness
- Are all aspects of the task addressed?
- Are edge cases handled?
- Is the output ready for the next wave to consume?

### Stage 2 output

```yaml
qa_review:
  wave: 1
  status: pass | pass_with_notes | fail
  findings:
    - area: "content quality"
      severity: info | warning | critical
      detail: "Description of finding"
      fix_required: true | false
  summary: "Brief assessment"
```

## Error logging

On any failure, append to state.yml `errors` array:

```yaml
errors:
  - timestamp: "2026-03-08T19:00:00Z"
    skill: "plan-verifier/wave-1"
    error: "file_existence: skills/a/SKILL.md missing"
    attempted_fix: "pending"
    result: "unresolved"
    next_approach: "Rebuild skill A"
```

**Rules:**
- Log immediately on failure
- Before re-running, check prior errors to avoid repeating failed approaches
- On successful re-check, update `result: resolved` but keep the entry
- Max 3 re-run rounds before escalating to manual review

## Verdict rules

- **pass**: All Stage 1 checks pass + Stage 2 passes (or skipped)
- **pass_with_warnings**: All checks pass but Stage 2 has non-blocking notes
- **fail**: Any Stage 1 check fails, OR Stage 2 has `fix_required: true` findings

## A/B benchmark verification

When the wave's verification type is `ab_benchmark`:
- Run `run_ab_benchmark.py` for each skill in the wave
- Gate: `avg_delta >= 0.05` and `avg_with_skill_pass_rate >= 0.6`
- Run `run_eval.py` for trigger accuracy: >= 0.7 for positive cases
- If fail: attempt `improve_description.py` (max 3 iterations), then manual review
- Store results in `tests/` directory
