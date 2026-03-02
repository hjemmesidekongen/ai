---
name: audit
command: "/seo:audit"
description: "Audit an existing website or page against SEO best practices and report issues with fix recommendations"
arguments:
  - name: url
    type: string
    required: true
    description: "The URL to audit (e.g., 'https://example.com' or 'https://example.com/page')"
  - name: project
    type: string
    required: false
    description: "Use an existing project's strategy as the baseline for audit rules"
---

# /seo:audit

Audits an existing website or page against SEO best practices. When used with `--project`, compares against the project's specific strategy rules. Reports issues with severity and fix recommendations.

## Usage

```
/seo:audit https://example.com                          # standalone audit
/seo:audit https://example.com --project my-project      # audit against project rules
```

## Purpose

Audits an existing website or page against SEO best practices and reports issues with fix recommendations. Checks on-page elements (title, meta, headings, schema), technical elements (HTTPS, mobile, robots), and scores each finding.

## Prerequisites

- task-planner plugin installed
- For `--project` mode: a completed SEO strategy at `.ai/seo/[project-name]/`

## Input

- `url` (required) — the URL to audit
- `--project [name]` (optional) — use existing project's strategy as baseline

## Execution Strategy

No interactive phases. Single-pass autonomous execution:

### Step 1: Load Baseline (if --project provided)

If `--project` is specified:
1. Read `.ai/seo/[project-name]/seo-strategy.yml`
2. Extract baseline rules:
   - `on_page.title_tag` — title tag pattern and rules
   - `on_page.meta_description` — meta description rules
   - `on_page.heading_hierarchy` — heading structure rules
   - `on_page.schema_markup` — expected schema types
   - `technical.checklist` — technical SEO requirements
   - `technical.core_web_vitals` — CWV targets

If no project, use built-in SEO best practices as the baseline.

### Step 2: Fetch and Analyze HTML

1. Fetch the target URL
2. Parse the HTML document
3. Extract key elements for analysis:
   - `<title>` tag content and length
   - `<meta name="description">` content and length
   - All heading tags (H1-H6) and their text
   - All `<img>` tags and their `alt` attributes
   - `<link rel="canonical">` href
   - All structured data (JSON-LD, microdata)
   - `<meta name="viewport">` content
   - Protocol (HTTP vs HTTPS)
   - `<meta name="robots">` content

### Step 3: On-Page SEO Checks

Score each element as **pass** (green), **warn** (yellow), or **fail** (red):

| Check | Pass | Warn | Fail |
|-------|------|------|------|
| Title tag exists | Present and ≤ 60 chars | Present but > 60 chars | Missing |
| Title has keyword | Contains target keyword (if project) | — | No keyword presence |
| Meta description | Present, 120-155 chars | Present, wrong length | Missing |
| Meta description CTA | Ends with action word | — | No CTA |
| H1 tag | Exactly 1 H1 | Multiple H1s | No H1 |
| Heading hierarchy | Logical (no skipped levels) | Minor skip (H1→H3) | Major issues |
| Image alt tags | All images have alt text | > 80% have alt text | < 80% have alt text |
| Canonical URL | Present and valid | Present but self-referential only | Missing |
| Schema markup | Relevant types present | Partial (Organization only) | No schema |

### Step 4: Technical SEO Checks

| Check | Pass | Warn | Fail |
|-------|------|------|------|
| HTTPS | Site uses HTTPS | — | HTTP only |
| Mobile viewport | Proper viewport meta tag | Viewport without width=device-width | Missing viewport |
| Robots meta | Indexable (no noindex) | noindex detected (intentional?) | Blocked by robots |
| Canonical consistency | Canonical matches URL | Canonical points elsewhere | No canonical |
| Structured data valid | Valid JSON-LD | Minor validation warnings | Invalid or missing |

### Step 5: Generate Audit Report

Produce a structured report:

```
## SEO Audit: [URL]

Audited: [timestamp]
Baseline: [project name or "built-in best practices"]

### Overall Score: [N]/100

### Summary
  ✓ [N] checks passed
  ⚠ [N] warnings
  ✗ [N] failures

### Critical Issues (fix immediately)
1. [issue] — [recommendation]
2. [issue] — [recommendation]

### Warnings (should fix)
1. [issue] — [recommendation]

### Passed Checks
1. [check] ✓
2. [check] ✓

### On-Page Elements
| Element | Status | Finding | Recommendation |
|---------|--------|---------|----------------|
| Title tag | ✓/⚠/✗ | [current value] | [what to change] |
| Meta description | ✓/⚠/✗ | [current value] | [what to change] |
...

### Technical Elements
| Element | Status | Finding | Recommendation |
|---------|--------|---------|----------------|
| HTTPS | ✓/⚠/✗ | [status] | [action] |
...
```

## Output

- Audit report printed to stdout (not saved to file by default)
- If `--project` provided: comparison is against the project's specific rules
- Score is 0-100 based on weighted check results (critical = 3x, standard = 1x)

## Recovery

Not needed — single-pass command with no state.
