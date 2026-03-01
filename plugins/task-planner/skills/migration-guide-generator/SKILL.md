# Migration Guide Generator

Generates migration definition files when a plugin version is bumped. Compares old and new YAML schemas field by field, classifies the migration type, and produces three artifacts: a human-readable migration guide, a structured transform script, and an updated MIGRATION-REGISTRY.yml.

This is a **utility skill**. It is called by the `/plugin:version` command when bumping a plugin's minor or major version. It is not called directly by wave plans.

## Calling Convention

The `/plugin:version` command calls this skill after archiving the current schema and before updating CHANGELOG.md.

**How to call:**

```
After archiving the old schema, call the migration-guide-generator to
diff the old and new schemas and produce migration artifacts.
If the migration type is "major", require user confirmation before proceeding.
```

**Where commands reference this:** In their command definition, after the schema archive step. Example:

```markdown
### Step N: Generate Migration

After archiving the schema, call the migration-guide-generator skill
(packages/task-planner/skills/migration-guide-generator/SKILL.md) to
diff the old and new schemas and produce the migration guide, transform
script, and MIGRATION-REGISTRY.yml entry.
```

## Input

The calling command provides:

- **Plugin name** — the plugin being versioned (e.g., `seo-plugin`)
- **Old version** — the previous version number (e.g., `1.0.0`)
- **New version** — the new version number (e.g., `1.1.0` or `2.0.0`)
- **Old schema path** — path to the archived schema (e.g., `packages/seo-plugin/resources/schemas/archive/v1.0.0.yml`)
- **New schema path** — path to the current schema (e.g., `packages/seo-plugin/resources/templates/seo-strategy-schema.yml`)

## Process

### Step 1: Load and Parse Schemas

Read both YAML schema files and parse them into a comparable tree structure.

**Old schema:** Read from `packages/[plugin]/resources/schemas/archive/v[old].yml`

**New schema:** Read from the plugin's current schema template. The exact filename varies by plugin — look in `packages/[plugin]/resources/templates/` for the main `*-schema.yml` file.

If either file does not exist, fail with error:
```
Schema file not found: [path]
Cannot generate migration without both old and new schemas.
```

Build a flat map of every field path in each schema:

```yaml
# Example flat map for brand-reference schema
identity.brand_name: { type: string, required: true }
identity.tagline: { type: string, required: false }
audience.personas: { type: array, items: object }
audience.personas[].name: { type: string, required: true }
content_rules.tone: { type: enum, values: [formal, casual, mixed] }
```

Include for each field:
- **Path** — dot-separated with `[]` for array items (e.g., `keywords.primary[].term`)
- **Type** — string, number, boolean, array, object, enum
- **Required** — true/false
- **Constraints** — enum values, min/max, patterns, default values

### Step 2: Diff the Schemas

Compare the flat maps field by field. Classify every difference into one of five categories:

**ADDED** — field path exists in new schema but not old:
```yaml
- path: "technical.structured_data"
  category: added
  type: object
  default: null
  note: "New field — requires default value"
```

**REMOVED** — field path exists in old schema but not new:
```yaml
- path: "content.seo_tips"
  category: removed
  old_type: array
  note: "Removed field — may break downstream consumers"
```

**RENAMED** — field path removed in old AND a similar field added in new. Do NOT assume renames automatically. Instead, ask the user:

```
Field 'content.seo' no longer exists in the new schema.
A new field 'content_rules.seo_guidelines' was added.

Was 'content.seo' renamed to 'content_rules.seo_guidelines', or was it removed?
  1. Renamed (migrate data from old path to new path)
  2. Removed (data at old path is no longer needed)
```

If the user confirms a rename:
```yaml
- path: "content_rules.seo_guidelines"
  category: renamed
  old_path: "content.seo"
  note: "Renamed from content.seo"
```

**MODIFIED** — same field path exists in both but properties changed:
```yaml
- path: "keywords.primary[].volume"
  category: modified
  old_type: string
  new_type: number
  note: "Type changed from string to number — requires data transformation"
```

Track what specifically changed:
- Type changed (e.g., string → array)
- Required status changed (optional → required, or vice versa)
- Enum values changed (added, removed, or renamed values)
- Constraints changed (min/max, pattern, default)

**UNCHANGED** — same path, same properties. Skip these — no migration action needed.

### Step 3: Classify the Migration

Based on the diff results, classify the overall migration:

| Changes Found | Migration Type | auto_safe |
|---------------|---------------|-----------|
| Only additions | `minor` | `true` |
| Only additions + constraint relaxations (required → optional) | `minor` | `true` |
| Any removals | `major` | `false` |
| Any renames | `major` | `false` |
| Any type changes | `major` | `false` |
| Any constraint tightening (optional → required) | `major` | `false` |

**If `major`:** Warn the user before proceeding:
```
This migration contains breaking changes:
  - [N] fields removed
  - [N] fields renamed
  - [N] fields with type changes

Projects using the old schema will need manual review after migration.
Proceed with generating migration artifacts? (y/n)
```

Generate a one-paragraph summary describing what changed and why. Reference specific field paths.

### Step 4: Generate the Migration Guide

Create `packages/[plugin]/migrations/v[old]-to-v[new].md`:

```markdown
# Migration: [plugin] v[old] → v[new]

**Type:** [minor|major]
**Auto-safe:** [true|false]
**Generated:** [ISO 8601 timestamp]

## Summary

[One paragraph describing what changed and why. Reference the plugin's
purpose and how these changes improve the schema.]

## Breaking Changes

[List of changes that require manual attention. Empty section with "None"
for minor migrations.]

- **[field.path]** — [description of breaking change and impact]
- **[field.path]** — [description]

## New Fields

[List of added fields with their default values.]

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `[field.path]` | [type] | `[default]` | [what this field stores] |

## Renamed Fields

[List of renamed fields with old and new paths.]

| Old Path | New Path | Notes |
|----------|----------|-------|
| `[old.path]` | `[new.path]` | [context] |

## Modified Fields

[List of fields with changed types, constraints, or requirements.]

| Field | Change | Old | New | Action |
|-------|--------|-----|-----|--------|
| `[field.path]` | type | string | number | Transform existing values |
| `[field.path]` | required | false | true | Set default for missing values |

## Removed Fields

[List of removed fields with guidance on impact.]

| Field | Old Type | Impact | Action |
|-------|----------|--------|--------|
| `[field.path]` | [type] | [what breaks] | [what to do] |

## Migration Steps

### Automatic (applied by /plugin:migrate)

[Numbered list of transformations the migrate command will apply automatically.]

1. Add field `[X]` with default value `[Y]`
2. Rename field `[A]` to `[B]` (move value)
3. Transform `[field]` from [old type] to [new type]
4. Update `_meta.plugin_version` to `[new]`
5. Update `_meta.schema_version` to `[new]`
6. Set `_meta.migrated_from` to `[old]`

### Manual Review Required

[Numbered list of changes that cannot be safely automated.
Empty section with "None — all changes are auto-safe" for minor migrations.]

1. **[field.path]** — [what was removed/changed and why manual review is needed]
2. **[field.path]** — [guidance on verifying the transformation]

## Rollback

To revert this migration:

1. Restore from the backup created by `/plugin:migrate` (at `[project-dir]/backups/`)
2. Or run `/plugin:migrate [plugin] --project [project] --rollback`
3. Or restore the file from git: `git checkout HEAD~1 -- [file-path]`
```

### Step 5: Generate the Transform Script

Create `packages/[plugin]/migrations/scripts/v[old]-to-v[new].yml`:

Use a structured YAML format (not a shell script) so that `/plugin:migrate` can parse and apply transformations programmatically:

```yaml
# Migration transform: [plugin] v[old] → v[new]
# Generated: [ISO 8601 timestamp]
# Type: [minor|major]
# Auto-safe: [true|false]

from: "[old]"
to: "[new]"

transforms:
  # Added fields — set default values
  - action: add
    path: "technical.structured_data"
    type: object
    default: {}
    description: "Add new structured data section"

  # Renamed fields — move value from old path to new path
  - action: rename
    old_path: "content.seo"
    new_path: "content_rules.seo_guidelines"
    description: "Move SEO content rules to new location"

  # Modified fields — transform value
  - action: transform
    path: "keywords.primary[].volume"
    from_type: string
    to_type: number
    transform: "parse_integer"
    fallback: 0
    description: "Convert volume from string to number"

  # Removed fields — comment out (don't delete)
  - action: remove
    path: "content.seo_tips"
    strategy: "comment"
    description: "Deprecated — flagged for user review"

  # Meta update — always present
  - action: update_meta
    set:
      plugin_version: "[new]"
      schema_version: "[new]"
      migrated_from: "[old]"
      updated_at: "__NOW__"
```

**Transform types:**

| Action | What it does | Auto-safe |
|--------|-------------|-----------|
| `add` | Inserts a new field with a default value | Yes |
| `rename` | Moves value from old path to new path, removes old path | No — user should verify |
| `transform` | Changes a value's type or format | No — may lose precision |
| `remove` | Comments out the field (prefixes with `# REMOVED:`) | No — user must review |
| `update_meta` | Updates the `_meta` block with new version info | Yes |

**Special values in transforms:**
- `__NOW__` — replaced with current ISO 8601 timestamp at migration time
- `__EMPTY__` — empty string
- `__NULL__` — null/nil value

### Step 6: Update MIGRATION-REGISTRY.yml

Read or create `packages/[plugin]/migrations/MIGRATION-REGISTRY.yml`.

**If the file does not exist**, create it with the header:

```yaml
# Migration Registry for [plugin]
# Auto-generated by migration-guide-generator
# Do not edit manually — use /plugin:version to add entries

plugin: "[plugin]"
migrations: []
```

**Append** the new migration entry to the `migrations` array:

```yaml
migrations:
  - from: "[old]"
    to: "[new]"
    type: "[minor|major]"
    auto_safe: [true|false]
    guide: "v[old]-to-v[new].md"
    script: "scripts/v[old]-to-v[new].yml"
    generated_at: "[ISO 8601 timestamp]"
    description: "[one-line summary of changes]"
    changes:
      added: [N]
      modified: [N]
      removed: [N]
      renamed: [N]
```

**Validation after update:**
- No duplicate entries (same `from` → `to` pair)
- The `from` version of this entry should match the `to` version of the previous entry (chain continuity)
- If a duplicate exists, ask the user: "A migration from v[old] to v[new] already exists. Overwrite it?"

## Output

Three files are created or updated:

1. `packages/[plugin]/migrations/v[old]-to-v[new].md` — human-readable migration guide
2. `packages/[plugin]/migrations/scripts/v[old]-to-v[new].yml` — structured transform definition
3. `packages/[plugin]/migrations/MIGRATION-REGISTRY.yml` — updated migration index

## Checkpoint

```yaml
type: data_validation
required_checks:
  - "Migration file documents every schema difference (no undocumented changes)"
  - "Every breaking change has a manual review note"
  - "Every additive change has a default value"
  - "Migration script handles all automatic transformations"
  - "MIGRATION-REGISTRY.yml updated with correct metadata"
  - "Rollback instructions present in migration guide"
on_fail: "Re-diff the schemas, identify missing changes, update all three output files"
on_pass: "Calling command proceeds to update CHANGELOG.md"
```

Although this is a utility skill (called by `/plugin:version`, not by wave plans directly), the checkpoint is still enforced. The calling command runs these checks after invoking the generator.

## Edge Cases

| Situation | Behavior |
|-----------|----------|
| Schemas are identical (no differences) | Return early: "No schema changes detected between v[old] and v[new]. No migration needed." Skip all file generation. |
| Old schema file not found | Fail with error: "Cannot find archived schema at [path]. Archive the schema first with /plugin:version." |
| New schema file not found | Fail with error: "Cannot find current schema at [path]. Verify the plugin has a schema template." |
| MIGRATION-REGISTRY.yml has a duplicate entry | Ask user whether to overwrite the existing entry |
| Migration chain gap (e.g., jumping from 1.0.0 to 1.2.0 without 1.1.0) | Warn: "No migration exists from v[last] to v[old]. The migration chain has a gap." Generate the file anyway — the gap is the caller's problem. |
| Plugin has no schema template | Fail with error: "No schema template found in packages/[plugin]/resources/templates/. Cannot diff without schemas." |
| Ambiguous renames (multiple removed + multiple added fields) | Ask the user about each potential rename individually. Never assume renames. |
| Array item schema changes (e.g., items inside `keywords.primary[]`) | Diff array item sub-fields recursively. Treat `[].fieldname` paths the same as regular paths. |

## Integration Points

### What calls this

- **/plugin:version command** — calls this after archiving the old schema when bumping minor or major versions. Not called for patch bumps (no schema changes).

### Related skills

- **version-meta-stamper** — writes the `_meta` block that migration transforms update
- **version-compatibility-checker** — reads MIGRATION-REGISTRY.yml to check if a migration path exists
- **/plugin:migrate command** — reads the transform script (`.yml`) and applies it to project data files
