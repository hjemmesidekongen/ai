# Version Meta Stamper

Adds or updates the `_meta` version block on any plugin output YAML file. Called by other skills as their final step before writing output — ensures every YAML artifact is traceable to the plugin version and schema version that created it.

This is a **utility skill**. It does not run standalone or appear in wave plans. Other skills call it as their last step.

## Calling Convention

Any skill that writes to a plugin output YAML file (e.g., `brand-reference.yml`, `seo-strategy.yml`) must call this skill as the final step before considering its output complete.

**How to call:**

```
After writing [output-file], call the version-meta-stamper to add/update
the _meta block with the current plugin version.
```

**Where skills reference this:** In their SKILL.md under the final process step, before the checkpoint. Example:

```markdown
### Step N: Version Stamp

After writing [output-file], call the version-meta-stamper skill
(packages/task-planner/skills/version-meta-stamper/SKILL.md) to
add/update the _meta block with the current plugin version.
```

## Input

The calling skill provides (implicitly via context):

- **Output file path** — the YAML file being written (e.g., `~/.claude/seo/my-project/seo-strategy.yml`)
- **Plugin directory** — the `packages/[plugin-name]/` directory containing `.claude-plugin/plugin.json`

## Process

### Step 1: Read Plugin Metadata

Read `.claude-plugin/plugin.json` from the current plugin's directory:

```json
{
  "name": "seo-plugin",
  "version": "1.0.0",
  ...
}
```

Extract:
- `plugin_name` — the `name` field
- `plugin_version` — the `version` field

### Step 2: Determine Schema Version

Look for an explicit schema version in the plugin's resources:

1. Check for `packages/[plugin-name]/resources/templates/schema-version.yml`:
   ```yaml
   schema_version: "1.0.0"
   ```
2. If that file does not exist, check the main YAML schema file header (first 10 lines) for a `# Schema version: X.Y.Z` comment
3. If neither exists, **default to the plugin version** from plugin.json

The schema version tracks the data format independently from the plugin code version. At v1.0.0 they are always identical.

### Step 3: Read Existing `_meta` Block (if any)

Read the target YAML file and check if a `_meta` top-level key already exists.

**If `_meta` exists**, extract:
- `created_at` — preserve this value (never overwrite)
- `plugin_version` — the previously stamped version (used to detect version changes)

**If `_meta` does not exist**, this is a fresh stamp.

### Step 4: Build the `_meta` Block

Construct the block with these rules:

```yaml
_meta:
  plugin_name: "[from plugin.json name]"
  plugin_version: "[from plugin.json version]"
  schema_version: "[from Step 2]"
  created_at: "[preserved from existing _meta, OR current ISO timestamp if new]"
  updated_at: "[current ISO timestamp — always set to now]"
  migrated_from: null | "[previous plugin_version if it differs from current]"
```

**Field rules:**

| Field | New file | Existing file (same version) | Existing file (version changed) |
|-------|----------|-----------------------------|---------------------------------|
| `plugin_name` | Set from plugin.json | Update (in case of rename) | Update |
| `plugin_version` | Set from plugin.json | Set from plugin.json (unchanged) | Set from plugin.json (new version) |
| `schema_version` | Set from Step 2 | Set from Step 2 | Set from Step 2 |
| `created_at` | Set to now (ISO 8601) | **Preserve existing value** | **Preserve existing value** |
| `updated_at` | Set to now (ISO 8601) | Set to now (ISO 8601) | Set to now (ISO 8601) |
| `migrated_from` | `null` | `null` (no change) | Set to previous `plugin_version` |

**ISO 8601 format:** `2026-03-01T14:30:00Z` (UTC, no milliseconds)

### Step 5: Write the `_meta` Block

Apply the `_meta` block to the target YAML file:

**If `_meta` already exists in the file:**
- Replace the entire `_meta` block with the new one (use Edit tool to replace old block with new)
- The `_meta` block should remain at its current position in the file (typically the top or bottom)

**If `_meta` does not exist:**
- Add the `_meta` block as the **last top-level section** in the YAML file
- Add a blank line before `_meta` for readability

**Placement convention:** `_meta` goes at the end of the file. The underscore prefix signals it is metadata, not domain data. This keeps it out of the way when humans read the file.

## Output

The target YAML file now contains a valid `_meta` block. No separate output file is produced.

**Example — fresh stamp:**

```yaml
# ... domain data above ...

_meta:
  plugin_name: "seo-plugin"
  plugin_version: "1.0.0"
  schema_version: "1.0.0"
  created_at: "2026-03-01T14:30:00Z"
  updated_at: "2026-03-01T14:30:00Z"
  migrated_from: null
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
  - "_meta block present in the output file"
  - "_meta.plugin_name matches plugin.json name"
  - "_meta.plugin_version matches plugin.json version"
  - "_meta.created_at is a valid ISO 8601 timestamp"
  - "_meta.updated_at >= _meta.created_at"
on_fail: "Re-read plugin.json and the output file, fix the _meta block, re-run checks"
on_pass: "Calling skill proceeds to its own checkpoint"
```

Although this is a utility skill (called by other skills, not by wave plans directly), the checkpoint is still enforced. The calling skill runs these checks after invoking the stamper. If any check fails, the calling skill must fix the `_meta` block before advancing.

## Edge Cases

| Situation | Behavior |
|-----------|----------|
| Plugin has no `version` in plugin.json | Fail with error: "plugin.json missing version field" |
| Target file does not exist yet | Do nothing — the calling skill creates the file first, then calls this skill |
| Target file is empty | Add only the `_meta` block |
| `_meta.created_at` is missing from existing block | Treat as a fresh stamp — set `created_at` to now |
| `migrated_from` already has a value and version changes again | Overwrite with the most recent previous version (not the original) |
| Non-YAML file (e.g., .md) | Do not stamp — this skill only operates on YAML files |

## Integration Points

### Which skills call this

Every skill that writes to the main output YAML file as its final step. Examples:

- **brand-guideline** — `compile-and-export` calls it on `brand-reference.yml`
- **seo-plugin** — `compile-and-export` calls it on `seo-strategy.yml`
- **Any future plugin** — the final compilation skill stamps the output

### Related skills

- **version-compatibility-checker** — reads `_meta.plugin_version` and `_meta.schema_version` to determine if a data file is compatible with the current plugin version
- **migration-guide-generator** — uses `_meta.migrated_from` to track migration history
