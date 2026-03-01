# Check Templates — Per-Checkpoint-Type Checklists

These templates tell the spec-compliance-reviewer what to look for based
on the checkpoint type declared in the target skill's frontmatter.

---

## data_validation

Used by skills that write structured YAML sections (most brand and SEO skills).

### File Existence
- The YAML file referenced in `writes` exists
- If `writes` references sections (e.g., `file.yml#section`), the parent
  file exists

### Schema Presence — Per Brand Skill

| Skill | Section | Required Top-Level Keys |
|-------|---------|------------------------|
| identity-interview | `meta` | name, industry, website |
| identity-interview | `identity` | mission, vision, values, positioning |
| audience-personas | `audience` | personas (array, ≥1 item) |
| tone-of-voice | `voice` | spectrum, attributes, writing_samples |
| typography-color | `colors` | primary, secondary, neutral |
| typography-color | `typography` | fonts, type_scale, weights |
| visual-identity | `visual_identity` | style, iconography, layout |
| logo-design | `logo` | variants, clear_space, minimum_sizes |
| content-rules | `content_rules` | writing_standards, content_types |
| social-media | `social_media` | platforms, pillars, hashtags |

### Schema Presence — Per SEO Skill

| Skill | Section | Required Top-Level Keys |
|-------|---------|------------------------|
| project-interview | `meta` | project_name, website_url |
| project-interview | `business_context` | industry, target_audience |
| keyword-research | `keywords` | primary (array, ≥1), secondary (array) |
| competitor-analysis | `competitors` | array with ≥1 entry, each has domain |
| on-page-strategy | `on_page` | title_templates, meta_descriptions |
| content-planning | `content_plan` | calendar (array, ≥1 entry) |
| technical-seo | `technical` | crawlability, performance, structured_data |
| link-building | `link_building` | strategies (array, ≥1) |

### Non-Empty
- No YAML section is null or empty object/array
- String values are not empty or whitespace-only
- Arrays have at least one item with substantive content

### State Consistency
- state.yml phase entry exists with matching skill name
- Status is not `pending`

---

## accessibility_validation

Used by typography-color and any skill that produces color data.

### File Existence
- `brand-reference.yml` exists with `colors` and `typography` sections

### Schema Presence
- `colors.primary` has hex value
- `colors.contrast_pairs` or `colors.contrast_matrix` exists
- `colors.dark_mode` section exists (if brand specifies dark mode)
- `typography.fonts` has at least one font family
- `typography.type_scale` has entries for body and heading levels

### Non-Empty
- Every color entry has: name, hex, rgb, usage
- Every contrast pair has: foreground, background, ratio
- Font entries have: family, weights, source

### Additional (Accessibility-Specific)
- Contrast ratio values are numeric (not placeholder strings)
- WCAG threshold fields reference correct standard (AA vs AAA)
- Colorblind notes exist per primary color (can be brief)

---

## schema_validation

Used by compile-and-export and final validation skills.

### File Existence
- All files in the `writes` list exist
- For glob patterns: at least one match per pattern
- Generated scripts are executable (`chmod +x`)

### Schema Presence
- For brand-reference.yml: all 9 sections present (identity, audience,
  voice, colors, typography, visual_identity, logo, content_rules,
  social_media)
- For seo output: all expected sections per the seo schema
- `_meta` block present with plugin_version and schema_version

### Non-Empty
- No section in the final YAML is empty
- Markdown deliverables have content under every heading
- HTML files are valid (contain `<html>` and `<body>` or are fragments)
- Shell scripts have at least one command beyond the shebang

### Cross-References
- Colors referenced in typography samples exist in the colors section
- Font names in typography match those in visual_identity (if referenced)
- Logo variants referenced in content_rules exist in the logo section
- All internal references resolve

---

## output_review

Used by skills that produce non-YAML deliverables (documents, scripts, HTML).

### File Existence
- Every declared output file exists at the expected path
- File extensions match expected type (.md, .html, .sh, .docx)

### Non-Empty
- Markdown: has content beyond just headings
- HTML: contains structured content (not just boilerplate)
- Shell scripts: contain commands, not just comments
- DOCX: file size suggests content (> 1KB typically)

### State Consistency
- Artifacts list in state.yml matches the files actually produced
- No artifacts listed that don't exist on disk

---

## consistency_check

Used when verifying cross-skill coherence (typically during final review).

### Cross-References to Verify

| Source | References | Target |
|--------|-----------|--------|
| colors.contrast_pairs | color names | colors.palette entries |
| typography.fonts | font names | visual_identity.typography_rules |
| logo.variants | color references | colors.primary, colors.secondary |
| content_rules.tone | voice attributes | voice.attributes |
| social_media.visual | color/font refs | colors + typography sections |
| seo keywords | brand terms | identity.positioning |

### State Consistency
- All phases marked `completed` in state.yml
- No unresolved errors in `errors` array
- `current_phase` reflects the final phase or is cleared
