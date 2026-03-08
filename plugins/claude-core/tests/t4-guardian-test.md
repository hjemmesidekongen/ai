# t4: CLAUDE.md Guardian Hook — Test Results

**Date:** 2026-03-08
**Script:** `plugins/claude-core/scripts/claude-md-guardian.sh`
**Hook registration:** `plugins/claude-core/.claude-plugin/plugin.json` (PostToolUse, matcher: Write|Edit)

## Test Results

| # | Test | Result |
|---|------|--------|
| 1 | CLAUDE.md edit triggers advisory output | PASS |
| 2 | Non-CLAUDE.md file produces no output | PASS |
| 3 | Nested CLAUDE.md path (subdir/CLAUDE.md) triggers | PASS |
| 4 | Case-insensitive match (claude.md) triggers | PASS |
| 5 | Empty JSON input — no crash, exit 0 | PASS |
| 6 | Empty stdin — no crash, exit 0 | PASS |
| 7 | claude-config.yml does NOT trigger (no false positive) | PASS |
| 8 | Output is valid JSON with systemMessage key | PASS |
| 9 | Performance: 15ms avg (10 runs, 150ms total) | PASS (<50ms) |
| 10 | plugin.json remains valid JSON after hook registration | PASS |
| 11 | Advisory contains all 4 validation checks | PASS |
| 12 | Grep fallback works when jq unavailable | PASS |

## Criteria from plan.yml

- [x] Hook fires when CLAUDE.md is edited
- [x] Hook does NOT fire for other files
- [x] Hook output is clear and actionable (4 specific checks + action directive)
- [x] Hook execution < 50ms (measured: 15ms avg)
- [x] Uninstall test: script is a standalone PostToolUse hook — removing it from plugin.json and deleting the script has no effect on any other feature

## Uninstall Test

The guardian hook is registered as a single entry in plugin.json PostToolUse array. Removing it:
1. Delete `plugins/claude-core/scripts/claude-md-guardian.sh`
2. Remove the Write|Edit matcher block from plugin.json PostToolUse array

No other script, command, or skill references this hook. The `|| true` in the plugin.json command ensures that even if the script is missing, the hook silently succeeds.
