# Brand Loader — Detailed Process

## Step 1: Locate Brand Data

```
project_name = active project from agency.yml
brand_dir = .ai/projects/{project_name}/brand/
brand_ref = brand_dir + "brand-reference.yml"

if not exists(brand_ref):
  ERROR: "No brand-reference.yml found at {brand_ref}"
  HINT: "Copy your brand-reference.yml to {brand_dir} or run /agency:init with --brand to load brand data"
  STOP
```

## Step 2: Read and Validate

```
brand = read_yaml(brand_ref)

# Validate minimum required sections
required_sections = ["meta", "colors", "typography"]
for section in required_sections:
  if section not in brand:
    WARN: "Missing section: {section} — some design tokens will be empty"

Report: "Loaded brand: {brand.meta.brand_name} ({brand.meta.industry})"
Report: "Sections found: {list of present sections}"
```

## Step 3: Extract Design Tokens

Extract design-friendly tokens from brand-reference.yml:

```yaml
# Output: brand-summary.yml
_meta:
  source: "brand-reference.yml"
  extracted_at: "[timestamp]"
  brand_name: "[from meta]"

tokens:
  colors:
    primary: "[from colors.primary_palette]"
    secondary: "[from colors.secondary_palette]"
    accent: "[from colors.accent_colors]"
    neutrals: "[from colors.neutral_palette]"
    semantic:
      success: "[if defined]"
      warning: "[if defined]"
      error: "[if defined]"
      info: "[if defined]"

  typography:
    heading_family: "[from typography.heading.family]"
    body_family: "[from typography.body.family]"
    mono_family: "[from typography.code.family, if present]"
    base_size: "[from typography.type_scale.base_size]"
    scale_ratio: "[from typography.type_scale.ratio]"
    weights:
      regular: 400
      medium: 500
      semibold: 600
      bold: 700

  spacing:
    base: "4px"
    scale: [4, 8, 12, 16, 24, 32, 48, 64, 96]
    # Derived from type scale if not explicitly defined

  voice:
    personality: "[from voice.brand_personality]"
    tone_spectrum: "[from voice.tone_spectrum]"
```

**Save extraction results to findings.md (2-Action Rule checkpoint):**

```markdown
## Brand Load Results
- Brand name: [name]
- Colors extracted: [count] (primary, secondary, accent, neutrals)
- Typography: [heading_family], [body_family]
- Spacing: [step count] steps
- Loaded at: [timestamp]
```

## Step 4: Register Assets

Append entries to .ai/projects/{project_name}/asset-registry.yml:

```yaml
- id: "brand-reference-yml"
  name: "Brand Reference"
  type: "document"
  format: "yml"
  path: ".ai/projects/{name}/brand/brand-reference.yml"
  producer: "brand/brand-loader"
  consumers: ["design/design-tokens", "design/logo-assets", "content/app-copy"]
  tags: ["brand", "reference", "source-of-truth"]
  created_at: "[now]"
  status: "final"

- id: "brand-summary-tokens"
  name: "Brand Design Tokens (Summary)"
  type: "design-token"
  format: "yml"
  path: ".ai/projects/{name}/brand/brand-summary.yml"
  producer: "brand/brand-loader"
  consumers: ["design/design-tokens", "design/component-specs", "dev/scaffold"]
  tags: ["tokens", "colors", "typography", "spacing", "brand"]
  created_at: "[now]"
  status: "final"
```

## Step 5: Report

```
Report:
  "Brand loaded: {brand_name}"
  "Tokens extracted: {color_count} colors, {font_count} fonts, {spacing_steps} spacing steps"
  "Assets registered: 2 entries in asset-registry.yml"
  "Ready for design module"
```

## Error Handling

| Error | Action |
|-------|--------|
| brand-reference.yml not found | Error with path hint |
| YAML parse error | Report line number, stop |
| Missing colors section | Warn, write empty tokens |
| Missing typography section | Warn, use system defaults |
| asset-registry.yml doesn't exist | Create it with just brand entries |

Log all errors to `state.yml` errors array. Before retrying, check errors array for previous attempts — never repeat a failed approach.

---

## Trace Protocol

If `state.yml` has `trace.enabled: true`, follow the
[trace protocol](../../../../resources/trace-protocol.md) to write a structured
trace file to `.ai/projects/[name]/traces/`.
