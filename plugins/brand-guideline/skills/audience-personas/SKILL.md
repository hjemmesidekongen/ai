---
name: audience-personas
user-invocable: false
description: >
  Identifies the target audience and creates detailed personas based on brand
  identity and positioning. Writes the audience section to brand-reference.yml
  and produces individual persona card markdown files in the brand directory.
  Use when defining target audience, creating buyer personas, running
  /brand:generate skill 2 of 9, or identifying market segments.
phase: 2
depends_on: [identity-interview]
writes:
  - "brand-reference.yml#audience"
  - "persona-card-*.md"
reads:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
checkpoint:
  type: data_validation
  required_checks:
    - name: "personas_count"
    - name: "persona_fields"
    - name: "primary_persona"
---

# Audience & Personas

Phase 2 of brand generation. Builds on the identity foundation from Phase 1 to identify who the brand serves and create detailed personas. The output feeds directly into tone-of-voice (Phase 3), content rules, and social media strategy.

## Context

**Writes:** `brand-reference.yml#audience`, `persona-card-*.md`
**Reads:** `brand-reference.yml#meta`, `brand-reference.yml#identity`
**Checkpoint:** data_validation — personas_count, persona_fields, primary_persona
**Depends on:** identity-interview (phase 1)

## Process Summary

1. Check findings.md and state.yml errors from any previous session
2. Read identity data from brand-reference.yml: brand_name, industry, positioning.target, positioning.category, identity.mission
3. Call decision-reader for domain `brand-audience` — apply brainstorm decisions by confidence level
4. Stage 1 — Market Type & Overview: B2B/B2C/Both and primary market description → write `audience.primary_market`
5. Stage 2 — Audience Segments: identify 2-3 distinct groups that will become persona cards
6. Stage 3 — Persona Deep Dive: for each segment, collect name, role, age range, goals, frustrations, channels, decision factors, content preferences, quote
7. Stage 4 — Primary Persona Selection: ask which persona is most important; reorder array so primary is first
8. Present full audience summary to user for approval, then write brand-reference.yml and persona card files
9. Run checkpoint; on pass update state.yml with recovery notes and advance to phase 3

## Execution

Before executing, read `references/process.md` for detailed instructions.
