# Spec Compliance Review: {{scope_description}}

## What Was Requested

{{#each tasks}}
### Task {{task_id}}: {{task_name}}
{{task_definition}}
**Expected outputs:** {{files_written}}
{{/each}}

## What Was Built

{{#each task_reports}}
### Task {{task_id}} — Implementer Claims:
- Status: {{status}}
- Commit: {{commit_sha}}
- Artifacts: {{artifacts_written}}
{{/each}}

## CRITICAL: Do Not Trust the Reports

Read the ACTUAL files on disk. Verify:
1. **File existence** — every expected output file exists
2. **Non-empty** — files have real content, not placeholders
3. **Schema presence** — YAML files have required sections
4. **File ownership** — only wrote to owned paths (check git diff)
5. **State consistency** — state.yml reflects current progress

For each task, run: `git diff --stat {{base_sha}}..{{commit_sha}}`

## Output Format

```yaml
spec_compliance:
  scope: "{{scope_description}}"
  reviewed_at: "<ISO timestamp>"
  tasks:
    {{task_id}}:
      status: pass | fail
      checks:
        file_existence: { status: pass|fail, missing: [...] }
        non_empty: { status: pass|fail, empty: [...] }
        schema_presence: { status: pass|fail, missing_sections: [...] }
        file_ownership: { status: pass|fail, violations: [...] }
      issues: [{ file: "...", line: N, issue: "..." }]
  overall: pass | fail
  summary: "<one line>"
```
