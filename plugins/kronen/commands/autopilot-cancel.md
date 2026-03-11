---
name: autopilot-cancel
description: "Cancel the active autopilot loop for the current session. Use when you need to stop or abort an autonomous iteration before completion."
user_invocable: true
usage: "/kronen:autopilot-cancel"
allowed-tools: ["Bash(ls .claude/autopilot-*.local.md:*)", "Bash(rm .claude/autopilot-*.local.md:*)", "Read(.claude/autopilot-*.local.md)"]
---

# Cancel Autopilot

To cancel the autopilot loop for the current session:

1. Determine the state file path:
   - If `$CLAUDE_SESSION_ID` is set: `.claude/autopilot-${CLAUDE_SESSION_ID}.local.md`
   - Otherwise: list `.claude/autopilot-*.local.md` files and pick the one with `active: true`

2. Check if the state file exists using Bash.

3. **If NOT found**: Say "No active autopilot loop found in this session."

4. **If found**:
   - Read the file to get the current `iteration:` value
   - Remove the file using Bash: `rm <file>`
   - Report: "Cancelled autopilot loop (was at iteration N)"
