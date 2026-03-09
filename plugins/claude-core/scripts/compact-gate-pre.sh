#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' ERR
# claude-core — compact gate (PreToolUse on Write|Edit)
# Blocks writes when compact is needed AND the target file is not part of the current unit.
# Unit-completion artifacts (SKILL.md, commands/*.md, agents/*.md, etc.) are allowed through
# because they're likely still part of the finishing unit.
# Active plan writes are also allowed — files owned by current-wave tasks bypass the gate.
# Non-unit files after the flag is set indicate a new unit starting — block with exit 2.
# Performance target: <30ms. Exits 0 (allow) or 2 (block).

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
FLAG_FILE="$PROJECT_DIR/.ai/compact-needed"

# Fast path: no flag = no gate
[ ! -f "$FLAG_FILE" ] && exit 0

# Read hook input JSON from stdin
INPUT=$(cat)

# Extract file_path using bash builtins
FILE_PATH=""
case "$INPUT" in *'"file_path":"'*)
  FILE_PATH="${INPUT#*\"file_path\":\"}"
  FILE_PATH="${FILE_PATH%%\"*}" ;;
esac

# If we can't extract a file path, allow (don't break anything)
[ -z "$FILE_PATH" ] && exit 0

# Check if the target file is a unit-completion artifact (same unit, allow through)
case "$FILE_PATH" in
  */SKILL.md | */commands/*.md | */agents/*.md | *decisions.yml | */findings.md)
    exit 0 ;;
  .ai/plans/*/state.yml | */plans/*/state.yml)
    exit 0 ;;
esac

# Check if the target file is owned by an active plan's current wave.
# Scans state.yml for in_progress plans, extracts current wave tasks,
# then checks if FILE_PATH appears in those tasks' writes arrays.
for state_file in "$PROJECT_DIR"/.ai/plans/*/state.yml; do
  [ ! -f "$state_file" ] && continue

  # Quick check: skip unless plan is active
  grep -q '^status: in_progress' "$state_file" 2>/dev/null || continue

  # Extract current wave name
  WAVE=""
  while IFS= read -r line; do
    case "$line" in "current_wave: "*)
      WAVE="${line#current_wave: }"
      WAVE="${WAVE%\"}" ; WAVE="${WAVE#\"}" ;;
    esac
  done < "$state_file"
  [ -z "$WAVE" ] || [ "$WAVE" = "null" ] && continue

  # Extract task IDs for the current wave.
  # state.yml indentation (2-space YAML):
  #   waves:
  #     wave-1:          (2-space)
  #       tasks: [t1, t2]  (4-space)
  IN_WAVE=0
  TASK_IDS=""
  IN_WAVES_SECTION=0
  while IFS= read -r line; do
    # Enter waves: section
    case "$line" in "waves:"*) IN_WAVES_SECTION=1; continue ;; esac
    [ "$IN_WAVES_SECTION" -eq 0 ] && continue
    # Top-level key (no indent) exits waves section
    case "$line" in [a-zA-Z]*) break ;; esac
    # Match wave headers at 2-space indent
    case "$line" in
      "  $WAVE:"*) IN_WAVE=1; continue ;;
      "  "[a-zA-Z]*) [ "$IN_WAVE" -eq 1 ] && break ;;
    esac
    [ "$IN_WAVE" -eq 0 ] && continue
    case "$line" in *"tasks:"*"["*)
      TASK_IDS="${line#*\[}"
      TASK_IDS="${TASK_IDS%\]*}"
      break ;;
    esac
  done < "$state_file"
  [ -z "$TASK_IDS" ] && continue

  # Collect writes from each task in the current wave.
  # state.yml indentation (2-space YAML):
  #   tasks:
  #     t1:              (2-space)
  #       writes:          (4-space)
  #         - path/to/file   (6-space)
  IN_TASKS=0
  CURRENT_TASK=""
  IN_WRITES=0
  while IFS= read -r line; do
    case "$line" in "tasks:"*) IN_TASKS=1; continue ;; esac
    [ "$IN_TASKS" -eq 0 ] && continue

    # Detect task ID lines (2-space indent, word + colon)
    case "$line" in "  "[a-zA-Z0-9_-]*":"*)
      tid="${line#  }" ; tid="${tid%%:*}"
      CURRENT_TASK=""
      # Check if this task ID appears in the wave's task list
      case " $TASK_IDS" in *"$tid"*) CURRENT_TASK="$tid" ;; esac
      IN_WRITES=0
      continue ;;
    esac

    [ -z "$CURRENT_TASK" ] && continue

    # Detect writes: block (4-space indent)
    case "$line" in "    writes:"*) IN_WRITES=1; continue ;; esac

    # Inside writes block: items at 6-space indent with "- "
    if [ "$IN_WRITES" -eq 1 ]; then
      case "$line" in "      - "*)
        WRITE_PATH="${line#      - }"
        case "$FILE_PATH" in *"$WRITE_PATH") exit 0 ;; esac ;;
      *)
        IN_WRITES=0 ;;
      esac
    fi
  done < "$state_file"
done

# Target file is NOT a unit-completion artifact, not owned by an active plan,
# and the compact flag exists. Block it.
printf '{"decision":"block","reason":"Compact required before starting next unit. Run /compact, then retry."}\n'
exit 2
