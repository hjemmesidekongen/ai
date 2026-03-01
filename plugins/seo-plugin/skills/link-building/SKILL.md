---
name: link-building
description: >
  Develops a link-building strategy with outreach targets, content promotion
  tactics, and authority-building recommendations. Writes the link_building
  section to seo-strategy.yml. Use when developing link-building strategy,
  identifying outreach targets, running /seo:strategy skill 6 of 8, or
  planning content promotion.
phase: 6
depends_on: [competitor-analysis, content-strategy]
writes:
  - "seo-strategy.yml#link_building"
reads:
  - "seo-strategy.yml#competitors"
  - "seo-strategy.yml#content_plan"
  - "brand-reference.yml#identity (via brand-context-loader)"
brand_sections_needed:
  - "identity.name"
  - "identity.positioning"
  - "identity.values"
checkpoint:
  type: data_validation
  required_checks:
    - name: "strategies_count"
      verify: "link_building.strategies has at least 3 entries, each with name (string), description (string), estimated_effort (low|medium|high), expected_impact (low|medium|high), timeline (string), and tactics (array with at least 2 entries)"
      fail_action: "Add more link-building strategies with all required fields"
    - name: "outreach_targets_count"
      verify: "link_building.outreach_targets has at least 5 entries, each with category (string), criteria (string), and estimated_count (number)"
      fail_action: "Identify more outreach target categories based on competitor backlink analysis"
    - name: "content_promotion_channels"
      verify: "link_building.content_promotion has at least 3 channels, each with channel (string) and tactics (array with at least 2 entries)"
      fail_action: "Add more content promotion channels with specific tactics"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Link Building

Phase 6 of SEO strategy generation. Develops a link-building strategy informed by competitor backlink analysis and aligned with the content plan.

## Context

- **Reads:** seo-strategy.yml (competitors, content_plan, project_context), brand-reference.yml (identity)
- **Writes:** seo-strategy.yml#link_building
- **Checkpoint:** data_validation -- strategies >= 3, outreach targets >= 5, promotion channels >= 3
- **Dependencies:** competitor-analysis, content-strategy

## Process Summary

1. Read prerequisite docs (implementation plan + addendum "Link-Building in 2026")
2. Load context from seo-strategy.yml (competitor backlinks, content plan, project context)
3. Load brand identity via brand-context-loader
4. Analyze competitor backlink patterns and identify opportunities
5. Define >= 3 link-building strategies with effort/impact/timeline/tactics
6. Identify >= 5 outreach target categories with criteria and estimated counts
7. Create content promotion plan with >= 3 channels and tactics
8. Align outreach messaging with brand identity
9. Present strategy summary for review, then write to seo-strategy.yml
10. Run checkpoint validation, write recovery notes, advance to phase 7

## Execution

Read `references/process.md` for detailed step-by-step instructions, YAML examples, strategy templates, outreach target examples, and checkpoint/recovery details.
