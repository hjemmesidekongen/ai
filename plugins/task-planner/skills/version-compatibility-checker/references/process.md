# Version Compatibility Checker — Full Process

Checks whether a project's data files are compatible with the current plugin version. Called automatically when any plugin loads existing project data — ensures stale or incompatible data is never silently loaded.

This is a **utility skill**. It does not run standalone or appear in wave plans. Data loaders (like `brand-context-loader`) call it before loading data.

## Calling Convention

Any skill or loader that reads from a plugin output YAML file (e.g., `brand-reference.yml`, `seo-strategy.yml`) must call this skill BEFORE loading the data.

**How to call:**

```
Before loading [data-file], call the version-compatibility-checker to
verify the file is compatible with the current plugin version.
If the result is "blocking", stop and show the migration message.
```

**Where skills reference this:** In their SKILL.md under the first process step, before any data processing. Example:

```markdown
### Step 1: Version Check

Before loading [data-file], call the version-compatibility-checker skill
(packages/task-planner/skills/version-compatibility-checker/SKILL.md) to
verify compatibility. If the result severity is "blocking", stop execution
and display the migration message to the user.
```

## Input

The calling skill provides (implicitly via context):

- **Data file path** — the YAML file being loaded (e.g., `~/.claude/seo/my-project/seo-strategy.yml`)
- **Plugin directory** — the `packages/[plugin-name]/` directory containing `.claude-plugin/plugin.json`

## Process

### Step 1: Read Current Plugin Version

Read `.claude-plugin/plugin.json` from the current plugin's directory:

```json
{
  "name": "seo-plugin",
  "version": "1.1.0",
  ...
}
```

Extract:
- `current_plugin_name` — the `name` field
- `current_plugin_version` — the `version` field

### Step 2: Read File Version Metadata

Read the target YAML file and look for the `_meta` top-level key.

**If `_meta` does not exist:** This is a "legacy" file created before the versioning system was added.

- Set `file_plugin_version` to `"0.0.0"`
- Set `file_schema_version` to `"0.0.0"`
- Note: `"This file has no version metadata. It was likely created before the versioning system was added. Assume v0.0.0."`

**If `_meta` exists:** Extract:
- `file_plugin_version` — from `_meta.plugin_version`
- `file_schema_version` — from `_meta.schema_version`

### Step 3: Compare Versions

Parse both `current_plugin_version` and `file_plugin_version` as semver (`major.minor.patch`).

Apply these rules in order:

| Condition | Severity | Action |
|-----------|----------|--------|
| Exact match (e.g., 1.0.0 = 1.0.0) | `ok` | Proceed normally. No message needed. |
| Patch mismatch only (e.g., 1.0.0 vs 1.0.1) | `info` | Proceed normally. Patch versions are always backwards compatible. |
| Minor mismatch (e.g., 1.0.0 vs 1.1.0) | `warning` | Warn the user. New features are available. Migration is optional. |
| Major mismatch (e.g., 1.x vs 2.x) | `blocking` | Block execution. Schema has breaking changes. Migration is required. |
| Legacy file (no `_meta`, assumed 0.0.0) | `warning` | Warn the user. Suggest running migration to add version metadata. |

**Messages by severity:**

- **ok:** No message displayed.
- **info:** `"Version compatible. File: v[file_version], Plugin: v[current_version]. Patch difference only."`
- **warning (minor):** `"This project was created with [plugin_name] v[file_version]. Current is v[current_version]. New features are available. Run /plugin:migrate [plugin_name] --project [project] to update. You can continue without migrating."`
- **warning (legacy):** `"This project has no version metadata (pre-versioning). Run /plugin:migrate [plugin_name] --project [project] to add version tracking. You can continue without migrating."`
- **blocking:** `"This project was created with [plugin_name] v[file_version]. Current is v[current_version]. The schema has breaking changes. You must migrate before continuing. Run /plugin:migrate [plugin_name] --project [project]"`

### Step 4: Check Migration Path

Only run this step if severity is `warning` or `blocking`.

1. Look for `packages/[plugin-name]/migrations/MIGRATION-REGISTRY.yml`
2. If the file does not exist:
   - Set `migration_available` to `false`
   - Set `migration_chain` to `[]`
   - If severity is `blocking`: append to message — `"No migration registry found. Contact the plugin maintainer."`
3. If the file exists, read it and check for a chain of migrations from `file_plugin_version` to `current_plugin_version`:

```yaml
# Example MIGRATION-REGISTRY.yml
migrations:
  - from: "1.0.0"
    to: "1.1.0"
    type: "minor"
    guide: "v1.0.0-to-v1.1.0.md"
    script: "scripts/v1.0.0-to-v1.1.0.sh"
  - from: "1.1.0"
    to: "2.0.0"
    type: "major"
    guide: "v1.1.0-to-v2.0.0.md"
    script: "scripts/v1.1.0-to-v2.0.0.sh"
```

4. Build the migration chain by walking from `file_plugin_version` to `current_plugin_version`:
   - Start at `file_plugin_version`
   - Find migration where `from` matches current position
   - Move to `to` version
   - Repeat until reaching `current_plugin_version` or no more migrations found
   - If the chain is incomplete (cannot reach current version): set `migration_available` to `false`

Example chain: `["1.0.0→1.1.0", "1.1.0→2.0.0"]`

### Step 5: Build Compatibility Result

Construct and return the result:

```yaml
compatible: true | false
severity: "ok" | "info" | "warning" | "blocking"
current_version: "[current plugin version from plugin.json]"
file_version: "[from _meta, or 0.0.0 if legacy]"
schema_version: "[from _meta.schema_version, or 0.0.0 if legacy]"
migration_available: true | false
migration_chain: ["1.0.0→1.1.0", "1.1.0→2.0.0"]
message: "[human-readable message from Step 3]"
```

**Field rules:**

| Field | Value |
|-------|-------|
| `compatible` | `true` if severity is `ok`, `info`, or `warning`. `false` if `blocking`. |
| `severity` | One of: `ok`, `info`, `warning`, `blocking` |
| `current_version` | From plugin.json `version` field |
| `file_version` | From `_meta.plugin_version`, or `"0.0.0"` for legacy files |
| `schema_version` | From `_meta.schema_version`, or `"0.0.0"` for legacy files |
| `migration_available` | `true` if a complete migration chain exists from file version to current version |
| `migration_chain` | Array of version transitions, or `[]` if no migration path |
| `message` | Human-readable message (empty string for `ok` severity) |

## Output

The compatibility result is returned to the calling skill. No file is written.

The calling skill uses the result to decide whether to proceed:

- **`compatible: true`** — proceed with loading data. Display message if severity is `warning`.
- **`compatible: false`** — stop execution. Display the blocking message to the user.

**Example — exact match (ok):**

```yaml
compatible: true
severity: "ok"
current_version: "1.0.0"
file_version: "1.0.0"
schema_version: "1.0.0"
migration_available: false
migration_chain: []
message: ""
```

**Example — minor mismatch (warning):**

```yaml
compatible: true
severity: "warning"
current_version: "1.1.0"
file_version: "1.0.0"
schema_version: "1.0.0"
migration_available: true
migration_chain: ["1.0.0→1.1.0"]
message: "This project was created with seo-plugin v1.0.0. Current is v1.1.0. New features are available. Run /plugin:migrate seo-plugin --project my-project to update. You can continue without migrating."
```

**Example — major mismatch (blocking):**

```yaml
compatible: false
severity: "blocking"
current_version: "2.0.0"
file_version: "1.0.0"
schema_version: "1.0.0"
migration_available: true
migration_chain: ["1.0.0→1.1.0", "1.1.0→2.0.0"]
message: "This project was created with seo-plugin v1.0.0. Current is v2.0.0. The schema has breaking changes. You must migrate before continuing. Run /plugin:migrate seo-plugin --project my-project"
```

**Example — legacy file (warning):**

```yaml
compatible: true
severity: "warning"
current_version: "1.0.0"
file_version: "0.0.0"
schema_version: "0.0.0"
migration_available: false
migration_chain: []
message: "This project has no version metadata (pre-versioning). Run /plugin:migrate seo-plugin --project my-project to add version tracking. You can continue without migrating."
```

## Checkpoint

```yaml
type: data_validation
required_checks:
  - "Handles all four cases: exact match, patch, minor, major"
  - "Returns structured result with all fields"
  - "Correctly identifies legacy files with no _meta block"
  - "Reads MIGRATION-REGISTRY.yml to check migration path availability"
on_fail: "Re-read plugin.json and the data file, re-run version comparison, fix the result"
on_pass: "Calling skill proceeds with data loading or displays blocking message"
```

Although this is a utility skill (called by other skills, not by wave plans directly), the checkpoint is still enforced. The calling skill runs these checks after invoking the checker.

## Edge Cases

| Situation | Behavior |
|-----------|----------|
| Plugin has no `version` in plugin.json | Fail with error: "plugin.json missing version field" |
| Data file does not exist | Fail with error: "Data file not found at [path]" — the calling skill should check existence first |
| `_meta` exists but `plugin_version` is missing | Treat as legacy — assume v0.0.0 |
| `_meta.plugin_name` differs from current plugin name | Fail with error: "Data file belongs to [file_plugin] but was loaded by [current_plugin]" |
| migrations/ directory does not exist | Set `migration_available` to `false`, `migration_chain` to `[]` |
| MIGRATION-REGISTRY.yml exists but chain is incomplete | Set `migration_available` to `false` — partial chains are not usable |
| File version is NEWER than plugin version | Severity `blocking`: "This project was created with a newer version (v[file]) than the installed plugin (v[current]). Update the plugin before continuing." |

## Integration Points

### Which skills call this

Every skill or loader that reads plugin output YAML files. Examples:

- **brand-context-loader** — calls this before loading `brand-reference.yml`
- **seo-plugin compile-and-export** — calls this before loading `seo-strategy.yml` for re-export
- **Any future plugin** — data loaders call this before reading project data

### Related skills

- **version-meta-stamper** — writes the `_meta` block that this skill reads
- **migration-guide-generator** — creates the migration files that this skill checks for
- **/plugin:migrate command** — user-facing command that performs the actual migration
