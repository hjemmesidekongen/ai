---
name: seo-fundamentals
description: >
  SEO fundamentals — E-E-A-T quality signals, Core Web Vitals, technical SEO,
  on-page optimization, keyword strategy, meta tag rules, structured data, and
  the SEO Health Index scoring model (0-100 weighted composite).
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "seo"
  - "search engine optimization"
  - "meta tags"
  - "keyword strategy"
  - "core web vitals"
  - "E-E-A-T"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "meta_tags_within_limits"
      verify: "Title tags 50-60 chars with keyword in first 30, meta descriptions 150-160 chars"
      fail_action: "Rewrite meta tags to hit character targets with keyword placement"
    - name: "heading_hierarchy_correct"
      verify: "One H1 per page, logical H2/H3 nesting, headings reflect content structure"
      fail_action: "Fix heading hierarchy — no skipped levels, no decorative headings"
    - name: "keyword_density_natural"
      verify: "Primary keyword at 0.5-1.5% density, no stuffing, semantic variations present"
      fail_action: "Reduce keyword density or add LSI keywords for natural coverage"
    - name: "canonical_and_indexing_correct"
      verify: "Self-referencing canonicals, no accidental noindex, HTTPS consistency"
      fail_action: "Fix canonical/indexing issues — these block ranking entirely"
  on_fail: "SEO issues will limit organic visibility — fix before deploying"
  on_pass: "SEO fundamentals are sound"
_source:
  origin: "dev-engine"
  inspired_by: "antigravity-awesome-skills/seo-fundamentals + seo-audit + seo-keyword-strategist + seo-meta-optimizer"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Combined four external SEO skills into one knowledge reference"
---

# seo-fundamentals

## E-E-A-T (Quality Evaluation)

Not a ranking factor — a quality evaluation framework. **Experience**: first-hand involvement, original examples. **Expertise**: subject competence, depth, accuracy. **Authoritativeness**: recognition by others, citations, links. **Trustworthiness**: HTTPS, transparency, accuracy. Pages competing in the same space differentiate on trust and experience, not keywords.

## Core Web Vitals

LCP < 2.5s (loading), INP < 200ms (interactivity), CLS < 0.1 (visual stability). CWV rarely override poor content — they matter when content quality is comparable. Failing CWV holds back otherwise good pages.

## Technical SEO

**Crawl control**: XML sitemaps (only canonical, indexable URLs), robots.txt (verify no accidental blocking), canonical tags (self-referencing, HTTPS consistent), clean URLs. **Performance**: mobile-first, semantic HTML, lazy loading, CDN. Key pages within 3 clicks. No orphaned URLs.

## On-Page Optimization

**Title tags**: 50-60 chars, keyword in first 30 chars, unique per page. **Meta descriptions**: 150-160 chars, action verb + benefit + CTA. **URLs**: under 60 chars, hyphens, lowercase, keyword early. **H1**: one per page, primary subject. **Images**: descriptive filenames, accurate alt text, compression. **Internal links**: 2-3 per page, descriptive anchors.

## Keyword Strategy

Primary keyword: 0.5-1.5% density. 3-5 secondary keywords. 20-30 LSI keywords for semantic coverage. Keyword in first 100 words and 2-3 H2s. Question keywords for People Also Ask. Never stuff — natural placement only.

## SEO Health Index

Weighted 0-100: Crawlability 30%, Technical 25%, On-Page 20%, Content/E-E-A-T 15%, Authority 10%. Start each category at 100, subtract by severity: Critical -15 to -30, High -10, Medium -5, Low -1 to -3. Bands: 90-100 Excellent, 75-89 Good, 60-74 Fair, 40-59 Poor, <40 Critical.

See `references/process.md` for structured data types, audit checklist, findings template, meta tag formulas, and prioritization framework.
