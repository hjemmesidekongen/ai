# Auto-Doc Process

Automated documentation update procedure. Runs after doc-checkpoint identifies stale docs.

## Prerequisites

- doc-checkpoint has been run (or will be run inline as step 1)
- Task work is verified and complete
- Changes are committed or staged

## Step 1: Run doc-checkpoint (if not already done)

If no doc_checkpoint output is available, run doc-checkpoint first to get the staleness checklist. Use its output as the work order.

## Step 2: Scan filesystem for ground truth

### Component counts

```bash
# Skills per plugin
ls -d plugins/*/skills/*/SKILL.md 2>/dev/null | wc -l

# Commands per plugin
ls plugins/*/commands/*.md 2>/dev/null | wc -l

# Agents per plugin
ls plugins/*/agents/*.md 2>/dev/null | wc -l

# Hooks (count entries in plugin.json, not script files)
# Parse plugin.json for hook entries
```

### Component names

```bash
# Skill names (directory names)
ls -d plugins/kronen/skills/*/SKILL.md | sed 's|.*/skills/||;s|/SKILL.md||' | sort

# Agent names (file basenames)
ls plugins/kronen/agents/*.md | sed 's|.*/||;s|\.md||' | sort

# Command names (file basenames)
ls plugins/kronen/commands/*.md | sed 's|.*/||;s|\.md||' | sort
```

## Step 3: Update ecosystem.json

For each plugin with changes:

1. Read current ecosystem.json
2. Compare `skills` array against skill directories on disk
3. Compare `commands` array against command files on disk
4. Compare `agents` array against agent files on disk
5. Add any missing entries, remove any ghost entries
6. Preserve array ordering (alphabetical or existing convention)

**Safety check**: never remove an entry without confirming the file is actually gone from disk. A missing file could be an error, not an intentional deletion.

## Step 4: Update CLAUDE.md structure tree

### Count updates

Find the parenthetical count strings and update them:
- `(NN skills, NN commands, NN agents)` in "What This Is" section
- Same pattern in the structure tree header comment

### Tree entries

For each new component:
- Add a line in the appropriate section of the structure tree
- Follow existing format: `      skill-name/               # Brief description`
- Place alphabetically or at end of section

For each removed component:
- Remove the corresponding line from the structure tree

### Hook counts

If plugin.json hooks changed:
- Count PreToolUse, PostToolUse, PreCompact, SessionStart, Stop hook entries
- Update the hook count annotation in the structure tree

## Step 5: Update MEMORY.md (if applicable)

If MEMORY.md contains component counts:
- Update the count line to match filesystem reality
- Update roadmap stats if present

**Constraint**: MEMORY.md is ≤150 lines. Do not expand it. Only update existing entries.

## Step 6: Update roadmap.yml (if applicable)

If completed work corresponds to a roadmap item:
- Set `priority: done`
- Add `completed: "YYYY-MM-DD"` field
- Update the stats comment block at the bottom

## Step 7: Verify

After all updates, run these verification checks:

| Check | Command | Expected |
|-------|---------|----------|
| CLAUDE.md skill count | Count in file == count on disk | Match |
| ecosystem.json skills | Array length == skill dirs | Match |
| ecosystem.json commands | Array length == command files | Match |
| ecosystem.json agents | Array length == agent files | Match |
| No orphan components | Every dir has a registry entry | True |
| No ghost entries | Every entry has a file on disk | True |

If any check fails, fix it before reporting completion.

## Safety rules

1. **Never touch ~/CLAUDE.md** — that's the user's personal config, modified manually only
2. **Never delete content you didn't add** — if unsure, flag it instead of removing
3. **Never fabricate descriptions** — use directory name or existing description only
4. **Preserve existing formatting** — match indentation, comment style, structure
5. **One commit for all doc updates** — bundle all fixes into a single documentation commit
6. **Report what changed** — list every file modified and what was updated

## Output format

After completing updates, report:

```yaml
auto_doc:
  files_updated:
    - file: "CLAUDE.md"
      changes: ["skill count 32→33", "added auto-doc to structure tree"]
    - file: "plugins/kronen/.claude-plugin/ecosystem.json"
      changes: ["added auto-doc to skills array"]
  checks_passed: 6/6
  manual_attention: []  # anything that couldn't be auto-fixed
```
