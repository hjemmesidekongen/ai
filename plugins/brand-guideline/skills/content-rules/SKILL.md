---
name: content-rules
description: >
  Defines writing standards, content type specifications, SEO guidelines, legal
  requirements, and a content review checklist. Builds on the brand's identity,
  audience personas, and tone of voice to produce actionable rules for all brand
  content. Writes the content section to brand-reference.yml.
  Use when defining writing standards, content guidelines, running /brand:generate
  skill 7 of 9, establishing editorial rules, or creating content type specs.
phase: 7
depends_on: [identity-interview, audience-personas, tone-of-voice]
writes:
  - "brand-reference.yml#content"
reads:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
  - "brand-reference.yml#audience"
  - "brand-reference.yml#voice"
checkpoint:
  type: data_validation
  required_checks:
    - name: "spelling_convention"
    - name: "content_types_count"
    - name: "readability_target"
    - name: "seo_guidelines"
---

# Content Rules

Phase 7 of brand generation. Translates the brand's voice, audience, and identity
into concrete, enforceable writing rules governing every piece of content the brand
produces — from blog posts to error messages.

## Context

**Reads:** `meta.brand_name`, `meta.industry`, `identity.values`, `identity.positioning`,
`audience.personas`, `voice.personality`, `voice.spectrum`, `voice.vocabulary`

**Writes:** `brand-reference.yml#content` (grammar, dos/donts, terminology,
content_types, seo, legal, review_checklist)

**Checkpoint:** `data_validation` — spelling_convention, content_types_count (≥3),
readability_target, seo_guidelines (meta_description + heading_hierarchy)

**Depends on:** identity-interview, audience-personas, tone-of-voice

## Process Summary

1. Read brand data from brand-reference.yml (identity, audience, voice sections)
2. Stage 1 — Writing standards: spelling, date format, numbers, currency, capitalization, Oxford comma, abbreviations → `content.grammar`
3. Stage 2 — Dos and don'ts: generate from voice data, present 4-6 of each for review → `content.dos`, `content.donts`
4. Stage 3 — Terminology: preferred terms vs. avoided, industry glossary → `content.terminology`
5. Stage 4 — Content types: suggest from industry/channels, define length/tone/structure for each (min 3) → `content.content_types`
6. Stage 5 — SEO guidelines: meta descriptions, heading hierarchy, keyword approach, internal linking → `content.seo`
7. Stage 6 — Legal and review checklist: disclaimers, trademark rules, readability target, accessibility → `content.legal`, `content.review_checklist`
8. Present full summary for user approval, then write to brand-reference.yml
9. Run checkpoint; on pass update state.yml and write recovery notes

## Execution

Before executing, read `references/process.md` for detailed instructions.
