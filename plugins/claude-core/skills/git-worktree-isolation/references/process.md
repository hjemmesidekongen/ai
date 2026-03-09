# git-worktree-isolation — Process

## Phase 1: Create

### Step 1 — Gitignore safety check

Before any worktree operation, verify `.gitignore` contains `.worktrees/`:

```bash
grep -q '\.worktrees' .gitignore 2>/dev/null || echo "MISSING"
```

If missing, add it:
```bash
echo '.worktrees/' >> .gitignore
git add .gitignore
git commit -m "add .worktrees/ to gitignore"
```

Never skip this. An un-ignored worktree directory shows up as untracked
files in every git status across the repo.

### Step 2 — Create the worktree

```bash
bash plugins/claude-core/scripts/worktree-create.sh <name> <branch-name>
```

Runs: gitignore check → `git worktree add .worktrees/<name> -b <branch-name>`
→ setup detection → baseline verification.

If the branch already exists, use the existing-branch form:
`git worktree add .worktrees/<name> <existing-branch>`

### Step 3 — Setup detection

After creating the worktree, auto-detect and run project setup:

| File present | Command run |
|---|---|
| `package.json` + `yarn.lock` | `yarn install` |
| `package.json` | `npm install` |
| `Gemfile` | `bundle install` |
| `requirements.txt` | `pip install -r requirements.txt` |
| `go.mod` | `go mod download` |
| None | Skip |

Setup runs inside `.worktrees/<name>/`.

### Step 4 — Baseline verification

```bash
git -C .worktrees/<name> status --porcelain
```

Expected: empty (clean) or only gitignored build artifacts.
If unexpected dirty files appear, report them before proceeding.

---

## Phase 2: Finish

### Option 1: merge

Merges branch into main, removes worktree.

```bash
bash plugins/claude-core/scripts/worktree-finish.sh <name> merge
```

Use when: work is done, ready to land directly.

### Option 2: pr

Pushes branch, opens GitHub PR via `gh pr create`, removes worktree.

```bash
bash plugins/claude-core/scripts/worktree-finish.sh <name> pr
```

Use when: work needs review before merging.

### Option 3: keep

Removes worktree directory, keeps branch for later.

```bash
bash plugins/claude-core/scripts/worktree-finish.sh <name> keep
```

Resume later: `git worktree add .worktrees/<name> <branch>`

### Option 4: discard

Removes worktree and deletes branch. **Irreversible.**

```bash
bash plugins/claude-core/scripts/worktree-finish.sh <name> discard
```

Use when: experiment failed, work not needed.

---

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `branch already checked out` | Branch in use elsewhere | Choose different name |
| `path already exists` | Stale directory | Remove it or use different name |
| `gh: command not found` | GitHub CLI missing | Install `gh` or use `keep` + manual PR |
| Dirty baseline after setup | Setup side effects | Inspect, add to .gitignore if appropriate |
| `worktree remove` fails | Uncommitted changes | Use `--force` or commit/stash first |

---

## Listing and Pruning

```bash
git worktree list          # show all worktrees
git worktree prune         # clean up stale entries
```
