# t6: Full Tracing Command — Test Verification

**Date:** 2026-03-08
**Command:** `plugins/claude-core/commands/trace-full.md`
**Config location:** `.ai/traces/trace-config.yml`
**Session location:** `.ai/traces/sessions/trace-full-{date}.yml`

## Verification Procedure

### Test 1: Toggle ON — creates config and session file

```
Pre-condition: No .ai/traces/trace-config.yml exists (or level != "full")

1. Run /trace:full
2. Verify .ai/traces/trace-config.yml exists with:
   - level: "full"
   - enabled_at: valid ISO 8601 timestamp
   - session_file: "trace-full-{today}.yml"
3. Verify .ai/traces/sessions/ directory exists
4. Verify .ai/traces/sessions/trace-full-{today}.yml exists with:
   - session.started_at: valid ISO 8601 timestamp
   - session.level: "full"
   - session.entries: [] (empty array)
5. Verify output contains "Full tracing enabled"

Expected: All files created, valid YAML, correct field values
```

### Test 2: Toggle OFF — updates config, reports summary

```
Pre-condition: trace-config.yml has level: "full"

1. Run /trace:full
2. Verify .ai/traces/trace-config.yml updated to:
   - level: "light"
   - disabled_at: valid ISO 8601 timestamp
   - enabled_at removed or absent
   - session_file removed or absent
3. Verify output contains "Full tracing disabled"
4. Verify output contains "Reverting to light mode"
5. Verify output reports entry count and error count

Expected: Config reverts to light, session file preserved (not deleted), summary reported
```

### Test 3: Toggle ON → OFF → ON (idempotent cycle)

```
1. Run /trace:full → should enable
2. Verify level: "full" in config
3. Run /trace:full → should disable
4. Verify level: "light" in config
5. Run /trace:full → should enable again
6. Verify level: "full" in config, new session file created

Expected: Clean toggle cycle with no residual state issues
```

### Test 4: Session YAML is valid and parseable

```
Pre-condition: Full tracing enabled, some entries written

1. Read .ai/traces/sessions/trace-full-{date}.yml
2. Validate YAML syntax (python3 -c "import yaml; yaml.safe_load(open(...))")
3. Verify entries array contains valid objects
4. Each entry has: timestamp, tool, decision_context, files_changed, outcome
5. timestamps are valid ISO 8601
6. outcome is "success" or "error"
7. files_changed is a list (possibly empty)

Expected: Valid YAML, all required fields present, correct types
```

### Test 5: Status bar reflects trace level

```
Pre-condition: statusline-command.sh reads trace-config.yml for trace indicator

1. Enable full tracing → verify status bar shows trace level as "full"
2. Disable full tracing → verify status bar shows trace level as "light" (or default)

Verification: Run the statusline script and check its output includes the correct
trace level indicator based on trace-config.yml content.

Expected: Status bar indicator matches trace-config.yml level value
```

### Test 6: Light tracing unaffected by full toggle

```
1. Note current line count of .ai/traces/trace-light.log
2. Enable full tracing
3. Perform a file write (triggers PostToolUse hook)
4. Verify .ai/traces/trace-light.log has new entry appended
5. Verify the light trace entry format is unchanged (timestamp|tool|status|duration|context)
6. Disable full tracing
7. Perform another file write
8. Verify .ai/traces/trace-light.log has another new entry

Expected: Light trace log grows regardless of full trace state — fully additive
```

### Test 7: Session directory auto-creation

```
Pre-condition: .ai/traces/sessions/ does NOT exist

1. Run /trace:full
2. Verify .ai/traces/sessions/ directory was created
3. Verify session file was written inside it

Expected: mkdir -p behavior — creates full path if needed
```

### Test 8: Disable with empty session (zero entries)

```
Pre-condition: Full tracing enabled, no entries written yet

1. Run /trace:full (disable)
2. Verify output reports "0 entries, 0 errors"
3. No crash or error

Expected: Graceful handling of empty entries array
```

### Test 9: Disable with errors in session

```
Pre-condition: Full tracing enabled, session has entries including some with outcome: "error"

1. Add test entries to session file (at least one with outcome: "error")
2. Run /trace:full (disable)
3. Verify output reports correct entry count and error count
4. Verify error entries are listed in the summary

Expected: Error summary displayed when errors exist in session
```

### Test 10: Missing session file on disable

```
Pre-condition: trace-config.yml says level: "full" and references a session_file,
               but the actual session file has been deleted

1. Run /trace:full (disable)
2. Verify no crash — reports "0 entries, 0 errors" or similar graceful fallback
3. Config still updated to level: "light"

Expected: Graceful degradation when session file is missing
```

## Criteria from plan.yml

- [ ] trace:full toggles on and off
- [ ] Status bar reflects trace level change (reads from trace-config.yml)
- [ ] Full trace YAML is valid and parseable
- [ ] Light tracing still works when full is enabled (additive)
- [ ] Disabling full tracing reverts to light-only

## Uninstall Test

The trace:full command is a standalone markdown file. Removing it:
1. Delete `plugins/claude-core/commands/trace-full.md`
2. Optionally remove `.ai/traces/trace-config.yml` and `.ai/traces/sessions/`

No hook, script, or other command references this file. The status bar reads
`trace-config.yml` directly — if the config file is absent, it falls back to
displaying "light" (the default). Light tracing is completely independent.

The command does not register any hooks in plugin.json. It is purely a
user-invoked command that reads/writes state files.
