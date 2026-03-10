---
name: git-worktree-isolation
description: >
  Structured git worktree lifecycle for isolated branch work. Creates a
  second working tree at .worktrees/<name>/ on a new branch, auto-detects
  and runs setup, verifies clean baseline. Finishes with 4 options: merge
  to main, open PR, keep branch, or discard. Safety: always verifies
  .worktrees/ is gitignored before creating.
  Use when starting risky or experimental work that shouldn't affect the
  main working tree, when parallel feature branches need isolation, before
  large refactors that may need to be discarded, or when you need a clean
  baseline to test something without stashing.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "worktree isolation"
  - "isolated branch work"
  - "experimental branch"
  - "risky refactor branch"
  - "parallel feature branch"
  - "try something risky"
  - "safe experiment"
  - "disposable branch"
  - "test without stashing"
reads:
  - ".gitignore"
  - "package.json|Gemfile|requirements.txt|go.mod (optional)"
writes:
  - ".gitignore (if .worktrees/ missing)"
  - ".worktrees/<name>/ (worktree directory)"
checkpoint:
  type: code_validation
  required_checks:
    - name: "gitignore_safe"
      verify: ".worktrees/ pattern exists in .gitignore before worktree is created"
      fail_action: "Add .worktrees/ to .gitignore first"
    - name: "clean_baseline"
      verify: "Worktree has no unexpected dirty files after setup"
      fail_action: "Investigate dirty files — may indicate setup script side effects"
    - name: "finish_complete"
      verify: "Chosen finish action executed and worktree removed from list"
      fail_action: "Run git worktree prune and verify worktree is gone"
  on_fail: "Fix the blocking issue before proceeding with worktree work."
  on_pass: "Worktree ready. Branch: <name>. Path: .worktrees/<name>/."
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "superpowers repo — git worktree isolation pattern"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted lifecycle + safety checks to claude-core skill format"
---

# git-worktree-isolation

Isolated branch work via git worktrees. Prevents experimental changes from
bleeding into the main working tree without stashing or branch-switching.

## Lifecycle

```
CREATE  → gitignore check → git worktree add → setup detection → baseline verify
WORK    → normal development in .worktrees/<name>/
FINISH  → choose: merge | pr | keep | discard
```

## Quick reference

```bash
# Create
bash plugins/claude-core/scripts/worktree-create.sh <name> <branch>

# Finish
bash plugins/claude-core/scripts/worktree-finish.sh <name> merge|pr|keep|discard

# List active worktrees
git worktree list
```

## Process

See `references/process.md` for full steps, setup detection rules, and
finish option details.
