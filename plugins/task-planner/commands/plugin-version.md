---
name: plugin-version
command: "/plugin:version"
description: "(plugin) Manage plugin versions: bump version numbers, archive schemas, generate migrations, and view version status"
arguments:
  - name: plugin-name
    type: string
    required: true
    description: "Kebab-case name of the plugin (e.g., brand-guideline, seo-plugin)"
  - name: action
    type: string
    required: false
    description: "Action to perform: 'bump' followed by major|minor|patch. Omit for --status or --history."
  - name: level
    type: string
    required: false
    description: "Bump level: major, minor, or patch. Only used with the 'bump' action."
  - name: status
    type: boolean
    required: false
    default: false
    flag: "--status"
    description: "Show current version info, migration count, and project versions"
  - name: history
    type: boolean
    required: false
    default: false
    flag: "--history"
    description: "Show version history from MIGRATION-REGISTRY.yml and CHANGELOG.md"
---

# /plugin:version

Manages plugin versions: bumping version numbers, archiving schemas, generating migration definitions, and viewing version status. This is the counterpart to `/plugin:migrate` — this command creates the migration artifacts that `/plugin:migrate` consumes.

This command does NOT use the task-planner for wave execution — it runs a linear, sequential pipeline. Each step must complete before the next begins.

## Usage

```
/plugin:version brand-guideline bump minor
/plugin:version seo-plugin bump major
/plugin:version brand-guideline bump patch
/plugin:version brand-guideline --status
/plugin:version seo-plugin --history
```

## Prerequisites

Before running, read:
1. `plugins/task-planner/resources/plugin-blueprint.md` — Section 12 (Plugin Versioning)
2. The three versioning skills:
   - `plugins/task-planner/skills/version-meta-stamper/SKILL.md`
   - `plugins/task-planner/skills/version-compatibility-checker/SKILL.md`
   - `plugins/task-planner/skills/migration-guide-generator/SKILL.md`

## Execution Steps

### Step 1: Validate Plugin

1. Verify the plugin directory exists at `plugins/[plugin-name]/`.
   If not:
   ```
   Plugin not found: plugins/[plugin-name]/
   Available plugins: [list directories in plugins/ that contain .claude-plugin/plugin.json]
   ```
   Exit.

2. Read `plugins/[plugin-name]/.claude-plugin/plugin.json` to get the current version.
   If the `version` field is missing:
   ```
   plugin.json is missing a "version" field.
   Add "version": "1.0.0" to plugins/[plugin-name]/.claude-plugin/plugin.json first.
   ```
   Exit.

3. Parse the version as semver: `[major].[minor].[patch]`.

4. Determine the mode based on arguments:
   - If `--status` → go to Step 2 (Status Mode)
   - If `--history` → go to Step 3 (History Mode)
   - If `bump [level]` → go to Step 4 (Bump Mode)
   - If none specified:
     ```
     Usage: /plugin:version [plugin-name] bump [major|minor|patch]
            /plugin:version [plugin-name] --status
            /plugin:version [plugin-name] --history
     ```
     Exit.

### Step 2: Status Mode (--status)

Display a comprehensive version overview for the plugin.

#### 2a: Plugin Version

Read `plugins/[plugin-name]/.claude-plugin/plugin.json`:
```
Plugin: [plugin-name]
Version: v[version]
```

#### 2b: Migration Count

Read `plugins/[plugin-name]/migrations/MIGRATION-REGISTRY.yml`:
- If the file exists: count entries in the `migrations` array
- If the file does not exist: `0 migrations (no registry)`

#### 2c: Archived Schemas

List files in `plugins/[plugin-name]/resources/schemas/archive/`:
- If directory exists: list all `.yml` files
- If directory does not exist: `No archived schemas`

#### 2d: Known Projects

Scan the plugin's data directories for projects and read their versions:

| Plugin | Data directory |
|--------|---------------|
| `brand-guideline` | `.ai/brands/` |
| `seo-plugin` | `.ai/seo/` |
| Other plugins | `.ai/[domain]/` where `[domain]` is derived from the plugin name (strip `-plugin` suffix if present) |

For each subdirectory (project) found:
1. Find the main data file (same logic as `/plugin:migrate` Step 1.2)
2. Read `_meta.plugin_version` from the data file
3. Compare to current plugin version using the version-compatibility-checker logic:
   - Exact match → `✓`
   - Patch mismatch → `✓` (compatible)
   - Minor mismatch → `⚠ needs migration (optional)`
   - Major mismatch → `✗ needs migration (required)`
   - No `_meta` → `⚠ legacy (no version metadata)`

#### 2e: Display

```
[plugin-name] v[version]
  Migrations: [N] registered
  Schemas:    [N] archived ([list versions])
  Projects:
    [project-1]  v[version] ✓
    [project-2]  v[version] ⚠ needs migration (optional)
    [project-3]  v[version] ✗ needs migration (required)
    [project-4]  (no version metadata) ⚠ legacy

  No projects found.  ← if data directory is empty or doesn't exist
```

Exit after displaying status.

### Step 3: History Mode (--history)

Display the version history as a formatted changelog.

#### 3a: Read Sources

Read both:
1. `plugins/[plugin-name]/migrations/MIGRATION-REGISTRY.yml` — for structured migration data
2. `plugins/[plugin-name]/CHANGELOG.md` — for human-readable descriptions

#### 3b: Build Timeline

If MIGRATION-REGISTRY.yml exists, build entries from the `migrations` array (newest first):

```
Version History: [plugin-name]

  v[to] ([type]) — [description]
    Generated: [generated_at]
    Changes: [added] added, [modified] modified, [removed] removed, [renamed] renamed
    Auto-safe: [yes|no]
    Guide: migrations/[guide filename]

  v[to] ([type]) — [description]
    ...

  v1.0.0 — Initial release
```

If MIGRATION-REGISTRY.yml does not exist but CHANGELOG.md does, display the CHANGELOG content directly.

If neither file exists:
```
No version history found for [plugin-name].
Current version: v[version] (from plugin.json)
```

Exit after displaying history.

### Step 4: Bump Mode

#### 4a: Calculate New Version

Parse the current version `[major].[minor].[patch]` and apply the bump:

| Level | Calculation | Example |
|-------|------------|---------|
| `patch` | Increment patch | 1.0.0 → 1.0.1 |
| `minor` | Increment minor, reset patch | 1.0.0 → 1.1.0 |
| `major` | Increment major, reset minor and patch | 1.2.3 → 2.0.0 |

If `level` is not one of `major`, `minor`, `patch`:
```
Invalid bump level: "[level]"
Valid levels: major, minor, patch
```
Exit.

#### 4b: Confirm Bump

Display the version change and ask for confirmation:

**For patch:**
```
Bumping [plugin-name]: v[current] → v[new] (patch)
  Patch bumps are for bugfixes with no schema changes.
  No migration will be generated.
  Proceed? [Y/n]
```

**For minor:**
```
Bumping [plugin-name]: v[current] → v[new] (minor)
  Minor bumps add new fields (backwards compatible).
  A migration will be generated for existing projects.
  Proceed? [Y/n]
```

**For major:**
```
Bumping [plugin-name]: v[current] → v[new] (major)
  Major bumps contain breaking changes (field removals, renames, type changes).
  A migration will be generated. Existing projects MUST migrate before using the new version.
  Proceed? [Y/n]
```

If the user declines, exit without changes.

#### 4c: Archive Current Schema

**This step is mandatory for minor and major bumps. Skip for patch bumps.**

1. Find the plugin's current YAML schema template:
   - Look in `plugins/[plugin-name]/resources/templates/` for the main `*-schema.yml` file
   - `brand-guideline` → `brand-reference-schema.yml`
   - `seo-plugin` → `seo-strategy-schema.yml`
   - Other plugins → the largest `*-schema.yml` file in the templates directory

2. If the schema file does not exist:
   ```
   No schema template found in plugins/[plugin-name]/resources/templates/.
   Cannot archive schema without a schema file.
   Create the schema first, then run this command again.
   ```
   Exit.

3. Create the archive directory if it doesn't exist:
   `plugins/[plugin-name]/resources/schemas/archive/`

4. Copy the current schema to:
   `plugins/[plugin-name]/resources/schemas/archive/v[current].yml`

5. If the archive file already exists:
   ```
   Schema archive already exists: v[current].yml
   This version has already been archived. Overwrite? [y/N]
   ```
   If the user declines, exit.

6. Report:
   ```
   Schema archived: plugins/[plugin-name]/resources/schemas/archive/v[current].yml
   ```

#### 4d: Update plugin.json

Update the `version` field in `plugins/[plugin-name]/.claude-plugin/plugin.json` to the new version.

Report:
```
Updated plugin.json: v[current] → v[new]
```

#### 4e: Schema Update Check (minor/major only)

**Skip this step for patch bumps.**

Ask the user whether the YAML schema has already been updated for the new version:

```
Has the YAML schema been updated for v[new]?
  Schema file: plugins/[plugin-name]/resources/templates/[schema-file]

  The migration generator needs to diff the old schema (just archived)
  against the new schema to produce migration artifacts.

  1. Yes — generate migration now
  2. No — I'll update the schema first, then run this command again
```

**If "Yes":** Proceed to Step 4f.

**If "No":**
```
Schema not yet updated for v[new].
  plugin.json has been updated to v[new].
  Schema archived at: plugins/[plugin-name]/resources/schemas/archive/v[current].yml

  Next steps:
    1. Update the schema at plugins/[plugin-name]/resources/templates/[schema-file]
    2. Run /plugin:version [plugin-name] bump [level] again to generate migration artifacts
       (The command will detect that plugin.json is already at v[new] and skip to migration generation.)
```

Wait — this would cause a problem because running bump again would try to bump v[new] further. Instead, handle re-entry:

**Re-entry detection:** When starting Step 4, check if the archived schema at `v[current].yml` already exists AND no migration artifacts exist for `v[current] → v[new]`. If so, skip Steps 4a-4d and go directly to Step 4e.

Revised "No" response:
```
Schema not yet updated for v[new].
  plugin.json has been updated to v[new].
  Schema archived at: plugins/[plugin-name]/resources/schemas/archive/v[previous].yml

  Next steps:
    1. Update the schema at plugins/[plugin-name]/resources/templates/[schema-file]
    2. Run /plugin:version [plugin-name] bump [level] again
       (It will detect the archived schema and skip to migration generation.)
```
Exit.

#### 4f: Generate Migration Artifacts (minor/major only)

**Skip this step for patch bumps.**

Call the migration-guide-generator skill to diff the old and new schemas and produce migration artifacts:

1. Read `plugins/task-planner/skills/migration-guide-generator/SKILL.md`
2. Invoke it with:
   - **Plugin name:** `[plugin-name]`
   - **Old version:** `[current]` (the version before the bump)
   - **New version:** `[new]` (the new version)
   - **Old schema path:** `plugins/[plugin-name]/resources/schemas/archive/v[current].yml`
   - **New schema path:** `plugins/[plugin-name]/resources/templates/[schema-file]`

3. The migration-guide-generator produces three files:
   - `plugins/[plugin-name]/migrations/v[current]-to-v[new].md` — migration guide
   - `plugins/[plugin-name]/migrations/scripts/v[current]-to-v[new].yml` — transform script
   - `plugins/[plugin-name]/migrations/MIGRATION-REGISTRY.yml` — updated registry

4. Verify all three files were created:
   ```
   Migration artifacts generated:
     Guide:    plugins/[plugin-name]/migrations/v[current]-to-v[new].md
     Script:   plugins/[plugin-name]/migrations/scripts/v[current]-to-v[new].yml
     Registry: plugins/[plugin-name]/migrations/MIGRATION-REGISTRY.yml (updated)
   ```

   If any file is missing:
   ```
   Migration generation incomplete. Missing:
     - [list missing files]

   Review the migration-guide-generator output for errors.
   ```
   Do not proceed to CHANGELOG update — the user must fix the issue first.

#### 4g: Update CHANGELOG.md

Read or create `plugins/[plugin-name]/CHANGELOG.md`.

**If the file does not exist**, create it with the header:

```markdown
# Changelog — [plugin-name]

All notable changes to this plugin are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).
```

**Prepend** the new entry after the header (newest entries at the top):

**For patch bumps:**
Ask the user for a one-line description:
```
What was fixed in this patch? (one line)
```

Then add:
```markdown
## v[new] — [YYYY-MM-DD]

### Fixed
- [user's description]
```

**For minor bumps (migration was generated):**
Read the summary from the migration guide (`v[current]-to-v[new].md`) and add:

```markdown
## v[new] — [YYYY-MM-DD]

### Added
- [list of added fields from migration guide]

### Changed
- [list of modified fields from migration guide, if any]

Migration: `migrations/v[current]-to-v[new].md` | Auto-safe: [yes|no]
```

**For major bumps (migration was generated):**
Read the summary and breaking changes from the migration guide and add:

```markdown
## v[new] — [YYYY-MM-DD]

### Breaking Changes
- [list of breaking changes from migration guide]

### Added
- [list of added fields, if any]

### Changed
- [list of modified fields, if any]

### Removed
- [list of removed fields, if any]

Migration: `migrations/v[current]-to-v[new].md` | Auto-safe: no
```

Report:
```
CHANGELOG.md updated with v[new] entry.
```

### Step 5: Report Results

#### For bump mode:

**Patch bump:**
```
Version bump complete: [plugin-name]
  v[current] → v[new] (patch)
  Updated: plugin.json, CHANGELOG.md
  No migration generated (patch bumps have no schema changes).

  Suggested commit message:
    chore([plugin-name]): bump to v[new] — [user's description]
```

**Minor/major bump:**
```
Version bump complete: [plugin-name]
  v[current] → v[new] ([level])
  Updated: plugin.json, CHANGELOG.md
  Archived: resources/schemas/archive/v[current].yml
  Migration: migrations/v[current]-to-v[new].md
  Transform: migrations/scripts/v[current]-to-v[new].yml
  Registry: migrations/MIGRATION-REGISTRY.yml

  To migrate existing projects:
    /plugin:migrate [plugin-name] --project [project-name]

  Suggested commit message:
    chore([plugin-name]): bump to v[new] — [migration summary]
```

**Minor/major bump (schema not yet updated):**
```
Partial version bump: [plugin-name]
  v[current] → v[new] ([level])
  Updated: plugin.json
  Archived: resources/schemas/archive/v[current].yml

  Migration artifacts NOT generated — schema not yet updated.
  Update the schema, then re-run this command.
```

## Output

Depending on the mode and bump level:

| Mode | Files Created/Updated |
|------|----------------------|
| `--status` | None (read-only) |
| `--history` | None (read-only) |
| `bump patch` | `plugin.json`, `CHANGELOG.md` |
| `bump minor` | `plugin.json`, `CHANGELOG.md`, `schemas/archive/v[old].yml`, migration guide, transform script, `MIGRATION-REGISTRY.yml` |
| `bump major` | Same as minor |

## Checkpoint

```yaml
type: data_validation
required_checks:
  - "plugin.json version updated correctly (semver increment)"
  - "Old schema archived before any changes (minor/major only)"
  - "If minor/major: migration-guide-generator produced all three files"
  - "CHANGELOG.md updated with new entry"
  - "MIGRATION-REGISTRY.yml updated (if migration generated)"
on_fail: "Verify plugin.json version, check archived schema, re-run migration generator"
on_pass: "Report success to user"
```

## Edge Cases

| Situation | Behavior |
|-----------|----------|
| Plugin directory not found | Error: list available plugins |
| plugin.json missing version field | Error: tell user to add version field |
| Schema template not found (minor/major) | Error: cannot archive or diff without schema |
| Archive file already exists for current version | Ask user whether to overwrite |
| Schema not yet updated for new version | Partial bump: update plugin.json and archive, skip migration generation, instruct user to update schema and re-run |
| Re-entry after partial bump | Detect archived schema exists + no migration artifacts → skip to migration generation |
| MIGRATION-REGISTRY.yml has duplicate entry | Handled by migration-guide-generator (asks user to overwrite) |
| CHANGELOG.md does not exist | Create with header, then add entry |
| --status with no projects | Show "No projects found" |
| --status with no migration registry | Show "0 migrations (no registry)" |
| --history with no registry or changelog | Show "No version history found" |
| Both --status and --history provided | --status takes precedence |
| bump with invalid level | Error: list valid levels (major, minor, patch) |
| bump with no level specified | Error: "Missing bump level. Usage: /plugin:version [plugin] bump [major\|minor\|patch]" |

## Integration Points

### What this command reads

- `plugins/[plugin-name]/.claude-plugin/plugin.json` — current plugin version
- `plugins/[plugin-name]/resources/templates/*-schema.yml` — current schema (to archive and diff)
- `plugins/[plugin-name]/resources/schemas/archive/` — previously archived schemas
- `plugins/[plugin-name]/migrations/MIGRATION-REGISTRY.yml` — migration index
- `plugins/[plugin-name]/CHANGELOG.md` — version history
- `~/.claude/[domain]/` — project data directories (for --status)

### What this command writes

- `plugins/[plugin-name]/.claude-plugin/plugin.json` — updated version
- `plugins/[plugin-name]/resources/schemas/archive/v[version].yml` — archived schema
- `plugins/[plugin-name]/CHANGELOG.md` — new changelog entry
- Migration artifacts (via migration-guide-generator):
  - `plugins/[plugin-name]/migrations/v[old]-to-v[new].md`
  - `plugins/[plugin-name]/migrations/scripts/v[old]-to-v[new].yml`
  - `plugins/[plugin-name]/migrations/MIGRATION-REGISTRY.yml`

### Related skills

- **migration-guide-generator** — called to diff schemas and produce migration artifacts
- **version-meta-stamper** — writes `_meta` blocks (not called here, but version-stamped files will reflect the new version on next generation)
- **version-compatibility-checker** — uses the version set here to check project data compatibility

### Related commands

- **/plugin:migrate** — applies the migration artifacts this command generates to project data files
- **/plugin:version --status** — shows which projects need migration after a version bump

## Recovery

If interrupted during a version bump:
1. Check state.yml for current phase (bump_version, update_schemas, update_changelog)
2. If plugin.json version was updated but schemas weren't: continue from schema update
3. If schemas updated but changelog wasn't: continue from changelog update
4. Run verification to confirm all version stamps are consistent
