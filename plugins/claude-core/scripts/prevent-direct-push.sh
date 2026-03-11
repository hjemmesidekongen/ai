#!/usr/bin/env bash
set -euo pipefail
# prevent-direct-push.sh — Blocks git push to protected branches
# claude-core PreToolUse hook (Bash)
# Protected branches: main, master, production, release/*
# Allows push to feature branches and push with -u (setting upstream).
# Blocking (exit 2 to deny).

trap 'exit 0' ERR

INPUT=$(cat)

# Extract the command being run
COMMAND=""
case "$INPUT" in *'"command":"'*)
  COMMAND="${INPUT#*\"command\":\"}"
  COMMAND="${COMMAND%%\"*}" ;;
esac
[ -z "$COMMAND" ] && exit 0

# Only care about git push commands
case "$COMMAND" in
  *"git push"*) ;;
  *) exit 0 ;;
esac

# Allow if pushing to a non-protected branch explicitly
# Extract the branch/refspec being pushed to
PROTECTED_BRANCHES="main master production"

# Check for force push — always block to protected branches
FORCE_PUSH=false
case "$COMMAND" in
  *"--force"*|*"-f "*|*" -f"*) FORCE_PUSH=true ;;
esac

# Extract remote and branch from command
# Patterns: git push origin main, git push -u origin feature/x, git push
for BRANCH in $PROTECTED_BRANCHES; do
  case "$COMMAND" in
    *"git push"*" $BRANCH"*|*"git push"*":$BRANCH"*)
      if [ "$FORCE_PUSH" = true ]; then
        echo '{"decision":"block","reason":"Force push to protected branch '"$BRANCH"' is blocked. Use a PR workflow instead."}'
        exit 2
      fi
      echo '{"decision":"block","reason":"Direct push to '"$BRANCH"' is blocked. Push to a feature branch and create a PR instead."}'
      exit 2
      ;;
  esac
  # Also catch release/* pattern
  case "$COMMAND" in
    *"git push"*" release/"*)
      echo '{"decision":"block","reason":"Direct push to release branch is blocked. Use a PR workflow instead."}'
      exit 2
      ;;
  esac
done

# Allow all other pushes (feature branches, -u upstream setting, etc.)
exit 0
