---
name: autopilot-run
description: Start autopilot loop in current session
user_invocable: true
argument-hint: "PROMPT [--max-iterations N] [--completion-promise TEXT]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-autopilot.sh:*)"]
---

# Autopilot Command

Execute the setup script to initialize the autopilot loop:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-autopilot.sh" $ARGUMENTS
```

Please work on the task. When you try to exit, the autopilot loop will feed the SAME PROMPT back to you for the next iteration. You'll see your previous work in files and git history, allowing you to iterate and improve.

CRITICAL RULE: If a completion promise is set, you may ONLY output it when the statement is completely and unequivocally TRUE. Do not output false promises to escape the loop, even if you think you're stuck or should exit for other reasons. The loop is designed to continue until genuine completion.
