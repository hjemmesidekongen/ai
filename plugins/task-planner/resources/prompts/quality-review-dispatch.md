# Quality Review: Wave {{wave_number}}

## What Was Implemented

{{wave_summary}}

## Git Diff Scope

```
BASE_SHA: {{wave_base_sha}}
HEAD_SHA: {{wave_head_sha}}
```

Run `git diff --stat {{wave_base_sha}}..{{wave_head_sha}}` to see all changes.
Then `git diff {{wave_base_sha}}..{{wave_head_sha}}` for full diff.

## Review Checklist

1. **Content Coherence** — do values make sense together?
2. **Domain Consistency** — does output align with brand/project context?
3. **Completeness** — are there gaps that pass schema but represent thin work?
4. **Quality Floor** — is content professional and specific, not generic?
5. **Cross-Skill Alignment** — do outputs build on earlier decisions correctly?

## Plan Context
{{#if plan_requirements}}
{{plan_requirements}}
{{/if}}

## Stage 1 Report
{{stage1_report_summary}}

## Output Format

```yaml
qa_report:
  wave: {{wave_number}}
  reviewed_at: "<ISO timestamp>"
  review_round: {{round}}
  base_sha: "{{wave_base_sha}}"
  head_sha: "{{wave_head_sha}}"
  checks:
    - name: "<check name>"
      status: pass | fail | pass_with_notes
      notes: "<specific findings with file:line references>"
      fix_required: true | false
      severity: critical | important | minor
  verdict: PASS | PASS_WITH_NOTES | FAIL
  blocking_issues: <count>
  strengths: [<what was done well>]
  recommendations: [<non-blocking suggestions>]
```
