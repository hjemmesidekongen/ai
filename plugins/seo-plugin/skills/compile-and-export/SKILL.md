---
name: compile-and-export
description: >
  Compiles all strategy sections into a cohesive SEO strategy document in
  Markdown format and validates the complete seo-strategy.yml. Final skill
  in the SEO strategy pipeline. Use when finalizing SEO strategy, compiling
  strategy document, running /seo:strategy skill 7 of 8 (final), or
  triggering QA review.
phase: 7
depends_on: [project-interview, keyword-research, competitor-analysis, on-page-optimization, technical-seo, content-strategy, link-building]
writes:
  - "seo-strategy.md"
  - "seo-strategy.yml#meta.updated_at"
  - "seo-strategy.yml#meta.version"
reads:
  - "seo-strategy.yml"
  - "state.yml"
checkpoint:
  type: file_validation
  required_checks:
    - name: "document_exists"
      verify: "seo-strategy.md exists and is at least 2000 words"
      fail_action: "Regenerate the document — ensure all 7 sections produce sufficient content"
    - name: "document_sections"
      verify: "seo-strategy.md contains all 7 sections: Executive Summary, Keyword Strategy, Competitor Landscape, On-Page Optimization Rules, Technical SEO Checklist, Content Plan, Link-Building Strategy"
      fail_action: "Add missing sections by reading the corresponding seo-strategy.yml data"
    - name: "yaml_complete"
      verify: "seo-strategy.yml has all 8 top-level sections: meta, project_context, keywords, competitors, on_page, technical, content_plan, link_building"
      fail_action: "Identify missing sections and report which skills need to run to fill them"
    - name: "no_placeholders"
      verify: "No placeholder text remains in any output file — no '[project-name]', no 'TODO', no '[from design]'"
      fail_action: "Replace all placeholder text with actual data from seo-strategy.yml"
  qa_review: mandatory
  on_fail: "Fix issues and re-run checkpoint. Mark strategy generation complete only after all checks pass."
  on_pass: "Update state.yml → mark phase 7 complete. Trigger QA agent review of all outputs."
---

# Compile & Export

Phase 7 -- the final skill in SEO strategy generation. Compiles phases 1-6 into a cohesive strategy document with mandatory QA review.

## Context

- **Reads:** seo-strategy.yml (all sections), state.yml
- **Writes:** seo-strategy.md, seo-strategy.yml#meta
- **Checkpoint:** file_validation -- document exists (2000+ words), all 7 sections, YAML complete (8 sections), all placeholder text replaced with actual data
- **QA Review:** Mandatory -- implementing agent never self-grades
- **Dependencies:** all 6 previous phases must be complete

## Process Summary

1. Read prerequisite docs (implementation plan + strategy template)
2. Verify all 6 previous phases are complete in state.yml
3. Validate all data sections meet minimum criteria
4. Generate Executive Summary (project overview, key opportunities, first actions)
5. Generate Keyword Strategy section (primary/secondary/long-tail tables)
6. Generate Competitor Landscape section (comparison + content gaps)
7. Generate On-Page Optimization Rules section
8. Generate Technical SEO Checklist section (CWV targets + checklist + mobile)
9. Generate Content Plan section (topic clusters + calendar)
10. Generate Link-Building Strategy section (strategies + outreach + promotion)
11. Assemble document using template, update meta and version stamp
12. Run checkpoint validation, trigger QA review

## Execution

Read `references/process.md` for detailed step-by-step instructions, section generation templates, validation criteria tables, and checkpoint/recovery details.
