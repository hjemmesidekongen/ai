# Asset Registry — Detailed Process

## Register Operation

Called by producing skills to register a new asset.

### Input
```yaml
asset:
  id: "design-logo-primary-svg"      # Required: kebab-case module-type-name
  name: "Primary Logo (SVG)"          # Required: human-readable
  type: "logo"                        # Required: from schema enum
  format: "svg"                       # Required: file format
  path: ".ai/projects/acme/design/logos/primary.svg"  # Required: relative path
  producer: "design/logo-assets"      # Required: module/skill
  consumers: []                       # Optional: known consumers
  tags: ["brand", "logo", "primary"]  # Required: at least 1 tag
  dimensions: { width: 200, height: 48, unit: "px" }  # Optional
  variants: []                        # Optional
  status: "final"                     # Optional: default "final"
```

### Process
```
1. Read existing asset-registry.yml (or create empty if missing)
2. Check for duplicate ID:
   - If exists: update the entry (preserve created_at, update other fields)
   - If new: append to assets list
3. Set created_at to current timestamp (for new entries only)
4. Write updated asset-registry.yml
5. Report: "Registered asset: {id} ({type}/{format}) from {producer}"
```

### Validation on Register
```
- id: must be non-empty, kebab-case
- type: must be one of schema enum values
- format: must be one of schema enum values
- path: must be a valid relative path string
- producer: must contain "/" (module/skill format)
- tags: must have at least 1 entry
```

## Query Operation

Called by consuming skills to find assets they need.

### Filters
```yaml
# By type
query: { type: "logo" }
# Returns: all assets where type == "logo"

# By producer
query: { producer: "design/logo-assets" }
# Returns: all assets produced by design/logo-assets

# By tag (any match)
query: { tags: ["brand", "primary"] }
# Returns: assets matching ANY of the tags

# By consumer
query: { consumer: "dev/scaffold" }
# Returns: assets that list dev/scaffold in consumers

# By format
query: { format: "svg" }
# Returns: all SVG assets

# Combined
query: { type: "component-spec", format: "yml", tags: ["button"] }
# Returns: YAML component specs tagged "button"
```

### Process
```
1. Read asset-registry.yml
2. Apply filters (AND logic between different filter types, OR within tags)
3. Return matching assets sorted by type, then name
4. If no matches: return empty list with message "No assets match filters: {filters}"
```

## Validate Operation

Full integrity check of the registry.

### Process
```
1. Read asset-registry.yml
2. For each asset:
   a. Check file exists at path (warn if missing, don't fail)
   b. Check required fields present (id, name, type, format, path, producer, tags)
   c. Check type is valid enum value
   d. Check format is valid enum value
   e. Check no duplicate IDs
3. Report:
   "Asset registry validation: {total} assets, {valid} valid, {warnings} warnings"
   List any warnings (missing files, invalid types, etc.)
```

## List Operation

Human-readable summary of all registered assets.

### Output Format
```
## Project Assets: {project_name}

### By Module
**brand/** (2 assets)
  - brand-reference-yml: Brand Reference (yml) — final
  - brand-summary-tokens: Brand Design Tokens (yml) — final

**design/** (8 assets)
  - design-logo-primary-svg: Primary Logo (svg) — final
  ...

### Summary
Total: {count} assets across {module_count} modules
Types: {type_breakdown}
```

## Error Handling

| Error | Action |
|-------|--------|
| asset-registry.yml doesn't exist | Create empty registry with project name and empty assets list |
| Duplicate ID on register | Update existing entry, log "Updated existing asset: {id}" |
| Invalid type/format | Reject registration, report valid values |
| File at path doesn't exist | Warn on validate, don't block on register (file may not be created yet) |

## Error Logging

Log all errors to `state.yml` errors array for tracking and retry prevention:

```yaml
errors:
  - timestamp: "[ISO timestamp]"
    skill: "asset-registry"
    error: "[error description]"
    attempted_fix: "[what was tried]"
    result: "[resolved/unresolved]"
    next_approach: "[alternative if unresolved]"
```

Before retrying any operation, check state.yml errors array for previous attempts on the same asset ID. Never repeat a failed approach.

---

## Step 0: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/{skill-name}-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 — required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` — what happened vs expected; surprises, gaps, confirmations
- `improvement_idea` — actionable suggestion for the skill/pipeline (if any)
- `design_decision` — lasting choice beyond this run (if any)

**Trace-level `reflections` section (REQUIRED — Stop hook enforces):**
```yaml
reflections:
  observations: ["at least one observation about the run"]
  improvement_ideas: []   # optional but encouraged
  design_decisions: []    # optional, only for lasting choices
```

The Stop hook will BLOCK completion if reflections section is missing.

---


## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED — Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
