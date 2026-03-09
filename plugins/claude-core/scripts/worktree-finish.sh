#!/usr/bin/env bash
set -euo pipefail
# claude-core — git worktree finish utility
# Usage: worktree-finish.sh <name> <action>
# Actions: merge | pr | keep | discard

NAME="${1:-}"
ACTION="${2:-}"

if [ -z "$NAME" ] || [ -z "$ACTION" ]; then
  echo "Usage: worktree-finish.sh <name> merge|pr|keep|discard" >&2
  exit 1
fi

WORKTREE_DIR=".worktrees/${NAME}"

if [ ! -d "$WORKTREE_DIR" ]; then
  echo "Error: worktree '$WORKTREE_DIR' not found." >&2
  echo "Active worktrees:" >&2
  git worktree list >&2
  exit 1
fi

# Get branch name from worktree
BRANCH=$(git -C "$WORKTREE_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null) || {
  echo "Error: could not determine branch for worktree '$NAME'." >&2
  exit 1
}

echo "Finishing worktree '$NAME' (branch: $BRANCH) with action: $ACTION"

case "$ACTION" in

  merge)
    MAIN_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo "Merging '$BRANCH' into '$MAIN_BRANCH'..."
    git worktree remove "$WORKTREE_DIR" 2>/dev/null || git worktree remove "$WORKTREE_DIR" --force
    git merge "$BRANCH" --no-ff -m "Merge branch '$BRANCH'"
    echo "Merged. Branch '$BRANCH' still exists (delete with: git branch -d $BRANCH)."
    ;;

  pr)
    echo "Pushing branch '$BRANCH' to remote..."
    git -C "$WORKTREE_DIR" push -u origin "$BRANCH"
    git worktree remove "$WORKTREE_DIR" 2>/dev/null || git worktree remove "$WORKTREE_DIR" --force
    echo "Creating pull request..."
    gh pr create --head "$BRANCH" --fill
    ;;

  keep)
    git worktree remove "$WORKTREE_DIR" 2>/dev/null || {
      echo "Worktree has uncommitted changes. Use 'discard' to force-remove, or commit first." >&2
      exit 1
    }
    echo "Worktree removed. Branch '$BRANCH' kept."
    echo "Resume with: git worktree add .worktrees/$NAME $BRANCH"
    ;;

  discard)
    echo "Discarding worktree and branch '$BRANCH'..."
    git worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
    # Check for unmerged commits before force-deleting
    MAIN_REF=$(git rev-parse --abbrev-ref HEAD)
    if ! git merge-base --is-ancestor "$BRANCH" "$MAIN_REF" 2>/dev/null; then
      echo "Warning: branch '$BRANCH' has unmerged commits not in '$MAIN_REF'."
      echo "Proceeding with delete as requested (discard action)."
    fi
    git branch -D "$BRANCH" 2>/dev/null || echo "Branch '$BRANCH' already deleted or not found."
    echo "Discarded."
    ;;

  *)
    echo "Error: unknown action '$ACTION'. Use: merge | pr | keep | discard" >&2
    exit 1
    ;;

esac

git worktree prune 2>/dev/null || true
echo "Done."
