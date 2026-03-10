#!/bin/bash

# Autopilot Loop Setup Script
# Creates state file for in-session autopilot loop
# Source ref: claude-code-main/plugins/ralph-wiggum/scripts/setup-ralph-loop.sh

set -euo pipefail

# Parse arguments
PROMPT_PARTS=()
MAX_ITERATIONS=50
COMPLETION_PROMISE="null"

# Parse options and positional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Autopilot Loop - Autonomous self-referential development loop

USAGE:
  /claude-core:autopilot-run [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop (can be multiple words without quotes)

OPTIONS:
  --max-iterations <n>           Maximum iterations before auto-stop (default: 50)
  --completion-promise '<text>'  Promise phrase (USE QUOTES for multi-word)
  -h, --help                     Show this help message

DESCRIPTION:
  Starts an autopilot loop in your CURRENT session. The stop hook prevents
  exit and feeds your output back as input until completion or iteration limit.

  To signal completion, output: <promise>YOUR_PHRASE</promise>

  Use this for:
  - Autonomous multi-phase builds (overnight execution)
  - Tasks requiring iteration and refinement
  - Self-correcting development loops

EXAMPLES:
  /claude-core:autopilot-run "Build a todo API" --completion-promise 'DONE' --max-iterations 20
  /claude-core:autopilot-run --max-iterations 100 Fix the auth bug
  /claude-core:autopilot-run "$(cat .ai/plans/my-plan/autopilot-prompt.md)" --completion-promise "ALL PHASES COMPLETE"

STOPPING:
  - Reaching --max-iterations (default: 50)
  - Detecting --completion-promise in <promise> tags
  - Running /claude-core:autopilot-cancel

MONITORING:
  # View current iteration:
  grep '^iteration:' .claude/autopilot.local.md

  # View full state:
  head -10 .claude/autopilot.local.md
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --max-iterations requires a number argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --max-iterations 10" >&2
        echo "     --max-iterations 50" >&2
        echo "     --max-iterations 0  (unlimited)" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations must be a positive integer or 0, got: $2" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --completion-promise requires a text argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --completion-promise 'DONE'" >&2
        echo "     --completion-promise 'ALL PHASES COMPLETE'" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    *)
      PROMPT_PARTS+=("$1")
      shift
      ;;
  esac
done

# Join all prompt parts with spaces
PROMPT="${PROMPT_PARTS[*]}"

# Validate prompt is non-empty
if [[ -z "$PROMPT" ]]; then
  echo "Error: No prompt provided" >&2
  echo "" >&2
  echo "   Examples:" >&2
  echo "     /claude-core:autopilot-run Build a REST API for todos" >&2
  echo "     /claude-core:autopilot-run Fix the auth bug --max-iterations 20" >&2
  echo "     /claude-core:autopilot-run --completion-promise 'DONE' Refactor code" >&2
  exit 1
fi

# Auto-detect completion promise from prompt if not explicitly set
if [[ "$COMPLETION_PROMISE" == "null" ]]; then
  # Check if prompt contains <promise>TEXT</promise> pattern
  DETECTED_PROMISE=$(echo "$PROMPT" | perl -0777 -ne 'print $1 if /<promise>(.*?)<\/promise>/s' 2>/dev/null || echo "")
  if [[ -n "$DETECTED_PROMISE" ]]; then
    echo "Auto-detected completion promise from prompt: \"$DETECTED_PROMISE\""
    echo ""
    COMPLETION_PROMISE="$DETECTED_PROMISE"
  fi
fi

# Create state file (markdown with YAML frontmatter)
mkdir -p .claude

# Quote completion promise for YAML if it contains special chars or is not null
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

cat > .claude/autopilot.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: $COMPLETION_PROMISE_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

$PROMPT
EOF

# Output setup message
cat <<EOF
Autopilot loop activated.

Iteration: 1
Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "${COMPLETION_PROMISE//\"/} (output ONLY when TRUE)"; else echo "none"; fi)

The stop hook is now active. When you try to exit, the SAME PROMPT will be
fed back. Previous work persists in files, creating a self-referential loop
where each iteration builds on the last.

To monitor: head -10 .claude/autopilot.local.md
To cancel:  /claude-core:autopilot-cancel
EOF

# Output the initial prompt
if [[ -n "$PROMPT" ]]; then
  echo ""
  echo "$PROMPT"
fi

# Display completion promise requirements if set
if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo ""
  echo "---"
  echo "COMPLETION PROMISE"
  echo "---"
  echo ""
  echo "To complete this loop, output this EXACT text:"
  echo "  <promise>$COMPLETION_PROMISE</promise>"
  echo ""
  echo "REQUIREMENTS:"
  echo "  - Use <promise> XML tags exactly as shown"
  echo "  - The statement MUST be completely and unequivocally TRUE"
  echo "  - Do NOT output false statements to exit the loop"
  echo "  - If stuck, keep iterating — do not lie to escape"
  echo "---"
fi
