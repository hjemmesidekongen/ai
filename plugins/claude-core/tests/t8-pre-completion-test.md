# t8: Pre-Completion Trace Review — Test Results

**Date:** 2026-03-08
**Script:** `plugins/claude-core/scripts/pre-completion-review.sh`
**Depends on:** t5 (trace-light.sh), t7 (error-annotation-format.yml)

## Purpose

Reads the trace log before marking a task complete. Filters today's error-annotated
entries by severity (critical, warning, info) and outputs a JSON systemMessage
summary. Blocks on critical errors, advises on warnings, passes when clean.

## Test Results

### Core functionality

| # | Test | Input | Expected | Result |
|---|------|-------|----------|--------|
| 1 | Clean trace (success lines only) | Light log with only success entries | CLEAN message | PASS |
| 2 | Critical error detected | 7-field line with severity=critical | BLOCK message with error list | PASS |
| 3 | Warning detected | 7-field line with severity=warning | ADVISORY message with warning list | PASS |
| 4 | Info entries not reported | 7-field line with severity=info | CLEAN (info is silent) | PASS |
| 5 | Critical + warning combined | Both in same log | BLOCK message listing critical + "Also: N warnings" | PASS |

### Date filtering

| # | Test | Input | Expected | Result |
|---|------|-------|----------|--------|
| 6 | Only today's entries processed | Errors from 2025-01-01 | CLEAN (old entries ignored) | PASS |
| 7 | Today's entries detected | Errors with today's date prefix | Correct counts | PASS |

### False-positive prevention

| # | Test | Input | Expected | Result |
|---|------|-------|----------|--------|
| 8 | Standard 5-field error line | `timestamp\|Edit\|error\|-\|foo.md` (no severity/summary) | CLEAN (not error-annotated) | PASS |
| 9 | Success lines ignored | `timestamp\|Write\|success\|42ms\|file.ts` | Not counted | PASS |

### Full trace session integration

| # | Test | Input | Expected | Result |
|---|------|-------|----------|--------|
| 10 | Full trace errors parsed | trace-config.yml level=full, session file with errors array | Critical + warning from session detected | PASS |
| 11 | Full trace ignored when level=light | trace-config.yml level=light | Session errors not counted | PASS |
| 12 | Combined light + full errors | Both sources have errors | All counted, labeled correctly ([tool] vs [full-trace]) | PASS |

### Edge cases

| # | Test | Input | Expected | Result |
|---|------|-------|----------|--------|
| 13 | Missing trace log file | No .ai/traces/trace-light.log | CLEAN, exit 0 | PASS |
| 14 | Empty trace log file | File exists but empty | CLEAN, exit 0 | PASS |
| 15 | No .ai/ directory at all | Run from /tmp | CLEAN, exit 0 | PASS |
| 16 | Missing trace-config.yml | No config file | Skips full trace check, exit 0 | PASS |
| 17 | Special characters in summary | Quotes, dashes, apostrophes | Valid JSON output | PASS |

### Output format

| # | Test | Input | Expected | Result |
|---|------|-------|----------|--------|
| 18 | CLEAN output is valid JSON | No errors | `python3 -m json.tool` succeeds | PASS |
| 19 | BLOCK output is valid JSON | Critical errors | `python3 -m json.tool` succeeds | PASS |
| 20 | ADVISORY output is valid JSON | Warnings only | `python3 -m json.tool` succeeds | PASS |
| 21 | Combined output is valid JSON | Critical + warning | `python3 -m json.tool` succeeds | PASS |

### Exit code

| # | Test | Input | Expected | Result |
|---|------|-------|----------|--------|
| 22 | Always exits 0 (clean) | No errors | Exit code 0 | PASS |
| 23 | Always exits 0 (critical) | Critical errors present | Exit code 0 | PASS |

### Performance

| # | Test | Input | Expected | Result |
|---|------|-------|----------|--------|
| 24 | Small log (<10 lines) | 1 entry | < 200ms | PASS (~10ms) |
| 25 | Large log (1000 lines) | 1000 entries + 2 errors | < 200ms | PASS (~20ms) |
| 26 | 3 consecutive runs consistency | Same input, 3 runs | Same output, stable timing | PASS (0.02s each) |

## Criteria from plan

- [x] Script correctly identifies critical errors in trace
- [x] Script correctly identifies warnings
- [x] Clean trace produces pass message
- [x] Script handles empty/missing trace gracefully
- [x] Execution < 200ms (measured: ~20ms with 1000-line log)

## Design Decisions

**Pure bash parsing:** No jq, awk, or grep — all field extraction uses bash builtins
(IFS splitting, case/esac, parameter expansion). This keeps execution fast and
dependency-free, consistent with trace-light.sh.

**Full trace is additive, not duplicative:** When full tracing is active, the script
reads the session file's errors array in addition to the light log. Error-annotated
light trace lines and full trace error entries are counted together. Labels
distinguish source: `[tool_name]` for light, `[full-trace]` for session file.

**Info severity is counted but not reported:** Info entries increment a counter but
don't appear in the output message. They're noteworthy observations that don't need
review before completion. This matches the severity guidelines in
error-annotation-format.yml.

**Advisory, not imperative:** The script always exits 0. It outputs a JSON
systemMessage that Claude reads and acts on — consistent with the hook design
pattern in ARCHITECTURE.md. A BLOCK message advises stopping; it doesn't enforce it.

## Uninstall Test

The script is standalone — not registered as a hook in plugin.json. It's called
on-demand (manually or by plan:execute). Removing it:
1. Delete `plugins/claude-core/scripts/pre-completion-review.sh`
2. No other script, hook, or command references it
3. plan:execute would need to be updated if it calls this script directly
