---
name: content-strategy
user-invocable: false
description: >
  Creates a content plan with topic clusters, content calendar framework,
  content types, and SEO-optimized content guidelines aligned with brand voice.
  Writes the content_plan section to seo-strategy.yml.
  Use when creating content plan, building topic clusters, running /seo:strategy
  skill 5 of 8, or defining content calendar.
phase: 5
depends_on: [keyword-research, competitor-analysis]
writes:
  - "seo-strategy.yml#content_plan"
reads:
  - "seo-strategy.yml#keywords"
  - "seo-strategy.yml#competitors"
  - "brand-reference.yml#voice (via brand-context-loader)"
  - "brand-reference.yml#audience (via brand-context-loader)"
  - "brand-reference.yml#content (via brand-context-loader)"
brand_sections_needed:
  - "voice.attributes"
  - "voice.channel_variations"
  - "audience.segments"
  - "audience.personas"
  - "content.content_types"
  - "content.seo_guidelines"
checkpoint:
  type: data_validation
  required_checks:
    - name: "topic_clusters_count"
      verify: "content_plan.topic_clusters has at least 3 entries"
      fail_action: "Group more primary keywords into additional topic clusters"
    - name: "pillar_pages_complete"
      verify: "Each topic cluster has a pillar page with title (string), target_keyword (string), word_count (number 3000-6000), and content_type (string)"
      fail_action: "Add missing pillar page fields -- ensure title, target_keyword, word_count (3000-6000), and content_type"
    - name: "supporting_pages_count"
      verify: "Each topic cluster has at least 3 supporting pages with title, target_keyword, search_intent, word_count, content_type, and priority fields"
      fail_action: "Add more supporting pages using secondary and long-tail keywords from the keyword research"
    - name: "content_types_defined"
      verify: "content_plan.content_types has at least 3 entries, each with type (string), word_count_range (string), structure (string), and seo_elements (array)"
      fail_action: "Define more content types with word_count_range, structure, and seo_elements"
    - name: "calendar_months"
      verify: "content_plan.calendar.months_planned is at least 3"
      fail_action: "Extend the content calendar to cover at least 3 months"
    - name: "calendar_schedule"
      verify: "content_plan.calendar.schedule has entries for all planned months with content arrays"
      fail_action: "Add content entries for months missing from the schedule"
  on_fail: "Fix issues and re-run checkpoint. Advance to next phase only after all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Content Strategy

Phase 5 of SEO strategy generation. Transforms keyword research and competitive insights into an actionable content plan organized around topic clusters. Output feeds into `/seo:content-brief`.

## Context

- **Reads:** `seo-strategy.yml#keywords` (primary, secondary, long_tail), `seo-strategy.yml#competitors` (content_gaps), brand-reference.yml (voice, audience, content via brand-context-loader)
- **Writes:** `seo-strategy.yml#content_plan` (topic_clusters, content_types, calendar)
- **Checkpoint:** data_validation -- cluster count, pillar pages, supporting pages, content types, calendar
- **Dependencies:** keyword-research and competitor-analysis must be complete
- **Non-interactive:** Generate full content plan, present for review, then write YAML

## Process Summary

1. Load keywords, competitor content gaps, and brand data (voice, audience, content)
2. Build 3+ topic clusters: group primary keywords as pillars, secondary/long-tail as supporting pages
3. Incorporate competitor content gaps (opportunity_score >= 60) into clusters
4. Define 3-6 content type templates (ultimate_guide, how_to, listicle, etc.) with SEO elements
5. Create 3-month content calendar with realistic publishing cadence
6. Align content tone with brand voice attributes and channel variations (if available)
7. Present content plan for review, then write content_plan section to seo-strategy.yml
8. Run checkpoint validation (max 3 rounds), write recovery notes, advance to phase 6

## Execution

Read `references/process.md` for the complete generation process including:
- Context loading from keywords, competitors, and brand-reference.yml
- Topic cluster building rules (pillar 3000-6000 words, supporting 1500-3000)
- Content gap incorporation, content type definitions, and calendar scheduling
- Brand voice alignment, output format, checkpoint table, and recovery notes
