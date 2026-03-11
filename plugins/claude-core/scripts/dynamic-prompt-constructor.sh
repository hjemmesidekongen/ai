#!/usr/bin/env bash
set -euo pipefail

# Dynamic Prompt Constructor
# Reads a dynamic plan's state.yml + learnings.yml and constructs a
# cycle-appropriate prompt for the autopilot stop hook to feed back.
# Instead of repeating a static prompt each iteration, this builds
# context-aware instructions that tell the agent where it is in the
# dynamic planning loop and what to do next.
#
# Usage: dynamic-prompt-constructor.sh <plan-directory>
# Output: constructed prompt on stdout, errors on stderr
# Exit:   0 on success (or plan done), 1 on errors

# --- Validate arguments ---

if [[ $# -ne 1 ]]; then
  echo "Usage: dynamic-prompt-constructor.sh <plan-directory>" >&2
  exit 1
fi

PLAN_DIR="$1"
STATE_FILE="$PLAN_DIR/state.yml"
LEARNINGS_FILE="$PLAN_DIR/learnings.yml"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "Error: state.yml not found at $STATE_FILE" >&2
  exit 1
fi

# --- Helper: extract a top-level YAML scalar value ---
# Handles quoted, unquoted, and multiline (> or |) values.
yaml_val() {
  local file="$1" key="$2"
  local raw
  raw=$(grep "^${key}:" "$file" 2>/dev/null | head -1 | sed "s/^${key}: *//" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")

  # Handle YAML multiline indicators (> or |)
  if [[ "$raw" == ">" ]] || [[ "$raw" == "|" ]]; then
    # Read indented continuation lines after the key line
    awk "/^${key}:/{found=1; next} found && /^  /{print; next} found{exit}" "$file" 2>/dev/null | sed 's/^  //' | tr '\n' ' ' | sed 's/  */ /g; s/ *$//'
  else
    echo "$raw"
  fi
}

# --- Read state.yml fields ---

CYCLE=$(yaml_val "$STATE_FILE" "cycle")
GOAL=$(yaml_val "$STATE_FILE" "goal")
REMAINING=$(yaml_val "$STATE_FILE" "remaining_goal")
REPLAN_COUNT=$(yaml_val "$STATE_FILE" "replan_count")
MAX_CYCLES=$(yaml_val "$STATE_FILE" "max_cycles")
STATUS=$(yaml_val "$STATE_FILE" "status")

# Defaults for optional fields
CYCLE="${CYCLE:-1}"
REPLAN_COUNT="${REPLAN_COUNT:-0}"
MAX_CYCLES="${MAX_CYCLES:-15}"
STATUS="${STATUS:-active}"

# Validate we have a goal
if [[ -z "$GOAL" ]]; then
  echo "Error: no goal found in $STATE_FILE" >&2
  exit 1
fi

# --- Check terminal conditions ---

# Plan is done — output nothing, let autopilot stop
if [[ "$STATUS" == "done" ]]; then
  exit 0
fi

# Max cycles reached — output escalation message
if [[ "$CYCLE" =~ ^[0-9]+$ ]] && [[ "$MAX_CYCLES" =~ ^[0-9]+$ ]] && [[ $CYCLE -ge $MAX_CYCLES ]]; then
  cat <<EOF
Dynamic plan: $(basename "$PLAN_DIR") — ESCALATE (max cycles reached)

Goal: $GOAL
Cycles completed: $CYCLE / $MAX_CYCLES

Max cycles reached. This plan needs human review.
Read $STATE_FILE and $LEARNINGS_FILE, summarize progress, and report what's done vs remaining.
Do NOT start another cycle. Set status to "escalated" in state.yml.
EOF
  exit 0
fi

# --- Read learnings.yml (if it exists) ---

ACTIVE_COUNT=0
QUESTION_COUNT=0
NEXT_ORIENTATION=""

if [[ -f "$LEARNINGS_FILE" ]]; then
  # Count active learnings (entries with "status: active" under entries section)
  ACTIVE_COUNT=$(grep -c '  status: active' "$LEARNINGS_FILE" 2>/dev/null || true)
  ACTIVE_COUNT="${ACTIVE_COUNT:-0}"

  # Count open questions (lines under open_questions that start with "  - ")
  QUESTION_COUNT=$(sed -n '/^open_questions:/,/^[a-z_]*:/{ /^  - /p; }' "$LEARNINGS_FILE" 2>/dev/null | wc -l | tr -d ' ')
  QUESTION_COUNT="${QUESTION_COUNT:-0}"

  # Extract next_orientation value
  NEXT_ORIENTATION=$(yaml_val "$LEARNINGS_FILE" "next_orientation")
fi

# --- Construct the next cycle number ---

NEXT_CYCLE=$((CYCLE + 1))

# --- Build the prompt ---

PLAN_NAME=$(basename "$PLAN_DIR")

cat <<EOF
Dynamic plan: ${PLAN_NAME} — Cycle ${NEXT_CYCLE}

Goal: ${GOAL}
Remaining: ${REMAINING:-"(not yet assessed)"}
Learnings: ${ACTIVE_COUNT} active, ${QUESTION_COUNT} open questions
Replans used: ${REPLAN_COUNT} / 2
EOF

# Add next_orientation if available
if [[ -n "$NEXT_ORIENTATION" ]]; then
  echo "Next orientation: ${NEXT_ORIENTATION}"
fi

cat <<EOF

Continue the dynamic planning loop:
1. Read ${PLAN_DIR}/state.yml and ${PLAN_DIR}/learnings.yml
2. Read plugins/claude-core/skills/dynamic-planner/references/process.md for the full algorithm
3. Run the REFLECT phase — classify as CONTINUE/ADJUST/REPLAN/ESCALATE
4. Based on classification, run the appropriate next step (plan next wave, replan, or escalate)
5. Execute the wave
6. Run the LEARN phase — record learnings, update remaining_goal, increment cycle
7. If goal is met, set status to done

If you need human input for scope changes or cost decisions, ESCALATE immediately.
EOF

exit 0
