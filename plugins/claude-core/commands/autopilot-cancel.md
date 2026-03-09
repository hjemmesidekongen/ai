---
name: autopilot-cancel
description: Cancel active autopilot loop
user_invocable: true
allowed-tools: ["Bash(test -f .claude/autopilot.local.md:*)", "Bash(rm .claude/autopilot.local.md)", "Read(.claude/autopilot.local.md)"]
---

# Cancel Autopilot

To cancel the autopilot loop:

1. Check if `.claude/autopilot.local.md` exists using Bash: `test -f .claude/autopilot.local.md && echo "EXISTS" || echo "NOT_FOUND"`

2. **If NOT_FOUND**: Say "No active autopilot loop found."

3. **If EXISTS**:
   - Read `.claude/autopilot.local.md` to get the current iteration number from the `iteration:` field
   - Remove the file using Bash: `rm .claude/autopilot.local.md`
   - Report: "Cancelled autopilot loop (was at iteration N)" where N is the iteration value
