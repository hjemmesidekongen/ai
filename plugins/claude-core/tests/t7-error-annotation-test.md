# t7: Error Annotation in Tracing — Test Results

**Date:** 2026-03-08
**Format file:** `plugins/claude-core/resources/error-annotation-format.yml`
**Behavior rule:** `plugins/claude-core/resources/error-annotation-behavior.md`
**Depends on:** t5 (trace-light.sh)

## Files Created

| File | Purpose |
|------|---------|
| `resources/error-annotation-format.yml` | Structured format for error annotations (light + full) |
| `resources/error-annotation-behavior.md` | CLAUDE.md instruction (staged, not yet added to CLAUDE.md) |

## Test Results

### Format validation (YAML parseability)

| # | Test | Result |
|---|------|--------|
| 1 | error-annotation-format.yml is valid YAML (ruby YAML.load_file) | PASS |
| 2 | Top-level keys: light_trace, full_trace, severity_guidelines, constraints | PASS |
| 3 | Severity enum values: critical, warning, info | PASS |
| 4 | Full trace required fields: timestamp, severity, error_summary, context | PASS |
| 5 | Full trace optional fields: reproduction, expected, actual, suggested_fix, related_files, trace_ref | PASS |

### Light trace example validation

| # | Test | Result |
|---|------|--------|
| 6 | `standard_error` example: 7 pipe-delimited fields | PASS |
| 7 | `warning` example: 7 pipe-delimited fields | PASS |
| 8 | `info` example: 7 pipe-delimited fields | PASS |
| 9 | All examples: status field == "error" | PASS |
| 10 | All examples: severity field is valid enum value | PASS |
| 11 | All examples: error_summary has no pipe characters | PASS |
| 12 | All examples: error_summary <= 120 characters | PASS |

### Light trace compatibility (error lines don't break standard parsing)

| # | Test | Result |
|---|------|--------|
| 13 | Standard 5-field line still parses correctly | PASS |
| 14 | Error-annotated lines detected by: status=="error" AND field_count>=7 | PASS |
| 15 | Standard success lines NOT detected as error-annotated | PASS |
| 16 | Standard error lines (5 fields) NOT detected as error-annotated (no false positive) | PASS |

### Full trace example validation

| # | Test | Result |
|---|------|--------|
| 17 | All 4 required fields present in example | PASS |
| 18 | All fields in example are defined (required or optional) | PASS |
| 19 | Severity value is valid enum member | PASS |
| 20 | error_summary: length <= 120, no pipe, single line | PASS |
| 21 | related_files is a list (array type) | PASS |

### CLAUDE.md behavior rule validation

| # | Test | Result |
|---|------|--------|
| 22 | Behavior rule references correct format file path | PASS |
| 23 | Rule specifies light trace format (7-field pipe line) | PASS |
| 24 | Rule specifies full trace format (session YAML errors array) | PASS |
| 25 | Rule covers: write in the moment, not after the fact | PASS |
| 26 | Rule covers: annotations as shared knowledge across sub-agents | PASS |
| 27 | Rule is self-contained (can be copy-pasted to CLAUDE.md as-is) | PASS |

## Criteria from plan.yml

- [x] Error annotation format is documented and parseable
- [x] Example entries validate against format (all 3 light + 1 full example pass)
- [x] CLAUDE.md behavior rule is clear and actionable
- [x] Annotations don't break light trace log parsing (error lines use same pipe format, detected by field count)

## Design Decisions

**Light trace error format:** Extended from 5 to 7 fields (added severity + error_summary).
Detection uses `status == "error" AND field_count >= 7` — backward compatible because
existing 5-field error lines (from trace-light.sh) remain valid and are not confused
with annotated error lines. This means:
- trace-light.sh continues writing standard 5-field error lines automatically
- Claude writes 7-field annotated error lines manually when it observes an error
- Parsers can distinguish the two by field count

**Behavior is a CLAUDE.md instruction, not a hook:** The format file defines structure;
the behavior rule tells Claude to use it. The actual annotation is written by Claude
(via Write/Edit to the trace file), not by any automated hook. This matches the
architecture principle: hooks are advisory, Claude decides action.

## Uninstall Test

Error annotation is a resource file + behavior rule — no hooks, no scripts.
Removing `resources/error-annotation-format.yml` and `resources/error-annotation-behavior.md`:
1. trace-light.sh continues to work (it writes standard 5-field lines independently)
2. No other script or hook references these files
3. The only downstream consumer is pre-completion-review.sh (t8), which has not been
   built yet and will handle missing format gracefully
