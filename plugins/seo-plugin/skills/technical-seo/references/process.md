# Technical SEO — Detailed Process

Phase 3 of SEO strategy generation (runs in parallel with competitor-analysis). This skill produces a comprehensive technical SEO checklist that serves as the audit baseline. The output feeds into the `/seo:audit` command and informs on-page-optimization recommendations.

## Prerequisites

- Read `docs/seo-plugin-implementation-plan.md` (the "Skill: technical-seo" section)
- Read `docs/seo-plugin-addendum.md` (the "Technical SEO Fundamentals" section)

## Findings Persistence

During checklist generation, write intermediate discoveries to the findings file:

```
~/.claude/seo/[project-name]/findings.md
```

**What to save:** Known issues cross-referenced, industry-specific technical requirements, checklist item rationale, priority decisions.

**2-Action Rule:** After every 2 research operations (checklist items generated, known issues matched, web search, file read), IMMEDIATELY save key findings to findings.md before continuing.

**Format:**

```markdown
## Technical SEO Findings

### Known Issues Cross-Referenced
- [issue from project interview] → mapped to checklist item: [item]

### Industry-Specific Items Added
- [item]: added because [industry] requires [reason]

### Priority Decisions
- [item] set to [priority] because [rationale]

### Research Notes
- [technical context, industry-specific requirements, standard references]
```

This file persists across `/compact` and session restarts. If context is lost, findings survive.

## Error Logging

When errors occur during generation (validation failures, checkpoint failures, unexpected issues):

1. Log the error to state.yml `errors` array immediately
2. Before retrying any approach, check `errors` for previous failed attempts
3. Never repeat a failed approach — mutate strategy instead
4. The verification-runner logs checkpoint failures automatically

## Before You Start

Load context from previous phases:

1. Read `seo-strategy.yml` → extract:
   - `project_context.website_url` — the site being audited
   - `project_context.current_status.known_issues` — existing problems to flag in the checklist
   - `project_context.industry` — some technical requirements vary by industry (e.g., e-commerce needs Product schema)

2. Report what you loaded: "Building technical SEO checklist for [website_url]. Found [N] known issues to cross-reference."

This skill is **non-interactive** — generate the full checklist and present it for review.

## Generation Process

### Step 1: Core Web Vitals Targets

Define the three Core Web Vitals with Google's recommended thresholds:

```yaml
core_web_vitals:
  lcp:
    target: 2.5
    unit: "seconds"
    description: "Largest Contentful Paint — measures loading performance. The largest visible element (image, video, or text block) should render within 2.5 seconds of page load."
  fid:
    target: 100
    unit: "milliseconds"
    description: "First Input Delay — measures interactivity. The page should respond to the first user interaction (click, tap, key press) within 100 milliseconds."
  cls:
    target: 0.1
    unit: "score"
    description: "Cumulative Layout Shift — measures visual stability. Page elements should not shift unexpectedly during loading. Score is unitless; lower is better."
```

These are fixed values from Google's guidelines — do not modify them.

### Step 2: Technical Checklist

Generate at least 10 checklist items across these categories. Aim for 12-15 items for thorough coverage.

**Category: crawlability** (at least 2 items)

| Item | Priority | Why |
|------|----------|-----|
| XML sitemap exists and is submitted to Google Search Console | critical | Without a sitemap, search engines may miss pages |
| robots.txt properly configured (no accidental blocks) | critical | Misconfigured robots.txt can deindex entire sections |
| Canonical URLs set on all pages to prevent duplicate content | high | Duplicate content dilutes ranking signals |
| 404 error pages return proper HTTP status codes | medium | Soft 404s waste crawl budget |
| Breadcrumb navigation implemented with structured data | medium | Helps search engines understand site hierarchy |
| Clean URL structure (no query parameters for indexable content) | medium | Clean URLs improve crawlability and user experience |

**Category: security** (at least 2 items)

| Item | Priority | Why |
|------|----------|-----|
| SSL/HTTPS enabled on all pages | critical | HTTPS is a direct ranking factor since 2014 |
| Security headers configured (HSTS, X-Content-Type-Options) | low | Not a direct ranking factor but improves trust signals |

**Category: mobile** (at least 2 items)

| Item | Priority | Why |
|------|----------|-----|
| Mobile-first indexing ready (responsive design) | critical | Google indexes mobile version first |
| Viewport meta tag properly configured | high | Required for proper mobile rendering |
| No intrusive interstitials on mobile | medium | Google penalizes sites with aggressive popups on mobile |

**Category: performance** (at least 2 items)

| Item | Priority | Why |
|------|----------|-----|
| Image optimization (WebP/AVIF format, proper sizing) | high | Images are typically the largest page weight contributor |
| Browser caching configured (cache-control headers) | medium | Reduces load time for repeat visitors |
| CDN configured for static assets | medium | Reduces latency for geographically distributed users |
| JavaScript execution minimized (defer/async loading) | high | Excessive JS blocks rendering and hurts FID |

**Category: accessibility** (at least 1 item)

| Item | Priority | Why |
|------|----------|-----|
| All images have descriptive alt text | high | Required for accessibility and image search ranking |
| Heading hierarchy is logical (no skipped levels) | medium | Helps screen readers and search engines parse content |

**Category: rich_results** (at least 1 item)

| Item | Priority | Why |
|------|----------|-----|
| Organization schema on homepage | high | Enables Knowledge Panel and brand signals |
| BreadcrumbList schema on all pages | medium | Enables breadcrumb rich results in SERPs |
| Article schema on blog/content pages | medium | Enables article rich results with publication date |

**Selecting items:** Include all items from the tables above as a baseline. Add industry-specific items:
- E-commerce: Product schema, Review schema, aggregate ratings
- SaaS: FAQ schema, Software Application schema
- Local business: LocalBusiness schema, Google Business Profile link
- Media: VideoObject schema, NewsArticle schema

Set all items to `status: "pending"` — these are recommendations, not current assessments.

### Step 3: Cross-Reference Known Issues

Check `project_context.current_status.known_issues` and flag matches:

For each known issue:
1. Find the matching checklist item (if any)
2. Add a `note` field: "Flagged in project interview: [known issue text]"
3. If no matching checklist item exists, add one with the known issue as the item description

This ensures the checklist addresses problems the user already knows about.

### Step 4: Mobile Requirements

Define at least 4 mobile requirements:

```yaml
mobile_requirements:
  - requirement: "Viewport meta tag set"
    specification: "<meta name='viewport' content='width=device-width, initial-scale=1'>"
    priority: "critical"
  - requirement: "Touch target sizes minimum 48x48 pixels"
    specification: "All interactive elements (buttons, links, form fields) must be at least 48x48px with 8px spacing"
    priority: "high"
  - requirement: "No horizontal scrolling"
    specification: "Content must fit within viewport width at all breakpoints (320px minimum)"
    priority: "high"
  - requirement: "Base font size 16px minimum"
    specification: "Body text must be at least 16px to prevent auto-zoom on iOS and ensure readability"
    priority: "medium"
```

## Writing the Output

Present the checklist for review:

```
## Technical SEO Checklist

### Core Web Vitals Targets
- LCP: ≤ 2.5 seconds
- FID: ≤ 100 milliseconds
- CLS: ≤ 0.1

### Checklist ([N] items across [N] categories)

| # | Category | Item | Priority |
|---|----------|------|----------|
| 1 | crawlability | XML sitemap exists... | critical |
| 2 | security | SSL/HTTPS enabled... | critical |
...

### Mobile Requirements ([N] items)
1. Viewport meta tag set (critical)
2. Touch targets ≥ 48x48px (high)
3. No horizontal scrolling (high)
4. Base font size ≥ 16px (medium)

Known issues flagged: [N]

Does this look comprehensive? I can add items or adjust priorities.
```

Present for review. Then write the `technical` section to `seo-strategy.yml`:

```yaml
technical:
  core_web_vitals:
    lcp:
      target: 2.5
      unit: "seconds"
      description: "Largest Contentful Paint — loading performance"
    fid:
      target: 100
      unit: "milliseconds"
      description: "First Input Delay — interactivity"
    cls:
      target: 0.1
      unit: "score"
      description: "Cumulative Layout Shift — visual stability"
  checklist:
    - item: "XML sitemap exists and is submitted to Google Search Console"
      priority: "critical"
      status: "pending"
      category: "crawlability"
    - item: "SSL/HTTPS enabled on all pages"
      priority: "critical"
      status: "pending"
      category: "security"
    # ... more items
  mobile_requirements:
    - requirement: "Viewport meta tag set"
      specification: "<meta name='viewport' content='width=device-width, initial-scale=1'>"
      priority: "critical"
    # ... more requirements
```

Update `state.yml`:
- Set `current_phase: "technical-seo"`
- Add phase entry with `status: "complete"` and checkpoint results

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `core_web_vitals` | Has `lcp` (target ≤ 2.5, unit "seconds"), `fid` (target ≤ 100, unit "milliseconds"), `cls` (target ≤ 0.1, unit "score") | Add missing vitals targets |
| `checklist_coverage` | ≥ 10 items across ≥ 4 categories | Add items to underrepresented categories |
| `checklist_fields` | Each item has `item`, `priority` (critical/high/medium/low), `status` (pending/in_progress/done/na), `category` | Fill missing fields |
| `critical_items` | ≥ 2 items with priority "critical" | Elevate the most impactful items |
| `mobile_requirements` | ≥ 4 entries | Add standard mobile requirements |

**On pass:** Update state.yml → mark phase 3 complete, write recovery notes, advance to phase 4.

**On fail:** Fix the failing checks, re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Project: [name] ([industry])
Technical items: [N] across [N] categories
Critical items: [N] ([list])
Known issues flagged: [N]
CWV targets: LCP ≤ 2.5s, FID ≤ 100ms, CLS ≤ 0.1
Mobile requirements: [N] defined
```
