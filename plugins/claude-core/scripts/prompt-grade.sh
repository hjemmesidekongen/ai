#!/usr/bin/env bash
# prompt-grade.sh — Grade incoming prompts on clarity and stakes
# claude-core UserPromptSubmit hook
# When a prompt is vague AND high-stakes, injects additionalContext to load prompt-optimizer.
# Pure text analysis, no LLM calls. Target: < 50ms.

# Non-blocking hook: any unexpected error outputs {} and exits 0
safe_exit() { echo '{}'; exit 0; }
trap safe_exit ERR

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOG_FILE="$PROJECT_DIR/.ai/traces/hook-errors.log"

# Cap input at 64KB to prevent DoS on shell variable operations
INPUT=$(head -c 65536)

# Extract prompt text using jq if available, fallback to string manipulation
PROMPT=""
if command -v jq >/dev/null 2>&1; then
  PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null) || PROMPT=""
else
  case "$INPUT" in *'"prompt"'*)
    PROMPT="${INPUT#*\"prompt\":}"
    PROMPT="${PROMPT# }"
    PROMPT="${PROMPT#\"}"
    PROMPT="${PROMPT%\"*}"
    ;;
  esac
fi

# Skip empty or very short prompts (commands, one-word queries)
if [ "${#PROMPT}" -lt 5 ]; then echo '{}'; exit 0; fi

# Lowercase for matching (bash 3.2 compatible)
PROMPT_LOWER=$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')

# --- Clarity Score (0-10) ---
CLARITY=0

# Word count: use wc
WORD_COUNT=$(printf '%s' "$PROMPT" | wc -w | tr -d ' ')

# Word count contribution (0-3 points)
if [ "$WORD_COUNT" -ge 31 ]; then
  CLARITY=$((CLARITY + 3))
elif [ "$WORD_COUNT" -ge 16 ]; then
  CLARITY=$((CLARITY + 2))
elif [ "$WORD_COUNT" -ge 6 ]; then
  CLARITY=$((CLARITY + 1))
fi

# File paths present (0-2 points)
FILE_PATH_SCORE=0
case "$PROMPT" in
  *"/"*"."*) FILE_PATH_SCORE=2 ;;
  *".ts"*|*".js"*|*".py"*|*".sh"*|*".yml"*|*".json"*|*".md"*) FILE_PATH_SCORE=1 ;;
  *"src/"*|*"plugins/"*|*"components/"*|*"pages/"*|*"lib/"*) FILE_PATH_SCORE=2 ;;
esac
CLARITY=$((CLARITY + FILE_PATH_SCORE))

# Action verbs (0-2 points)
ACTION_SCORE=0
case "$PROMPT_LOWER" in
  *" add "*|*" create "*|*" remove "*|*" update "*|*" change "*|*" move "*|*" extract "*) ACTION_SCORE=$((ACTION_SCORE + 1)) ;;
esac
case "$PROMPT_LOWER" in
  *" replace "*|*" convert "*|*" split "*|*" merge "*|*" insert "*|*" wrap "*|*" rename "*) ACTION_SCORE=$((ACTION_SCORE + 1)) ;;
esac
if [ "$ACTION_SCORE" -gt 2 ]; then ACTION_SCORE=2; fi
CLARITY=$((CLARITY + ACTION_SCORE))

# Constraints mentioned (0-2 points)
CONSTRAINT_SCORE=0
case "$PROMPT_LOWER" in
  *" must "*|*" should "*|*" only "*|*" without "*|*" no more than "*|*" at most "*|*" at least "*) CONSTRAINT_SCORE=$((CONSTRAINT_SCORE + 1)) ;;
esac
case "$PROMPT_LOWER" in
  *" lines"*|*" characters"*|*" words"*|*" bytes"*|*" max "*|*" limit "*|*" under "*) CONSTRAINT_SCORE=$((CONSTRAINT_SCORE + 1)) ;;
esac
if [ "$CONSTRAINT_SCORE" -gt 2 ]; then CONSTRAINT_SCORE=2; fi
CLARITY=$((CLARITY + CONSTRAINT_SCORE))

# Output format specs (0-1 point)
case "$PROMPT_LOWER" in
  *"json"*|*"yaml"*|*"csv"*|*"markdown"*|*"table"*|*"list"*|*"format"*|*"output"*) CLARITY=$((CLARITY + 1)) ;;
esac

# Cap clarity at 10
if [ "$CLARITY" -gt 10 ]; then CLARITY=10; fi

# --- Stakes Score (0-10) ---
STAKES=0

# High stakes keywords (7-10 range)
case "$PROMPT_LOWER" in
  *"refactor"*) STAKES=8 ;;
  *"architect"*) STAKES=9 ;;
  *"design system"*) STAKES=9 ;;
  *"migrate"*|*"migration"*) STAKES=9 ;;
  *"implement"*) STAKES=7 ;;
  *"scaffold"*) STAKES=7 ;;
  *"deploy"*|*"production"*) STAKES=10 ;;
  *"build"*) STAKES=7 ;;
  *"redesign"*|*"rewrite"*) STAKES=9 ;;
  *"infrastructure"*) STAKES=8 ;;
  *"database"*|*"schema"*) STAKES=8 ;;
  *"authentication"*|*"auth "*) STAKES=9 ;;
  *"security"*) STAKES=9 ;;
  *"api "*|*" api"*|*"endpoint"*) STAKES=7 ;;
  *"codebase"*|*"everything"*|*"entire"*|*"whole project"*) STAKES=7 ;;
esac

# Creative-high keywords (7-8 range) — only if not already scored higher
if [ "$STAKES" -lt 7 ]; then
  case "$PROMPT_LOWER" in
    *"professional"*|*"polished"*) STAKES=7 ;;
    *"beautiful"*|*"stunning"*) STAKES=7 ;;
    *"landing page"*|*"landing"*) STAKES=8 ;;
    *"brand"*|*"branding"*) STAKES=8 ;;
    *"portfolio"*|*"showcase"*) STAKES=7 ;;
  esac
fi

# Medium stakes (4-6 range)
if [ "$STAKES" -eq 0 ]; then
  case "$PROMPT_LOWER" in
    *"component"*|*"feature"*) STAKES=5 ;;
    *"hook"*|*"plugin"*) STAKES=5 ;;
    *"test"*|*"spec"*) STAKES=4 ;;
    *"config"*|*"setup"*) STAKES=4 ;;
    *"style"*|*"css"*) STAKES=4 ;;
  esac
fi

# Low stakes keywords (1-3 range) — only if still 0
if [ "$STAKES" -eq 0 ]; then
  case "$PROMPT_LOWER" in
    *"fix "*|*" fix"*) STAKES=3 ;;
    *"rename"*) STAKES=2 ;;
    *"delete"*|*"remove"*) STAKES=2 ;;
    *"read "*|*" read"*) STAKES=1 ;;
    *"list "*|*" list"*) STAKES=1 ;;
    *"check "*|*" check"*) STAKES=2 ;;
    *"show "*|*" show"*) STAKES=1 ;;
    *"status"*) STAKES=1 ;;
    *"log"*|*"print"*) STAKES=1 ;;
  esac
fi

# Default: no keywords detected, assume medium
if [ "$STAKES" -eq 0 ]; then STAKES=5; fi

# --- Decision ---
# Intervene when: (clarity <= 4 AND stakes >= 6) OR (clarity <= 6 AND stakes >= 8)
INTERVENE=0
if [ "$CLARITY" -le 4 ] && [ "$STAKES" -ge 6 ]; then
  INTERVENE=1
elif [ "$CLARITY" -le 6 ] && [ "$STAKES" -ge 8 ]; then
  INTERVENE=1
fi

# Truncate prompt for logging (first 80 chars)
PROMPT_PREVIEW=$(printf '%.80s' "$PROMPT")
# Strip pipes, newlines, carriage returns from preview for log safety
PROMPT_PREVIEW=$(printf '%s' "$PROMPT_PREVIEW" | tr '|\n\r' '---')

# Log decision
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

if [ "$INTERVENE" -eq 1 ]; then
  printf '%s|prompt-grade|intervene|%s|clarity=%d stakes=%d — vague high-stakes prompt\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$PROMPT_PREVIEW" "$CLARITY" "$STAKES" >> "$LOG_FILE" 2>/dev/null || true

  printf '{"additionalContext":"The user'\''s prompt is vague for a high-stakes task. Before executing, load the prompt-optimizer skill (Mode A: auto-sharpen). Analyze the prompt, infer missing context from the codebase, and rewrite it into a precise instruction. Show '\''I will approach this as: [sharpened prompt]'\'' then proceed with the sharpened version."}\n'
else
  printf '%s|prompt-grade|pass|%s|clarity=%d stakes=%d\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$PROMPT_PREVIEW" "$CLARITY" "$STAKES" >> "$LOG_FILE" 2>/dev/null || true

  echo '{}'
fi

exit 0
