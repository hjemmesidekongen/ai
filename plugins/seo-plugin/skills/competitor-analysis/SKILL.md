---
name: competitor-analysis
description: >
  Analyzes top competitors for target keywords, identifying their strengths,
  weaknesses, content gaps, and backlink profiles. Writes the competitors
  section to seo-strategy.yml. Use when analyzing competitors, identifying
  content gaps, running /seo:strategy skill 3 of 8, or evaluating backlink
  profiles.
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
  on_fail: "Fix issues and re-run checkpoint. Advance to next phase only after all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Competitor Analysis

Phase 3 of SEO strategy generation (runs in parallel with technical-seo). Analyzes the competitive landscape to identify content gaps and link-building opportunities. Output feeds into content-strategy (Phase 5) and link-building (Phase 6).

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | seo-strategy.yml#project_context, seo-strategy.yml#keywords |
| **Writes** | seo-strategy.yml#competitors (analyzed array + content_gaps array) |
| **Checkpoint** | data_validation: 3+ competitors with DA/keywords/strengths/weaknesses/backlinks, 5+ content gaps |
| **Dependencies** | project-interview (Phase 1); uses keywords from Phase 2 if available |

## Process Summary

1. Load project context from seo-strategy.yml (industry, URL, goals, current status)
2. Load keywords.primary if available (identifies keyword competitors)
3. Step 1: Identify 3-5 competitors (direct, keyword, and content competitors)
4. Step 2: Estimate domain authority (0-100) for each competitor
5. Step 3: Identify top 5-10 ranking keywords per competitor with position estimates
6. Step 4: Analyze 2-4 content strengths per competitor (specific, actionable)
7. Step 5: Analyze 2-4 content weaknesses per competitor (exploitable opportunities)
8. Step 6: Estimate backlink profiles (total backlinks, referring domains, top sources)
9. Step 7: Cross-reference weaknesses to identify 5+ content gaps with opportunity scores
10. Present full analysis for review, then write to seo-strategy.yml and update state.yml
11. Run checkpoint validation; fix failures up to 3 rounds
12. Write recovery notes to state.yml and advance to phase 4

## Execution

Follow the detailed process in [references/process.md](references/process.md).
