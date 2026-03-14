#!/usr/bin/env bash
set -euo pipefail

# Autopilot Loop Setup Script
# Creates state file for in-session autopilot loop
# Source ref: claude-code-main/plugins/ralph-wiggum/scripts/setup-ralph-loop.sh

# Parse arguments
PROMPT_PARTS=()
MAX_ITERATIONS=50
COMPLETION_PROMISE="null"
DYNAMIC_PLAN=""

# Parse options and positional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Autopilot Loop - Autonomous self-referential development loop

USAGE:
  /kronen:autopilot-run [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop (can be multiple words without quotes)

OPTIONS:
  --max-iterations <n>           Maximum iterations before auto-stop (default: 50)
  --completion-promise '<text>'  Promise phrase (USE QUOTES for multi-word)
  --dynamic-plan <path>          Link to a dynamic plan directory (stop hook uses dynamic prompt constructor)
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
  /kronen:autopilot-run "Build a todo API" --completion-promise 'DONE' --max-iterations 20
  /kronen:autopilot-run --max-iterations 100 Fix the auth bug
  /kronen:autopilot-run --dynamic-plan .ai/plans/my-plan "Start the dynamic plan"

STOPPING:
  - Reaching --max-iterations (default: 50)
  - Detecting --completion-promise in <promise> tags
  - Running /kronen:autopilot-cancel

MONITORING:
  # View current iteration:
  grep '^iteration:' $STATE_FILE

  # View full state:
  head -10 $STATE_FILE
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
    --dynamic-plan)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --dynamic-plan requires a plan directory path" >&2
        exit 1
      fi
      if [[ ! -f "${2}/state.yml" ]]; then
        echo "Error: no state.yml found at ${2}/state.yml" >&2
        exit 1
      fi
      DYNAMIC_PLAN="$2"
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
PROMPT="${PROMPT_PARTS[*]:-}"

# For dynamic plans, prompt is optional (plan-prompt-constructor generates it)
if [[ -z "$PROMPT" ]] && [[ -z "$DYNAMIC_PLAN" ]]; then
  echo "Error: No prompt provided" >&2
  echo "" >&2
  echo "   Examples:" >&2
  echo "     /kronen:autopilot-run Build a REST API for todos" >&2
  echo "     /kronen:autopilot-run Fix the auth bug --max-iterations 20" >&2
  echo "     /kronen:autopilot-run --completion-promise 'DONE' Refactor code" >&2
  exit 1
fi

# For dynamic plans without explicit prompt, use a default
if [[ -z "$PROMPT" ]] && [[ -n "$DYNAMIC_PLAN" ]]; then
  PROMPT="Execute the next cycle of the dynamic plan at ${DYNAMIC_PLAN}"
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

# Determine session-specific filename
SANITIZED_ID=$(echo "${CLAUDE_SESSION_ID:-}" | tr -cd 'a-zA-Z0-9_-')
if [ -n "$SANITIZED_ID" ]; then
  STATE_FILE=".claude/autopilot-${SANITIZED_ID}.local.md"
else
  # Fallback for manual invocation outside a session
  STATE_FILE=".claude/autopilot-unknown.local.md"
fi

# Quote completion promise for YAML if it contains special chars or is not null
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

# Quote dynamic plan path for YAML
if [[ -n "$DYNAMIC_PLAN" ]]; then
  DYNAMIC_PLAN_YAML="\"$DYNAMIC_PLAN\""
else
  DYNAMIC_PLAN_YAML="null"
fi

cat > "$STATE_FILE" <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: $COMPLETION_PROMISE_YAML
dynamic_plan: $DYNAMIC_PLAN_YAML
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

The stop hook is now active. $(if [[ -n "$DYNAMIC_PLAN" ]]; then echo "Dynamic plan linked: $DYNAMIC_PLAN
Each iteration constructs a fresh prompt from the plan's state and learnings."; else echo "When you try to exit, the SAME PROMPT will be fed back.
Previous work persists in files, creating a self-referential loop."; fi)

To monitor: head -10 $STATE_FILE
To cancel:  /kronen:autopilot-cancel
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
