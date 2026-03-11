# git-advanced-workflows: Process Reference

## Branching Strategies

### Trunk-Based Development
All developers commit directly to `main` (or short-lived branches < 2 days). Feature flags
gate incomplete work. CI must pass before merge. Requires a mature test suite and deployment pipeline.

Best for: small teams, high-deployment-frequency products, microservices.

Risks: requires feature flags discipline; incomplete features can bleed into production if flags aren't set.

### GitHub Flow
`main` is always deployable. Create a branch, open a PR, get review, merge via squash or merge commit.
No `develop` branch. No release branches unless you need them for versioning.

Best for: web apps, SaaS products, teams of 3–15, continuous delivery.

Workflow:
1. `git checkout -b feat/my-feature`
2. Work, commit, push
3. Open PR against `main`
4. Squash merge after approval
5. Deploy immediately

### Gitflow
Two permanent branches: `main` (production) and `develop` (integration). Features branch off `develop`.
Releases branch off `develop`, get stabilized, then merge to both `main` and `develop`. Hotfixes branch
off `main`, merge to both.

Best for: versioned software, mobile apps with release cycles, teams with external QA.

Branch naming:
- `feature/TICKET-description`
- `release/1.4.0`
- `hotfix/1.3.1-login-fix`

Pitfall: `develop` becomes a garbage dump if teams don't enforce PR quality. Long-lived feature branches
diverge and create painful merges. Mitigate with frequent rebase-onto-develop.

---

## Interactive Rebase Workflows

`git rebase -i HEAD~N` — edit the last N commits.

Commands available in the rebase editor:
- `pick` — keep as-is
- `reword` — edit the commit message
- `squash` — combine into previous commit, merge messages
- `fixup` — combine into previous commit, discard this message
- `drop` — delete the commit entirely
- `edit` — pause here; amend then `git rebase --continue`

### Clean-up before PR
1. `git rebase -i origin/main` — rebase against base branch
2. Squash all fixup/WIP commits into their logical parent
3. Reword messages to imperative mood with clear scope
4. Force-push your branch: `git push --force-with-lease`

### Autosquash workflow
```bash
# During work, mark fixup commits explicitly:
git commit --fixup=<sha-of-parent-commit>

# Then squash all of them in one pass:
git rebase -i --autosquash origin/main
```

---

## git bisect for Bug Hunting

Bisect uses binary search across commit history to find the commit that introduced a bug.

```bash
git bisect start
git bisect bad                  # current commit is broken
git bisect good v2.3.0          # last known-good tag or SHA

# Git checks out the midpoint commit. Test it, then:
git bisect good                 # or:
git bisect bad

# Repeat until git reports: "abc123 is the first bad commit"
git bisect reset                # return to HEAD
```

Automate with a test script:
```bash
git bisect run npm test -- --testNamePattern="login redirect"
```

This runs the command at each step — exits 0 for good, non-zero for bad. Bisect completes without
manual intervention.

---

## Cherry-Pick Safely

Cherry-pick copies a commit from one branch to another without merging the whole branch.

```bash
git cherry-pick <sha>
git cherry-pick <sha1>..<sha2>   # range (exclusive of sha1)
git cherry-pick <sha1>^..<sha2>  # range (inclusive of sha1)
```

Safe use cases:
- Backporting a bugfix to a release branch
- Pulling a specific commit to a hotfix without taking WIP on develop

Risks:
- Creates duplicate commits with different SHAs — diff history between branches becomes noisy
- If the cherry-picked commit depends on earlier context that doesn't exist on the target, expect conflicts
- Don't cherry-pick commits that will eventually be merged — it causes phantom conflicts at merge time

After cherry-pick to a release branch, always verify the fix in isolation before tagging.

---

## Worktree Patterns

`git worktree` checks out multiple branches into separate directories simultaneously, sharing the
same `.git` database. No stashing, no branch switching, no lost state.

```bash
# Create a worktree for a hotfix while staying on your feature branch:
git worktree add ../hotfix-login hotfix/1.3.1-login-fix

# Work in that directory as a normal repo:
cd ../hotfix-login
# ... fix, commit, push ...

# Remove when done:
git worktree remove ../hotfix-login
```

Use worktrees when:
- You need to review or run another branch without interrupting work-in-progress
- Running long CI builds on one branch while developing on another
- Hotfix urgency; can't wait to stash and context-switch cleanly

Limit active worktrees. Each one takes disk space and can cause confusion if left stale.

---

## Stash Management

`git stash` shelves uncommitted changes so you can switch context cleanly.

```bash
git stash push -m "wip: auth form validation"   # named stash
git stash list                                    # view all stashes
git stash pop                                     # apply and drop top
git stash apply stash@{2}                         # apply specific, keep in list
git stash drop stash@{2}                          # delete specific
git stash clear                                   # delete all (destructive)
```

Stash specific files only:
```bash
git stash push -m "just the config change" -- config/settings.ts
```

Stash including untracked files:
```bash
git stash push -u -m "with new files"
```

Discipline: treat stashes as short-term (minutes to hours). Long-term work belongs in a branch.
Stashes have no branch association — they detach from context and become confusing after a few days.

---

## Conflict Resolution Strategies

### Before you start
- `git fetch` and rebase before opening a PR to minimize conflicts at merge time
- Short-lived branches reduce divergence — aim for < 2 days before merging

### During a conflict
```bash
git diff --diff-filter=U          # show only conflicted files
git mergetool                     # opens configured visual diff tool
```

Conflict markers:
```
<<<<<<< HEAD
your change
=======
incoming change
>>>>>>> feature/other-branch
```

Resolution approaches:
- **Accept ours**: `git checkout --ours -- path/to/file`
- **Accept theirs**: `git checkout --theirs -- path/to/file`
- **Manual merge**: edit the file, remove markers, stage with `git add`

After resolving all files: `git rebase --continue` (for rebase) or `git merge --continue`.

### Rerere (reuse recorded resolution)
```bash
git config rerere.enabled true
```
Git records how you resolved a conflict. Next time the same conflict appears (e.g., repeated rebases),
it applies the recorded resolution automatically.

---

## Git Hooks

Hooks run automatically at lifecycle points. Store in `.git/hooks/` (local only) or use a tool like
`husky` or `lefthook` to version them in the repo.

### pre-commit
Runs before the commit is created. Use for: lint, type-check, secret scanning, test subset.

```bash
#!/bin/sh
set -euo pipefail
npx lint-staged
```

If it exits non-zero, the commit is aborted. Keep it fast (< 5s) or developers will bypass it.

### commit-msg
Validates the commit message format. Useful for enforcing conventional commits or ticket references.

```bash
#!/bin/sh
set -euo pipefail
commit_regex='^(feat|fix|chore|docs|refactor|test|style)(\(.+\))?: .{1,72}'
if ! grep -qE "$commit_regex" "$1"; then
  echo "Commit message does not match conventional format."
  exit 1
fi
```

### pre-push
Heavier checks — run full test suite, check branch protection rules. Slower is acceptable here
since pushes are less frequent.

---

## Anti-Patterns

**Long-lived feature branches** — diverge from main, produce massive merge conflicts, obscure
progress visibility. Merge or delete branches within 1–2 days. Use feature flags instead.

**Merge commits everywhere** — a repo full of `Merge branch 'develop' into feature/x` commits
makes `git log` unreadable. Rebase before merge to keep history linear.

**Force-pushing shared branches** — rewrites history for everyone downstream. Never force-push
`main`, `develop`, or any branch another person is working on. Use `--force-with-lease` on
personal branches to at least catch upstream changes before overwriting.

**Squashing on shared branches** — if other people branch off a feature branch, squashing
that branch rewrites the base they're working from. Squash only before the first time a branch
is merged into a shared target.

**Committing secrets or large binaries** — they persist in history even after deletion.
Use `git filter-repo` to excise them, rotate credentials immediately, and add pre-commit hooks
to catch them before they land.

**Ignoring `.gitignore` hygiene** — committing `node_modules`, build artifacts, or editor files
creates noise and slows clone/fetch. Use a global gitignore for editor files, project-level for
build artifacts.
