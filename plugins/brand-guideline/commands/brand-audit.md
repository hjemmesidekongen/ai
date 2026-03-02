---
name: brand-audit
command: "/brand:audit"
description: "Audit an existing brand-reference.yml and its assets for gaps, inconsistencies, and accessibility issues"
arguments:
  - name: brand
    type: string
    required: false
    description: "Brand slug to audit. Defaults to the currently active brand (from .ai/active-brand.yml)."
---

# /brand:audit

Audits an existing brand-reference.yml and its generated assets for completeness, internal consistency, WCAG accessibility compliance, and asset integrity. Run after `/brand:generate` to verify quality, or anytime the brand has been manually edited.

## Usage

```
/brand:audit                      # audit the active brand
/brand:audit --brand "acme-corp"  # audit a specific brand
```

## How It Works

This is a single-pass audit — no task-planner, no waves, no checkpoints. It reads brand-reference.yml and the assets directory, runs all checks, and produces a report with severity levels and fix suggestions.

## Execution

### Step 0 — Load Brand Context

```
Use brand-context-loader to resolve the target brand:
  1. If --brand flag provided → use that brand
  2. Otherwise → follow the standard fallback chain (active-brand.yml → auto-discover → ask)

brand_dir = ".ai/brands/[brand]/"
ref_path = brand_dir + "brand-reference.yml"
assets_dir = brand_dir + "assets/"

if not exists(ref_path):
  ERROR: "No brand-reference.yml found at [ref_path]. Run /brand:generate first."
  STOP

ref = read_yaml(ref_path)
if ref is malformed:
  ERROR: "brand-reference.yml has YAML parse errors at line [N]. Fix before auditing."
  STOP

Report: "Auditing brand: [ref.meta.brand_name] ([brand_slug])"
```

---

### Step 1 — Completeness Check

Validate brand-reference.yml against the full schema (brand-reference-schema.yml). Score every field.

```
schema = load("resources/templates/brand-reference-schema.yml")

total_required = 0
total_filled = 0
missing_required = []
empty_optional = []
placeholder_values = []

for each field in schema (recursively):
  path = field's dot-notation path (e.g. "identity.mission", "colors.primary[0].hex")

  if field.required:
    total_required += 1
    value = get_value(ref, path)

    if value is missing or null:
      missing_required.append({
        path: path,
        severity: "CRITICAL",
        message: "Required field missing",
        fix: "Run /brand:generate or add manually"
      })
    elif is_placeholder(value):
      # Detect placeholders: "TODO", "TBD", "CHANGE ME", "[placeholder]", "Lorem ipsum"
      total_filled += 1
      placeholder_values.append({
        path: path,
        value: value,
        severity: "WARNING",
        message: "Contains placeholder value",
        fix: "Replace with actual brand data"
      })
    else:
      total_filled += 1

  else:  # optional field
    value = get_value(ref, path)
    if value is missing or null:
      empty_optional.append({
        path: path,
        severity: "INFO",
        message: "Optional field not populated",
        fix: "Consider adding for richer brand data"
      })

# Section-level scoring
sections = [meta, identity, visual, typography, colors, voice, audience, content, social]
section_scores = {}
for each section in sections:
  section_required = count required fields in section
  section_filled = count filled required fields in section
  section_scores[section] = { filled: section_filled, total: section_required }

completeness_score = round(total_filled / total_required * 100)
```

**Output:**
```
## Completeness: [completeness_score]%

| Section     | Score   | Status |
|-------------|---------|--------|
| meta        | 6/6     | ✓      |
| identity    | 8/8     | ✓      |
| visual      | 3/7     | ⚠      |
| typography  | 12/12   | ✓      |
| colors      | 18/22   | ⚠      |
| voice       | 10/10   | ✓      |
| audience    | 8/8     | ✓      |
| content     | 0/4     | ✗      |
| social      | 5/5     | ✓      |

Missing required fields:
- [CRITICAL] content.dos — Required field missing → Run /brand:generate or add manually
- [CRITICAL] content.donts — Required field missing → ...

Placeholder values:
- [WARNING] identity.brand_story — Contains "Lorem ipsum..." → Replace with actual brand data
```

---

### Step 2 — Consistency Check

Cross-reference integrity across sections. Each check verifies that data referenced in one section actually exists in another.

```
consistency_issues = []

# 2a. Colors in logo SVGs match color palette
if ref.visual.logo exists:
  for each logo_variant in list_svg_files(assets_dir + "logo/svg/"):
    svg_colors = extract_hex_colors_from_svg(logo_variant)
    palette_colors = collect_all_hex_from(ref.colors)

    for each svg_color in svg_colors:
      if svg_color not in palette_colors:
        consistency_issues.append({
          severity: "WARNING",
          check: "logo-color-mismatch",
          message: "Logo [variant] uses [svg_color] which is not in the color palette",
          fix: "Add [svg_color] to the palette or update the logo SVG"
        })

# 2b. Fonts in visual_identity match typography section
if ref.visual exists AND ref.typography exists:
  visual_fonts = extract_font_references(ref.visual)
  declared_fonts = [ref.typography.primary.family]
  if ref.typography.secondary:
    declared_fonts.append(ref.typography.secondary.family)

  for each font in visual_fonts:
    if font not in declared_fonts:
      consistency_issues.append({
        severity: "WARNING",
        check: "font-mismatch",
        message: "Visual identity references font '[font]' not declared in typography",
        fix: "Add '[font]' to typography section or update visual identity"
      })

# 2c. Voice attributes align with writing samples
if ref.voice.personality exists AND ref.voice.writing_samples exists:
  personality_attrs = [p.attribute for p in ref.voice.personality]
  for each sample in ref.voice.writing_samples:
    # Heuristic: check if the "good" example contradicts personality
    # e.g., personality says "Professional" but sample is very casual
    alignment = assess_voice_alignment(personality_attrs, sample.good)
    if alignment.conflicts:
      consistency_issues.append({
        severity: "WARNING",
        check: "voice-sample-mismatch",
        message: "Writing sample for '[sample.context]' may not reflect '[alignment.conflicting_attr]' personality",
        fix: "Review the 'good' example — does it sound [alignment.conflicting_attr]?"
      })

# 2d. Social media profile_picture_variant references a real logo variant
if ref.social.platforms exists AND ref.visual.logo exists:
  available_variants = list logo variant names from ref.visual.logo
  for each platform in ref.social.platforms:
    if platform.visual_format references a logo variant:
      variant_ref = extract_variant_reference(platform)
      if variant_ref AND variant_ref not in available_variants:
        consistency_issues.append({
          severity: "WARNING",
          check: "social-logo-variant",
          message: "[platform.name] references logo variant '[variant_ref]' which doesn't exist",
          fix: "Use one of: [available_variants]"
        })

# 2e. Content rules readability target vs. audience
if ref.content exists AND ref.audience exists:
  if ref.content has readability_target:
    audience_type = infer_audience_type(ref.audience)
    # B2B technical → grade 12 OK, consumer → grade 8 expected
    if audience_type == "consumer" AND readability_target > 10:
      consistency_issues.append({
        severity: "WARNING",
        check: "readability-audience-mismatch",
        message: "Readability target (grade [readability_target]) is high for a consumer audience",
        fix: "Consider lowering to grade 8-10 for better consumer accessibility"
      })
    elif audience_type == "b2b_technical" AND readability_target < 8:
      consistency_issues.append({
        severity: "INFO",
        check: "readability-audience-note",
        message: "Readability target (grade [readability_target]) is simple for a B2B technical audience",
        fix: "This may be intentional — verify it matches your communication goals"
      })
```

---

### Step 3 — Accessibility Audit

Re-compute ALL contrast ratios from scratch. Never trust pre-computed values — colors may have been manually changed.

```
accessibility_issues = []

# 3a. Re-compute contrast ratios for every accessible_pair
color_categories = [ref.colors.primary, ref.colors.secondary, ref.colors.accent]
for each category in color_categories:
  if category is null: continue

  for each color in category:
    if color.accessible_pairs is null:
      accessibility_issues.append({
        severity: "CRITICAL",
        check: "missing-contrast-data",
        message: "[color.name] has no accessible_pairs defined",
        fix: "Run the typography-color skill to generate contrast data"
      })
      continue

    for each pair in color.accessible_pairs:
      actual_ratio = compute_contrast_ratio(pair.foreground, pair.background)

      # Check if stored ratio matches actual
      if abs(actual_ratio - pair.contrast_ratio) > 0.1:
        accessibility_issues.append({
          severity: "WARNING",
          check: "stale-contrast-ratio",
          message: "[color.name] pair [pair.foreground]/[pair.background]: stored ratio [pair.contrast_ratio], actual [actual_ratio]",
          fix: "Update the contrast_ratio to [actual_ratio] and re-check WCAG pass/fail flags"
        })

      # WCAG AA normal text: 4.5:1
      if actual_ratio < 4.5 AND pair.wcag_aa_normal == true:
        accessibility_issues.append({
          severity: "CRITICAL",
          check: "wcag-aa-fail",
          message: "[pair.foreground] on [pair.background] fails WCAG AA normal text ([actual_ratio]:1 < 4.5:1) but is marked as passing",
          fix: "Set wcag_aa_normal to false, or adjust colors to achieve 4.5:1"
        })
      elif actual_ratio >= 4.5 AND pair.wcag_aa_normal == false:
        accessibility_issues.append({
          severity: "INFO",
          check: "wcag-aa-undermarked",
          message: "[pair.foreground] on [pair.background] passes WCAG AA ([actual_ratio]:1) but is marked as failing",
          fix: "Set wcag_aa_normal to true"
        })

      # WCAG AA large text: 3:1
      if actual_ratio < 3.0 AND pair.wcag_aa_large == true:
        accessibility_issues.append({
          severity: "CRITICAL",
          check: "wcag-aa-large-fail",
          message: "[pair.foreground] on [pair.background] fails WCAG AA large text ([actual_ratio]:1 < 3:1) but is marked as passing",
          fix: "Set wcag_aa_large to false, or adjust colors to achieve 3:1"
        })

# 3b. Check the legacy accessibility array too (colors.accessibility)
if ref.colors.accessibility exists:
  for each entry in ref.colors.accessibility:
    # Parse the foreground/background from the pair description
    # Re-compute and verify
    actual_ratio = compute_contrast_ratio_from_pair_description(entry, ref.colors)
    if actual_ratio is not null:
      stored = parse_ratio_string(entry.contrast_ratio)  # "4.56:1" → 4.56
      if abs(actual_ratio - stored) > 0.1:
        accessibility_issues.append({
          severity: "WARNING",
          check: "legacy-contrast-stale",
          message: "Accessibility entry '[entry.pair]': stored [entry.contrast_ratio], actual [actual_ratio]:1",
          fix: "Update contrast_ratio to '[actual_ratio]:1'"
        })

# 3c. Colorblind safety notes present and complete
for each category in color_categories:
  if category is null: continue
  for each color in category:
    if color.colorblind_notes is null:
      accessibility_issues.append({
        severity: "WARNING",
        check: "missing-colorblind-notes",
        message: "[color.name] has no colorblind_notes",
        fix: "Add protanopia, deuteranopia, and tritanopia assessments"
      })
    else:
      for each type in [protanopia, deuteranopia, tritanopia]:
        if color.colorblind_notes[type] is null or empty:
          accessibility_issues.append({
            severity: "WARNING",
            check: "incomplete-colorblind-notes",
            message: "[color.name] is missing [type] assessment",
            fix: "Add a [type] visibility note"
          })

# 3d. Dark mode contrast compliance
if ref.colors.dark_mode exists:
  if ref.colors.dark_mode.accessible_pairs is null or empty:
    accessibility_issues.append({
      severity: "CRITICAL",
      check: "dark-mode-no-contrast",
      message: "Dark mode defined but has no accessible_pairs",
      fix: "Add validated contrast pairs for dark mode backgrounds"
    })
  else:
    for each pair in ref.colors.dark_mode.accessible_pairs:
      actual_ratio = compute_contrast_ratio(pair.foreground, pair.background)
      if actual_ratio < 4.5:
        accessibility_issues.append({
          severity: "CRITICAL",
          check: "dark-mode-contrast-fail",
          message: "Dark mode: [pair.foreground] on [pair.background] fails AA ([actual_ratio]:1 < 4.5:1)",
          fix: "Adjust dark mode colors — lighten foreground or darken background"
        })

# 3e. Logo readable at minimum sizes
if ref.visual.logo.minimum_size exists:
  min_size = parse_size(ref.visual.logo.minimum_size.digital)  # e.g., "24px" → 24
  if min_size < 16:
    accessibility_issues.append({
      severity: "WARNING",
      check: "logo-min-size",
      message: "Logo minimum digital size ([min_size]px) is below 16px — may be unreadable",
      fix: "Set minimum_size.digital to at least 16px, preferably 24px"
    })

# 3f. No information conveyed by color alone
if ref.colors.semantic exists:
  semantic_colors = [success, warning, error, info]
  has_icon_guidance = false
  # Check if content rules or elsewhere mention icon alternatives
  if ref.content exists:
    has_icon_guidance = any mention of "icon" + "color" in content rules
  if not has_icon_guidance:
    accessibility_issues.append({
      severity: "WARNING",
      check: "color-only-meaning",
      message: "Semantic colors defined but no guidance found for pairing with icons/labels",
      fix: "Add a content rule: 'Never rely on color alone — always pair semantic colors with icons or text labels'"
    })
```

#### Contrast Ratio Computation

Use the WCAG 2.2 relative luminance formula:

```
function compute_contrast_ratio(hex1, hex2):
  L1 = relative_luminance(hex1)
  L2 = relative_luminance(hex2)
  lighter = max(L1, L2)
  darker = min(L1, L2)
  return (lighter + 0.05) / (darker + 0.05)

function relative_luminance(hex):
  r, g, b = parse_hex_to_rgb(hex)  # 0-255 each
  # Convert to sRGB
  rs = r / 255
  gs = g / 255
  bs = b / 255
  # Linearize
  r_lin = rs / 12.92 if rs <= 0.04045 else ((rs + 0.055) / 1.055) ^ 2.4
  g_lin = gs / 12.92 if gs <= 0.04045 else ((gs + 0.055) / 1.055) ^ 2.4
  b_lin = bs / 12.92 if bs <= 0.04045 else ((bs + 0.055) / 1.055) ^ 2.4
  return 0.2126 * r_lin + 0.7152 * g_lin + 0.0722 * b_lin
```

---

### Step 4 — Asset Audit

Verify all expected files from brand-asset-manifest.md exist and meet quality standards.

```
asset_issues = []

# 4a. Check expected files exist
# Build expected file list from brand-reference.yml asset references + manifest spec

expected_svgs = [
  "assets/logo/svg/logo-full-light.svg",
  "assets/logo/svg/logo-full-dark.svg",
  "assets/logo/svg/logo-wordmark-light.svg",
  "assets/logo/svg/logo-wordmark-dark.svg",
  "assets/logo/svg/logo-mark.svg",
  "assets/logo/svg/logo-mark-mono.svg"
]

expected_brand_icons = [
  "assets/brand-icon/brand-icon.svg",
  "assets/brand-icon/brand-icon-light.svg",
  "assets/brand-icon/brand-icon-dark.svg",
  "assets/brand-icon/brand-icon-mono.svg"
]

expected_favicons = [
  "assets/favicons/favicon.svg",
  "assets/favicons/favicon.ico",
  "assets/favicons/favicon-16.png",
  "assets/favicons/favicon-32.png",
  "assets/favicons/favicon-48.png",
  "assets/favicons/favicon-96.png",
  "assets/favicons/apple-touch-icon.png",
  "assets/favicons/mstile-144.png",
  "assets/favicons/safari-pinned-tab.svg",
  "assets/favicons/site.webmanifest",
  "assets/favicons/browserconfig.xml"
]

expected_social = [
  "assets/social/og-image.png",
  "assets/social/twitter-card.png",
  "assets/social/linkedin-banner.png"
]

all_expected = expected_svgs + expected_brand_icons + expected_favicons + expected_social

for each file_path in all_expected:
  full_path = brand_dir + file_path
  if not exists(full_path):
    # SVG master files are critical, PNGs are warning (can be regenerated)
    severity = "CRITICAL" if file_path.endsWith(".svg") else "WARNING"
    asset_issues.append({
      severity: severity,
      check: "missing-asset",
      message: "[file_path] not found",
      fix: "Run /brand:generate to create, or scripts/generate-assets.sh for PNGs"
    })

# 4b. SVG validity checks
for each svg_file in find_files(assets_dir, "*.svg"):
  content = read_file(svg_file)

  # Well-formed XML
  if not is_valid_xml(content):
    asset_issues.append({
      severity: "CRITICAL",
      check: "svg-invalid-xml",
      message: "[svg_file] is not well-formed XML",
      fix: "Fix XML syntax errors in the SVG"
    })
    continue  # can't check further

  # viewBox present
  if "viewBox" not in content:
    asset_issues.append({
      severity: "WARNING",
      check: "svg-no-viewbox",
      message: "[svg_file] has no viewBox attribute — will not scale correctly",
      fix: "Add a viewBox attribute to the root <svg> element"
    })

  # File size check (flag over 15KB)
  size_kb = file_size_bytes(svg_file) / 1024
  if size_kb > 15:
    asset_issues.append({
      severity: "WARNING",
      check: "svg-large-file",
      message: "[svg_file] is [size_kb]KB (target: under 15KB)",
      fix: "Optimize SVG — remove unnecessary paths, metadata, or embedded assets"
    })
  elif size_kb > 5 AND is_favicon_or_icon(svg_file):
    asset_issues.append({
      severity: "INFO",
      check: "svg-icon-size",
      message: "[svg_file] is [size_kb]KB — icons/favicons should ideally be under 1KB",
      fix: "Simplify the icon for smaller file size"
    })

# 4c. Favicon dark mode CSS media query
favicon_svg = brand_dir + "assets/favicons/favicon.svg"
if exists(favicon_svg):
  content = read_file(favicon_svg)
  if "prefers-color-scheme" not in content:
    asset_issues.append({
      severity: "WARNING",
      check: "favicon-no-dark-mode",
      message: "favicon.svg has no dark mode CSS media query",
      fix: "Add @media (prefers-color-scheme: dark) { ... } inside a <style> block"
    })

# 4d. Apple touch icon — no transparency
apple_icon = brand_dir + "assets/favicons/apple-touch-icon.png"
if exists(apple_icon):
  if has_transparency(apple_icon):
    asset_issues.append({
      severity: "CRITICAL",
      check: "apple-icon-transparency",
      message: "apple-touch-icon.png has transparency — iOS will add a black background",
      fix: "Re-generate with a solid background color using -alpha remove in ImageMagick"
    })

  # Check dimensions (should be 180x180)
  dims = get_image_dimensions(apple_icon)
  if dims != (180, 180):
    asset_issues.append({
      severity: "WARNING",
      check: "apple-icon-dimensions",
      message: "apple-touch-icon.png is [dims] — expected 180x180",
      fix: "Re-generate at 180x180 from the brand icon SVG"
    })

# 4e. PNG dimension checks (spot-check key sizes)
png_checks = {
  "assets/favicons/favicon-16.png": (16, 16),
  "assets/favicons/favicon-32.png": (32, 32),
  "assets/favicons/favicon-48.png": (48, 48),
  "assets/favicons/favicon-96.png": (96, 96),
  "assets/favicons/mstile-144.png": (144, 144),
  "assets/social/og-image.png": (1200, 630),
  "assets/social/twitter-card.png": (1200, 675),
  "assets/social/linkedin-banner.png": (1584, 396)
}

for each path, expected_dims in png_checks:
  full = brand_dir + path
  if exists(full):
    actual = get_image_dimensions(full)
    if actual != expected_dims:
      asset_issues.append({
        severity: "WARNING",
        check: "png-wrong-dimensions",
        message: "[path] is [actual] — expected [expected_dims]",
        fix: "Re-generate from SVG at the correct dimensions"
      })
```

---

### Step 5 — Generate Report

Combine all issues from Steps 1-4 into a structured report.

```
all_issues = completeness_issues + consistency_issues + accessibility_issues + asset_issues

# Count by severity
critical_count = count(all_issues where severity == "CRITICAL")
warning_count = count(all_issues where severity == "WARNING")
info_count = count(all_issues where severity == "INFO")

# Calculate overall score
total_checks = count of all checks performed across all 4 sections
passed_checks = total_checks - critical_count - warning_count
overall_score = round(passed_checks / total_checks * 100)

# Determine overall status
if critical_count > 0:
  status = "FAIL — [critical_count] critical issue(s) must be fixed"
elif warning_count > 0:
  status = "PASS WITH WARNINGS — [warning_count] issue(s) should be fixed"
else:
  status = "PASS — all checks passed"
```

#### Report: brand-audit-report.md

Write to `.ai/brands/[brand]/brand-audit-report.md`:

```markdown
# Brand Audit Report: [brand_name]
Generated: [ISO 8601 timestamp]
Brand: [brand_slug] (v[ref.meta.version])

## Overall Score: [overall_score]%
**Status:** [status]

| Severity | Count |
|----------|-------|
| CRITICAL | [critical_count] |
| WARNING  | [warning_count] |
| INFO     | [info_count] |

---

## 1. Completeness ([completeness_score]%)

[section scores table]
[list of missing/placeholder issues]

## 2. Consistency

[list of cross-reference issues, or "All consistency checks passed."]

## 3. Accessibility

[list of contrast/colorblind/dark-mode issues, or "All accessibility checks passed."]

### WCAG Contrast Summary
| Pair | Ratio | AA Normal | AA Large | Status |
|------|-------|-----------|----------|--------|
[table of all pairs with pass/fail]

## 4. Assets

[list of missing/invalid/oversized asset issues, or "All asset checks passed."]

### Asset Inventory
| Category | Expected | Found | Missing |
|----------|----------|-------|---------|
| Logo SVGs | 6 | [n] | [n] |
| Brand icons | 4 | [n] | [n] |
| Favicons | 11 | [n] | [n] |
| Social images | 3 | [n] | [n] |

---

## Recommended Actions

### Must Fix (CRITICAL)
[numbered list of critical issues with fix instructions]

### Should Fix (WARNING)
[numbered list of warnings with fix instructions]

### Optional (INFO)
[numbered list of info items]
```

#### Report: brand-audit-report.yml

Write to `.ai/brands/[brand]/brand-audit-report.yml`:

```yaml
meta:
  brand: "[brand_slug]"
  brand_name: "[brand_name]"
  audited_at: "[ISO 8601]"
  schema_version: "[ref.meta.version]"
  audit_version: "1.0"

summary:
  overall_score: [N]
  status: "[FAIL|PASS_WITH_WARNINGS|PASS]"
  critical: [N]
  warning: [N]
  info: [N]

completeness:
  score: [N]
  total_required: [N]
  total_filled: [N]
  sections:
    - name: "meta"
      filled: [N]
      total: [N]
    # ... all 9 sections
  issues:
    - path: "content.dos"
      severity: "CRITICAL"
      message: "Required field missing"
      fix: "Run /brand:generate or add manually"

consistency:
  issues:
    - check: "logo-color-mismatch"
      severity: "WARNING"
      message: "..."
      fix: "..."

accessibility:
  issues:
    - check: "wcag-aa-fail"
      severity: "CRITICAL"
      message: "..."
      fix: "..."
  contrast_pairs:
    - foreground: "#2563EB"
      background: "#FFFFFF"
      ratio: 4.56
      wcag_aa_normal: true
      wcag_aa_large: true

assets:
  issues:
    - check: "missing-asset"
      severity: "CRITICAL"
      path: "assets/logo/svg/logo-full-light.svg"
      message: "..."
      fix: "..."
  inventory:
    logo_svgs: { expected: 6, found: [N], missing: [N] }
    brand_icons: { expected: 4, found: [N], missing: [N] }
    favicons: { expected: 11, found: [N], missing: [N] }
    social_images: { expected: 3, found: [N], missing: [N] }
```

---

## Output Files

| File | Location | Purpose |
|------|----------|---------|
| `brand-audit-report.md` | `.ai/brands/[brand]/` | Human-readable audit report |
| `brand-audit-report.yml` | `.ai/brands/[brand]/` | Machine-readable audit data |

---

## Checkpoint

**Type:** `schema_validation`

**Required checks:**
- Audit report generated with all 4 sections (Completeness, Consistency, Accessibility, Assets)
- Every issue has a severity level (`CRITICAL`, `WARNING`, or `INFO`) and a fix suggestion
- Overall score calculated as percentage of passed checks

**Verification:**
```
report_md = brand_dir + "brand-audit-report.md"
report_yml = brand_dir + "brand-audit-report.yml"

assert exists(report_md), "brand-audit-report.md not generated"
assert exists(report_yml), "brand-audit-report.yml not generated"

yml = read_yaml(report_yml)
assert yml.summary.overall_score is number, "Overall score missing"
assert yml.completeness is not null, "Completeness section missing"
assert yml.consistency is not null, "Consistency section missing"
assert yml.accessibility is not null, "Accessibility section missing"
assert yml.assets is not null, "Assets section missing"

# Verify every issue has required fields
all_issues = yml.completeness.issues + yml.consistency.issues + yml.accessibility.issues + yml.assets.issues
for each issue in all_issues:
  assert issue.severity in ["CRITICAL", "WARNING", "INFO"]
  assert issue.message is not empty
  assert issue.fix is not empty
```

---

## Error Handling

| Error | Action |
|-------|--------|
| `.ai/brands/` doesn't exist | Create it. Report: "No brands found." |
| Brand slug not found | Show error + list available brands. |
| `brand-reference.yml` missing | ERROR and stop — nothing to audit. |
| `brand-reference.yml` is malformed YAML | Show parse error with line number. Do not proceed. |
| `assets/` directory missing | Report all assets as missing. Continue with other checks. |
| SVG file can't be parsed as XML | Report as CRITICAL. Continue checking other files. |
| Image dimensions can't be read | Report as WARNING. Suggest checking file integrity. |

---

## What This Command Does NOT Do

- Does not modify brand-reference.yml or any assets (read-only audit)
- Does not use the task-planner (single-pass, no waves or checkpoints)
- Does not fix issues automatically — it reports them with fix suggestions
- Does not validate brand data quality (e.g., "is this a good tagline?") — only structural checks
- Does not check external resources (font availability, URL validity)
