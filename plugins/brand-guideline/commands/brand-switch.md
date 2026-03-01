---
name: brand-switch
command: "/brand:switch"
description: "Set the active brand context for all brand-aware plugins, or list available brands"
arguments:
  - name: brand_name
    type: string
    required: false
    description: "Brand slug to switch to. Omit to show the interactive brand list."
  - name: list
    type: boolean
    required: false
    default: false
    description: "Show all available brands with status and completeness."
---

# /brand:switch

A utility command that sets the active brand context. Once set, all brand-aware plugins (website-builder, seo-plugin, content-engine, social-media-plugin) automatically use this brand's data without requiring `--brand` on every command.

## Usage

```
/brand:switch                    # interactive — list brands and pick one
/brand:switch "acme-corp"        # switch directly to acme-corp
/brand:switch --list             # show all brands without switching
```

## How It Works

This is a configuration command, not a generation command. It reads and writes a single config file (`~/.claude/active-brand.yml`) and does no brand data processing.

## Execution

### Step 1 — Determine Mode

```
if --list flag is set OR no brand_name provided:
  goto LIST_MODE
else:
  goto SWITCH_MODE
```

---

### Step 2a — LIST MODE

Scan `~/.claude/brands/` for brand directories and display a summary table.

```
brands_dir = "~/.claude/brands/"

if not exists(brands_dir):
  create brands_dir
  print "No brands found. Run /brand:generate or /brand:analyze to create one."
  STOP

brands = list_directories(brands_dir)

if brands is empty:
  print "No brands found. Run /brand:generate or /brand:analyze to create one."
  STOP

# Determine which brand is currently active
active_brand = null
if exists("~/.claude/active-brand.yml"):
  active_config = read_yaml("~/.claude/active-brand.yml")
  active_brand = active_config.active_brand

# Build the table
for each brand_slug in brands:
  ref_path = brands_dir + brand_slug + "/brand-reference.yml"

  if exists(ref_path):
    ref = read_yaml(ref_path)
    name = ref.meta.brand_name or brand_slug
    tagline = ref.meta.tagline or "—"
    modified = file_modified_date(ref_path)
    completeness = calculate_completeness(ref)
  else:
    name = brand_slug
    tagline = "(no brand-reference.yml)"
    modified = "—"
    completeness = "0%"

  is_active = (brand_slug == active_brand)
  marker = "★" if is_active else " "

  add_to_table(marker, name, tagline, modified, completeness)

# Display
print table with columns: [Active, Name, Tagline, Last Modified, Completeness]
```

#### Completeness Calculation

Count non-empty top-level sections in brand-reference.yml against the full schema:

```
sections = [meta, identity, visual, typography, colors, voice, audience, content, social]
total = 9
filled = count sections where section exists AND has at least one non-empty field
completeness = round(filled / total * 100)
```

Display as: `78%` (7/9 sections)

#### Interactive Selection

If `--list` was NOT explicitly set (user just ran `/brand:switch` with no arguments):

```
after displaying table:
  ask: "Which brand do you want to activate?"
  options: list of brand slugs from table
  selected = user's choice
  goto SWITCH_MODE with brand_name = selected
```

---

### Step 2b — SWITCH MODE

Activate a specific brand by writing `~/.claude/active-brand.yml`.

```
brand_name = provided brand slug
brands_dir = "~/.claude/brands/"
brand_path = brands_dir + brand_name

# 1. Verify brand exists
if not exists(brand_path):
  print "Brand '[brand_name]' not found."
  print ""
  goto LIST_MODE   # show available brands to help the user
  STOP

# 2. Check for brand-reference.yml
ref_path = brand_path + "/brand-reference.yml"
has_reference = exists(ref_path)

if has_reference:
  ref = read_yaml(ref_path)
  completeness = calculate_completeness(ref)
  display_name = ref.meta.brand_name or brand_name
else:
  completeness = "0%"
  display_name = brand_name

# 3. Warn if incomplete (but don't block)
if not has_reference:
  warn: "⚠ No brand-reference.yml found in ~/.claude/brands/[brand_name]/."
  warn: "Some plugins may fail if required brand sections are missing."
  warn: "Run /brand:generate or /brand:analyze to populate brand data."
  print ""

elif completeness < 50:
  warn: "⚠ Brand data is [completeness]% complete. Some plugins may not have enough data."
  print ""

# 4. Write active-brand.yml
write_yaml("~/.claude/active-brand.yml"):
  active_brand: "[brand_name]"
  brand_path: "~/.claude/brands/[brand_name]"
  switched_at: "[ISO 8601 timestamp]"

# 5. Confirm
print "Switched to [display_name]."
print "All brand-dependent plugins will now use this brand's data."
if has_reference:
  print "Completeness: [completeness]% ([filled]/[total] sections)"
```

---

## active-brand.yml Schema

```yaml
# ~/.claude/active-brand.yml
# Written by /brand:switch. Read by brand-context-loader.
active_brand: "acme-corp"
brand_path: "~/.claude/brands/acme-corp"
switched_at: "2026-03-01T14:30:00Z"
```

This file is the single source of truth for "which brand is active." It is:
- Written by `/brand:switch`
- Read by `brand-context-loader` (shared skill)
- Ignored if `--brand` is passed explicitly to any command

---

## Error Handling

| Error | Action |
|-------|--------|
| `~/.claude/brands/` doesn't exist | Create it. Show "no brands found" message. |
| Brand slug not found | Show error + list available brands. |
| `brand-reference.yml` missing | Warn but allow switch. Note which plugins may fail. |
| `brand-reference.yml` is malformed YAML | Show parse error. Do not switch. |
| `active-brand.yml` write fails | Report permission error. Suggest checking `~/.claude/` permissions. |

---

## Integration with brand-context-loader

This command writes `~/.claude/active-brand.yml`. The `brand-context-loader` shared skill reads it as part of its brand discovery fallback chain (see updated brand-context-loader SKILL.md for details).

---

## What This Command Does NOT Do

- Does not validate brand data beyond checking file existence and YAML parsing
- Does not modify brand-reference.yml or any brand assets
- Does not use the task-planner (no waves, no checkpoints)
- Does not run any brand generation or analysis
- Does not require a checkpoint — it's a configuration command
