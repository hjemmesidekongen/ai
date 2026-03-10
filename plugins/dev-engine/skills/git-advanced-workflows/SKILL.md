---
name: git-advanced-workflows
description: >
  Advanced git workflows: branching strategies, interactive rebase, bisect,
  cherry-pick, stashing, worktrees, and conflict resolution patterns.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "git workflow"
  - "branching strategy"
  - "git advanced"
  - "git rebase"
  - "git bisect"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "strategy_matches_team"
      verify: "Branching strategy fits team size and release cadence"
      fail_action: "Reassess — trunk-based for small teams, gitflow for release trains"
    - name: "history_clean"
      verify: "Commits are logical units, no WIP or fixup leftovers"
      fail_action: "Squash or rebase to clean history before merge"
    - name: "no_force_push_shared"
      verify: "Force push only on personal branches, never shared ones"
      fail_action: "Use --force-with-lease at minimum, prefer merge"
  on_fail: "Git workflow has issues — review the patterns"
  on_pass: "Clean git workflow with appropriate strategy"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# git-advanced-workflows

## Branching Strategy Decision Tree

**Small team (1–5), continuous deployment?** → Trunk-based development. Feature flags over branches.

**Release trains or external QA gates?** → Gitflow. `develop`, `release/*`, `hotfix/*` branches with strict merge paths.

**Web app, small-to-mid team, PR-driven?** → GitHub Flow. `main` always deployable, short-lived feature branches.

When in doubt, start with GitHub Flow. Migrate to Gitflow only when release cycles force it.

## Rebase vs Merge

Rebase on personal branches to keep history linear. Rebase before opening a PR to pull in upstream changes. Merge into shared branches (`main`, `develop`) — never rebase shared history.

**Golden rule:** never rebase commits that exist outside your local repo. Rebasing rewrites SHAs; anyone downstream ends up with diverged history they can't cleanly reconcile.

## Commit Hygiene

Each commit is one logical unit — reviewable and revertable.

- Imperative mood subject: "fix login redirect" not "fixed"
- 50 chars subject, 72 chars body lines; ticket reference in body
- `git commit --fixup` + `git rebase --autosquash` to fold fixups
- `git rebase -i HEAD~N` to squash, reorder, or reword before merge

No WIP commits. No "address review comments" commits — squash them in.

## Full Patterns

See `references/process.md`:
- Trunk-based, Gitflow, GitHub Flow in detail
- Interactive rebase, bisect, cherry-pick, worktrees, stash
- Conflict resolution, pre-commit hooks, anti-patterns
