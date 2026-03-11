---
name: autopilot-run
description: Start autopilot loop in current session
user_invocable: true
argument-hint: "PROMPT [--max-iterations N] [--completion-promise TEXT] [--dynamic-plan PATH]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-autopilot.sh:*)"]
---

# Autopilot Command

Run the setup script using Bash. Pass all arguments exactly as provided:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-autopilot.sh" $ARGUMENTS
```

If the Bash call fails due to argument parsing, reconstruct the command manually:
1. Parse the user's arguments to identify flags (--max-iterations, --completion-promise, --dynamic-plan) and the prompt text
2. Run: `"${CLAUDE_PLUGIN_ROOT}/scripts/setup-autopilot.sh" [flags...] "prompt text"`

Please work on the task. When you try to exit, the autopilot loop will feed the prompt back to you for the next iteration. Previous work persists in files, creating a loop where each iteration builds on the last.

For dynamic plans (--dynamic-plan flag), each iteration gets a fresh cycle-aware prompt constructed from the plan's state.yml and learnings.yml.

CRITICAL RULE: If a completion promise is set, you may ONLY output it when the statement is completely and unequivocally TRUE. Do not output false promises to escape the loop.
