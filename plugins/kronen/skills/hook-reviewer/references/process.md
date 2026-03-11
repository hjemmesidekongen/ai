# Hook Reviewer — Full Reference

## Review philosophy

Reviewers are read-only. Never modify the files under review. Produce a YAML verdict
documenting findings and recommendations. Enhancers (future) act on verdicts — reviewers
only judge.

## Two-stage review flow

```
Stage 1: Spec Compliance     →  All checks must pass  →  Stage 2: Quality Review
         (mechanical)                                           (judgment-based)
                                                                    ↓
                                                              YAML Verdict
```

If Stage 1 fails, stop and report. Do not proceed to Stage 2.

## Stage 1: Spec Compliance

Mechanical checks against the hook-creator specification. Every check is binary
(pass/fail).

### Check 1: Event type valid

The hook's event matches one of the 18 official events:

PreToolUse, PostToolUse, PostToolUseFailure, Stop, SubagentStop, SubagentStart,
UserPromptSubmit, PermissionRequest, SessionStart, SessionEnd, PreCompact,
Notification, TeammateIdle, TaskCompleted, InstructionsLoaded, ConfigChange,
WorktreeCreate, WorktreeRemove.

### Check 2: Exit code semantics

| Situation | Expected exit | Flag if |
|-----------|--------------|---------|
| Advisory hook (logging, tracing) | `0` | Exit 2 used for non-blocking purpose |
| Blocking hook (validation, gate) | `0` or `2` | Exit 1 used for blocking intent |
| Stop/SubagentStop decision hook | `0` | No JSON decision output |

Verify the script's exit codes match the hook's intended behavior.

### Check 3: JSON output schema

For hooks that produce output, verify the JSON matches the event-specific schema:

| Event | Required fields |
|-------|----------------|
| PreToolUse | `hookSpecificOutput.hookEventName`, `hookSpecificOutput.permissionDecision` |
| Stop/SubagentStop | `decision`, `reason` |
| PermissionRequest | `hookSpecificOutput.hookEventName`, `hookSpecificOutput.permissionDecision` |
| All others | `continue` (optional), `systemMessage` (optional) |

### Check 4: hookEventName in hookSpecificOutput

If the hook produces `hookSpecificOutput`, verify `hookEventName` is present inside it.
Without this field, hook-specific output is silently ignored.

### Check 5: Shell header

Script must start with:
```bash
#!/usr/bin/env bash
set -euo pipefail
```

Both lines required. `set -e` alone is insufficient.

### Check 6: CLAUDE_PROJECT_DIR usage

Scan for relative paths (paths not starting with `$`, `/`, or a variable):
- `.ai/...` → should be `$CLAUDE_PROJECT_DIR/.ai/...`
- `plugins/...` → should be `$CLAUDE_PROJECT_DIR/plugins/...` or `$CLAUDE_PLUGIN_ROOT/...`

### Check 7: || true after grep

With `set -euo pipefail`, any grep/awk returning no matches kills the script.
Scan for grep/awk pipelines missing `|| true`:
```bash
# Bad: dies if no match
STATUS=$(grep 'pattern' "$file")

# Good: survives no match
STATUS=$(grep 'pattern' "$file") || true
```

### Check 8: Matcher validity

If the hook has a `matcher` in plugin.json:
- Verify it's a valid regex pattern
- Verify it targets the correct field for the event type (tool_name for PreToolUse,
  agent_type for SubagentStart, etc.)
- Verify case matches (matchers are case-sensitive)

### Check 9: Timeout set

Verify `timeout` is explicitly set in the plugin.json hook entry. Flag if missing
(relying on defaults is fragile).

### Check 10: Hook type valid for event

| Hook type | Restriction |
|-----------|-------------|
| prompt | Only PreToolUse, Stop, SubagentStop, UserPromptSubmit |
| command | All events |
| http | All events |
| agent | All events |

Flag if a prompt hook is registered for an unsupported event.

### Check 11: Registration location

Verify the hook is registered in one of:
- `plugin.json` `hooks` section
- `hooks/hooks.json`
- Skill/agent YAML frontmatter `hooks:` section

Not registered = not active.

### Stage 1 output

```yaml
spec_compliance:
  status: pass | fail
  checks:
    event_type_valid: { status: pass|fail, detail: "" }
    exit_code_semantics: { status: pass|fail, detail: "" }
    json_output_schema: { status: pass|fail|skipped, detail: "" }
    hook_event_name: { status: pass|fail|skipped, detail: "" }
    shell_header: { status: pass|fail, detail: "" }
    project_dir_usage: { status: pass|fail, detail: "" }
    grep_or_true: { status: pass|fail, detail: "" }
    matcher_valid: { status: pass|fail|skipped, detail: "" }
    timeout_set: { status: pass|fail, detail: "" }
    hook_type_valid: { status: pass|fail, detail: "" }
    registration: { status: pass|fail, detail: "" }
  failed_count: 0
```

## Stage 2: Quality Review

Judgment-based evaluation. Only runs after Stage 1 passes.

### Security

| Check | What to look for |
|-------|-----------------|
| Input validation | Does the script validate/sanitize extracted JSON fields? |
| Path traversal | Could `tool_input.file_path` contain `../` that reaches outside project? |
| Command injection | Are extracted values used in commands without quoting? |
| Credential exposure | Does the script log sensitive fields (tokens, passwords)? |
| Exit 2 on untrusted input | Could external input trigger a blocking exit? |

### Reliability

| Check | What to look for |
|-------|-----------------|
| Empty stdin handling | Does `INPUT=$(cat)` handle empty input gracefully? |
| Missing field handling | Script works when optional JSON fields are absent |
| File existence checks | Script checks if target files exist before reading |
| Quote stripping | YAML values go through `tr -d '"'` before comparison |
| Idempotency | Running the hook twice produces the same result |

### Performance

| Check | What to look for |
|-------|-----------------|
| Timeout appropriateness | Timeout matches expected execution time |
| Async consideration | Long-running hooks should use `async: true` |
| Heavy operations | Avoid network calls, large file scans in synchronous hooks |
| statusMessage | Hooks taking >2s should set statusMessage for user feedback |

### Exit code intent

Verify the script's exit code aligns with its purpose:
- Logging/tracing hooks → always exit 0
- Validation gates → exit 0 (pass) or exit 2 (block)
- Stop hooks → exit 0 with JSON decision

### Parallel safety

Hooks in the same event group run in parallel. Check:
- No shared temp files without unique naming
- No file locks that could deadlock with sibling hooks
- No assumptions about execution order

### Error message quality

When the hook produces `systemMessage` or `reason`:
- Is the message actionable? (tells Claude what to do next)
- Is it specific? (not just "error occurred")
- Is it appropriate length? (not a wall of text)

### Stage 2 output

```yaml
quality_review:
  status: pass | pass_with_notes | fail
  findings:
    - area: "security|reliability|performance|intent|parallel_safety|error_messages"
      severity: info | warning | critical
      detail: "Description of finding"
      fix_required: true | false
  summary: "Brief overall assessment"
```

## 3-Level testing hierarchy

After code review, validate the hook can actually run:

### Level 1: Direct invocation

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"/test.md"},"hook_event_name":"PreToolUse"}' | \
  bash plugins/<plugin>/scripts/<hook>.sh
echo "Exit: $?"
```

Verify: exits cleanly, no stderr output (unless intentionally blocking).

### Level 2: JSON validation

```bash
bash plugins/<plugin>/scripts/<hook>.sh < test-input.json | python3 -m json.tool
```

Verify: output is valid JSON matching the event-specific schema.

### Level 3: Live test

```bash
claude --debug
```

Trigger the hook's event and verify in debug output:
- Hook is registered
- Hook fires on the correct event
- Timing is within timeout
- Output is consumed correctly

### Test input templates

Provide test inputs for each event the hook handles:

```json
// PreToolUse
{"session_id":"test","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/test.md","content":"test"},"cwd":"/tmp","permission_mode":"default"}

// PostToolUse
{"session_id":"test","hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"/test.md"},"tool_response":"File written","cwd":"/tmp","permission_mode":"default"}

// Stop
{"session_id":"test","hook_event_name":"Stop","stop_reason":"natural","transcript_path":"/tmp/transcript.jsonl","cwd":"/tmp","permission_mode":"default"}
```

## Verdict format

```yaml
hook_review:
  hook: "scripts/<hook-name>.sh"
  plugin: "<plugin-name>"
  event: "<event-type>"
  hook_type: "command|prompt|http|agent"
  reviewed_at: "<timestamp>"
  status: pass | pass_with_notes | fail
  spec_compliance:
    status: pass | fail
    checks: { ... }
    failed_count: 0
  quality_review:
    status: pass | pass_with_notes | fail
    findings: []
    summary: ""
  recommendations: []
  testing:
    level_1: pass | fail | skipped
    level_2: pass | fail | skipped
    level_3: pass | fail | skipped
```

## Common findings

| Finding | Severity | Category | Fix |
|---------|----------|----------|-----|
| Exit 2 used for advisory warning | critical | spec | Change to exit 0 + systemMessage |
| Relative path without $CLAUDE_PROJECT_DIR | critical | spec | Prefix with $CLAUDE_PROJECT_DIR |
| Missing `\|\| true` after grep | critical | spec | Append `\|\| true` |
| Missing `hookEventName` in hookSpecificOutput | critical | spec | Add hookEventName field |
| No timeout in plugin.json entry | warning | spec | Set explicit timeout |
| Prompt hook on unsupported event | critical | spec | Change hook type or event |
| Unquoted variable in command substitution | warning | security | Quote all variables |
| No empty-stdin handling | warning | reliability | Add empty-input guard |
| Missing `tr -d '"'` on YAML extraction | warning | reliability | Add quote stripping |
| Synchronous hook with network call | info | performance | Consider async: true |
| No statusMessage on slow hook | info | performance | Add statusMessage |
| Generic error message | info | quality | Make message specific and actionable |
| Shared temp file without unique name | warning | parallel | Use `$$` or `mktemp` |
| `tool_result` instead of `tool_response` | critical | spec | Rename to `tool_response` |

## Review checklist

Quick-reference for manual reviews:

- [ ] Event type is one of the 18 official events
- [ ] Exit codes match intent (0 advisory, 2 blocking only)
- [ ] JSON output matches event-specific schema
- [ ] `hookEventName` present in any `hookSpecificOutput`
- [ ] Shell header has `#!/usr/bin/env bash` + `set -euo pipefail`
- [ ] All paths use `$CLAUDE_PROJECT_DIR` or `$CLAUDE_PLUGIN_ROOT`
- [ ] All grep/awk pipelines have `|| true`
- [ ] Hook type is valid for the event
- [ ] Timeout set explicitly in registration
- [ ] Matcher targets correct field for event type
- [ ] Hook registered in plugin.json, hooks.json, or frontmatter
- [ ] Input validation on extracted JSON fields
- [ ] Empty stdin handled gracefully
- [ ] No credential exposure in logging
- [ ] Variables quoted in command substitutions
- [ ] Uses `tool_response` (not `tool_result`)
- [ ] Passes Level 1 direct invocation test
- [ ] JSON output validates with `python3 -m json.tool`
