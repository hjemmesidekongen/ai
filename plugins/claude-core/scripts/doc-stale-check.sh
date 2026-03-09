#!/usr/bin/env bash
set -euo pipefail
# claude-core — Stop hook: warn if plugin files changed without doc updates
# Advisory only — exit 0 always, JSON output.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Gather changed files (staged + unstaged + last commit)
CHANGED=$(git -C "$PROJECT_DIR" diff --name-only HEAD 2>/dev/null || true)
STAGED=$(git -C "$PROJECT_DIR" diff --cached --name-only 2>/dev/null || true)
ALL_CHANGED=$(printf '%s\n%s' "$CHANGED" "$STAGED" | sort -u | grep -v '^$' || true)

[ -z "$ALL_CHANGED" ] && exit 0

# Infrastructure files: skills, commands, scripts, plugin config, agents
INFRA=$(echo "$ALL_CHANGED" | grep -E 'plugins/.+/(skills|commands|scripts|agents|hooks)/' || true)
INFRA_CONFIG=$(echo "$ALL_CHANGED" | grep -E 'plugins/.+/\.claude-plugin/' || true)
INFRA_FILES=$(printf '%s\n%s' "$INFRA" "$INFRA_CONFIG" | grep -v '^$' | sort -u || true)

[ -z "$INFRA_FILES" ] && exit 0

INFRA_COUNT=$(echo "$INFRA_FILES" | wc -l | tr -d ' ')
[ "$INFRA_COUNT" -le 1 ] && exit 0

# Documentation files
DOC_FILES=$(echo "$ALL_CHANGED" | grep -E '(CLAUDE\.md|MEMORY\.md|roadmap\.yml|README\.md|ecosystem\.json)' || true)

[ -n "$DOC_FILES" ] && exit 0

# Infrastructure changed, docs didn't — warn
echo "{\"decision\":\"approve\",\"reason\":\"Doc drift detected.\",\"systemMessage\":\"Doc drift warning: ${INFRA_COUNT} plugin files changed but no docs updated. Run doc-checkpoint skill.\"}"

exit 0
