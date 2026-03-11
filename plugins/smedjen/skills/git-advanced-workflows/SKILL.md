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
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 2
  changes: "Replaced standard git knowledge with advanced automation, monorepo patterns, and safety checklists"
---

# git-advanced-workflows

## Scripted Bisect Automation

`git bisect start HEAD v2.1.0 && git bisect run npm test` — fully automated regression finder. The test command must exit 0 (good) or 1 (bad). Exit 125 means "skip this commit" (useful for broken builds unrelated to the bug).

For frontend regressions: `git bisect run bash -c "npm run build && node check-bundle-size.js"`. Any scriptable assertion works.

Write bisect test scripts as standalone files (`scripts/bisect-check.sh`) so they survive checkout across commits.

## Monorepo Git Patterns

**Sparse checkout**: `git sparse-checkout set packages/my-app packages/shared` — clone the full repo but only materialize relevant paths. Cuts working tree by 90% in large monorepos.

**Path-scoped hooks**: lint-staged config per package — `lint-staged` supports package-level configs. In the root `.lintstagedrc`, use `"packages/app-a/**/*.ts": "eslint"` patterns to scope checks.

**CODEOWNERS by path**: `packages/payments/ @payments-team` — enforces review boundaries. Combine with branch protection rules for path-based approval requirements.

**Selective CI**: trigger pipelines only for changed paths. GitHub Actions: `paths:` filter. GitLab: `rules: changes:`. Skip full-repo CI on every commit.

## Pre-commit Hook Patterns

**lint-staged + husky**: `npx husky init`, add `npx lint-staged` to `.husky/pre-commit`. Runs linters only on staged files. **Commit message validation**: commitlint in `.husky/commit-msg` with `@commitlint/config-conventional`. **Type checking**: `tsc --noEmit` is slow — use `tsc-files --noEmit` to check only staged `.ts` files.

## Large File Handling

**Git LFS**: binary assets (images, fonts, models) under ~1GB total. `git lfs track "*.psd"` adds to `.gitattributes`. **Externalize**: assets >100MB or frequently changing media belong in S3/CDN — LFS bandwidth costs add up. **BFG Repo Cleaner**: already committed large files? `bfg --strip-blobs-bigger-than 10M` rewrites history. Coordinate before force-pushing.

## Dangerous Commands Safety Checklist

| Command | Risk | Safe alternative |
|---------|------|-----------------|
| `git push --force` | Overwrites remote history | `--force-with-lease` (fails if remote changed) |
| `git reset --hard` | Destroys uncommitted work | `git stash` first, or `git reset --keep` |
| `git clean -fd` | Deletes untracked files permanently | `git clean -fdn` (dry run) first |
| `git checkout -- .` | Discards all unstaged changes | `git stash` to preserve, restore if needed |
| `git branch -D` | Deletes branch without merge check | `-d` (lowercase) fails if unmerged |

Before any destructive command: `git stash && git log --oneline -5` to verify state.

See `references/process.md` for interactive rebase, cherry-pick, worktrees, stash, and conflict resolution.
