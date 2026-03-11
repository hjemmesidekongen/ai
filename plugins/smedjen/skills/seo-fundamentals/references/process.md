# SEO Fundamentals — Detailed Reference

## Structured Data (Schema)

Helps search engines understand meaning. Enables rich results eligibility but doesn't guarantee them.

| Type | Purpose |
|------|---------|
| Article | Content classification |
| Organization | Entity identity |
| Person | Author information |
| FAQPage | Q&A clarity |
| Product | Commerce details |
| Review | Ratings context |
| BreadcrumbList | Site structure |

## Meta Tag Formulas

### URL Structure
- Under 60 characters
- Hyphens, lowercase only
- Primary keyword early
- Remove stop words
- Format: `/primary-keyword-secondary-keyword`

### Title Tags
- 50-60 characters (pixels vary by font)
- Primary keyword in first 30 characters
- Include power words or numbers for freshness
- Brand placement at end: `Primary Keyword - Hook | Brand`
- 3-5 variations for A/B testing

### Meta Descriptions
- 150-160 characters
- Action verb + primary keyword + benefit + CTA
- Include secondary keyword naturally
- Format: `Action verb + benefit. Include keyword. Clear CTA.`

### Power Words for Titles
Proven, Essential, Complete, Ultimate, Step-by-Step, Free, New, Simple, Fast, Easy

## Keyword Strategy Package

### Density Guidelines
```
Primary keyword:   0.5-1.5% density
Secondary keywords: 3-5 targets, natural placement
LSI keywords:       20-30 semantic variations
Entities:           Related concepts to include
```

### Keyword Placement Priority
1. Title tag (first 30 chars)
2. H1 heading
3. First 100 words of body
4. 2-3 H2 headings
5. Image alt text
6. URL slug
7. Meta description
8. Naturally throughout body

### Over-Optimization Signals
- Keyword density above 2%
- Exact-match keyword in every heading
- Unnatural keyword insertion
- Keyword at start of every paragraph
- Same anchor text for all internal links

### Advanced Keyword Types
- Question keywords: target People Also Ask boxes
- Voice search: conversational, long-tail queries
- Featured snippet: direct answer format (40-60 words)
- Keyword clusters: group related terms into topic hubs

## Technical SEO Audit Checklist

### Crawlability
- [ ] robots.txt: no accidental blocking of important paths
- [ ] robots.txt: sitemap reference present
- [ ] XML sitemaps: accessible, valid, only canonical URLs
- [ ] XML sitemaps: submitted in Search Console
- [ ] Key pages within 3 clicks from homepage
- [ ] No orphaned pages
- [ ] No infinite scroll without crawlable pagination

### Indexation
- [ ] Indexed vs expected page count matches
- [ ] No accidental noindex on important pages
- [ ] No canonical conflicts
- [ ] No redirect chains or loops
- [ ] No soft 404s
- [ ] Self-referencing canonicals on all pages
- [ ] HTTPS consistency (no mixed content)
- [ ] www/non-www consistency
- [ ] Trailing slash consistency

### Performance (Core Web Vitals)
- [ ] LCP < 2.5s
- [ ] INP < 200ms
- [ ] CLS < 0.1
- [ ] Server response time acceptable
- [ ] Images optimized (format, compression, lazy loading)
- [ ] JavaScript execution cost managed
- [ ] CSS delivery optimized
- [ ] Caching strategy in place
- [ ] CDN configured

### Mobile
- [ ] Responsive layout
- [ ] Proper viewport meta tag
- [ ] Tap targets adequately sized
- [ ] No horizontal scrolling
- [ ] Content parity with desktop

### On-Page
- [ ] Unique title tag per page (50-60 chars)
- [ ] Unique meta description per page (150-160 chars)
- [ ] One H1 per page
- [ ] Logical heading hierarchy (H1 > H2 > H3)
- [ ] Descriptive image alt text
- [ ] Internal links with descriptive anchors (2-3 per page)
- [ ] No broken links

### Content Quality (E-E-A-T)
- [ ] First-hand experience demonstrated
- [ ] Clear author attribution
- [ ] Original insights or data
- [ ] Content fully answers search intent
- [ ] Factually accurate and up to date
- [ ] Transparent business information
- [ ] Privacy policy and terms present

## SEO Health Index — Scoring Model

### Category Weights
| Category | Weight |
|----------|--------|
| Crawlability & Indexation | 30 |
| Technical Foundations | 25 |
| On-Page Optimization | 20 |
| Content Quality & E-E-A-T | 15 |
| Authority & Trust Signals | 10 |
| **Total** | **100** |

### Severity Deductions (per issue)
| Severity | Deduction |
|----------|-----------|
| Critical (blocks crawling/indexing/ranking) | -15 to -30 |
| High impact | -10 |
| Medium impact | -5 |
| Low / cosmetic | -1 to -3 |

### Confidence Modifier
- High confidence (directly observed): 100% of deduction
- Medium confidence (strong indicators): 50% of deduction
- Low confidence (indirect/sample-based): 25% of deduction

### Health Bands
| Score | Status | Interpretation |
|-------|--------|---------------|
| 90-100 | Excellent | Strong foundation, minor optimizations only |
| 75-89 | Good | Solid performance with clear improvement areas |
| 60-74 | Fair | Meaningful issues limiting growth |
| 40-59 | Poor | Serious SEO constraints |
| <40 | Critical | SEO is fundamentally broken |

### Findings Template
For each issue:
- **Issue**: one-sentence description
- **Category**: which of the 5 categories
- **Evidence**: URLs, metrics, crawl data (no intuition)
- **Severity**: Critical / High / Medium / Low
- **Confidence**: High / Medium / Low
- **Why it matters**: plain-language SEO impact
- **Score impact**: point deduction before weighting
- **Recommendation**: what to do (not how to implement)

### Action Prioritization
1. **Critical Blockers**: Critical severity, invalidates health index if unresolved
2. **High-Impact Improvements**: High/Medium severity with large cumulative deductions
3. **Quick Wins**: Low/Medium severity, easy fix, measurable score improvement
4. **Long-Term Opportunities**: Structural/content improvements for resilience over time

## AI-Assisted Content Principles

Search engines evaluate output quality, not authorship method.

### Effective Use
- AI as drafting or research assistant
- Human review for accuracy and clarity
- Original insights and synthesis
- Clear accountability

### Risky Use
- Publishing unedited AI output
- Factual errors or hallucinations
- Thin or duplicated content
- Keyword-driven text with no real value

## Relative Importance of SEO Factors

| Weight | Factor |
|--------|--------|
| Highest | Content relevance and quality |
| High | Authority and trust signals |
| Medium | Page experience (CWV, UX) |
| Medium | Mobile optimization |
| Baseline | Technical accessibility |

Technical SEO enables ranking. Content quality earns it.
