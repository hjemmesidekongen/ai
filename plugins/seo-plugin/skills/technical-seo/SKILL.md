---
name: technical-seo
description: >
  Produces a technical SEO checklist covering site speed, mobile-friendliness,
  crawlability, indexation, structured data, and Core Web Vitals targets.
  Writes the technical section to seo-strategy.yml.
  Use when creating technical SEO checklist, defining Core Web Vitals targets,
  running /seo:strategy skill 3 of 8 (parallel), or auditing mobile readiness.
phase: 3
depends_on: [project-interview]
writes:
  - "seo-strategy.yml#technical"
reads:
  - "seo-strategy.yml#project_context"
checkpoint:
  type: data_validation
  required_checks:
    - name: "core_web_vitals"
      verify: "technical.core_web_vitals has lcp (target <= 2.5, unit 'seconds'), fid (target <= 100, unit 'milliseconds'), and cls (target <= 0.1, unit 'score')"
      fail_action: "Add missing Core Web Vitals targets with correct thresholds"
    - name: "checklist_coverage"
      verify: "technical.checklist has at least 10 items across at least 4 categories"
      fail_action: "Add more checklist items to underrepresented categories"
    - name: "checklist_fields"
      verify: "Each checklist item has item (string), priority (critical|high|medium|low), status (pending|in_progress|done|na), and category (string)"
      fail_action: "Fill in missing fields on incomplete checklist items"
    - name: "critical_items"
      verify: "At least 2 checklist items have priority 'critical'"
      fail_action: "Elevate the most impactful items to critical priority"
    - name: "mobile_requirements"
      verify: "technical.mobile_requirements has at least 4 entries"
      fail_action: "Add mobile requirements: viewport, touch targets, scrolling, font size"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Technical SEO

Phase 3 of SEO strategy generation (runs in parallel with competitor-analysis). Produces a comprehensive technical SEO checklist that serves as the audit baseline for `/seo:audit` and informs on-page-optimization.

## Context

- **Reads:** `seo-strategy.yml#project_context` (website_url, known_issues, industry)
- **Writes:** `seo-strategy.yml#technical` (core_web_vitals, checklist, mobile_requirements)
- **Checkpoint:** data_validation -- CWV targets, checklist coverage/fields, critical items, mobile requirements
- **Dependencies:** project-interview must be complete
- **Non-interactive:** Generate full checklist, present for review, then write YAML

## Process Summary

1. Load project context from seo-strategy.yml (website_url, known_issues, industry)
2. Define Core Web Vitals targets (LCP <= 2.5s, FID <= 100ms, CLS <= 0.1)
3. Generate 12-15 checklist items across 6 categories (crawlability, security, mobile, performance, accessibility, rich_results)
4. Cross-reference known issues from project interview and flag matches
5. Define 4+ mobile requirements (viewport, touch targets, scrolling, font size)
6. Present checklist for review, then write technical section to seo-strategy.yml
7. Run checkpoint validation, fix failures (max 3 rounds)
8. Write recovery notes to state.yml and advance to phase 4

## Execution

Read `references/process.md` for the complete generation process including:
- Prerequisites and spec references
- Findings persistence and 2-Action Rule
- Error logging to state.yml
- Detailed YAML structures for CWV, checklist items, and mobile requirements
- Category-specific checklist item tables with priorities
- Industry-specific schema additions (e-commerce, SaaS, local, media)
- Cross-referencing known issues procedure
- Output presentation format and YAML write structure
- Checkpoint validation table and recovery notes template
