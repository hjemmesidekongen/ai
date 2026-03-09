#!/usr/bin/env bash
set -euo pipefail
# claude-core — git worktree create utility
# Usage: worktree-create.sh <name> <branch-name>
# Creates .worktrees/<name>/ on a new branch, runs setup, verifies baseline.

NAME="${1:-}"
BRANCH="${2:-}"

if [ -z "$NAME" ] || [ -z "$BRANCH" ]; then
  echo "Usage: worktree-create.sh <name> <branch-name>" >&2
  exit 1
fi

# Validate inputs: alphanumeric, dots, underscores, hyphens, slashes only
VALID_PATTERN='^[a-zA-Z0-9._/-]+$'
if [[ ! "$NAME" =~ $VALID_PATTERN ]] || [[ ! "$BRANCH" =~ $VALID_PATTERN ]]; then
  echo "Error: name and branch must match [a-zA-Z0-9._/-]+" >&2
  exit 1
fi

WORKTREE_DIR=".worktrees/${NAME}"

# --- Step 1: Gitignore safety check ---
if [ -f ".gitignore" ]; then
  if ! grep -q '\.worktrees' .gitignore 2>/dev/null; then
    echo "Adding .worktrees/ to .gitignore..."
    echo '.worktrees/' >> .gitignore
    git add .gitignore
    git commit -m "add .worktrees/ to gitignore"
    echo ".gitignore updated."
  fi
else
  echo '.worktrees/' > .gitignore
  git add .gitignore
  git commit -m "add .gitignore with .worktrees/ pattern"
  echo ".gitignore created."
fi

# --- Step 2: Create worktree ---
if [ -d "$WORKTREE_DIR" ]; then
  echo "Error: $WORKTREE_DIR already exists." >&2
  exit 1
fi

echo "Creating worktree '$NAME' on branch '$BRANCH'..."
git worktree add "$WORKTREE_DIR" -b "$BRANCH"
echo "Worktree created at $WORKTREE_DIR"

# --- Step 3: Setup detection ---
cd "$WORKTREE_DIR"

if [ -f "yarn.lock" ] && [ -f "package.json" ]; then
  echo "Detected yarn project. Running yarn install..."
  yarn install --frozen-lockfile 2>/dev/null || yarn install
elif [ -f "package.json" ]; then
  echo "Detected npm project. Running npm install..."
  npm install --silent 2>/dev/null || npm install
elif [ -f "Gemfile" ]; then
  echo "Detected Ruby project. Running bundle install..."
  bundle install --quiet 2>/dev/null || bundle install
elif [ -f "requirements.txt" ]; then
  echo "Detected Python project. Running pip install..."
  pip install -r requirements.txt -q 2>/dev/null || pip install -r requirements.txt
elif [ -f "go.mod" ]; then
  echo "Detected Go project. Running go mod download..."
  go mod download
else
  echo "No setup file detected. Skipping setup."
fi

cd - > /dev/null

# --- Step 4: Baseline verification ---
DIRTY=$(git -C "$WORKTREE_DIR" status --porcelain 2>/dev/null | grep -v '^?' || true)
if [ -n "$DIRTY" ]; then
  echo "Warning: unexpected dirty files after setup:"
  echo "$DIRTY"
  echo "Inspect before proceeding."
else
  echo "Baseline clean."
fi

echo ""
echo "Worktree ready."
echo "  Path:   $WORKTREE_DIR"
echo "  Branch: $BRANCH"
echo ""
echo "Finish with: bash plugins/claude-core/scripts/worktree-finish.sh $NAME merge|pr|keep|discard"
