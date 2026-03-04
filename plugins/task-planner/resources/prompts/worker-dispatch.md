# Task {{task_id}}: {{task_name}}

## Your Assignment

{{task_definition_from_plan}}

## Skill Instructions

{{SKILL_MD_content}}

## File Ownership

**You MUST only write to these paths:**
{{#each owns}}
- {{path}}
{{/each}}

**You may read from:**
{{#each reads}}
- {{path}}
{{/each}}

## Before You Start

Read these files in order before beginning work:
{{#each read_list}}
- `{{path}}` — {{reason}}
{{/each}}

## Error Context
{{#if previous_errors}}
Previous attempt failed. Do NOT repeat the same approach.
- Error: {{error}}
- What was tried: {{attempted_fix}}
- Try instead: {{next_approach}}
{{else}}
No previous errors for this task.
{{/if}}

## Completion Gate
{{#if project_context}}
This project has a completion gate. After your work passes self-review,
run these checks before committing (code files only — skip for YAML/Markdown/SVG):

- Build: `{{project_context.build_cmd}}`
- Lint: `{{project_context.lint_cmd}}`
- Test: `{{project_context.test_cmd}}`

If a check fails, attempt one fix. If still failing, report `status: failed`.
If `project_context` commands are empty, skip that individual check.
{{else}}
No completion gate configured for this project. Proceed to commit after self-review.
{{/if}}

## Self-Tier Assessment
{{#if self_tier}}
Your model_tier is "self". Before starting work, assess the task complexity:

| Dimension | junior | senior | principal |
|-----------|--------|--------|-----------|
| Scope | Single file | Multi-file | System-wide |
| Ambiguity | Clear spec | Some choices | Open-ended |
| Risk | Isolated | Affects features | Critical path |
| Domain | Basic | Moderate | Deep specialist |

Declare your tier (take the highest from any dimension) and include in your report:
```yaml
self_tier_assessment:
  declared_tier: "<junior|senior|principal>"
  reasoning: "<why>"
```

If execution fails: report `status: failed` with your tier. The orchestrator
will re-dispatch at the next tier up (junior→senior→principal→blocked).
{{else}}
Your model_tier is "{{model_tier}}" — no self-assessment needed.
{{/if}}

## Commit Your Work

When implementation is complete:
1. Stage only files in your ownership list
2. Commit with message: `{{plan_name}}: {{task_name}} [{{task_id}}]`
3. Note the commit SHA in your report

## Report Format

When done, output exactly this YAML structure:

```yaml
task_complete:
  task_id: "{{task_id}}"
  model_tier: "{{model_tier}}"
  status: completed | failed | blocked
  commit_sha: "<the commit hash>"
  artifacts_written:
    - path: "<file path>"
      description: "<what this file contains>"
  decisions_made:
    - "<any judgment calls you made>"
  recovery_notes: |
    <brief description of what you did, key decisions,
     and context the next task might need>
  error: "<only if status is failed or blocked>"
  needs: "<only if status is blocked>"
```

## Rules

1. Only write to files in your ownership list — violations will be caught
2. Do not evaluate the quality of your own output — reviewers handle that
3. If blocked, report honestly — do not produce placeholder output
4. Commit before reporting — your commit is the deliverable
