---
name: competitor-analysis
description: >
  Analyzes top competitors for target keywords, identifying their strengths,
  weaknesses, content gaps, and backlink profiles. Writes the competitors
  section to seo-strategy.yml.
phase: 3
depends_on: [project-interview]
writes:
  - "seo-strategy.yml#competitors"
reads:
  - "seo-strategy.yml#project_context"
  - "seo-strategy.yml#keywords"
checkpoint:
  type: data_validation
  required_checks:
    - name: "competitors_count"
      verify: "competitors.analyzed has at least 3 entries, each with domain (string), domain_authority (0-100), and top_keywords (array with at least 3 entries)"
      fail_action: "Identify additional competitors for the project's industry"
    - name: "content_analysis"
      verify: "Each competitor has at least 2 content_strengths and 2 content_weaknesses entries"
      fail_action: "Analyze content output for competitors missing strength/weakness data"
    - name: "backlink_profiles"
      verify: "Each competitor has backlink_profile with total_backlinks (number), referring_domains (number), and top_sources (array)"
      fail_action: "Estimate backlink profile for competitors missing this data"
    - name: "content_gaps"
      verify: "content_gaps has at least 5 entries, each with keyword (string), gap_type (missing|thin|outdated), opportunity_score (0-100), and recommended_action (string)"
      fail_action: "Cross-reference competitor weaknesses to identify more content gap opportunities"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Competitor Analysis

Phase 3 of SEO strategy generation (runs in parallel with technical-seo). This skill analyzes the competitive landscape to identify content gaps and link-building opportunities. The output feeds into content-strategy (Phase 5) and link-building (Phase 6).

## Prerequisites

- Read `docs/seo-plugin-implementation-plan.md` (the "Skill: competitor-analysis" section)
- Read `docs/seo-plugin-addendum.md` (the "Competitive Analysis for SEO" section)

## Before You Start

Load context from previous phases:

1. Read `seo-strategy.yml` → extract:
   - `project_context.industry` — determines which competitors to analyze
   - `project_context.website_url` — the project's own domain (exclude from competitor list)
   - `project_context.goals` — shapes which competitive dimensions matter most
   - `project_context.current_status` — baseline for comparison
   - `keywords.primary` — if available, use to identify which competitors rank for target keywords

2. Report what you loaded: "Analyzing competitors for [industry] project at [website_url]."

This skill is **non-interactive** — generate the full analysis and present it for review at the end.

## Analysis Process

### Step 1: Identify Competitors

Identify 3-5 likely competitors based on:

1. **Industry peers** — the most prominent companies in the project's industry
2. **Keyword competitors** — sites likely ranking for the project's target keywords (these may differ from direct business competitors)
3. **Content competitors** — sites producing content in the same topic space

For each competitor, determine:
- `domain` — the competitor's website domain (e.g., "competitor.com")
- Company name (for reference, not stored in YAML)

**Competitor selection criteria:**
- Include at least 1 direct business competitor (same product/service category)
- Include at least 1 content competitor (ranks for similar informational keywords)
- Include a mix of established players (DA 50+) and emerging competitors (DA 20-40)
- Exclude the project's own domain

### Step 2: Domain Authority Estimation

For each competitor, estimate domain authority (0-100) based on industry knowledge:

| Company Type | Typical DA Range |
|-------------|-----------------|
| Major industry leader (e.g., HubSpot, Shopify) | 70-90 |
| Well-known mid-market company | 50-70 |
| Established niche player | 35-55 |
| Growing startup with some traction | 20-40 |
| New or very small company | 5-20 |

Base estimates on:
- Company age and market presence
- How often they appear in industry discussions
- Whether they're publicly traded or well-funded
- Their content marketing activity level

### Step 3: Top Keywords Analysis

For each competitor, identify their top 5-10 ranking keywords:

1. Start with the project's primary keywords — which competitors would rank for these?
2. Add industry-standard terms the competitor is known for
3. Include both head terms and branded terms

For each keyword:
- `keyword` — the search term
- `position` — estimated SERP position (1-100)
- `estimated_traffic` — rough monthly visits from this keyword

**Position estimation logic:**
- Industry leaders typically hold positions 1-5 for head terms
- Mid-market companies typically rank 5-15
- Niche players rank 10-30 for head terms but 1-5 for long-tail

### Step 4: Content Strengths Analysis

For each competitor, identify 2-4 specific content strengths:

**Categories to evaluate:**
- **Content depth** — long-form guides, comprehensive resources
- **Content frequency** — publishing cadence, blog activity
- **Content variety** — blog, video, podcasts, tools, templates
- **Content quality** — original research, expert contributors, data-driven
- **SEO optimization** — structured data, internal linking, keyword targeting
- **User experience** — site speed, mobile optimization, navigation

Write strengths as specific, actionable observations:
- Good: "Comprehensive long-form guides averaging 3000+ words with custom graphics"
- Bad: "Good content" (too vague)

### Step 5: Content Weaknesses Analysis

For each competitor, identify 2-4 specific content weaknesses:

**Categories to evaluate:**
- **Content gaps** — missing topics, underserved keywords
- **Content freshness** — outdated articles, stale blog
- **Technical issues** — missing structured data, poor mobile experience
- **Engagement** — no comments, low social shares, thin content
- **UX problems** — slow load times, intrusive ads, poor navigation

Write weaknesses as specific, exploitable opportunities:
- Good: "No FAQ structured data on product pages — missing rich result opportunities"
- Bad: "Could be better" (not actionable)

### Step 6: Backlink Profile Estimation

For each competitor, estimate their backlink profile:

- `total_backlinks` — total number of backlinks (rough order of magnitude)
- `referring_domains` — unique domains linking to them
- `top_sources` — 2-3 notable domains that link to them (e.g., industry publications, directories, partner sites)

**Estimation benchmarks:**

| DA Range | Typical Referring Domains | Typical Total Backlinks |
|---------|--------------------------|------------------------|
| 70-90 | 5,000-50,000+ | 100,000-1,000,000+ |
| 50-70 | 1,000-10,000 | 10,000-200,000 |
| 35-55 | 200-3,000 | 2,000-50,000 |
| 20-40 | 50-500 | 500-10,000 |

### Step 7: Content Gap Identification

Cross-reference all competitor weaknesses to find exploitable gaps:

1. **Missing content** — topics/keywords where no competitor has coverage
2. **Thin content** — topics where competitors have shallow, surface-level content
3. **Outdated content** — topics where competitor content is old and hasn't been refreshed

For each content gap:
- `keyword` — the target keyword or topic
- `gap_type` — one of: `missing`, `thin`, `outdated`
- `opportunity_score` — 0-100, calculated as:
  - Search volume weight (40%): higher volume → higher score
  - Gap severity weight (35%): missing (100) > thin (65) > outdated (40)
  - Goal alignment weight (25%): how well the keyword aligns with the project's stated goals
- `recommended_action` — specific action to exploit this gap (e.g., "Create a comprehensive 3000-word guide covering [topic] with original data")

**Minimum 5 content gaps required.** Aim for 8-10 for a thorough analysis.

Sort content gaps by opportunity_score (highest first).

## Writing the Output

Present the complete analysis for review:

```
## Competitor Analysis Summary

### Competitors Analyzed: [N]

1. [domain] — DA: [da]
   Strengths: [top 2 strengths]
   Weaknesses: [top 2 weaknesses]
   Backlinks: [referring_domains] referring domains

2. [domain] — DA: [da]
   ...

### Content Gaps Found: [N]

| # | Keyword | Gap Type | Score | Action |
|---|---------|----------|-------|--------|
| 1 | [keyword] | [type] | [score] | [action summary] |
| 2 | ... | ... | ... | ... |

Does this analysis look reasonable? I can adjust competitors
or gap scoring before we save.
```

Present for review — if the user wants adjustments, make them. Then write to `seo-strategy.yml`:

```yaml
competitors:
  analyzed:
    - domain: "competitor1.com"
      domain_authority: 65
      top_keywords:
        - keyword: "project management software"
          position: 3
          estimated_traffic: 8500
        - keyword: "task tracking tool"
          position: 7
          estimated_traffic: 2100
        - keyword: "team collaboration platform"
          position: 5
          estimated_traffic: 4200
      content_strengths:
        - "Comprehensive blog with 3 posts per week covering industry trends"
        - "Strong resource library with downloadable templates and guides"
      content_weaknesses:
        - "No video content — missing YouTube and visual learner audience"
        - "Product comparison pages are thin (< 500 words) with no structured data"
      backlink_profile:
        total_backlinks: 45000
        referring_domains: 2800
        top_sources:
          - "techcrunch.com"
          - "g2.com"
          - "capterra.com"

  content_gaps:
    - keyword: "project management for remote teams guide"
      gap_type: "missing"
      opportunity_score: 85
      recommended_action: "Create a comprehensive 3000-word guide covering remote project management with templates and case studies"
    - keyword: "agile vs waterfall comparison 2026"
      gap_type: "outdated"
      opportunity_score: 72
      recommended_action: "Publish an updated comparison with current statistics and real-world examples"
```

Update `state.yml`:
- Set `current_phase: "competitor-analysis"`
- Add phase entry with `status: "complete"` and checkpoint results

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `competitors_count` | ≥ 3 competitors, each with `domain`, `domain_authority` (0-100), `top_keywords` (≥ 3 entries) | Identify more competitors |
| `content_analysis` | Each competitor has ≥ 2 `content_strengths` and ≥ 2 `content_weaknesses` | Analyze content for incomplete competitors |
| `backlink_profiles` | Each has `backlink_profile` with `total_backlinks`, `referring_domains`, `top_sources` | Estimate backlinks for incomplete profiles |
| `content_gaps` | ≥ 5 gaps, each with `keyword`, `gap_type` (missing/thin/outdated), `opportunity_score` (0-100), `recommended_action` | Cross-reference weaknesses to find more gaps |

**On pass:** Update state.yml → mark phase 3 complete, write recovery notes, advance to phase 4 (on-page-optimization).

**On fail:** Fix the failing checks, re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Project: [name] ([industry])
Competitors: [N] analyzed ([comma-separated domains])
Avg competitor DA: [average]
Content gaps: [N] found (top: [top 3 by score])
Highest opportunity: [keyword] (score: [score], type: [gap_type])
Key insight: [one-sentence summary of the competitive landscape]
```
