---
name: on-page-optimization
user-invocable: false
description: >
  Generates on-page SEO rules including title tag patterns, meta description
  templates, heading structure, internal linking strategy, and schema markup
  recommendations. Writes the on_page section to seo-strategy.yml.
  Use when defining on-page SEO rules, title tag patterns, heading hierarchy,
  running /seo:strategy skill 4 of 8, or configuring schema markup.
phase: 4
depends_on: [project-interview, keyword-research]
writes:
  - "seo-strategy.yml#on_page"
reads:
  - "seo-strategy.yml#project_context"
  - "seo-strategy.yml#keywords"
checkpoint:
  type: data_validation
  required_checks:
    - name: "title_tag_complete"
      verify: "on_page.title_tag has pattern (string), max_length (number <= 60), and rules (array with at least 2 entries)"
      fail_action: "Add missing title tag fields -- ensure pattern, max_length, and at least 2 rules"
    - name: "meta_description_complete"
      verify: "on_page.meta_description has pattern (string), max_length (number <= 155), and rules (array with at least 2 entries)"
      fail_action: "Add missing meta description fields -- ensure pattern, max_length, and at least 2 rules"
    - name: "heading_hierarchy_complete"
      verify: "on_page.heading_hierarchy has rules defined for h1, h2, h3, and h4 -- each with a rules array"
      fail_action: "Add rules for any missing heading level (h1 through h4)"
    - name: "internal_linking_rules"
      verify: "on_page.internal_linking has at least 3 entries, each with rule (string) and implementation (string)"
      fail_action: "Add more internal linking rules with both rule and implementation fields"
    - name: "schema_markup_types"
      verify: "on_page.schema_markup has at least 2 entries, each with type (string), required_properties (array), and use_case (string)"
      fail_action: "Add schema markup recommendations based on the project's industry and content types"
  on_fail: "Fix issues and re-run checkpoint. Advance to next phase only after all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# On-Page Optimization

Phase 4 of SEO strategy generation. Transforms keyword research into concrete on-page SEO rules guiding content creation. Output feeds into content-strategy (Phase 5) and `/seo:audit`.

## Context

- **Reads:** `seo-strategy.yml#project_context` (website_url, industry, goals), `seo-strategy.yml#keywords` (primary, secondary, long_tail)
- **Writes:** `seo-strategy.yml#on_page` (title_tag, meta_description, heading_hierarchy, internal_linking, schema_markup)
- **Checkpoint:** data_validation -- title tag, meta description, heading hierarchy, internal linking, schema markup
- **Dependencies:** project-interview and keyword-research must be complete
- **Non-interactive:** Generate all rules, present for review, then write YAML

## Process Summary

1. Load project context and keyword data from seo-strategy.yml
2. Define title tag pattern with max 60 chars and 3-4 rules (keyword placement, brand positioning)
3. Define meta description pattern with max 155 chars and 3-4 rules (keyword, CTA)
4. Define heading hierarchy rules for H1 through H4 (keyword integration per level)
5. Define 4-5 internal linking rules with implementation guidance
6. Recommend 3-4 schema markup types based on industry
7. Present rules for review, then write on_page section to seo-strategy.yml
8. Run checkpoint validation, fix failures (max 3 rounds)
9. Write recovery notes to state.yml and advance to phase 5

## Execution

Read `references/process.md` for the complete generation process including:
- Prerequisites and spec references
- Context loading from project_context and keywords
- Title tag patterns with industry customizations (e-commerce, SaaS, blog, local)
- Meta description template with action verb patterns
- Heading hierarchy rules for H1-H4 with content type variations
- Internal linking strategy (contextual, pillar-cluster, new-to-existing, orphan fix)
- Schema markup selection table (11 types) with industry mapping
- Output presentation format and YAML write structure
- Checkpoint validation table and recovery notes template
