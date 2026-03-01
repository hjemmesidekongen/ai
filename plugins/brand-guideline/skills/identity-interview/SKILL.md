---
name: identity-interview
description: >
  Runs an interactive interview to capture the brand's foundation: name, tagline,
  industry, mission, vision, values, brand story, positioning, and competitive
  landscape. Writes the meta and identity sections to brand-reference.yml.
  Use when running /brand:generate, starting brand creation, beginning a new
  brand, or during skill 1 of 9 in the brand pipeline.
phase: 1
depends_on: []
writes:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
reads: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "brand_name_present"
    - name: "mission_statement"
    - name: "values_count"
    - name: "positioning_structure"
---

# Identity Interview

Phase 1 of brand generation. The first skill that runs — everything else builds on the foundation captured here. Produces the `meta` and `identity` sections of `brand-reference.yml`.

## Context

**Writes:** `brand-reference.yml#meta`, `brand-reference.yml#identity`
**Reads:** nothing (first skill in pipeline)
**Checkpoint:** data_validation — brand_name_present, mission_statement, values_count, positioning_structure
**Depends on:** nothing

## Process Summary

1. Check findings.md and state.yml errors from any previous session
2. Call decision-reader for domain `brand-identity` — apply brainstorm decisions by confidence level
3. Stage 1 — Brand Basics: collect name, tagline, industry, website → write `meta` section
4. Stage 2 — Mission Statement: capture why the brand exists → write `identity.mission`
5. Stage 3 — Vision Statement: capture where the brand is heading → write `identity.vision`
6. Stage 4 — Core Values: collect 3-5 values with descriptions → write `identity.values`
7. Stage 5 — Positioning Statement: walk through target/category/differentiator/proof template → write `identity.positioning`
8. Stage 6 — Brand Story & Competitive Landscape: capture origin story and competitor notes
9. Present full summary to user for approval, then write brand-reference.yml (both sections)
10. Run checkpoint; on pass update state.yml with recovery notes and advance to phase 2

## Execution

Before executing, read `references/process.md` for detailed instructions.
