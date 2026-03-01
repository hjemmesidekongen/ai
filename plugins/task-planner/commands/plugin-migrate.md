---
name: plugin-migrate
command: "/plugin:migrate"
description: "Migrate a project's data files from an older plugin version to the current version"
arguments:
  - name: plugin-name
    type: string
    required: true
    description: "Kebab-case name of the plugin (e.g., brand-guideline, seo-plugin)"
  - name: project
    type: string
    required: true
    flag: "--project"
    description: "Name of the project to migrate"
  - name: dry-run
    type: boolean
    required: false
    default: false
    flag: "--dry-run"
    description: "Show what would change without applying any modifications"
  - name: rollback
    type: boolean
    required: false
    default: false
    flag: "--rollback"
    description: "Revert the most recent migration from backup"
  - name: force
    type: boolean
    required: false
    default: false
    flag: "--force"
    description: "Skip confirmation prompts for auto_safe migrations"
---

# /plugin:migrate

Migrates a project's data files from an older plugin version to the current version. Reads the migration chain from MIGRATION-REGISTRY.yml, backs up the project, applies each transform script in order, and runs verification afterward.

This command does NOT use the task-planner for wave execution — it runs a linear, sequential migration pipeline. Each step in the chain must complete before the next begins.

## Usage

```
/plugin:migrate brand-guideline --project acme-corp
/plugin:migrate seo-plugin --project my-site --dry-run
/plugin:migrate brand-guideline --project acme-corp --force
/plugin:migrate brand-guideline --project acme-corp --rollback
```

## Prerequisites

Before running, read:
1. `plugins/task-planner/resources/plugin-blueprint.md` — Section 12 (Plugin Versioning)
2. The three versioning skills:
   - `plugins/task-planner/skills/version-meta-stamper/SKILL.md`
   - `plugins/task-planner/skills/version-compatibility-checker/SKILL.md`
   - `plugins/task-planner/skills/migration-guide-generator/SKILL.md`

## Execution Steps

### Step 1: Identify the Project

Resolve the project's data directory based on the plugin name:

| Plugin | Data directory |
|--------|---------------|
| `brand-guideline` | `~/.claude/brands/[project-name]/` |
| `seo-plugin` | `~/.claude/seo/[project-name]/` |
| Other plugins | `~/.claude/[domain]/[project-name]/` where `[domain]` is derived from the plugin name (strip `-plugin` suffix if present) |

1. Verify the directory exists. If not:
   ```
   Project directory not found: [resolved-path]
   Check that the project name is correct.
   Available projects: [list directories in the parent]
   ```

2. Find the main data file. Each plugin has a primary YAML output file:
   - `brand-guideline` → `brand-reference.yml`
   - `seo-plugin` → `seo-strategy.yml`
   - Other plugins → look for the largest `.yml` file in the directory, or check the plugin's compile-and-export skill for the output filename

3. Read the `_meta` block from the data file to get `file_version`:
   - If `_meta` exists → `file_version = _meta.plugin_version`
   - If `_meta` does not exist → `file_version = "0.0.0"` (pre-versioning legacy file)

4. Read `plugins/[plugin-name]/.claude-plugin/plugin.json` to get `current_plugin_version`.

5. If `file_version == current_plugin_version`:
   ```
   Project [project-name] is already at v[version]. No migration needed.
   ```
   Exit.

### Step 2: Determine Migration Chain

1. Read `plugins/[plugin-name]/migrations/MIGRATION-REGISTRY.yml`.

   If the file does not exist:
   ```
   No migration registry found at plugins/[plugin-name]/migrations/MIGRATION-REGISTRY.yml.
   This plugin has no registered migrations. Cannot proceed.
   ```
   Exit.

2. Build the migration chain by walking from `file_version` to `current_plugin_version`:
   - Start at `file_version`
   - Find the entry where `from` matches the current position
   - Move to the `to` version
   - Repeat until reaching `current_plugin_version` or no more entries found

3. If the chain is incomplete (cannot reach `current_plugin_version`):
   ```
   Cannot find a complete migration path from v[file_version] to v[current_version].

   Available migrations:
     [list all entries in MIGRATION-REGISTRY.yml]

   The chain breaks at v[last_reachable_version]. No migration exists
   from v[last_reachable_version] to the next version.

   Use /plugin:version to generate the missing migration.
   ```
   Exit.

4. Display the migration plan:
   ```
   Migration plan for [project-name] ([plugin-name]):
     Current: v[file_version]
     Target:  v[current_plugin_version]
     Steps:   [N]

     v[file_version] → v[step1_to] ([minor|major], auto_safe: [yes|no])
     v[step1_to] → v[step2_to] ([minor|major], auto_safe: [yes|no])
     ...
   ```

### Step 3: Handle --rollback

If `--rollback` is set, skip Steps 4-6 and perform rollback instead:

1. Find the backup directory: `[project-dir]/.backup/`

2. If the directory does not exist or is empty:
   ```
   No backups found for project [project-name].
   Cannot rollback without a backup.
   ```
   Exit.

3. List available backups (sorted by timestamp, newest first):
   ```
   Available backups for [project-name]:
     1. [timestamp] (most recent)
     2. [timestamp]
     ...
   ```

4. Ask the user which backup to restore (default: most recent):
   ```
   Restore from backup at [timestamp]?
   This will overwrite current files in [project-dir].
   The current files will NOT be backed up before overwrite.
   Proceed? [y/N]
   ```

5. If confirmed:
   - Copy all files from `[project-dir]/.backup/[timestamp]/` back to `[project-dir]/`
   - Do NOT delete the backup directory (keep it for safety)
   - Report:
     ```
     Rollback complete. Project [project-name] restored to backup from [timestamp].
     The backup has been preserved at [backup-path].
     ```

6. Exit after rollback — do not continue to Steps 4-6.

### Step 4: Backup

**This step is mandatory. Never skip it. Even with `--dry-run`, create the backup.**

1. Create the backup directory: `[project-dir]/.backup/[ISO-8601-timestamp]/`
   - Timestamp format: `2026-03-01T14-30-00Z` (colons replaced with hyphens for filesystem safety)

2. Copy the entire project directory contents (excluding `.backup/` itself) into the backup directory.

3. Verify the backup:
   - Count files in backup vs. original
   - If counts don't match, fail:
     ```
     Backup verification failed. Expected [N] files, found [M].
     Aborting migration to protect your data.
     ```

4. Report:
   ```
   Backup created: [backup-path]
   [N] files backed up.
   ```

### Step 5: Apply Migration Chain

For each migration in the chain (in order):

#### 5a: Load Migration Artifacts

Read the migration guide and transform script:
- Guide: `plugins/[plugin-name]/migrations/v[from]-to-v[to].md`
- Script: `plugins/[plugin-name]/migrations/scripts/v[from]-to-v[to].yml`

If either file is missing:
```
Migration artifacts not found for v[from] → v[to]:
  Missing: [list missing files]

Use /plugin:version to regenerate migration artifacts.
```
Exit (do not apply partial migrations).

#### 5b: Show Migration Summary

Read the migration registry entry for this step and display:
```
Applying migration: v[from] → v[to]
  Type: [minor|major]
  Auto-safe: [yes|no]
  Changes:
    - [N] fields added
    - [N] fields modified
    - [N] fields renamed
    - [N] fields removed
```

#### 5c: Handle --dry-run

If `--dry-run` is set:
- Read the transform script and describe each transform that would be applied:
  ```
  [DRY RUN] Would apply these transforms:

  1. ADD "technical.structured_data" (object, default: {})
  2. RENAME "content.seo" → "content_rules.seo_guidelines"
  3. TRANSFORM "keywords.primary[].volume" (string → number, fallback: 0)
  4. REMOVE "content.seo_tips" (strategy: comment)
  5. UPDATE _meta (plugin_version → "[to]")
  ```
- Do NOT modify any files
- Continue to the next migration in the chain (show all steps in dry-run mode)

#### 5d: Confirm Before Applying

**If auto_safe AND --force:** Apply without asking. Show a one-line message:
```
Auto-applying v[from] → v[to] (auto-safe, --force)
```

**If auto_safe AND NOT --force:**
```
This migration is auto-safe (only additive changes).
Apply v[from] → v[to]? [Y/n]
```
If the user declines, abort the entire migration chain (do not leave data in a partially migrated state).

**If NOT auto_safe:**
Show each breaking change from the transform script and ask for confirmation:

For `remove` actions:
```
Field "[path]" will be removed (commented out).
  Current value: [show the value from the data file]
  This field is no longer used by the plugin.
  Proceed? [Y/n]
```

For `rename` actions:
```
Field "[old_path]" will be renamed to "[new_path]".
  Current value: [show the value]
  The value will be moved to the new location.
  Proceed? [Y/n]
```

For `transform` actions:
```
Field "[path]" will be transformed from [old_type] to [new_type].
  Current value: [show the value]
  Transform: [description]
  Fallback value: [fallback]
  Option A: Apply transform (recommended)
  Option B: Set to fallback value ([fallback])
  Option C: Skip this field (keep as-is — may cause issues)
```

Record the user's decision for each breaking change in the migration log.

#### 5e: Apply Transforms

Read the transform script YAML and apply each transform to the data file:

**`add` action:**
- Navigate to the parent path in the YAML
- Insert the new field with its default value
- If the parent path does not exist, create it

**`rename` action:**
- Read the value at `old_path`
- Write it to `new_path` (creating parent paths as needed)
- Remove the field at `old_path`
- If `old_path` does not exist, skip (warn but don't fail)

**`transform` action:**
- Read the current value at `path`
- Apply the named transform:
  - `parse_integer` — parse string to integer, use fallback on failure
  - `parse_float` — parse string to float, use fallback on failure
  - `to_string` — convert to string representation
  - `to_array` — wrap scalar value in a single-element array
  - `from_array` — take first element of array as scalar
  - Other transforms — log a warning and use the fallback value
- Write the transformed value back to `path`

**`remove` action:**
- If `strategy` is `"comment"`: prefix the field's YAML lines with `# REMOVED: `
- If `strategy` is `"delete"`: remove the field entirely
- Default strategy is `"comment"` if not specified

**`update_meta` action:**
- Update the `_meta` block with the values in `set`
- Replace `__NOW__` with current ISO 8601 timestamp
- Replace `__EMPTY__` with empty string
- Replace `__NULL__` with null

**Array path handling (`[]`):**
When a path contains `[]` (e.g., `keywords.primary[].volume`), apply the transform to every item in the array. Loop through all elements and apply the action to each one.

#### 5f: Version Stamp

After applying all transforms for this migration step, call the version-meta-stamper skill to update the `_meta` block:
- Read `plugins/task-planner/skills/version-meta-stamper/SKILL.md`
- Apply it to the data file with the `to` version as the current version

This ensures `_meta.plugin_version` reflects the version after this migration step (not the final target — that happens in the last step of the chain).

#### 5g: Verify Step

After each migration step, verify:
1. The data file is still valid YAML (parseable without errors)
2. `_meta.plugin_version` matches the `to` version
3. All `add` transforms resulted in the field existing with the correct default
4. All `rename` transforms moved the value (old path gone, new path has value)

If any verification fails:
```
Migration step v[from] → v[to] failed verification:
  - [list failures]

The data file may be in an inconsistent state.
Restore from backup: /plugin:migrate [plugin] --project [project] --rollback
```
Stop the chain — do not apply subsequent migrations.

### Step 6: Post-Migration

After all migrations in the chain have been applied:

#### 6a: Write Migration Log

Create or update `[project-dir]/migration-log.yml`:

```yaml
# Migration log for [project-name]
# Generated by /plugin:migrate

last_migration:
  plugin: "[plugin-name]"
  from: "[original file_version]"
  to: "[current_plugin_version]"
  applied_at: "[ISO 8601 timestamp]"
  backup_path: "[backup-path]"

migrations_applied:
  - from: "[step1_from]"
    to: "[step1_to]"
    applied_at: "[ISO 8601 timestamp]"
    type: "[minor|major]"
    auto_safe: true
    changes_applied:
      - "ADD technical.structured_data (object, default: {})"
      - "UPDATE _meta (plugin_version → [step1_to])"

  - from: "[step2_from]"
    to: "[step2_to]"
    applied_at: "[ISO 8601 timestamp]"
    type: "[minor|major]"
    auto_safe: false
    changes_applied:
      - "RENAME content.seo → content_rules.seo_guidelines"
      - "TRANSFORM keywords.primary[].volume (string → number)"
      - "UPDATE _meta (plugin_version → [step2_to])"
    manual_decisions:
      - field: "keywords.primary[].volume"
        user_choice: "Apply transform"
      - field: "content.seo_tips"
        user_choice: "Remove (commented out)"

backup_path: "[backup-path]"
verification_result: "passed"
```

#### 6b: Run Verification

Run the version-compatibility-checker to confirm the migrated data is now compatible:
- Read `plugins/task-planner/skills/version-compatibility-checker/SKILL.md`
- Apply it to the data file
- Expected result: severity `ok` (exact match after migration)

If severity is NOT `ok`:
```
Warning: Post-migration compatibility check returned "[severity]".
  Message: [compatibility message]

The migration may be incomplete. Review the data file manually.
```

#### 6c: Report Results

```
Migration complete: [project-name] ([plugin-name])
  From: v[original_version]
  To:   v[current_version]
  Steps applied: [N]
  Backup: [backup-path]
  Log: [project-dir]/migration-log.yml
  Verification: [passed | passed_with_warnings | failed]
```

If `--dry-run` was set:
```
Dry run complete: [project-name] ([plugin-name])
  From: v[original_version]
  To:   v[current_version]
  Steps reviewed: [N]
  No files were modified.
  Run without --dry-run to apply the migration.
```

## Output

- Migrated data files with updated `_meta` blocks
- Backup directory: `[project-dir]/.backup/[timestamp]/`
- Migration log: `[project-dir]/migration-log.yml`

## Checkpoint

```yaml
type: data_validation + schema_validation
required_checks:
  - "Backup created before any changes"
  - "Every migration in chain applied in order"
  - "_meta block updated with correct version after each step"
  - "migration-log.yml written with complete record"
  - "Verification run after all migrations applied"
  - "--dry-run mode makes no file changes"
  - "--rollback restores from backup correctly"
on_fail: "Restore from backup, re-run migration with verbose logging"
on_pass: "Report success to user"
```

## Edge Cases

| Situation | Behavior |
|-----------|----------|
| Project already at current version | Exit early: "No migration needed." |
| No MIGRATION-REGISTRY.yml | Error: cannot migrate without registry |
| Incomplete migration chain | Error with list of available migrations and where the chain breaks |
| Data file has no `_meta` block | Treat as v0.0.0 (legacy), attempt migration from 0.0.0 |
| Migration step fails verification | Stop chain, report failure, suggest rollback |
| User declines a non-auto-safe change | Abort entire chain (don't leave partially migrated data) |
| --dry-run with --force | --dry-run takes precedence (show changes, don't apply) |
| --rollback with no backups | Error: no backups found |
| Backup directory already exists for this timestamp | Append a counter: `[timestamp]-2`, `[timestamp]-3` |
| Transform script references a path that doesn't exist in data | Warn and skip that transform (don't fail the whole migration) |
| Multiple data files in project directory | Only migrate the main data file (primary YAML output). Other files are auxiliary. |
| Plugin directory not found | Error: "Plugin [name] not found at plugins/[name]/" |

## Integration Points

### What this command reads

- `plugins/[plugin-name]/.claude-plugin/plugin.json` — current plugin version
- `plugins/[plugin-name]/migrations/MIGRATION-REGISTRY.yml` — migration chain index
- `plugins/[plugin-name]/migrations/v[from]-to-v[to].md` — migration guide (for display)
- `plugins/[plugin-name]/migrations/scripts/v[from]-to-v[to].yml` — transform definitions
- `[project-dir]/[main-data-file].yml` — the file being migrated

### What this command writes

- `[project-dir]/.backup/[timestamp]/` — full backup of project data
- `[project-dir]/[main-data-file].yml` — migrated data file (in-place update)
- `[project-dir]/migration-log.yml` — record of what was applied

### Related skills

- **version-meta-stamper** — called after each migration step to update `_meta`
- **version-compatibility-checker** — called after all migrations to verify compatibility
- **migration-guide-generator** — creates the migration artifacts this command consumes

### Related commands

- **/plugin:version** — bumps plugin versions and generates migration artifacts
- **/plugin:migrate --rollback** — reverts migration from backup
