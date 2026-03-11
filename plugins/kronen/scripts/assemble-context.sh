#!/usr/bin/env bash
# kronen — Shared context assembler
# Builds enriched snapshot: .ai/context/snapshot.yml
# Usage: assemble-context.sh <source>  (precompact|stop|session-start)
# Called by: precompact-snapshot.sh, session-context-stop.sh, session-recovery.sh
# Always exits 0.

set -euo pipefail

main() {
  local SOURCE="${1:-unknown}"
  local PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
  local CONTEXT_DIR="$PROJECT_DIR/.ai/context"
  local SNAPSHOT="$CONTEXT_DIR/snapshot.yml"
  mkdir -p "$CONTEXT_DIR" 2>/dev/null
  local TS
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # === Layer 1: Workspace (works in any git repo) ===
  local BRANCH DIRTY_COUNT IDENTITY
  BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null) || BRANCH="unknown"
  DIRTY_COUNT=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ') || DIRTY_COUNT=0

  IDENTITY=""
  if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    IDENTITY=$(head -5 "$PROJECT_DIR/CLAUDE.md" | grep -m1 '^# ' | sed 's/^# //') || true
  fi
  [ -z "$IDENTITY" ] && IDENTITY=$(basename "$PROJECT_DIR")

  # === Layer 2: Project (requires .ai/agency.yml) ===
  local ACTIVE_PROJECT="" PROJECT_STATUS="" CURRENT_MODULE="" COMPLETED_MODULES=""
  local AGENCY_FILE="$PROJECT_DIR/.ai/agency.yml"
  if [ -f "$AGENCY_FILE" ]; then
    ACTIVE_PROJECT=$(grep '^active:' "$AGENCY_FILE" | head -1) || true
    ACTIVE_PROJECT="${ACTIVE_PROJECT#active: }"; ACTIVE_PROJECT="${ACTIVE_PROJECT//\"/}"
  fi

  if [ -n "$ACTIVE_PROJECT" ]; then
    local STATE_FILE="$PROJECT_DIR/.ai/projects/$ACTIVE_PROJECT/state.yml"
    if [ -f "$STATE_FILE" ]; then
      PROJECT_STATUS=$(grep '^status:' "$STATE_FILE" | head -1 | awk '{print $2}' | tr -d '"') || true
      CURRENT_MODULE=$(grep '^current_module:' "$STATE_FILE" | head -1 | awk '{print $2}' | tr -d '"') || true
      COMPLETED_MODULES=$(awk '
        /^modules:/ { in_mod=1; next }
        in_mod && /^[^ ]/ { exit }
        in_mod && /^  [a-z]/ { mod=$1; sub(/:.*/, "", mod) }
        in_mod && /status:.*"completed"/ { mods = mods (mods ? ", " : "") mod }
        END { print mods }
      ' "$STATE_FILE" 2>/dev/null) || true
    fi
  fi

  # === Layer 3: Working state (requires .ai/plans/) ===
  local PLAN_NAME="" PLAN_WAVE="" PLAN_TASK="" ERROR_COUNT=0

  for state_file in "$PROJECT_DIR"/.ai/plans/*/state.yml; do
    [ ! -f "$state_file" ] && continue
    local status_val
    status_val=$(grep '^status:' "$state_file" | head -1 | awk '{print $2}' | tr -d '"') || true
    if [ "$status_val" = "in_progress" ]; then
      PLAN_NAME=$(grep '^plan:' "$state_file" | head -1 | awk '{print $2}' | tr -d '"') || true
      PLAN_WAVE=$(grep '^current_wave:' "$state_file" | head -1 | awk '{print $2}' | tr -d '"') || true
      PLAN_TASK=$(grep '^current_task:' "$state_file" | head -1 | awk '{print $2}' | tr -d '"') || true
      ERROR_COUNT=$(grep -c '  - timestamp:' "$state_file" 2>/dev/null) || ERROR_COUNT=0
      break
    fi
  done

  # Modified files from trace-light
  MODIFIED_FILES=()
  local TRACE_FILE="$PROJECT_DIR/.ai/traces/trace-light.log"
  if [ -f "$TRACE_FILE" ]; then
    while IFS= read -r line; do
      local rest="${line#*|}"
      local tool="${rest%%|*}"
      case "$tool" in
        Write|Edit)
          local ctx="${line##*|}"
          [ -n "$ctx" ] && [ "$ctx" != "-" ] && MODIFIED_FILES+=("$ctx") ;;
      esac
    done < <(tail -20 "$TRACE_FILE")

    # Deduplicate (bash 3 compat — no associative arrays)
    if [ ${#MODIFIED_FILES[@]} -gt 0 ]; then
      local unique_seen="" idx=0
      UNIQUE_FILES=()
      for f in "${MODIFIED_FILES[@]}"; do
        case "$unique_seen" in
          *"|$f|"*) ;;
          *) unique_seen="${unique_seen}|$f|"; UNIQUE_FILES+=("$f") ;;
        esac
      done
      MODIFIED_FILES=("${UNIQUE_FILES[@]}")
    fi
  fi

  # === Layer 4: Session Trail ===
  local INTENT="" NEXT_STEP=""
  local -a DECISIONS_MODIFIED=()

  # Intent: active plan title from plan.md, fallback to brainstorm, fallback to generic
  if [ -n "$PLAN_NAME" ]; then
    local PLAN_DOC="$PROJECT_DIR/.ai/plans/$PLAN_NAME/plan.md"
    if [ -f "$PLAN_DOC" ]; then
      INTENT=$(grep -m1 '^# ' "$PLAN_DOC" | sed 's/^# //' | cut -c1-80) || true
    fi
  fi
  if [ -z "$INTENT" ]; then
    for bs_dir in "$PROJECT_DIR"/.ai/brainstorm/*/; do
      [ -d "$bs_dir" ] || continue
      INTENT="Brainstorm: $(basename "$bs_dir")"
      break
    done
  fi
  [ -z "$INTENT" ] && INTENT="No active plan or session"

  # Decisions: scan trace-light for writes to *decision* files (last 100 entries)
  if [ -f "$TRACE_FILE" ]; then
    while IFS='|' read -r _ts tool _status ctx; do
      case "$tool" in
        Write|Edit)
          case "$ctx" in
            *decision*)
              [ -n "$ctx" ] && [ "$ctx" != "-" ] && DECISIONS_MODIFIED+=("$ctx") ;;
          esac ;;
      esac
    done < <(tail -100 "$TRACE_FILE")

    # Deduplicate decisions list
    if [ ${#DECISIONS_MODIFIED[@]} -gt 0 ]; then
      local dseen="" UNIQUE_D=()
      for d in "${DECISIONS_MODIFIED[@]}"; do
        case "$dseen" in
          *"|$d|"*) ;;
          *) dseen="${dseen}|$d|"; UNIQUE_D+=("$d") ;;
        esac
      done
      DECISIONS_MODIFIED=("${UNIQUE_D[@]}")
    fi
  fi

  # Next step: first pending task in active plan's state.yml
  if [ -n "$PLAN_NAME" ]; then
    local PLAN_STATE="$PROJECT_DIR/.ai/plans/$PLAN_NAME/state.yml"
    if [ -f "$PLAN_STATE" ]; then
      NEXT_STEP=$(awk '
        /^        name:/ { tname=$0; sub(/.*name: /, "", tname); gsub(/"/, "", tname) }
        /^        status: pending/ && tname != "" { print tname; tname=""; exit }
      ' "$PLAN_STATE" 2>/dev/null) || true
    fi
  fi

  # === Write snapshot (target: <80 lines) ===
  {
    echo "# Session context — generated by assemble-context.sh"
    echo "generated: \"$TS\""
    echo "source: \"$SOURCE\""
    echo ""
    echo "workspace:"
    echo "  branch: \"$BRANCH\""
    echo "  dirty_files: $DIRTY_COUNT"
    echo "  identity: \"$IDENTITY\""
    echo ""
    if [ -n "$ACTIVE_PROJECT" ]; then
      echo "project:"
      echo "  name: \"$ACTIVE_PROJECT\""
      echo "  status: \"${PROJECT_STATUS:-unknown}\""
      echo "  current_module: ${CURRENT_MODULE:-null}"
      if [ -n "$COMPLETED_MODULES" ]; then
        echo "  completed: [$COMPLETED_MODULES]"
      else
        echo "  completed: []"
      fi
    else
      echo "project: null"
    fi
    echo ""
    echo "working_state:"
    if [ -n "$PLAN_NAME" ]; then
      echo "  active_plan: \"$PLAN_NAME ($PLAN_WAVE, $PLAN_TASK)\""
    else
      echo "  active_plan: null"
    fi
    if [ ${#MODIFIED_FILES[@]} -gt 0 ]; then
      echo "  modified_files:"
      local count=0
      for f in "${MODIFIED_FILES[@]}"; do
        echo "    - $f"
        count=$((count + 1))
        [ $count -ge 10 ] && break
      done
    else
      echo "  modified_files: []"
    fi
    echo "  error_count: $ERROR_COUNT"
    echo ""
    echo "session_trail:"
    echo "  intent: \"$INTENT\""
    if [ ${#DECISIONS_MODIFIED[@]} -gt 0 ]; then
      echo "  decisions_modified:"
      local dcount=0
      for d in "${DECISIONS_MODIFIED[@]}"; do
        echo "    - $d"
        dcount=$((dcount + 1))
        [ $dcount -ge 5 ] && break
      done
    else
      echo "  decisions_modified: []"
    fi
    if [ -n "$NEXT_STEP" ]; then
      echo "  next_step: \"$NEXT_STEP\""
    else
      echo "  next_step: null"
    fi
    echo ""
    echo "probes:"
    [ -n "$PLAN_NAME" ] && echo "  - \"Were you executing plan '${PLAN_NAME}'?\""
    [ "$INTENT" != "No active plan or session" ] && echo "  - \"Were you working on: ${INTENT}?\""
    if [ ${#MODIFIED_FILES[@]} -gt 0 ]; then
      local probe_file="${MODIFIED_FILES[0]}"
      probe_file="${probe_file##*/}"
      echo "  - \"Did you modify files including '${probe_file}'?\""
    fi
    [ -n "$NEXT_STEP" ] && echo "  - \"Is your next step: ${NEXT_STEP}?\""
    echo "  - \"Are there any blockers or errors to address?\""
  } > "$SNAPSHOT"
}

trap 'exit 0' ERR
main "$@"
exit 0
