---
name: project-interview
description: >
  Runs an interactive interview to gather project context for SEO strategy:
  website URL, industry, business model, SEO goals, target audience segments,
  and current SEO status. Writes the meta and project_context sections to
  seo-strategy.yml. Use when running /seo:strategy, starting SEO project,
  gathering project context, or during skill 1 of 8 in the SEO pipeline.
phase: 1
depends_on: []
writes:
  - "seo-strategy.yml#meta"
  - "seo-strategy.yml#project_context"
reads:
  - "brand-reference.yml#identity (via brand-context-loader)"
  - "brand-reference.yml#audience (via brand-context-loader)"
brand_sections_needed:
  - "identity.mission"
  - "identity.values"
  - "identity.positioning"
  - "audience.segments"
checkpoint:
  type: data_validation
  required_checks:
    - name: "website_url_valid"
      verify: "project_context.website_url starts with http:// or https://"
      fail_action: "Ask the user for a valid website URL"
    - name: "industry_present"
      verify: "project_context.industry is a non-empty string"
      fail_action: "Ask the user to specify their industry"
    - name: "goals_count"
      verify: "project_context.goals has at least 2 entries, each with goal, metric, target, and timeframe"
      fail_action: "Ask for additional SEO goals until at least 2 are defined"
    - name: "audience_count"
      verify: "project_context.target_audience has at least 2 segments, each with segment, search_behavior, and preferred_content"
      fail_action: "Ask for additional audience segments until at least 2 are defined"
    - name: "current_status_complete"
      verify: "project_context.current_status has domain_authority (number), indexed_pages (number), and known_issues (array)"
      fail_action: "Ask about missing current SEO status fields"
    - name: "meta_complete"
      verify: "meta has plugin_name, project_name, created_at, version, and generated_by"
      fail_action: "Fill in missing meta fields from context"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Project Interview

Phase 1 of SEO strategy generation. First skill that runs -- everything else builds on the project context captured here. Produces the `meta` and `project_context` sections of `seo-strategy.yml`.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | brand-reference.yml (identity, audience) via brand-context-loader |
| **Writes** | seo-strategy.yml#meta, seo-strategy.yml#project_context; initializes state.yml |
| **Checkpoint** | data_validation: URL valid, industry present, 2+ goals, 2+ audience segments, status complete, meta complete |
| **Dependencies** | None (first skill in pipeline) |

## Process Summary

1. Load brainstorm decisions via decision-reader (pre-fill confirmed answers)
2. Load brand context via brand-context-loader (identity, audience sections)
3. Stage 1: Collect project name + website URL -> `meta` section
4. Stage 2: Collect industry + business model -> `project_context.industry`
5. Stage 3: Collect 2+ SEO goals with metrics, targets, timeframes -> `project_context.goals`
6. Stage 4: Collect 2+ audience segments with search behavior -> `project_context.target_audience`
7. Stage 5: Collect current SEO status (DA, indexed pages, keywords, issues) -> `project_context.current_status`
8. Present summary for user confirmation, then write seo-strategy.yml + state.yml
9. Run checkpoint validation; fix failures up to 3 rounds
10. Write recovery notes to state.yml and advance to phase 2

## Execution

Follow the detailed process in [references/process.md](references/process.md).
