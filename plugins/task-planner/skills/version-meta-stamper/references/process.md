# Version Meta Stamper — Full Process

Utility skill that adds or updates the `_meta` version block in any plugin output YAML file. This skill is never invoked directly by the user — other skills call it as their last step before writing output to disk.

## Purpose

Every YAML output file in the ecosystem (brand-reference.yml, seo-strategy.yml, etc.) must carry a `_meta` block that records which plugin version created it. This enables version-compatibility-checker to detect mismatches and migration-guide-generator to produce upgrade paths.

## Calling Convention

Any skill that writes a plugin output YAML file must call the version-meta-stamper as its **final step before writing to disk**. The calling skill provides:

```
stamp_meta(
  file_path:    "[path to the YAML output file]",
  plugin_path:  "[path to the plugin root, e.g. plugins/brand-guideline]"
)
```

### Where to Add the Call

In the calling skill's SKILL.md, add a step before the checkpoint:

```markdown
### Step N: Stamp Version Metadata

Before writing [output-file] to disk, call the version-meta-stamper:

  stamp_meta(
    file_path:   "~/.claude/brands/[brand]/brand-reference.yml",
    plugin_path: "plugins/brand-guideline"
  )

This reads plugin.json, resolves the schema version, and inserts/updates the
_meta block as the first top-level key in the output YAML.
```

### Example — compile-and-export (brand-guideline)

```markdown
## Step 7: Stamp Version Metadata

Before writing brand-reference.yml to disk:

1. Call version-meta-stamper with:
   - file_path: the brand-reference.yml being compiled
   - plugin_path: plugins/brand-guideline
2. The stamper reads plugin.json → gets name ("brand-guideline") and version ("1.0.0")
3. It checks for a schema version file → defaults to plugin version
4. It inserts _meta as the first key in brand-reference.yml
5. Then proceed to write the file and run the checkpoint
```

### Example — updating an existing file

```markdown
## Final Step: Update Version Metadata

Before saving the updated seo-strategy.yml:

1. Call version-meta-stamper — it reads the existing _meta block
2. It preserves created_at (never overwritten)
3. It updates plugin_version and updated_at
4. If plugin_version changed: sets migrated_from to the old version
5. Write the file
```

## Process

### Step 1: Read Plugin Metadata

Read `.claude-plugin/plugin.json` from the plugin directory provided by the caller:

```json
{
  "name": "seo-plugin",
  "version": "1.0.0",
  ...
}
```

Extract:
- `name` → becomes `_meta.plugin_name`
- `version` → becomes `_meta.plugin_version`

If plugin.json is missing or has no `version` field, **abort** and report the error to the calling skill. Do not write a `_meta` block with incomplete data.

### Step 2: Resolve Schema Version

The schema version tracks the YAML schema independently from the plugin version. They often match, but can diverge (e.g., a patch release that fixes code but doesn't change the schema).

Resolution order:

1. **Check `[plugin_path]/resources/schemas/schema-version.yml`**

   ```yaml
   # schema-version.yml
   schema_version: "1.0.0"
   ```

   If this file exists and contains a valid semver string, use it.

2. **Check the YAML schema file header** — look for files matching
   `[plugin_path]/resources/templates/*-schema.yml` or
   `[plugin_path]/resources/schemas/*.yml` (excluding `archive/`).
   If any has a `schema_version` field in its top-level keys, use it.

3. **Default to plugin version** — if neither source provides a schema version, use the plugin version from plugin.json. This is the common case at v1.0.0.

### Step 3: Read Existing `_meta` Block (if any)

Read the target YAML file. Check if a `_meta` key exists at the top level.

**If `_meta` exists** (updating an existing file):

- Extract `created_at` — **NEVER overwrite this value**
- Extract `plugin_version` — the previously stamped version
- Compare old `plugin_version` with the current one:
  - If different: `migrated_from` = old plugin_version
  - If same: `migrated_from` stays unchanged (null or its previous value)
- Preserve any extra custom fields in the `_meta` block that aren't part of the six canonical fields

**If `_meta` does not exist** (new file):

- `created_at` = current ISO 8601 timestamp
- `migrated_from` = `null`

### Step 4: Build the `_meta` Block

Construct the block:

```yaml
_meta:
  plugin_name: "[from plugin.json]"
  plugin_version: "[from plugin.json]"
  schema_version: "[from Step 2]"
  created_at: "[preserved from existing, OR current ISO timestamp if new]"
  updated_at: "[current ISO timestamp — always set to now]"
  migrated_from: null | "[previous plugin_version if changed]"
```

**Field rules:**

| Field | New file | Existing (same version) | Existing (version changed) |
|-------|----------|-------------------------|----------------------------|
| `plugin_name` | Set from plugin.json | Update | Update |
| `plugin_version` | Set from plugin.json | Unchanged | Set to new version |
| `schema_version` | Set from Step 2 | Set from Step 2 | Set from Step 2 |
| `created_at` | Set to now | **Preserve** | **Preserve** |
| `updated_at` | Set to now | Set to now | Set to now |
| `migrated_from` | `null` | Unchanged | Set to previous `plugin_version` |

**Timestamp format:** ISO 8601 UTC, e.g. `"2026-03-01T14:30:00Z"`

### Step 5: Insert or Replace in the Target File

- **If `_meta` already exists:** replace the entire block with the new one
- **If `_meta` does not exist:** insert it as the **first top-level key**

The `_meta` block must always be the **first section** in the file. This convention makes it immediately visible when reading the file and ensures consistent placement across all plugins. It matches the format shown in `plugins/task-planner/resources/plugin-blueprint.md` Section 12.

### Step 6: Return to Calling Skill

Return the stamped YAML content to the calling skill. The stamper prepares the data; the calling skill is responsible for the actual disk write.

Return value:

```yaml
stamped: true
plugin_name: "[name]"
plugin_version: "[version]"
schema_version: "[schema version]"
created_at: "[timestamp]"
updated_at: "[timestamp]"
migrated_from: null | "[old version]"
```

The calling skill can use these values in its checkpoint validation.

## Output Examples

**Example — fresh stamp:**

```yaml
_meta:
  plugin_name: "seo-plugin"
  plugin_version: "1.0.0"
  schema_version: "1.0.0"
  created_at: "2026-03-01T14:30:00Z"
  updated_at: "2026-03-01T14:30:00Z"
  migrated_from: null

# ... domain data below ...
```

**Example — update after plugin version bump (1.0.0 → 1.1.0):**

```yaml
_meta:
  plugin_name: "seo-plugin"
  plugin_version: "1.1.0"
  schema_version: "1.1.0"
  created_at: "2026-03-01T14:30:00Z"
  updated_at: "2026-03-15T09:00:00Z"
  migrated_from: "1.0.0"
```

## Checkpoint

```yaml
type: data_validation
required_checks:
  - name: "meta_block_present"
    verify: "_meta key exists as the first top-level key in the output YAML"
    fail_action: "Re-run stamper — the _meta block was not inserted"
  - name: "meta_fields_complete"
    verify: "_meta has all six fields: plugin_name, plugin_version, schema_version, created_at, updated_at, migrated_from"
    fail_action: "Check plugin.json exists and is readable. Re-stamp with complete data."
  - name: "created_at_immutable"
    verify: "If the file existed before this run, _meta.created_at matches the original value"
    fail_action: "Restore the original created_at — this field must never change after first write"
  - name: "version_matches_plugin"
    verify: "_meta.plugin_version matches the version field in plugin.json"
    fail_action: "Re-read plugin.json and re-stamp"
  - name: "migrated_from_correct"
    verify: "If plugin_version changed from the previous _meta, migrated_from equals the old version. If unchanged, migrated_from is null or its previous value."
    fail_action: "Set migrated_from to the previous plugin_version"
on_fail: "Fix the failing check and re-stamp. Do not let the calling skill write a file with invalid _meta."
on_pass: "Return stamped data to the calling skill. The calling skill handles state.yml updates."
```

Although this is a utility skill (called by other skills, not by wave plans), the checkpoint is still enforced. The calling skill runs these checks after invoking the stamper. If any check fails, the calling skill must fix the `_meta` block before advancing.

## Edge Cases

| Situation | Behavior |
|-----------|----------|
| Plugin has no `version` in plugin.json | Abort with error: "plugin.json missing version field" |
| Target file does not exist yet | The calling skill creates the file first, then calls the stamper |
| Target file is empty | Add only the `_meta` block |
| `_meta.created_at` missing from existing block | Treat as fresh — set `created_at` to now |
| `migrated_from` already set and version changes again | Overwrite with the most recent previous version (not the original) |
| `_meta` has extra custom fields | Preserve them — only overwrite the six canonical fields |
| Non-YAML file (e.g., .md) | Do not stamp — this skill only operates on YAML files |
| Multiple output files for one plugin | Each file gets its own `_meta` block with its own `created_at` |

## Integration Points

### Which skills call this

Every skill that writes the plugin's main output YAML file in its final step:

| Plugin | Skill | Output File |
|--------|-------|-------------|
| brand-guideline | compile-and-export | `brand-reference.yml` |
| seo-plugin | compile-and-export | `seo-strategy.yml` |
| Any future plugin | Final compilation skill | Plugin's main YAML output |

Individual phase skills (identity-interview, keyword-research, etc.) do NOT call the stamper — they write sections to the output file incrementally. The stamper runs once at the end, during the final compilation step.

**Exception:** Skills that produce standalone YAML deliverables (e.g., `content-brief-001.yml`) should stamp each file individually.

### Related skills

- **version-compatibility-checker** — reads `_meta.plugin_version` and `_meta.schema_version` to determine if a data file is compatible with the current plugin version
- **migration-guide-generator** — uses `_meta.migrated_from` to track migration history and determine which migrations to apply
