# Brand Asset Manifest
## Complete list of assets the brand guideline plugin must generate

---

## Overview

The `/brand:generate` command produces all assets below. They are saved to:

```
.ai/brands/[brand-name]/
├── brand-reference.yml          # Machine-readable (plugins read this)
├── brand-manual.md              # Human-readable document
├── brand-manual.docx            # Human-readable document (formatted)
│
├── assets/
│   ├── logo/
│   │   ├── svg/                 # ← Master source files (never delete these)
│   │   │   ├── logo-full-light.svg       # Full logo for light backgrounds
│   │   │   ├── logo-full-dark.svg        # Full logo for dark backgrounds
│   │   │   ├── logo-wordmark-light.svg   # Text-only version, light bg
│   │   │   ├── logo-wordmark-dark.svg    # Text-only version, dark bg
│   │   │   ├── logo-mark.svg            # Icon/symbol only (no text)
│   │   │   └── logo-mark-mono.svg       # Monochrome mark
│   │   │
│   │   └── png/                 # Auto-generated from SVGs
│   │       ├── logo-full-light@1x.png
│   │       ├── logo-full-light@2x.png
│   │       ├── logo-full-light@3x.png
│   │       ├── logo-full-dark@1x.png
│   │       ├── logo-full-dark@2x.png
│   │       └── logo-full-dark@3x.png
│   │
│   ├── brand-icon/
│   │   ├── brand-icon.svg               # Simplified mark for small contexts
│   │   ├── brand-icon-light.svg         # For dark backgrounds
│   │   ├── brand-icon-dark.svg          # For light backgrounds
│   │   └── brand-icon-mono.svg          # Single color
│   │
│   ├── favicons/
│   │   ├── favicon.svg                  # Master SVG with dark mode support
│   │   ├── favicon.ico                  # Multi-size ICO (16 + 32)
│   │   ├── favicon-16.png
│   │   ├── favicon-32.png
│   │   ├── favicon-48.png
│   │   ├── favicon-96.png
│   │   ├── apple-touch-icon.png         # 180x180, solid background
│   │   ├── mstile-144.png              # Windows tile
│   │   ├── safari-pinned-tab.svg        # Monochrome SVG
│   │   ├── browserconfig.xml            # Windows tile config
│   │   └── site.webmanifest             # PWA manifest with icon refs
│   │
│   ├── app-icons/
│   │   ├── ios/
│   │   │   ├── icon-40.png
│   │   │   ├── icon-58.png
│   │   │   ├── icon-60.png
│   │   │   ├── icon-76.png
│   │   │   ├── icon-80.png
│   │   │   ├── icon-87.png
│   │   │   ├── icon-120.png
│   │   │   ├── icon-152.png
│   │   │   ├── icon-167.png
│   │   │   ├── icon-180.png
│   │   │   └── icon-1024.png            # App Store
│   │   │
│   │   ├── android/
│   │   │   ├── mdpi.png                 # 48x48
│   │   │   ├── hdpi.png                 # 72x72
│   │   │   ├── xhdpi.png               # 96x96
│   │   │   ├── xxhdpi.png              # 144x144
│   │   │   ├── xxxhdpi.png             # 192x192
│   │   │   └── playstore.png           # 512x512
│   │   │
│   │   └── pwa/
│   │       ├── icon-72.png
│   │       ├── icon-96.png
│   │       ├── icon-128.png
│   │       ├── icon-144.png
│   │       ├── icon-152.png
│   │       ├── icon-192.png
│   │       ├── icon-384.png
│   │       └── icon-512.png
│   │
│   ├── social/
│   │   ├── og-image.png                 # Open Graph — 1200x630
│   │   ├── twitter-card.png             # Twitter/X — 1200x675
│   │   └── linkedin-banner.png          # LinkedIn — 1584x396
│   │
│   └── icons/                           # Custom brand icon library
│       ├── icon-library.svg             # All icons in one sprite sheet
│       ├── individual/
│       │   ├── icon-arrow-right.svg
│       │   ├── icon-check.svg
│       │   ├── icon-close.svg
│       │   ├── icon-menu.svg
│       │   ├── icon-search.svg
│       │   ├── icon-user.svg
│       │   ├── icon-mail.svg
│       │   ├── icon-phone.svg
│       │   ├── icon-location.svg
│       │   ├── icon-calendar.svg
│       │   ├── icon-download.svg
│       │   ├── icon-external-link.svg
│       │   ├── icon-share.svg
│       │   ├── icon-heart.svg
│       │   ├── icon-star.svg
│       │   ├── icon-settings.svg
│       │   ├── icon-notification.svg
│       │   ├── icon-cart.svg
│       │   └── ... (extends based on brand needs)
│       └── react/                       # Optional: React components
│           └── Icons.tsx                # Auto-generated from SVGs
│
└── preview/
    └── brand-preview.html               # Interactive preview page
```

---

## Asset-by-Asset Specifications

### 1. SVG Logo System

**What:** The primary logo in all variants needed for web, app, and print.

**Variants required:**

| Variant | File | When to use |
|---------|------|-------------|
| Full logo — light bg | `logo-full-light.svg` | Primary use on white/light backgrounds |
| Full logo — dark bg | `logo-full-dark.svg` | On dark backgrounds, photography |
| Wordmark — light bg | `logo-wordmark-light.svg` | When space is tight horizontally |
| Wordmark — dark bg | `logo-wordmark-dark.svg` | Wordmark on dark backgrounds |
| Mark only | `logo-mark.svg` | App icons, favicons, avatars, small spaces |
| Monochrome mark | `logo-mark-mono.svg` | Single-color contexts, watermarks |

**SVG rules (enforced by the skill):**
- Self-contained — no external fonts, no linked images
- Meaningful group IDs for each element (e.g., `<g id="wordmark">`, `<g id="icon">`)
- viewBox set correctly, no fixed width/height (allows infinite scaling)
- Optimized — no unnecessary paths, groups, or metadata
- Under 5KB per file ideally (definitely under 15KB)
- All text converted to paths (no font dependencies)

**Generation method:** Claude Code generates SVG code directly. This is its strongest asset generation capability. The skill dispatches multiple sub-agents in parallel to produce 20-25 concepts, then narrows through guided iteration.

**Tools required:** None — pure SVG output from Claude Code.

**Refinement:** Optionally import into Figma or Illustrator for curve cleanup and precise kerning.

---

### 2. Brand Icon

**What:** A simplified version of the logo mark, optimized for contexts where the full logo is too complex. Think: app icon shape, social media avatar, watermark.

**Rules:**
- Must be recognizable at 32x32px
- Works in a circle crop (social avatars) and a square crop (app icons)
- No fine details that disappear at small sizes
- Has light, dark, and monochrome variants
- If the logo mark is already simple enough, this may be the same file

**Generation method:** Derived from the logo mark SVG. Claude simplifies the mark, tests at small sizes, and generates variants.

---

### 3. Favicons

**What:** Browser tab icons, bookmarks bar, home screen shortcuts.

**The modern favicon stack (2025-2026 standard):**

| File | Size | Purpose |
|------|------|---------|
| `favicon.svg` | Scalable | Modern browsers — with dark mode CSS media query |
| `favicon.ico` | 16+32 multi | Legacy browser fallback |
| `favicon-16.png` | 16x16 | Specific fallback |
| `favicon-32.png` | 32x32 | Standard browser tab |
| `favicon-48.png` | 48x48 | Windows taskbar |
| `favicon-96.png` | 96x96 | Google TV, high-DPI shortcuts |
| `apple-touch-icon.png` | 180x180 | iOS home screen (solid bg, no transparency!) |
| `mstile-144.png` | 144x144 | Windows Start tiles |
| `safari-pinned-tab.svg` | Scalable | Safari pinned tab (monochrome only) |
| `site.webmanifest` | — | PWA manifest linking to icons |
| `browserconfig.xml` | — | Windows tile configuration |

**Critical details:**
- `favicon.svg` MUST include a CSS `@media (prefers-color-scheme: dark)` rule to adapt for dark mode — 80%+ of mobile users run dark mode
- `apple-touch-icon.png` MUST have a solid background (no transparency) — iOS adds an ugly black bg otherwise
- `favicon.ico` MUST contain both 16x16 and 32x32 sizes or it will be blurry
- Keep SVG favicon under 1KB for zero page-load impact

**Dark mode SVG example:**
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <style>
    .icon { fill: #1E3A8A; }
    @media (prefers-color-scheme: dark) {
      .icon { fill: #93C5FD; }
    }
  </style>
  <path class="icon" d="..."/>
</svg>
```

**Generation method:** Claude Code generates the master SVG. A bundled shell script (using ImageMagick `convert`) generates all PNG sizes and the .ico file from the SVG source.

**Dependencies:** ImageMagick (for PNG/ICO conversion). Installed via:
- macOS: `brew install imagemagick`
- Ubuntu: `apt-get install imagemagick`
- Cross-platform: `npm install -g sharp-cli`

**HTML output** (the plugin should also generate the correct head tags):
```html
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="icon" href="/favicon-32.png" type="image/png" sizes="32x32">
<link rel="icon" href="/favicon-16.png" type="image/png" sizes="16x16">
<link rel="shortcut icon" href="/favicon.ico">
<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">
<link rel="manifest" href="/site.webmanifest">
<meta name="msapplication-TileColor" content="#ffffff">
<meta name="msapplication-config" content="/browserconfig.xml">
<meta name="theme-color" content="#ffffff">
```

---

### 4. App Icons

**What:** Icons for native iOS apps, Android apps, and PWA installs.

**Key difference from favicons:** App icons typically use the brand icon on a solid colored background with rounded corners (iOS applies rounding automatically — never bake rounded corners into the image).

**iOS requirements:**
All sizes as PNG, no transparency, no rounded corners (system applies them).

| Size | Usage |
|------|-------|
| 40x40 | iPad Spotlight (20pt@2x) |
| 58x58 | iPhone Settings (29pt@2x) |
| 60x60 | iPhone Notification (20pt@3x) |
| 76x76 | iPad App (76pt@1x) |
| 80x80 | iPad Spotlight (40pt@2x) |
| 87x87 | iPhone Settings (29pt@3x) |
| 120x120 | iPhone App (60pt@2x) |
| 152x152 | iPad App (76pt@2x) |
| 167x167 | iPad Pro (83.5pt@2x) |
| 180x180 | iPhone App (60pt@3x) |
| 1024x1024 | App Store |

**Android requirements:**
PNG with optional transparency, following Material Design adaptive icon specs.

| Density | Size | Folder |
|---------|------|--------|
| mdpi | 48x48 | res/mipmap-mdpi |
| hdpi | 72x72 | res/mipmap-hdpi |
| xhdpi | 96x96 | res/mipmap-xhdpi |
| xxhdpi | 144x144 | res/mipmap-xxhdpi |
| xxxhdpi | 192x192 | res/mipmap-xxxhdpi |
| Play Store | 512x512 | — |

**PWA requirements:**
| Size | Usage |
|------|-------|
| 72x72 | Small screen splash |
| 96x96 | Medium screen |
| 128x128 | Desktop shortcut |
| 144x144 | Windows tile |
| 152x152 | iPad fallback |
| 192x192 | Android home screen |
| 384x384 | Large display |
| 512x512 | Splash screen / Store |

**Generation method:** Claude Code generates the master SVG icon (brand-icon.svg on a colored background), then a shell script batch-converts to all sizes using ImageMagick or sharp-cli.

---

### 5. Social Media Images

**What:** Default sharing images when pages are shared on social platforms.

| Asset | Dimensions | Platform |
|-------|-----------|----------|
| `og-image.png` | 1200x630 | Facebook, LinkedIn, general Open Graph |
| `twitter-card.png` | 1200x675 | X / Twitter summary_large_image |
| `linkedin-banner.png` | 1584x396 | LinkedIn company page banner |

**Content:** Logo centered on brand-colored background with tagline. Clean and simple — these are defaults. Individual pages/posts can override with specific images.

**Generation method:** Claude Code generates as SVG at the correct dimensions, then converts to PNG. Or generates directly using HTML canvas if running in a browser context.

---

### 6. Custom Icon Library

**What:** A set of SVG icons that match the brand's visual style, used across the website, app, and marketing materials.

**Why not just use Lucide/Heroicons/etc.?** You can — and the skill should recommend a base icon set as a starting point. But brand-specific icons (for your product features, industry concepts, or unique UI elements) should match the brand's visual language: same stroke weight, same corner radius, same level of detail.

**Base set (minimum 18 icons):**

| Category | Icons |
|----------|-------|
| Navigation | arrow-right, arrow-left, menu, close, search, external-link |
| Actions | download, upload, share, heart, star, check |
| Communication | mail, phone, chat, notification |
| Commerce | cart, credit-card |
| Utility | user, settings, calendar, location, clock |

**Icon design rules (enforced by the skill):**
- Consistent stroke width across all icons (e.g., 1.5px or 2px)
- Consistent viewBox (24x24 is standard)
- Consistent corner radius (e.g., 2px rounded joins)
- No fills unless the brand style calls for it — outline style by default
- Use `currentColor` for fill/stroke so icons inherit text color
- Each icon under 1KB
- Accessible: all icons get a descriptive `<title>` element

**Output formats:**
- Individual SVGs in `icons/individual/`
- Combined SVG sprite sheet in `icons/icon-library.svg`
- Optional: React component file `icons/react/Icons.tsx` that exports each icon as a component

**Generation method:** Claude Code generates SVG code for each icon. The skill enforces visual consistency by defining the rules (stroke width, corner radius, viewBox) once and applying them to every icon.

**Expansion:** After the initial set, new icons can be added by describing what's needed — Claude generates them following the established rules from the brand reference.

---

## Updated brand-reference.yml Asset Section

```yaml
# --------------------------------------------------
# ASSETS (references to generated files)
# --------------------------------------------------
assets:
  logo:
    full_light: "assets/logo/svg/logo-full-light.svg"
    full_dark: "assets/logo/svg/logo-full-dark.svg"
    wordmark_light: "assets/logo/svg/logo-wordmark-light.svg"
    wordmark_dark: "assets/logo/svg/logo-wordmark-dark.svg"
    mark: "assets/logo/svg/logo-mark.svg"
    mark_mono: "assets/logo/svg/logo-mark-mono.svg"
    clear_space: "Minimum clear space equal to the height of the mark on all sides"
    minimum_size:
      digital: "24px height"
      print: "10mm height"
    misuse:
      - "Never stretch or distort proportions"
      - "Never change brand colors"
      - "Never place on busy backgrounds without overlay"
      - "Never add shadows, gradients, or outlines"
      - "Never rotate the logo"
      - "Never rearrange logo elements"

  brand_icon:
    default: "assets/brand-icon/brand-icon.svg"
    light: "assets/brand-icon/brand-icon-light.svg"
    dark: "assets/brand-icon/brand-icon-dark.svg"
    mono: "assets/brand-icon/brand-icon-mono.svg"

  favicons:
    svg: "assets/favicons/favicon.svg"
    ico: "assets/favicons/favicon.ico"
    apple_touch: "assets/favicons/apple-touch-icon.png"
    manifest: "assets/favicons/site.webmanifest"
    html_snippet: |
      <link rel="icon" href="/favicon.svg" type="image/svg+xml">
      <link rel="icon" href="/favicon-32.png" type="image/png" sizes="32x32">
      <link rel="shortcut icon" href="/favicon.ico">
      <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">
      <link rel="manifest" href="/site.webmanifest">
      <meta name="theme-color" content="#ffffff">

  app_icons:
    source: "assets/brand-icon/brand-icon.svg"
    background_color: "#FFFFFF"
    ios_directory: "assets/app-icons/ios/"
    android_directory: "assets/app-icons/android/"
    pwa_directory: "assets/app-icons/pwa/"

  social:
    og_image: "assets/social/og-image.png"
    twitter_card: "assets/social/twitter-card.png"
    linkedin_banner: "assets/social/linkedin-banner.png"

  icon_library:
    sprite: "assets/icons/icon-library.svg"
    individual_dir: "assets/icons/individual/"
    style:
      stroke_width: "1.5px"
      viewbox: "0 0 24 24"
      corner_radius: "2px"
      fill: "none"
      stroke: "currentColor"
      stroke_linecap: "round"
      stroke_linejoin: "round"
    count: 18  # Updated after generation
    react_components: "assets/icons/react/Icons.tsx"
```

---

## Dependencies & Conversion Script

The plugin should include a `scripts/generate-assets.sh` that automates PNG generation from SVGs:

```bash
#!/bin/bash
# Requires: ImageMagick (convert) or sharp-cli
# Run after SVG master files are finalized

BRAND_DIR="$1"  # e.g., .ai/brands/my-company

# Check dependencies
if ! command -v convert &> /dev/null; then
    echo "ImageMagick not found. Install:"
    echo "  macOS: brew install imagemagick"
    echo "  Linux: apt-get install imagemagick"
    echo "  npm:   npm install -g sharp-cli"
    exit 1
fi

# Logo PNGs from SVGs
for variant in logo-full-light logo-full-dark; do
    for scale in 1 2 3; do
        size=$((300 * scale))
        convert "$BRAND_DIR/assets/logo/svg/${variant}.svg" \
            -resize ${size}x${size} \
            "$BRAND_DIR/assets/logo/png/${variant}@${scale}x.png"
    done
done

# Favicons
convert "$BRAND_DIR/assets/brand-icon/brand-icon.svg" \
    -resize 16x16 "$BRAND_DIR/assets/favicons/favicon-16.png"
convert "$BRAND_DIR/assets/brand-icon/brand-icon.svg" \
    -resize 32x32 "$BRAND_DIR/assets/favicons/favicon-32.png"
convert "$BRAND_DIR/assets/brand-icon/brand-icon.svg" \
    -resize 48x48 "$BRAND_DIR/assets/favicons/favicon-48.png"
convert "$BRAND_DIR/assets/brand-icon/brand-icon.svg" \
    -resize 96x96 "$BRAND_DIR/assets/favicons/favicon-96.png"

# Apple touch icon (solid background, no transparency)
convert "$BRAND_DIR/assets/brand-icon/brand-icon.svg" \
    -resize 180x180 \
    -background "$(grep background_color $BRAND_DIR/brand-reference.yml | awk '{print $2}')" \
    -alpha remove \
    "$BRAND_DIR/assets/favicons/apple-touch-icon.png"

# Multi-size favicon.ico
convert "$BRAND_DIR/assets/favicons/favicon-16.png" \
        "$BRAND_DIR/assets/favicons/favicon-32.png" \
        "$BRAND_DIR/assets/favicons/favicon.ico"

# iOS icons
for size in 40 58 60 76 80 87 120 152 167 180 1024; do
    convert "$BRAND_DIR/assets/brand-icon/brand-icon.svg" \
        -resize ${size}x${size} \
        -background white -alpha remove \
        "$BRAND_DIR/assets/app-icons/ios/icon-${size}.png"
done

# Android icons
declare -A android=( [mdpi]=48 [hdpi]=72 [xhdpi]=96 [xxhdpi]=144 [xxxhdpi]=192 [playstore]=512 )
for density in "${!android[@]}"; do
    size=${android[$density]}
    convert "$BRAND_DIR/assets/brand-icon/brand-icon.svg" \
        -resize ${size}x${size} \
        "$BRAND_DIR/assets/app-icons/android/${density}.png"
done

# PWA icons
for size in 72 96 128 144 152 192 384 512; do
    convert "$BRAND_DIR/assets/brand-icon/brand-icon.svg" \
        -resize ${size}x${size} \
        "$BRAND_DIR/assets/app-icons/pwa/icon-${size}.png"
done

# Social images (logo centered on brand-colored background)
# These are generated by Claude as HTML/SVG — not from the icon
echo "Social images should be generated by the social-media skill"

echo "✅ All assets generated successfully"
```

---

## Updated Plugin Structure

```
brand-guideline/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── brand-generate.md
│   ├── brand-analyze.md
│   ├── brand-audit.md
│   ├── brand-switch.md
│   └── brand-export-assets.md     # NEW — regenerate all PNGs from SVGs
├── skills/
│   ├── brand-context-loader/
│   │   └── SKILL.md
│   ├── visual-identity/
│   │   └── SKILL.md               # Now includes full logo design process
│   ├── typography-color/
│   │   └── SKILL.md               # Now includes accessibility validation
│   ├── tone-of-voice/
│   │   └── SKILL.md
│   ├── audience-personas/
│   │   └── SKILL.md
│   ├── content-rules/
│   │   └── SKILL.md
│   ├── social-media/
│   │   └── SKILL.md
│   ├── favicon-generator/          # NEW
│   │   └── SKILL.md
│   ├── app-icon-generator/         # NEW
│   │   └── SKILL.md
│   └── icon-library/               # NEW
│       └── SKILL.md
├── scripts/
│   ├── generate-assets.sh          # NEW — batch convert SVGs to all sizes
│   └── validate-accessibility.sh   # NEW — check all color pairs
└── resources/
    ├── templates/
    │   ├── brand-reference-schema.yml
    │   ├── manual-structure.md
    │   ├── persona-card.md
    │   ├── site.webmanifest.template    # NEW
    │   └── browserconfig.xml.template   # NEW
    └── examples/
        ├── sample-voice-spectrum.md
        └── sample-favicon-dark-mode.svg # NEW
```

---

## Summary

**Total assets generated per brand:**

| Category | Files | Method |
|----------|-------|--------|
| Logo SVGs | 6 variants | Claude Code generates SVG directly |
| Logo PNGs | 6 at 3 scales = 18 | ImageMagick from SVG |
| Brand icon | 4 variants (SVG) | Claude Code generates SVG |
| Favicons | 11 files + manifest + config | SVG by Claude, PNGs via script |
| iOS app icons | 11 sizes | Script from brand icon SVG |
| Android app icons | 6 densities | Script from brand icon SVG |
| PWA icons | 8 sizes | Script from brand icon SVG |
| Social images | 3 platform-specific | Claude Code generates |
| Icon library | 18+ individual SVGs + sprite + React | Claude Code generates SVG |
| Documents | 3 (yml + md + docx) | Claude Code generates |
| Preview | 1 interactive HTML | Claude Code generates |

**Total: ~85+ files per brand, from one `/brand:generate` run.**
