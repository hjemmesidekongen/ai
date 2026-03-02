---
name: brand-analyze
command: "/brand:analyze"
description: "(brand) Reverse-engineer brand guidelines from existing materials — websites, documents, or social profiles"
arguments:
  - name: url
    type: string
    required: false
    description: "Website URL to scrape (homepage + key pages). Extracts colors, fonts, logo, copy, meta tags."
  - name: docs
    type: string[]
    required: false
    description: "File paths to existing brand documents, style guides, pitch decks, or PDFs."
  - name: social
    type: string[]
    required: false
    description: "Social media profile URLs to analyze tone, posting patterns, hashtags, visual style."
  - name: brand
    type: string
    required: false
    description: "Brand slug for the output directory. If omitted, derived from the brand name found during analysis."
  - name: merge
    type: boolean
    required: false
    default: false
    description: "Merge into an existing brand-reference.yml instead of creating a new one."
---

# /brand:analyze

Reverse-engineers brand guidelines from existing materials. The user provides a website URL, uploaded documents, social media profiles, or any combination — and the command produces a draft `brand-reference.yml` with confidence markers on every field.

## Usage

```
/brand:analyze --url https://example.com
/brand:analyze --docs "./brand-guide.pdf" "./pitch-deck.pdf"
/brand:analyze --social "https://linkedin.com/company/example" "https://x.com/example"
/brand:analyze --url https://example.com --docs "./style-guide.pdf" --social "https://x.com/example"
/brand:analyze --url https://example.com --merge --brand existing-brand
```

At least one of `--url`, `--docs`, or `--social` is required.

## Architecture

Unlike `/brand:generate`, this command does **not** use the task-planner. It's a single-pass analysis:

```
Gather → Analyze → Infer → Draft → Present → Validate
```

There's no multi-wave execution because all data gathering happens up front, and the analysis is a single reasoning pass over all collected evidence.

The output uses the **same brand-reference.yml schema** as `/brand:generate`, so the result is immediately usable by all brand-aware plugins via `brand-context-loader`.

## Execution Steps

### Step 0: Validate Inputs

1. Check that at least one input source is provided (`--url`, `--docs`, or `--social`)
2. If none provided:
   ```
   At least one source is required:
     --url https://example.com          (website to scrape)
     --docs "./file.pdf"                (brand documents)
     --social "https://x.com/example"   (social profiles)

   You can combine multiple sources for better results.
   ```
3. If `--merge` is set, verify that `.ai/brands/[brand]/brand-reference.yml` exists
4. If `--url` is provided, validate it's a well-formed URL

Report to user:

```
## Brand Analyzer

I'll reverse-engineer brand guidelines from your existing materials.

Sources:
  [✓] Website: https://example.com
  [✓] Documents: style-guide.pdf, pitch-deck.pdf
  [✗] Social media: (not provided)

This produces a draft brand-reference.yml with confidence markers on every field.
Let's start gathering data.
```

### Step 1: Gather Data

Collect raw brand signals from all provided sources. Run all source types in parallel where possible.

#### 1A: Website Scraping (if `--url` provided)

Fetch the homepage and up to 3 key pages (about, product/services, contact — detected from navigation links). For each page, extract:

**Visual signals:**
- Colors from CSS: background-color, color, border-color, accent-color properties. Count frequency of each hex value. Ignore standard browser defaults (#000, #fff unless they're clearly branded).
- Fonts from CSS: font-family declarations, @font-face rules, Google Fonts / Adobe Fonts stylesheet links. Note which fonts are used for headings vs body.
- Logo: `<img>` in `<header>` or `<nav>`, favicon links (`<link rel="icon">`), apple-touch-icon, OG image (`<meta property="og:image">`).
- Layout patterns: max-width of content containers, grid usage, overall spacing feel.

**Content signals:**
- Page titles and meta descriptions
- H1-H3 heading text (captures messaging hierarchy)
- Hero/above-the-fold copy (usually the first `<section>` or `<main>` content)
- CTA button text (captures action language)
- Footer content (often has mission statement, tagline, boilerplate)
- OG tags: `og:title`, `og:description`, `og:site_name`
- `<meta name="description">`

**Structural signals:**
- Navigation structure (reveals product/service categories)
- Social media links in header/footer (captures platform presence)
- Copyright text (captures official brand name)

Store all extracted data in a working object:

```yaml
_raw_website:
  pages_scraped: 4
  colors_found:
    - hex: "#2563EB"
      frequency: 47
      contexts: ["buttons", "links", "headings"]
    - hex: "#1E293B"
      frequency: 32
      contexts: ["body text", "headings"]
  fonts_found:
    - family: "Inter"
      source: "Google Fonts"
      contexts: ["headings", "navigation", "buttons"]
    - family: "Georgia"
      source: "system"
      contexts: ["body text", "blockquotes"]
  logo_urls:
    - src: "https://example.com/logo.svg"
      location: "header"
    - src: "https://example.com/favicon.ico"
      location: "head"
  copy_samples:
    - location: "hero"
      text: "Ship faster with tools that just work."
    - location: "meta_description"
      text: "Example helps teams ship software faster."
  social_links: ["https://linkedin.com/company/example", "https://x.com/example"]
  navigation: ["Products", "Pricing", "About", "Blog", "Contact"]
```

#### 1B: Document Analysis (if `--docs` provided)

For each document:

1. Read the file (supports PDF, DOCX, MD, TXT, images)
2. Extract brand-relevant content:
   - Explicit brand values, mission, vision statements
   - Color specifications (hex codes, Pantone references, color names)
   - Typography specifications (font names, sizes, weight rules)
   - Logo usage rules
   - Tone of voice descriptions
   - Audience descriptions
   - Content guidelines or style rules
   - Any positioning statements or competitive framing

Store in:

```yaml
_raw_docs:
  files_analyzed: 2
  brand_statements:
    - source: "style-guide.pdf, page 3"
      type: "mission"
      text: "To empower teams to build better software, faster."
    - source: "pitch-deck.pdf, page 7"
      type: "positioning"
      text: "Unlike legacy CI/CD tools, we focus on developer experience."
  color_specs:
    - source: "style-guide.pdf, page 12"
      hex: "#2563EB"
      name: "Primary Blue"
      pantone: "2728 C"
  font_specs:
    - source: "style-guide.pdf, page 14"
      family: "Inter"
      use: "All headings and UI text"
  tone_descriptions:
    - source: "style-guide.pdf, page 8"
      text: "We write like a smart friend, not a textbook."
  audience_descriptions:
    - source: "pitch-deck.pdf, page 5"
      text: "Engineering teams at mid-size SaaS companies (50-500 employees)"
```

#### 1C: Social Media Analysis (if `--social` provided)

For each social profile URL:

1. Fetch the profile page
2. Extract:
   - Bio/description text
   - Profile picture and banner image (visual signals)
   - Recent post samples (tone analysis)
   - Posting frequency patterns
   - Hashtag usage
   - Content themes and pillars
   - Engagement style (how they reply)
   - Platform-specific formatting patterns

Store in:

```yaml
_raw_social:
  profiles_analyzed: 2
  platforms:
    - name: "LinkedIn"
      url: "https://linkedin.com/company/example"
      bio: "Building the future of developer tools."
      followers: "~12K"
      post_themes: ["Product updates", "Engineering culture", "Industry takes"]
      tone_observations: "Professional but approachable, uses emojis sparingly"
      hashtags: ["#DevTools", "#Engineering", "#DeveloperExperience"]
      frequency: "3-4 posts per week"
    - name: "X / Twitter"
      url: "https://x.com/example"
      bio: "Ship faster. Break less."
      tone_observations: "Snappy, opinionated, technical humor"
      hashtags: ["#shipping", "#devex"]
      frequency: "1-2 posts per day"
```

### Step 2: Analyze & Infer

For every section of `brand-reference.yml`, determine the confidence level of each field:

| Confidence | Meaning | Example |
|-----------|---------|---------|
| `high` | Directly extracted from source material with clear evidence | Hex color found in CSS 47 times |
| `medium` | Inferred from strong signals across multiple sources | Voice tone inferred from 15+ copy samples |
| `low` | Reasonable guess from limited evidence | Industry inferred from product page content |
| `missing` | Not enough data to determine | No values statement found anywhere |

**Analysis per section:**

#### meta
- `brand_name`: Extract from `<title>`, `og:site_name`, copyright text, logo alt text. Confidence: high if consistent across sources.
- `tagline`: Extract from `og:description`, hero text, social bios. Confidence: high if found verbatim; medium if constructed from copy.
- `industry`: Infer from product descriptions, navigation, job listings, meta descriptions. Confidence: medium typically.
- `website`: From `--url` input. Confidence: high.

#### identity
- `mission`: Look for explicit "our mission" sections in docs; infer from about page copy. Confidence: high if explicit; medium if inferred.
- `vision`: Look for explicit "our vision" sections. Often missing from websites. Confidence: high if found; missing otherwise.
- `values`: Look for explicit values pages or sections; infer from repeated themes in copy. Confidence: high if explicit; low if inferred.
- `brand_story`: Look for about/story pages; extract founding narrative from docs. Confidence: high if found; missing otherwise.
- `positioning`: Construct from hero copy, meta descriptions, competitive statements. Confidence: medium typically.

#### colors
- Extract all colors from CSS, documents, and visual materials.
- Classify into primary/secondary/accent/neutral based on frequency and context.
- Primary: most used brand color (excluding black/white/gray).
- Secondary: second most used non-neutral color.
- Accent: less frequent, high-contrast colors used for CTAs or highlights.
- Neutrals: grays, blacks, whites used for backgrounds and text.
- Compute contrast ratios for all likely foreground/background pairs.
- Confidence: high for extracted hex values; medium for classification.

#### typography
- Extract font families, weights, and sizes from CSS.
- Classify primary vs secondary based on usage context (headings vs body).
- Build a type scale from actual heading sizes found in CSS.
- Confidence: high for font names and sizes from CSS; medium for usage classification.

#### voice
- Analyze collected copy samples for tone dimensions:
  - **Formality** (1-10): Measure sentence structure, vocabulary sophistication, contractions usage.
  - **Humor** (1-10): Look for wordplay, casual asides, emoji usage.
  - **Enthusiasm** (1-10): Count exclamation marks, superlatives, energy words.
  - **Technicality** (1-10): Measure jargon density, assumed knowledge level.
- Extract personality from writing patterns: "confident" if declarative statements dominate; "friendly" if second-person and contractions are common.
- Construct writing samples from actual website copy (good examples) and generate contrasting bad examples.
- Confidence: medium for spectrum scores; low for personality attributes (subjective).

#### audience
- Infer from product descriptions, pricing tiers, case studies, job listings, social followers.
- If docs contain explicit audience descriptions, use those directly.
- Confidence: high if docs have audience data; medium if inferred from product signals.

#### visual
- Imagery style: analyze OG images, hero images, about page photos.
- Layout: extract grid system, spacing, alignment from CSS.
- Logo: captured from header; usage rules from docs if available.
- Confidence: high for extracted assets; low for inferred usage rules.

#### content
- Extract writing patterns: sentence length averages, active vs passive voice ratio, vocabulary level.
- Grammar rules: detect Oxford comma usage, capitalization patterns, date formats from existing content.
- Confidence: medium for inferred rules; high only if docs contain explicit style rules.

#### social
- Directly from social profile analysis if `--social` provided.
- Inferred from social links found on website if not.
- Confidence: high if analyzed directly; missing if only links found.

### Step 3: Generate Draft

Write a draft `brand-reference.yml` that follows the exact same schema as `/brand:generate` output, with two additions per field:

1. **`_confidence`** marker on every object and value
2. **`_evidence`** note explaining where the data came from

Example field with confidence markers:

```yaml
meta:
  _confidence: high
  brand_name: "Example Corp"
  _evidence_brand_name: "Consistent across og:site_name, copyright text, and logo alt"
  tagline: "Ship faster with tools that just work."
  _evidence_tagline: "Found verbatim in hero section and og:description"
  _confidence_tagline: high
  industry: "Developer Tools / SaaS"
  _evidence_industry: "Inferred from product descriptions and navigation structure"
  _confidence_industry: medium
```

**Rules for the draft:**
- Every top-level section must be present, even if all fields are `missing`
- Missing sections should have placeholder values with `_confidence: missing`
- Colors must include computed contrast ratios even in draft
- Inferred values should be clearly marked as inferences, not facts
- Evidence notes should cite specific sources (page name, CSS line, document + page)

### Step 4: Present to User

Show a summary and walk through each section for confirmation.

**Summary header:**

```
## Brand Analysis Complete

Sources analyzed:
  Website: 4 pages scraped from https://example.com
  Documents: 2 files (style-guide.pdf, pitch-deck.pdf)
  Social: not provided

### Coverage

| Section          | Fields | High | Medium | Low | Missing |
|-----------------|--------|------|--------|-----|---------|
| Meta            |    4   |   3  |    1   |  0  |    0    |
| Identity        |    6   |   2  |    1   |  1  |    2    |
| Colors          |   12   |  10  |    2   |  0  |    0    |
| Typography      |    8   |   7  |    1   |  0  |    0    |
| Voice           |   10   |   0  |    6   |  3  |    1    |
| Audience        |    6   |   1  |    2   |  1  |    2    |
| Visual          |    5   |   2  |    1   |  0  |    2    |
| Content         |    8   |   3  |    2   |  1  |    2    |
| Social          |    4   |   0  |    0   |  0  |    4    |
| **Total**       | **63** | **28** | **16** | **6** | **13** |

**Overall confidence: 70%** (44 of 63 fields are high or medium)
```

**Section-by-section walkthrough:**

For each section, present the extracted/inferred data and ask the user to confirm or correct:

```
### Meta

brand_name: "Example Corp" (high — consistent across 4 sources)
tagline: "Ship faster with tools that just work." (high — hero + og:description)
industry: "Developer Tools / SaaS" (medium — inferred from product pages)
website: "https://example.com" (high — provided as input)

Is this correct? Any changes?
```

Walk through all 9 sections. For `missing` fields, explicitly ask:

```
### Identity

mission: "To empower teams to build better software, faster." (high — about page)
vision: [MISSING — no vision statement found]
values: [LOW — inferred "Innovation" and "Simplicity" from copy themes]
brand_story: [MISSING — no origin story found]
positioning:
  category: "Developer Tools" (medium — product page)
  target: "Engineering teams at mid-size SaaS companies" (medium — pitch deck)
  differentiator: [LOW — "developer experience focus" inferred from hero copy]
  proof: [MISSING — no proof points found]

I need your help filling in the gaps:
1. What's your vision statement? (one sentence about where you're headed)
2. Are "Innovation" and "Simplicity" correct as core values? What are the real ones?
3. What's your origin story? (even 2-3 sentences help)
4. What proof supports your differentiator? (metrics, awards, customer quotes)
```

After the user provides corrections and fills gaps:
- Update the draft with user-provided data (mark these as `_confidence: high`, `_evidence: "user-provided"`)
- Re-run validation on any changed color values

### Step 5: Validate

Run validation checks on the finalized draft:

#### Accessibility Validation (on extracted colors)

Compute contrast ratios for all foreground/background color pairs using the WCAG luminance formula:

```
L = 0.2126 × R_lin + 0.7152 × G_lin + 0.0722 × B_lin

where R_lin = (R/255)^2.2 (simplified gamma)

Contrast ratio = (L_lighter + 0.05) / (L_darker + 0.05)
```

Check:
- All body-text pairs must pass WCAG AA (≥ 4.5:1)
- All large-text pairs must pass WCAG AA (≥ 3:1)
- Flag any failing pairs with a warning and suggested fix

Report:

```
### Accessibility Check

✓ Body text pairs: 4 of 4 pass WCAG AA
✗ Large text pairs: 3 of 4 pass WCAG AA
  ⚠ Accent (#F59E0B) on White (#FFFFFF) — ratio 2.14:1 (needs ≥ 3:1)
    Suggestion: darken to #D97706 (ratio 3.31:1) or use on dark backgrounds only

✓ All primary colors have colorblind safety notes
```

#### Data Validation

Check that the draft has all required sections per the schema:

```
### Schema Completeness

✓ meta: all required fields present
✓ identity: all required fields present (user filled gaps)
✓ colors: primary, neutrals, accessibility present
✓ typography: primary font, scale (3+ levels) present
⚠ voice: writing_samples missing (added placeholder — review recommended)
✓ audience: at least 1 persona present
✓ visual: imagery and layout present
⚠ content: content_types has only 1 entry (recommend 3+)
✗ social: section empty (no social data provided)
```

#### Font License Check

If fonts were extracted from CSS:

```
### Font Licensing Notes

Inter — Google Fonts (SIL Open Font License) ✓ Free for all use
Georgia — System font ✓ No license needed
Custom Font X — @font-face from example.com ⚠ Verify you have the license
```

### Step 6: Finalize & Save

1. Remove all `_confidence` and `_evidence` markers from the final `brand-reference.yml` (they go in the analysis report instead)
2. Write the clean `brand-reference.yml` to `.ai/brands/[brand-slug]/brand-reference.yml`
3. Write the analysis report to `.ai/brands/[brand-slug]/brand-analysis-report.md`

If `--merge` was specified:
- Read the existing `brand-reference.yml`
- For each field in the draft:
  - If the existing file has the field and draft confidence is `high`: ask user which to keep
  - If the existing file has the field and draft confidence is `medium` or lower: keep existing
  - If the existing file is missing the field: add from draft
- Write the merged result

**Analysis report structure (`brand-analysis-report.md`):**

```markdown
# Brand Analysis Report: [Brand Name]
Generated: [date]

## Sources Analyzed
- Website: [URL] ([N] pages)
- Documents: [list of files]
- Social: [list of profiles]

## Coverage Summary
[The coverage table from Step 4]

## Detailed Findings

### Meta
| Field | Value | Confidence | Evidence |
|-------|-------|-----------|----------|
| brand_name | Example Corp | high | og:site_name, copyright, logo alt |
| tagline | Ship faster... | high | Hero section, og:description |
[...all fields...]

### Identity
[...same table format...]

[...all sections...]

## Accessibility Report

### Color Contrast Matrix
| Foreground | Background | Ratio | AA Normal | AA Large | Use |
|-----------|-----------|-------|-----------|----------|-----|
| #2563EB | #FFFFFF | 4.56:1 | ✓ | ✓ | Links on white |
| #F59E0B | #FFFFFF | 2.14:1 | ✗ | ✗ | ⚠ Decorative only |
[...all pairs...]

### WCAG Failures
[List of pairs that fail with suggested fixes]

### Colorblind Safety
[Notes per color for protanopia, deuteranopia, tritanopia]

### Font Licensing
[License status per font]

## Gaps & Recommendations
[List of missing or low-confidence fields with recommendations for how to fill them]

## Next Steps
- Review and correct any inferred values
- Fill in missing sections using `/brand:generate --resume`
- Run `/brand:audit` for a comprehensive quality check
```

**Directory structure created:**

```
.ai/brands/[brand-slug]/
├── brand-reference.yml         # Clean, schema-compliant
├── brand-analysis-report.md    # Full analysis with evidence
├── assets/                     # Empty (no assets generated — use /brand:generate for that)
│   ├── logo/svg/
│   ├── icons/
│   ├── favicons/
│   ├── app-icons/
│   └── social/
├── preview/
└── scripts/
```

### Step 7: Completion Report

```
## Brand Analysis Complete: [Brand Name]

### What was generated

**Files:**
  brand-reference.yml — draft brand data (schema-compliant)
  brand-analysis-report.md — full analysis with evidence and recommendations

### Coverage
  [N] of [total] fields filled (high: X, medium: Y, low: Z, missing: W)

### Location
  .ai/brands/[brand-slug]/

### Accessibility
  [N] color pairs checked
  [X] WCAG AA failures flagged (see report for details)

### Next steps
  - Review brand-analysis-report.md for inferred values
  - Run `/brand:generate --resume --brand [slug]` to fill gaps interactively
  - Run `/brand:audit --brand [slug]` to check quality
  - Use `/brand:switch [slug]` to load into other plugins
```

## Checkpoint

This command runs two checkpoint types at Step 5:

### data_validation
| Check | Verify | Fail Action |
|-------|--------|-------------|
| `top_level_sections` | brand-reference.yml has all 9 top-level keys (meta, identity, visual, typography, colors, voice, audience, content, social) — even if some are marked missing | Add empty sections with `_confidence: missing` |
| `confidence_markers` | Every field has a `_confidence` marker in the analysis report | Add missing markers as `low` with a note |
| `analysis_report` | `brand-analysis-report.md` exists and has all sections | Generate missing report sections |
| `evidence_notes` | Every non-missing field in the report has evidence | Add "no evidence recorded" for fields without evidence |

### accessibility_validation
| Check | Verify | Fail Action |
|-------|--------|-------------|
| `contrast_ratios_computed` | All extracted foreground/background pairs have contrast_ratio | Compute missing ratios |
| `wcag_aa_body` | All body-text pairs flagged if they fail AA (≥ 4.5:1) | Add warning and suggested fix |
| `wcag_aa_large` | All large-text pairs flagged if they fail AA (≥ 3:1) | Add warning and suggested fix |
| `colorblind_notes` | Primary and accent colors have colorblind safety notes | Generate missing notes |

## Error Handling

| Error | Action |
|-------|--------|
| URL unreachable | Report which pages failed, continue with what's available |
| Document unreadable | Report the error, skip that document, continue with others |
| Social profile private/blocked | Report the limitation, skip that profile |
| No data extracted from any source | Ask user to provide a different source or try `/brand:generate` instead |
| Brand slug collision (not merge) | Ask: overwrite, merge, or pick a different name |
| All fields are missing/low | Warn that analysis produced limited results; recommend `/brand:generate` for a guided approach |
| CSS parsing fails | Fall back to visible color extraction from screenshots/OG images |

## Differences from /brand:generate

| Aspect | /brand:generate | /brand:analyze |
|--------|----------------|----------------|
| Input | User answers questions | Existing materials |
| Process | 9-phase pipeline with task-planner | Single-pass analysis |
| Confidence | All fields are definitive | Fields have confidence markers |
| Assets | Generates logos, icons, favicons, etc. | No asset generation |
| Duration | 30-60 min interactive | 5-10 min automated |
| Best for | New brands, rebrands | Existing brands needing documentation |
| Resume | Via task-planner state | Not resumable (re-run instead) |
