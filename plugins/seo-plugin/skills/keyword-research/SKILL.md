---
name: keyword-research
description: >
  Conducts keyword research identifying primary, secondary, and long-tail
  keywords with search volume estimates, difficulty scores, and search intent
  classification. Writes the keywords section to seo-strategy.yml. Use when
  conducting keyword research, identifying target keywords, running
  /seo:strategy skill 2 of 8, or analyzing search intent.
phase: 2
depends_on: [project-interview]
writes:
  - "seo-strategy.yml#keywords"
reads:
  - "seo-strategy.yml#project_context"
  - "brand-reference.yml#voice (via brand-context-loader)"
  - "brand-reference.yml#content (via brand-context-loader)"
brand_sections_needed:
  - "voice.vocabulary"
  - "voice.attributes"
  - "content.seo_guidelines"
checkpoint:
  type: data_validation
  required_checks:
    - name: "primary_keywords_count"
      verify: "keywords.primary has at least 5 entries, each with keyword, search_volume (number), difficulty (0-100), search_intent (enum), and priority (enum)"
      fail_action: "Generate more primary keywords and ask user to confirm"
    - name: "secondary_keywords_count"
      verify: "keywords.secondary has at least 10 entries, each with search_volume, difficulty, and search_intent"
      fail_action: "Generate more secondary keywords from seed variations"
    - name: "longtail_keywords_count"
      verify: "keywords.long_tail has at least 15 entries, each with search_volume, difficulty, and search_intent"
      fail_action: "Generate more long-tail keywords (question-based, specific phrases)"
    - name: "intent_classification"
      verify: "Every keyword has search_intent set to one of: informational, navigational, commercial, transactional"
      fail_action: "Classify any unclassified keywords"
    - name: "no_duplicates"
      verify: "No duplicate keywords across primary, secondary, and long_tail arrays"
      fail_action: "Remove duplicate keywords, keeping the one in the highest-priority category"
  on_fail: "Fix issues and re-run checkpoint. Advance to next phase only after all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Keyword Research

Phase 2 of SEO strategy generation. Builds on project context from Phase 1 to identify target keywords organized by priority and search intent. Output feeds into competitor-analysis (Phase 3), on-page-optimization, and content-strategy.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | seo-strategy.yml#project_context; brand-reference.yml (voice, content) via brand-context-loader |
| **Writes** | seo-strategy.yml#keywords (primary, secondary, long_tail arrays) |
| **Checkpoint** | data_validation: 5+ primary, 10+ secondary, 15+ long-tail, all intent-classified, no duplicates |
| **Dependencies** | project-interview (Phase 1 must be complete) |

## Process Summary

1. Load project context from seo-strategy.yml (industry, goals, audience, existing keywords)
2. Load brand context via brand-context-loader (voice.vocabulary, content.seo_guidelines)
3. Stage 1: Generate 10+ seed keywords from industry, goals, audience, brand vocabulary
4. Stage 2: Expand seeds into secondary (2-3 per seed) and long-tail (3-5 per seed) variations
5. Stage 3: Estimate search volume, difficulty (0-100), and classify search intent for each keyword
6. Stage 4: Present organized keyword list; user sets priority (high/medium/low) for primary keywords
7. Stage 5: Deduplicate across all arrays, validate minimum counts
8. Present summary with intent breakdown for user confirmation, then write to seo-strategy.yml
9. Run checkpoint validation; fix failures up to 3 rounds
10. Write recovery notes to state.yml and advance to phase 3

## Execution

Follow the detailed process in [references/process.md](references/process.md).
