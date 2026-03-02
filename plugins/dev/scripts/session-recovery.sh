#!/bin/bash
echo "=== Session Recovery Check ==="
if [ -f state.yml ]; then
  echo "State file found."
  echo "Current phase: $(grep 'current_phase:' state.yml 2>/dev/null)"
  echo "Last updated: $(stat -c %Y state.yml 2>/dev/null || stat -f %m state.yml 2>/dev/null)"
  ERRORS=$(grep -c '  - timestamp:' state.yml 2>/dev/null || echo 0)
  echo "Logged errors: $ERRORS"
  echo "Git changes since last commit:"
  git diff --stat HEAD 2>/dev/null || echo "  (not a git repo)"
else
  echo "No state.yml found. Fresh start."
fi
