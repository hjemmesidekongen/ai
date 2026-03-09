# t5: Light Tracing Hook — Test Results

**Date:** 2026-03-08
**Script:** `plugins/claude-core/scripts/trace-light.sh`
**Hook registration:** `plugins/claude-core/.claude-plugin/plugin.json` (PostToolUse, no matcher — fires on all tools)
**Log location:** `.ai/traces/trace-light.log`

## Log Format

```
timestamp|tool_name|status|context
```

Example entries:
```
2026-03-08T15:35:26Z|Write|success|plugins/claude-core/README.md
2026-03-08T15:35:26Z|Bash|success|ls
2026-03-08T15:35:26Z|Edit|error|foo.md
```

## Test Results

| # | Test | Input | Expected | Result |
|---|------|-------|----------|--------|
| 1 | Write success | `{"tool_name":"Write","tool_input":{"file_path":"README.md"},...}` | Log entry with file path | PASS |
| 2 | Bash success | `{"tool_name":"Bash","tool_input":{"command":"git status"},...}` | Log entry with command | PASS |
| 3 | Edit error (is_error:true) | `{"tool_name":"Edit",...,"is_error":true}` | Status = error | PASS |
| 4 | Grep tool | `{"tool_name":"Grep","tool_input":{"pattern":"TODO"},...}` | Context = pattern | PASS |
| 5 | Skill tool | `{"tool_name":"Skill","tool_input":{"skill":"plan:create"},...}` | Context = skill name | PASS |
| 6 | Long command truncation (>80 chars) | Long Bash command | Truncated to 80 chars with ... | PASS |
| 7 | Empty JSON input | `{}` | No log entry, exit 0 | PASS |
| 8 | Read tool | `{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.md"},...}` | File path in context | PASS |
| 9 | Glob tool | `{"tool_name":"Glob","tool_input":{"pattern":"**/*.sh"},...}` | Pattern in context | PASS |
| 10 | Directory creation | Run in dir without .ai/traces/ | Creates directory, writes log | PASS |
| 11 | Append (not overwrite) | Two consecutive writes | Both entries in log, 2 lines | PASS |
| 12 | Performance | 3 runs via /usr/bin/time | ~10ms per invocation | PASS (<30ms) |
| 13 | plugin.json valid JSON | After hook registration | python3 json.load succeeds | PASS |

## Criteria from plan.yml

- [x] Log entries appear after tool invocations
- [x] Format is parseable (consistent pipe delimiter, 4 fields per line)
- [x] Script execution < 30ms (measured: ~10ms via /usr/bin/time)
- [x] Log file grows correctly (append, not overwrite)
- [x] Graceful when log directory doesn't exist (creates it via mkdir -p)
- [x] Uninstall test: removing script doesn't break other features

## Performance Details

Measured with `/usr/bin/time -p`:
- 3 consecutive runs: 0.01s, 0.01s, 0.01s (~10ms each)
- The bash-builtins approach (string manipulation via `${var#...}` / `${var%%...}`) avoids subshell overhead from repeated grep/sed pipelines
- Single `grep -qi` call for error detection, all other field extraction is pure bash

## Uninstall Test

The trace-light hook is registered as a separate entry in plugin.json PostToolUse array (no matcher = fires on all tools). Removing it:
1. Delete `plugins/claude-core/scripts/trace-light.sh`
2. Remove the matcherless hook block from plugin.json PostToolUse array

No other script, command, or skill references this hook. The `|| true` in the plugin.json command ensures that even if the script is missing, the hook silently succeeds. The `.ai/traces/trace-light.log` file is inert data — removing the hook simply stops new entries from being appended.
