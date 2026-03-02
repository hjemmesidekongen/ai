# Compile & Export — Detailed Process

Phase 9 — the final skill in the brand generation pipeline. This skill takes everything produced by phases 1-8 and creates the finished deliverables: a validated brand reference, professional documentation, asset tooling, and an interactive preview.

**This is the only skill with a mandatory QA review.** The implementing agent never self-grades — a dedicated QA agent reviews all outputs before the brand is marked complete.

## Before You Start

Read the complete `brand-reference.yml` and `state.yml`. Verify that all 8 previous phases are marked complete in state.yml. If any phase is incomplete, stop and inform the user which phases still need to run.

Also read `findings.md` if it exists — it contains research notes, user responses, and rationale from all previous phases. This additional context can enrich the brand manual narrative sections (brand story, positioning rationale, audience insights) beyond what's captured in brand-reference.yml alone.

Also scan the `assets/` directory to understand what SVG masters exist. You'll reference these files throughout.

## Step 1: Validate brand-reference.yml

Before generating any output, run a thorough validation of the brand reference file.

### 1a. Schema Completeness

Check that every required section exists and has the minimum required fields:

| Section | Required fields | Minimum items |
|---------|----------------|---------------|
| `meta` | `brand_name`, `industry`, `generated_date`, `version` | — |
| `identity` | `mission`, `vision`, `values`, `positioning` | values ≥ 3, positioning has all 4 fields |
| `audience` | `primary_market`, `personas` | personas ≥ 2 |
| `voice` | `personality`, `spectrum`, `messaging`, `writing_samples` | personality ≥ 2, writing_samples ≥ 1 |
| `typography` | `primary`, `scale` | scale ≥ 3 levels |
| `colors` | `primary`, `neutrals`, `accessibility` | primary ≥ 1, neutrals ≥ 2, accessibility ≥ 1 |
| `visual` | `logo` | logo has `primary` |
| `content` | `dos`, `donts` | dos ≥ 1, donts ≥ 1 |
| `social` | `platforms` | platforms ≥ 2 |

If any section is missing or incomplete, list what's missing and tell the user which skill to re-run. Do NOT proceed to document generation with incomplete data.

### 1b. Cross-Reference Integrity

Verify that data references across sections are consistent:

| Check | What to verify |
|-------|---------------|
| Logo colors | Every color hex in logo SVGs exists in `colors.primary`, `colors.secondary`, or `colors.accent` |
| Logo fonts | Any font referenced in logo SVGs exists in `typography.primary` or `typography.secondary` (note: logos should use paths, not fonts — flag if fonts are embedded) |
| Social profile picture | `social.visual_rules.profile_picture` references a logo variant that exists in `assets.logo` or `visual.logo.variants` |
| Favicon colors | Colors in `assets/favicons/favicon.svg` match brand palette |
| Social images | Colors in `assets/social/*.svg` match brand palette |
| Persona channels → platforms | At least one channel from `audience.personas[].channels` maps to an active platform in `social.platforms` |
| Content type → social | If `content.content_types` includes "Social media", there should be corresponding `social.platforms` |

Report any broken references. For each, show the source location and what it references.

### 1c. Empty Field Check

Scan every field in brand-reference.yml. Flag any required field that is empty, null, or contains placeholder text like "TODO", "TBD", "[answer]", or "...".

**After validation:** Present a summary to the user:

```
Schema validation results:

✓ All 9 sections present
✓ Cross-references valid (or: ✗ 2 broken references — see below)
✓ No empty required fields (or: ✗ 3 empty fields — see below)

[Details of any issues]

Ready to generate deliverables? (or: Fix these issues first?)
```

Only proceed to Step 2 after all validation checks pass.

## Step 2: Generate brand-manual.md

Create a professional markdown document covering the complete brand guidelines. This is the human-readable version of everything in brand-reference.yml, written as an agency deliverable.

### Document Structure

```markdown
# [Brand Name] — Brand Guidelines

> Version [version] · [generated_date]

---

## Table of Contents

1. [About the Brand](#about-the-brand)
2. [Target Audience](#target-audience)
3. [Brand Voice](#brand-voice)
4. [Color System](#color-system)
5. [Typography](#typography)
6. [Logo Usage](#logo-usage)
7. [Visual Identity](#visual-identity)
8. [Content Rules](#content-rules)
9. [Social Media](#social-media)

---
```

### Section 1: About the Brand

Source: `meta` + `identity`

```markdown
## About the Brand

### Mission
[identity.mission]

### Vision
[identity.vision]

### Our Values

| Value | What it means |
|-------|--------------|
| [name] | [description] |
...

### Brand Story
[identity.brand_story — if present]

### Positioning

> For **[target]**, [brand_name] is the **[category]** that **[differentiator]** because **[proof]**.
```

### Section 2: Target Audience

Source: `audience`

```markdown
## Target Audience

**Primary market:** [audience.primary_market]

### [Persona 1 name] *(Primary)*
> "[quote]"

| | |
|---|---|
| **Role** | [role] |
| **Age** | [age_range] |

**Goals:** [bulleted list]
**Frustrations:** [bulleted list]
**Channels:** [bulleted list]
**Decision factors:** [bulleted list]

---

### [Persona 2 name]
[same format]
```

### Section 3: Brand Voice

Source: `voice`

```markdown
## Brand Voice

### Personality

| We are | We are not |
|--------|-----------|
| [attribute] | [not] |
...

[Include descriptions]

### Tone Spectrum

| Dimension | Level | |
|-----------|-------|---|
| Formality | [N]/10 | [visual bar: ████████░░] |
| Humor | [N]/10 | [visual bar] |
| Enthusiasm | [N]/10 | [visual bar] |
| Technicality | [N]/10 | [visual bar] |

### Key Messages

**Tagline:** [tagline]

**Value propositions:**
[bulleted list]

**Elevator pitch:**
[elevator_pitch]

**Boilerplate:**
[boilerplate]

### Writing Samples

| Context | ✓ Do | ✗ Don't | Why |
|---------|------|---------|-----|
| [context] | [good] | [bad] | [why] |
...
```

### Section 4: Color System

Source: `colors`

```markdown
## Color System

### Primary Colors

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| [name] | [hex] | [rgb] | [use] |
...

[Include tint/shade scale if present — show 50-900 values]

### Secondary Colors
[same table format]

### Accent Colors
[same table format]

### Neutrals

| Color | Hex | Usage |
|-------|-----|-------|
...

### Semantic Colors

| Purpose | Color |
|---------|-------|
| Success | [hex] |
| Warning | [hex] |
| Error | [hex] |
| Info | [hex] |

### Color Proportions

[proportions.rule] — [dominant] / [secondary] / [accent]

### Accessibility — Contrast Matrix

| Pair | Ratio | AA Normal | AA Large | AAA Normal |
|------|-------|-----------|----------|------------|
| [pair description] | [ratio] | [pass/fail] | [pass/fail] | [pass/fail] |
...

[Include colorblind notes if present]

### Dark Mode

[If dark_mode section exists, include background surfaces, text colors, and brand adjustments]
```

### Section 5: Typography

Source: `typography`

```markdown
## Typography

### Primary Font: [family]
**Use:** [use]
**Weights:** [weights joined]
**Source:** [source]

### Secondary Font: [family]
[same format]

### Type Scale

| Level | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| [level] | [size] | [weight] | [line_height] | [use] |
...
```

### Section 6: Logo Usage

Source: `visual.logo` + `assets.logo`

```markdown
## Logo Usage

### Logo Variants

| Variant | File | Use on |
|---------|------|--------|
| [name] | [file] | [use_on] |
...

### Clear Space
[clear_space rule]

### Minimum Size
[minimum_size — digital and print]

### Logo Misuse — Never Do These

[List each misuse rule as a numbered item with clear explanation]

1. ✗ [misuse rule 1]
2. ✗ [misuse rule 2]
...
```

### Section 7: Visual Identity

Source: `visual.imagery` + `visual.layout`

```markdown
## Visual Identity

### Imagery Style
**Style:** [imagery.style]
**Mood:** [imagery.mood]
**Subjects:** [imagery.subjects]
**Avoid:** [imagery.avoid]

### Layout
**Grid:** [layout.grid]
**Spacing:** [layout.spacing_principle]
**Alignment:** [layout.alignment]
```

### Section 8: Content Rules

Source: `content`

```markdown
## Content Rules

### Writing Dos
[bulleted list from content.dos]

### Writing Don'ts
[bulleted list from content.donts]

### Terminology

| Preferred | Instead of | Context |
|-----------|-----------|---------|
| [term] | [not] | [context] |
...

### Grammar & Style

| Rule | Standard |
|------|----------|
| Oxford comma | [yes/no] |
| Capitalization | [rule] |
| Numbers | [rule] |
| Date format | [format] |

### Content Type Specifications

[For each content_type: type, length, tone_adjustment, structure — formatted as subsections]

[Include SEO guidelines if present]
[Include review checklist if present]
```

### Section 9: Social Media

Source: `social`

```markdown
## Social Media

### Platform Guidelines

#### [Platform name]
**Audience:** [audience]
**Tone:** [tone_adjustment]
**Frequency:** [frequency]
**Post types:** [bulleted list]
**Hashtag strategy:** [strategy]
**Visual format:** [format]

[Repeat for each platform]

### Content Pillars
[If content_pillars present, list each with description and example topics]

### Engagement Rules
- **Response time:** [response_time]
- **Tone in replies:** [tone_in_replies]
- **Escalation:** [escalation]

**Never:**
[bulleted list from engagement.never]
```

### Footer

```markdown
---

## Appendix

### Asset Inventory

| Category | Location | Files |
|----------|----------|-------|
| Logo SVGs | assets/logo/svg/ | [list files] |
| Logo PNGs | assets/logo/png/ | [list files or "Generate with scripts/generate-assets.sh"] |
| Favicons | assets/favicons/ | [list files] |
| Social images | assets/social/ | [list files] |
| App icons | assets/app-icons/ | [generate with script] |

### Quick Reference

One-page summary of the most commonly needed brand elements:
- Brand name + tagline
- Primary color hex codes
- Font families
- Logo file paths
- Key voice attributes

---

*Generated by /brand:generate — [brand_name] Brand Guidelines v[version]*
*[generated_date]*
```

**After writing:** Confirm to the user how many sections were generated and the total line count.

## Step 3: Generate brand-manual.docx

Convert brand-manual.md to a formatted Word document.

### Method

Use `pandoc` if available:

```bash
pandoc brand-manual.md \
  -o brand-manual.docx \
  --from markdown \
  --to docx \
  --toc \
  --toc-depth=2 \
  --metadata title="[Brand Name] — Brand Guidelines" \
  --metadata date="[generated_date]"
```

If pandoc is not available:

1. Note that docx generation requires pandoc
2. Provide install instructions: `brew install pandoc` (macOS), `apt-get install pandoc` (Linux)
3. Skip this step — the markdown version is still fully usable

### Docx Requirements

- Table of contents generated from headings
- Proper heading hierarchy (H1 → H2 → H3)
- Tables formatted with borders
- Page numbers in footer
- Brand name in header

**Note:** Pandoc produces a functional docx. For agency-grade styling (brand colors in headings, logo on cover), the user can apply a custom Word template or use a reference docx. Mention this as an optional enhancement.

## Step 4: Generate Asset Conversion Script

Create `scripts/generate-assets.sh` — a comprehensive shell script that converts all SVG masters to their PNG derivatives.

### Script Structure

```bash
#!/bin/bash
# ============================================================
# Asset Generation Script for [Brand Name]
# Converts SVG master files to all required PNG sizes.
#
# Dependencies: ImageMagick (convert command)
# Install:
#   macOS:  brew install imagemagick
#   Linux:  apt-get install imagemagick
#   npm:    npm install -g sharp-cli (alternative)
#
# Usage: ./scripts/generate-assets.sh [brand-directory]
# Example: ./scripts/generate-assets.sh .ai/brands/my-company
# ============================================================

set -euo pipefail

BRAND_DIR="${1:-.}"

# Resolve to absolute path
BRAND_DIR="$(cd "$BRAND_DIR" && pwd)"

echo "Generating assets for brand directory: $BRAND_DIR"

# --------------------------------------------------
# Dependency check
# --------------------------------------------------
if ! command -v convert &> /dev/null; then
    echo "ERROR: ImageMagick not found."
    echo ""
    echo "Install it:"
    echo "  macOS:  brew install imagemagick"
    echo "  Linux:  apt-get install imagemagick"
    echo "  npm:    npm install -g sharp-cli"
    exit 1
fi

echo "ImageMagick found: $(convert --version | head -1)"

# --------------------------------------------------
# Helper: convert SVG to PNG at a given size
# --------------------------------------------------
svg_to_png() {
    local src="$1"
    local dst="$2"
    local size="$3"

    if [ ! -f "$src" ]; then
        echo "  SKIP: $src not found"
        return 1
    fi

    mkdir -p "$(dirname "$dst")"
    convert -background none -density 300 "$src" -resize "${size}" "$dst"
    echo "  OK: $dst (${size})"
}

# Helper: convert SVG to PNG with solid background (no transparency)
svg_to_png_solid() {
    local src="$1"
    local dst="$2"
    local size="$3"
    local bg_color="${4:-white}"

    if [ ! -f "$src" ]; then
        echo "  SKIP: $src not found"
        return 1
    fi

    mkdir -p "$(dirname "$dst")"
    convert -background "$bg_color" -density 300 "$src" -resize "${size}" -alpha remove "$dst"
    echo "  OK: $dst (${size}, solid bg: $bg_color)"
}

GENERATED=0
SKIPPED=0

# --------------------------------------------------
# 1. Logo PNGs (1x, 2x, 3x)
# --------------------------------------------------
echo ""
echo "=== Logo PNGs ==="

for variant in logo-full-light logo-full-dark logo-wordmark-light logo-wordmark-dark; do
    src="$BRAND_DIR/assets/logo/svg/${variant}.svg"
    for scale in 1 2 3; do
        size=$((300 * scale))
        dst="$BRAND_DIR/assets/logo/png/${variant}@${scale}x.png"
        if svg_to_png "$src" "$dst" "${size}x"; then
            ((GENERATED++))
        else
            ((SKIPPED++))
        fi
    done
done

# Mark-only variants (square, different base size)
for variant in logo-mark logo-mark-mono; do
    src="$BRAND_DIR/assets/logo/svg/${variant}.svg"
    for scale in 1 2 3; do
        size=$((128 * scale))
        dst="$BRAND_DIR/assets/logo/png/${variant}@${scale}x.png"
        if svg_to_png "$src" "$dst" "${size}x${size}"; then
            ((GENERATED++))
        else
            ((SKIPPED++))
        fi
    done
done

# --------------------------------------------------
# 2. Favicons
# --------------------------------------------------
echo ""
echo "=== Favicons ==="

ICON_SRC="$BRAND_DIR/assets/brand-icon/brand-icon.svg"
if [ ! -f "$ICON_SRC" ]; then
    ICON_SRC="$BRAND_DIR/assets/logo/svg/logo-mark.svg"
fi

for size in 16 32 48 96; do
    dst="$BRAND_DIR/assets/favicons/favicon-${size}.png"
    if svg_to_png "$ICON_SRC" "$dst" "${size}x${size}"; then
        ((GENERATED++))
    else
        ((SKIPPED++))
    fi
done

# Apple touch icon — solid background, no transparency
dst="$BRAND_DIR/assets/favicons/apple-touch-icon.png"
if svg_to_png_solid "$ICON_SRC" "$dst" "180x180"; then
    ((GENERATED++))
else
    ((SKIPPED++))
fi

# Windows tile
dst="$BRAND_DIR/assets/favicons/mstile-144.png"
if svg_to_png_solid "$ICON_SRC" "$dst" "144x144"; then
    ((GENERATED++))
else
    ((SKIPPED++))
fi

# Multi-size favicon.ico (16 + 32)
FAV16="$BRAND_DIR/assets/favicons/favicon-16.png"
FAV32="$BRAND_DIR/assets/favicons/favicon-32.png"
if [ -f "$FAV16" ] && [ -f "$FAV32" ]; then
    convert "$FAV16" "$FAV32" "$BRAND_DIR/assets/favicons/favicon.ico"
    echo "  OK: favicon.ico (multi-size: 16+32)"
    ((GENERATED++))
else
    echo "  SKIP: favicon.ico (missing favicon-16.png or favicon-32.png)"
    ((SKIPPED++))
fi

# --------------------------------------------------
# 3. iOS App Icons
# --------------------------------------------------
echo ""
echo "=== iOS App Icons ==="

for size in 40 58 60 76 80 87 120 152 167 180 1024; do
    dst="$BRAND_DIR/assets/app-icons/ios/icon-${size}.png"
    if svg_to_png_solid "$ICON_SRC" "$dst" "${size}x${size}"; then
        ((GENERATED++))
    else
        ((SKIPPED++))
    fi
done

# --------------------------------------------------
# 4. Android App Icons
# --------------------------------------------------
echo ""
echo "=== Android App Icons ==="

declare -A ANDROID_SIZES=(
    [mdpi]=48
    [hdpi]=72
    [xhdpi]=96
    [xxhdpi]=144
    [xxxhdpi]=192
    [playstore]=512
)

for density in "${!ANDROID_SIZES[@]}"; do
    size=${ANDROID_SIZES[$density]}
    dst="$BRAND_DIR/assets/app-icons/android/${density}.png"
    if svg_to_png "$ICON_SRC" "$dst" "${size}x${size}"; then
        ((GENERATED++))
    else
        ((SKIPPED++))
    fi
done

# --------------------------------------------------
# 5. PWA Icons
# --------------------------------------------------
echo ""
echo "=== PWA Icons ==="

for size in 72 96 128 144 152 192 384 512; do
    dst="$BRAND_DIR/assets/app-icons/pwa/icon-${size}.png"
    if svg_to_png "$ICON_SRC" "$dst" "${size}x${size}"; then
        ((GENERATED++))
    else
        ((SKIPPED++))
    fi
done

# --------------------------------------------------
# 6. Social Media Images
# --------------------------------------------------
echo ""
echo "=== Social Media Images ==="

social_files=("og-image:1200x630" "twitter-card:1200x675" "linkedin-banner:1584x396")
for entry in "${social_files[@]}"; do
    name="${entry%%:*}"
    dims="${entry##*:}"
    src="$BRAND_DIR/assets/social/${name}.svg"
    dst="$BRAND_DIR/assets/social/${name}.png"
    if svg_to_png "$src" "$dst" "$dims"; then
        ((GENERATED++))
    else
        ((SKIPPED++))
    fi
done

# --------------------------------------------------
# Summary
# --------------------------------------------------
echo ""
echo "============================================"
echo "Asset generation complete!"
echo "  Generated: $GENERATED files"
echo "  Skipped:   $SKIPPED files (source SVG not found)"
echo "============================================"

if [ "$SKIPPED" -gt 0 ]; then
    echo ""
    echo "Note: Skipped files are missing their source SVGs."
    echo "Run the relevant brand generation skills to create them first."
fi
```

**After writing:** Set the executable permission:

```bash
chmod +x scripts/generate-assets.sh
```

## Step 5: Generate Web Integration Files

### 5a. site.webmanifest

Path: `assets/favicons/site.webmanifest`

```json
{
  "name": "[brand_name]",
  "short_name": "[brand_name — truncated to 12 chars if needed]",
  "description": "[identity.mission — first sentence]",
  "start_url": "/",
  "display": "standalone",
  "background_color": "[colors.neutrals white hex or #FFFFFF]",
  "theme_color": "[colors.primary[0].hex]",
  "icons": [
    {
      "src": "/assets/app-icons/pwa/icon-72.png",
      "sizes": "72x72",
      "type": "image/png"
    },
    {
      "src": "/assets/app-icons/pwa/icon-96.png",
      "sizes": "96x96",
      "type": "image/png"
    },
    {
      "src": "/assets/app-icons/pwa/icon-128.png",
      "sizes": "128x128",
      "type": "image/png"
    },
    {
      "src": "/assets/app-icons/pwa/icon-144.png",
      "sizes": "144x144",
      "type": "image/png"
    },
    {
      "src": "/assets/app-icons/pwa/icon-152.png",
      "sizes": "152x152",
      "type": "image/png"
    },
    {
      "src": "/assets/app-icons/pwa/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/assets/app-icons/pwa/icon-384.png",
      "sizes": "384x384",
      "type": "image/png"
    },
    {
      "src": "/assets/app-icons/pwa/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

### 5b. browserconfig.xml

Path: `assets/favicons/browserconfig.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<browserconfig>
  <msapplication>
    <tile>
      <square70x70logo src="/assets/app-icons/pwa/icon-72.png"/>
      <square150x150logo src="/assets/app-icons/pwa/icon-152.png"/>
      <square310x310logo src="/assets/app-icons/pwa/icon-384.png"/>
      <TileColor>[colors.primary[0].hex]</TileColor>
    </tile>
  </msapplication>
</browserconfig>
```

### 5c. HTML Head Snippet

Path: `html-head-snippet.html`

Generate the full set of link and meta tags for favicons, icons, and theme color:

```html
<!-- Favicons -->
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="icon" href="/assets/favicons/favicon-32.png" type="image/png" sizes="32x32">
<link rel="icon" href="/assets/favicons/favicon-16.png" type="image/png" sizes="16x16">
<link rel="shortcut icon" href="/assets/favicons/favicon.ico">

<!-- Apple -->
<link rel="apple-touch-icon" sizes="180x180" href="/assets/favicons/apple-touch-icon.png">
<link rel="mask-icon" href="/assets/favicons/safari-pinned-tab.svg" color="[colors.primary[0].hex]">

<!-- PWA -->
<link rel="manifest" href="/assets/favicons/site.webmanifest">

<!-- Windows -->
<meta name="msapplication-TileColor" content="[colors.primary[0].hex]">
<meta name="msapplication-config" content="/assets/favicons/browserconfig.xml">

<!-- Theme -->
<meta name="theme-color" content="[colors.primary[0].hex]" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="[dark_mode.background.base or #1a1a2e]" media="(prefers-color-scheme: dark)">

<!-- Open Graph -->
<meta property="og:image" content="/assets/social/og-image.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">

<!-- Twitter -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:image" content="/assets/social/twitter-card.png">
```

## Step 6: Generate Brand Preview Page

Path: `preview/brand-preview.html`

Create a self-contained HTML page (no external dependencies) that shows the complete brand at a glance. All styles are inline. All data is embedded directly from brand-reference.yml.

### Preview Page Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[Brand Name] — Brand Preview</title>
  <style>
    /* Embed brand fonts via Google Fonts @import or system fallbacks */
    /* Use brand colors throughout */
    /* Light/dark mode toggle */
    /* Responsive layout */
  </style>
</head>
<body>
```

The page must include these sections:

**1. Header**
- Brand name and tagline
- Light/dark toggle button (JavaScript — no dependencies)

**2. Logo Gallery**
- Show all logo variants as inline SVGs or img references
- Light background and dark background side by side
- Show mark, wordmark, and full logo variants

**3. Color Palette**
- Each color as a swatch card showing:
  - Color name
  - Hex code (click to copy)
  - RGB value
  - Usage description
- Include tint/shade scales if present
- Show the contrast matrix as a visual grid

**4. Typography Samples**
- Display each type scale level using the actual font
- Show: level name, size, weight, sample text
- If Google Fonts, include @import in the style block

**5. Voice Summary**
- Personality attributes as "We are / We are not" cards
- Tone spectrum as visual bars
- Key messages: tagline, elevator pitch

**6. Audience Overview**
- Compact persona cards with name, role, quote, top goals

**7. Asset File Index**
- Table of all generated assets with relative paths
- Status indicator: generated vs. pending (needs script)

**Footer:**
- "Generated by /brand:generate" with version and date

### Interactive Features

The preview page should include minimal JavaScript (embedded, no CDN) for:

1. **Light/dark mode toggle** — Swaps background, text colors, and shows the appropriate logo variants
2. **Click-to-copy on color hex codes** — Copies to clipboard with visual feedback
3. **Smooth scroll navigation** — Sticky nav bar with section links

Keep the total page size under 100KB (excluding referenced images).

## Step 7: Run Asset Conversion (Conditional)

After generating the script, attempt to run it:

```bash
# Check if ImageMagick is available
if command -v convert &> /dev/null; then
    ./scripts/generate-assets.sh "$BRAND_DIR"
fi
```

**If ImageMagick is available:** Run the script and report results (generated count, skipped count).

**If ImageMagick is not available:** Inform the user:

```
ImageMagick is not installed, so PNG assets were not generated.
All SVG masters are ready. To generate PNGs:

1. Install ImageMagick:
   macOS:  brew install imagemagick
   Linux:  apt-get install imagemagick

2. Run the script:
   ./scripts/generate-assets.sh [brand-directory]
```

## Step 8: Version Stamp

After writing brand-reference.yml, call the version-meta-stamper skill
(plugins/task-planner/skills/version-meta-stamper/SKILL.md) to
add/update the `_meta` block with the current plugin version.

This ensures every brand-reference.yml file is traceable to the plugin
version that created it. The `_meta` block is added at the end of the
file with `plugin_name: "brand-guideline"` and `plugin_version` set to
the current version from `plugins/brand-guideline/.claude-plugin/plugin.json`.

## Step 9: Final Summary

After all deliverables are generated, present a complete summary:

```
Brand generation complete for [Brand Name]!

Documents:
  ✓ brand-manual.md — [N] sections, [L] lines
  ✓ brand-manual.docx — [generated/skipped (requires pandoc)]

Scripts & Integration:
  ✓ scripts/generate-assets.sh — executable
  ✓ assets/favicons/site.webmanifest
  ✓ assets/favicons/browserconfig.xml
  ✓ html-head-snippet.html

Preview:
  ✓ preview/brand-preview.html

Asset Conversion:
  ✓ [N] PNGs generated / [skipped if ImageMagick not available]

Next: QA review is mandatory before this brand is marked complete.
```

## Checkpoint: schema_validation + file_validation

After all outputs are written, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `schema_valid` | brand-reference.yml has all 9 required sections with minimum fields | List missing sections, re-run corresponding skill |
| `cross_references` | All cross-references resolve (colors, fonts, logo variants, persona channels) | List broken references with source → target |
| `manual_sections` | brand-manual.md has all 9 sections | Identify and generate missing sections |
| `docx_valid` | brand-manual.docx exists and is valid (if pandoc available) | Regenerate |
| `script_executable` | scripts/generate-assets.sh exists and has +x | Create and chmod |
| `webmanifest_valid` | site.webmanifest is valid JSON with name, icons, theme_color | Regenerate |
| `preview_html` | brand-preview.html exists with brand color/font/logo references | Regenerate |

**On pass:** Update `state.yml` → mark phase 9 complete. Trigger QA agent.

**On fail:** Fix issues and re-run. Max 3 rounds. Do NOT mark complete.

## QA Review

This is **mandatory** — the implementing agent does not self-grade.

After checkpoint passes, hand off to the QA agent with this context:

```
QA review requested for: [brand_name] brand generation (all phases)
Brand directory: [path]

Files to review:
1. brand-reference.yml — complete schema validation
2. brand-manual.md — all 9 sections present and well-written
3. brand-manual.docx — valid document (if generated)
4. scripts/generate-assets.sh — correct, executable, handles errors
5. site.webmanifest — valid JSON, correct icon paths
6. browserconfig.xml — valid XML
7. html-head-snippet.html — correct link/meta tags
8. preview/brand-preview.html — renders correctly, interactive features work
9. All SVG assets — well-formed, use brand colors, correct dimensions

Acceptance criteria:
- No placeholder text in any output
- All cross-references resolve
- Color accessibility data is complete
- Logo misuse rules are included
- Voice writing samples match the defined personality
- Social platform guidelines are consistent with audience personas
```

The QA agent reviews all outputs and either:
- **Approves** → Brand generation is complete
- **Rejects with findings** → Fix issues and re-submit

## Recovery Notes

After QA passes, write final recovery notes to `state.yml`:

```
Brand: [name] ([industry])
Status: COMPLETE
Phases completed: 9/9
Documents: brand-manual.md, brand-manual.docx
Assets: [count] SVGs, [count] PNGs generated
Script: scripts/generate-assets.sh
Preview: preview/brand-preview.html
Web integration: site.webmanifest, browserconfig.xml, html-head-snippet.html
QA: Approved by QA agent on [date]
```
