---
name: brand-context-loader
description: >
  Loads the active brand context from brand-reference.yml and state.yml.
  Used by all brand-aware plugins (SEO, social media, website, content).
  Must fire at session start and before any brand-consuming work.
shared: true
consumed_by:
  - brand-guideline
  - website-builder
  - seo-plugin
  - social-media-plugin
  - content-plugin
---

# Brand Context Loader

Shared skill that loads brand context from disk. Every brand-aware plugin calls this before doing work. It handles brand discovery, selection, state recovery, and section access.

## Session Start Protocol (MANDATORY)

Before doing ANY brand-related work:

1. Check if `--brand` flag was provided → use that brand
2. If not, check if `~/.claude/active-brand.yml` exists → use the active brand
3. If not, scan `~/.claude/brands/` for available brands
4. If only one brand exists, load it automatically
5. If multiple exist, ask which brand to use
6. Read `brand-reference.yml` and `state.yml`
7. Report status and resume point
8. NEVER skip this check. NEVER start a phase that has already been completed.

## Brand Discovery

```
function load_brand(brand_flag):
  brands_dir = "~/.claude/brands/"

  # Priority 1: Explicit --brand flag
  if brand_flag is provided:
    brand_path = brands_dir + brand_flag
    if not exists(brand_path):
      ERROR: "Brand '[brand_flag]' not found in ~/.claude/brands/"
      list available brands
      STOP
    return load_from(brand_path)

  # Priority 2: Active brand set by /brand:switch
  active_brand_path = "~/.claude/active-brand.yml"
  if exists(active_brand_path):
    active_config = read_yaml(active_brand_path)
    brand_slug = active_config.active_brand
    brand_path = brands_dir + brand_slug
    if exists(brand_path):
      Report: "Using active brand: [brand_slug] (set by /brand:switch)"
      return load_from(brand_path)
    else:
      warn: "Active brand '[brand_slug]' no longer exists. Falling back to discovery."

  # Priority 3: Auto-discover from ~/.claude/brands/
  brands = list_directories(brands_dir)

  if brands is empty:
    return null   # No brands exist — this is a fresh start

  if brands.length == 1:
    return load_from(brands_dir + brands[0])

  # Multiple brands, no active brand set — ask user
  ask: "Multiple brands found. Which one? (Tip: use /brand:switch to set a default)"
  options: brands
  return load_from(brands_dir + selected_brand)
```

## Loading a Brand

When a brand directory is found, load two files:

### 1. brand-reference.yml (the data)

```
path: ~/.claude/brands/[brand]/brand-reference.yml

if file exists:
  Read and parse YAML
  Validate against brand-reference-schema.yml (if available)
  Report: "Loaded brand context for [meta.brand_name] (v[meta.version], updated [meta.generated_date])"

if file does not exist:
  This is a new brand with no data yet
  Report: "Brand directory exists but no brand-reference.yml found. Run /brand:generate to create."
```

### 2. state.yml (the execution state)

```
path: ~/.claude/brands/[brand]/state.yml

if file exists:
  Read and parse YAML
  Report current phase and status:
    "Brand generation: [current_phase_number]/[total_phases] phases complete"
    "Current phase: [current_phase] ([status])"

  if status is "in_progress":
    Read recovery_notes
    Report: "Resuming from: [recovery_notes summary]"
    Resume from current_phase — do NOT restart completed phases

  if status is "completed":
    Report: "Brand generation complete. All phases passed."

  if status is "failed":
    Report: "Brand generation failed at phase [current_phase]."
    Show checkpoint failure details
    Suggest: "/brand:generate --resume to retry"

if file does not exist:
  This is either a fresh brand or was created manually
  No state to recover — start from phase 1 if generating
```

### 3. Version Compatibility Check

After loading brand-reference.yml and before returning data, call the
version-compatibility-checker skill
(packages/task-planner/skills/version-compatibility-checker/SKILL.md) to
verify the file is compatible with the current plugin version.

```
brand_ref = read_yaml(brand_path + "/brand-reference.yml")

# Check version compatibility
result = version_compatibility_check(
  data_file: brand_path + "/brand-reference.yml",
  plugin_dir: "packages/brand-guideline/"
)

if result.severity == "ok" or result.severity == "info":
  # Proceed normally — versions match or only patch difference
  pass

if result.severity == "warning":
  # Show migration suggestion but continue
  Report: result.message
  # e.g. "This project was created with brand-guideline v1.0.0.
  #  Current is v1.1.0. New features are available.
  #  Run /plugin:migrate brand-guideline --project [brand] to update.
  #  You can continue without migrating."

if result.severity == "blocking":
  # Stop — schema has breaking changes
  Report: result.message
  # e.g. "This project was created with brand-guideline v1.0.0.
  #  Current is v2.0.0. The schema has breaking changes.
  #  You must migrate before continuing.
  #  Run /plugin:migrate brand-guideline --project [brand]"
  STOP — do not proceed with loading data
```

**Legacy files (no `_meta` block):** The checker treats these as v0.0.0
and returns a warning. The brand can still be loaded, but the user is
advised to run `/plugin:migrate` to add version tracking.

## What Gets Loaded

The full brand-reference.yml has these sections. Consuming plugins request only what they need:

| Section | Contains | Used By |
|---------|----------|---------|
| `meta` | Brand name, tagline, industry, website, version | All plugins |
| `identity` | Mission, vision, values, brand story, positioning | SEO, content, pitch deck, ad campaigns |
| `visual` | Logo variants, imagery style, layout principles | Website builder, pitch deck |
| `typography` | Font families, weights, type scale | Website builder, pitch deck |
| `colors` | Primary, secondary, accent, neutrals, semantic, accessibility | Website builder, social media, pitch deck |
| `voice` | Personality, spectrum, messaging, writing samples | SEO, social media, content, email, ads |
| `audience` | Primary market, personas with goals/frustrations/channels | All plugins |
| `content` | Dos/don'ts, terminology, grammar rules, content types | Content, SEO, social media, email |
| `social` | Platform guides, engagement rules | Social media |

### Section Access

Consuming plugins should request specific sections rather than loading everything:

```
# SEO plugin only needs these:
brand = load_brand("my-company")
sections = [brand.audience, brand.voice, brand.content, brand.identity.positioning]

# Website builder needs visual + structural:
brand = load_brand("my-company")
sections = [brand.visual, brand.typography, brand.colors, brand.voice, brand.audience, brand.identity]
```

## Memory Save Triggers

After loading brand context, check if any session-level observations should be saved to auto memory (`~/.claude/projects/[project]/memory/MEMORY.md`):

```
After completing each phase, save patterns like:
- "User prefers [X] style of communication during interviews"
- "Brand uses American English spelling"
- "User wants minimal questions — prefers Claude to make decisions and present for approval"
- "User is the brand owner, not an agency working for a client"
```

These are NOT brand data (that goes in brand-reference.yml). These are workflow preferences that improve the experience across sessions.

## Multi-Agent Coordination

When used in agent teams, brand-reference.yml and state.yml ARE the shared state:

- Each agent calls brand-context-loader independently
- All agents read the same brand-reference.yml
- Agents write to their assigned sections only (per file-ownership registry)
- state.yml is updated by the orchestrator, not individual agents
- No complex memory synchronization needed — the files on disk are the coordination channel

## Error Handling

| Error | Action |
|-------|--------|
| `~/.claude/brands/` doesn't exist | Create it. Report: "No brands directory found. Created ~/.claude/brands/" |
| Brand directory is empty | Report: "Brand directory exists but is empty. Run /brand:generate to start." |
| brand-reference.yml is malformed YAML | Report parse error with line number. Do not proceed. |
| state.yml references a phase that doesn't exist | Warn user. Suggest re-running /brand:generate. |
| Permission denied reading files | Report error. Suggest checking file permissions. |
