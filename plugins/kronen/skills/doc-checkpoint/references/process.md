# Doc Checkpoint — Process

## 1. Input Gathering

Collect changed files from three sources:

```bash
# Staged changes
git diff --cached --name-only

# Unstaged changes
git diff --name-only

# Last commit (in case work was just committed)
git diff --name-only HEAD~1..HEAD
```

Merge all three lists, deduplicate, and categorize each file:

| Category | Pattern |
|----------|---------|
| skill | `plugins/*/skills/*/` |
| command | `plugins/*/commands/` |
| hook/script | `plugins/*/scripts/` |
| agent | `plugins/*/agents/` |
| plugin-config | `plugins/*/.claude-plugin/` |
| resource | `plugins/*/resources/` |
| project-state | `.ai/` |
| documentation | `*CLAUDE.md`, `*MEMORY.md`, `*.yml` in `.ai/` |
| code | everything else |

## 2. Routing Table

For each category of changed file, determine required documentation updates:

| Change category | Documentation target | What to write | Priority |
|---|---|---|---|
| New skill directory | Project CLAUDE.md | Add to structure tree, update skill count | required |
| Removed skill directory | Project CLAUDE.md | Remove from tree, update skill count | required |
| New command file | Project CLAUDE.md | Add to commands table | required |
| New hook script | Project CLAUDE.md, ARCHITECTURE.md | Add to hook inventory | required |
| New agent | Project CLAUDE.md | Add to agent list | required |
| ecosystem.json changed | Verify counts match disk | Cross-check arrays vs directories | required |
| Plugin.json hooks changed | ARCHITECTURE.md | Update hook inventory table | recommended |
| New behavioral rule in ~/CLAUDE.md | ~/CLAUDE.md | Check for contradictions | recommended |
| Roadmap item delivered | .ai/roadmap.yml | Mark status: done, add date | recommended |
| README feature change | Plugin README.md | Update feature list | recommended |
| Resource file changed | None (internal) | Skip unless schema change | optional |
| Code-only change | None | Skip | optional |

## 3. Evaluation Logic

For each documentation target, check for staleness:

### Project CLAUDE.md
- Count skill directories on disk: `ls -d plugins/*/skills/*/SKILL.md | wc -l`
- Compare against count stated in CLAUDE.md
- Check structure tree includes all current directories
- Flag missing or extra entries

### ecosystem.json
- For each plugin, compare `skills` array against `skills/*/SKILL.md` on disk
- Compare `commands` array against `commands/*.md` on disk
- Flag unregistered components (exist on disk but not in registry)
- Flag ghost entries (in registry but not on disk)

### MEMORY.md
- Check if skill/command counts mentioned match reality
- Check if plugin names and descriptions are current
- Flag entries referencing deleted or renamed components

### .ai/roadmap.yml
- If any completed work maps to a roadmap item, check if status is updated
- Flag items still marked "now" or "next" that appear to be delivered

### ~/CLAUDE.md
- If new rules were added, scan for contradictions with existing rules
- Check line count stays under 200

## 4. Cross-Checks

Run these structural checks regardless of what changed:

| Check | How | Priority |
|---|---|---|
| Ecosystem count match | `skills` array length == skill directories on disk | required |
| No orphan skills | Every `skills/*/SKILL.md` has an ecosystem.json entry | required |
| No ghost entries | Every ecosystem.json entry has a directory on disk | required |
| CLAUDE.md line count | `wc -l ~/CLAUDE.md` < 200 | recommended |
| MEMORY.md line count | `wc -l MEMORY.md` < 150 | recommended |

## 5. Output Format

Produce a YAML checklist:

```yaml
doc_checkpoint:
  timestamp: "2026-03-09T14:30:00Z"
  files_analyzed: 12
  categories_found: [skill, command, plugin-config]
  updates:
    - target: "CLAUDE.md (project)"
      action: "Update skill count from 15 to 16"
      detail: "New skill doc-checkpoint added but count not updated"
      priority: required
    - target: "ecosystem.json"
      action: "Verify doc-checkpoint registered"
      detail: "Skill directory exists, check registry entry"
      priority: required
    - target: ".ai/roadmap.yml"
      action: "Mark RL-019 as done"
      detail: "Documentation governance system delivered"
      priority: recommended
  summary:
    required: 2
    recommended: 1
    optional: 0
```

## 6. Priority Levels

| Priority | Meaning | Action |
|---|---|---|
| required | Structural inconsistency — counts wrong, components unregistered, tree outdated | Must fix before reporting task complete |
| recommended | Staleness — roadmap not updated, README outdated, description drift | Should fix, can defer if trivial |
| optional | Nice-to-have — comment improvements, formatting consistency | Skip unless convenient |

## 7. Edge Cases

**Clean working tree (no changes):**
Report "No changes detected" and exit. Don't fabricate a checklist.

**Already-committed changes:**
Use `git diff HEAD~1..HEAD` to analyze the last commit. Useful when running
doc-checkpoint after committing.

**Multiple plugins changed:**
Run checks for each plugin independently. A change in agency/ should check
agency's ecosystem.json, not kronen's.

**Rename operations:**
Flag both the old name (should be removed from docs) and the new name (should
be added). Common source of staleness.

**No infrastructure changes:**
If only code/resource files changed with no skill/command/hook additions,
output an empty checklist with a note: "No documentation updates needed."
