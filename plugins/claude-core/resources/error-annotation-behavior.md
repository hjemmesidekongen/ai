# Error Annotation Behavior Rule

**Purpose:** This file contains the CLAUDE.md instruction for error annotation in tracing.
Add this to the project CLAUDE.md when claude-core tracing is active.

---

## CLAUDE.md Rule (copy this block)

```markdown
## Error annotation in tracing

When you encounter an error during work, immediately write an annotation following
the format in `plugins/claude-core/resources/error-annotation-format.yml`.

**Rules:**
- Write the annotation in the moment — do not rationalize or reconstruct after the fact
- Grade severity honestly: critical (blocks completion), warning (review later), info (noted)
- For light tracing: append an error-annotated line to `.ai/traces/trace-light.log`
  Format: `timestamp|tool_name|error|duration|context|severity|error_summary`
  The two extra pipe fields (severity, error_summary) extend the standard 5-field format
- For full tracing: add a structured error entry to the session YAML at
  `.ai/traces/sessions/trace-full-{date}.yml` under the `errors:` array
- The annotation is shared knowledge across sub-agents — write clearly enough that
  another agent can understand the error without surrounding context
- No pipe characters in error_summary — use dashes or commas instead
- error_summary max 120 characters, single line
- Do not skip annotations for "small" errors — if it's worth noticing, it's worth recording
```

---

## Integration notes

- This rule depends on trace-light.sh (t5) already being active
- The light trace hook writes standard entries automatically; this rule tells Claude
  to write *enhanced* error entries when errors are encountered
- The pre-completion-review hook (t8) will read these annotations to surface
  unresolved errors before task completion
- When full tracing is enabled (t6), Claude writes the structured YAML entry
  in addition to the light trace line
