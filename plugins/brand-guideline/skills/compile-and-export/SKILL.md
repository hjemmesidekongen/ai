---
name: compile-and-export
description: >
  Final skill in the brand generation pipeline. Validates brand-reference.yml
  against the full schema, generates the brand manual (md + docx), creates the
  asset conversion script, web integration files, and an interactive brand
  preview page. Runs asset conversion if ImageMagick is available. Triggers
  mandatory QA review on all outputs.
  Use when finalizing brand deliverables, compiling brand manual, running
  /brand:generate skill 9 of 9, generating asset scripts, or triggering QA review.
phase: 9
depends_on: [identity-interview, audience-personas, tone-of-voice, typography-color, visual-identity, logo-design, content-rules, social-media]
writes:
  - "brand-manual.md"
  - "brand-manual.docx"
  - "scripts/generate-assets.sh"
  - "assets/favicons/site.webmanifest"
  - "assets/favicons/browserconfig.xml"
  - "html-head-snippet.html"
  - "preview/brand-preview.html"
reads:
  - "brand-reference.yml"
  - "state.yml"
  - "assets/**/*.svg"
checkpoint:
  type: schema_validation
  required_checks:
    - name: "schema_valid"
    - name: "cross_references"
    - name: "manual_sections"
    - name: "docx_valid"
    - name: "script_executable"
    - name: "webmanifest_valid"
    - name: "preview_html"
  qa_review: mandatory
---

# Compile & Export

Phase 9 — the final skill in the brand generation pipeline. Takes everything produced
by phases 1-8 and creates finished deliverables: validated brand reference, professional
documentation, asset tooling, and an interactive preview.

**This is the only skill with a mandatory QA review.** The implementing agent never
self-grades — a dedicated QA agent reviews all outputs before the brand is marked complete.

## Context

**Reads:** complete `brand-reference.yml`, `state.yml`, `assets/**/*.svg`, `findings.md` (if present)

**Writes:** `brand-manual.md`, `brand-manual.docx`, `scripts/generate-assets.sh`,
`assets/favicons/site.webmanifest`, `assets/favicons/browserconfig.xml`,
`html-head-snippet.html`, `preview/brand-preview.html`

**Checkpoint:** `schema_validation` — schema_valid (all 9 sections), cross_references,
manual_sections (all 9), docx_valid, script_executable, webmanifest_valid, preview_html.
QA review is mandatory on pass.

**Depends on:** all 8 previous phases complete in state.yml

## Process Summary

1. Verify all 8 previous phases complete in state.yml; stop if any are missing
2. Step 1 — Validate brand-reference.yml: schema completeness (9 sections + minimums), cross-reference integrity (colors/fonts/logo/channels), empty field scan; present results before proceeding
3. Step 2 — Generate brand-manual.md: 9 sections (About the Brand, Target Audience, Brand Voice, Color System, Typography, Logo Usage, Visual Identity, Content Rules, Social Media) + Appendix; use findings.md for richer narrative
4. Step 3 — Generate brand-manual.docx: pandoc conversion with TOC, heading hierarchy, tables, page numbers; note pandoc install if unavailable
5. Step 4 — Generate scripts/generate-assets.sh: full ImageMagick script for logo PNGs (1x/2x/3x), favicons (16/32/48/96px + ICO + apple-touch), iOS icons (11 sizes), Android icons (5 densities), PWA icons (8 sizes), social image PNGs; chmod +x
6. Step 5 — Generate web integration files: site.webmanifest (JSON, 8 PWA icon sizes), browserconfig.xml (Windows tiles), html-head-snippet.html (favicon/OG/Twitter meta tags)
7. Step 6 — Generate preview/brand-preview.html: self-contained HTML with logo gallery, color swatches (click-to-copy), typography samples, voice summary, audience cards, asset index; light/dark toggle + smooth scroll
8. Step 7 — Run asset conversion: execute generate-assets.sh if ImageMagick available; report generated/skipped counts; provide install instructions if unavailable
9. Step 8 — Version stamp: call version-meta-stamper skill to add `_meta` block to brand-reference.yml
10. Step 9 — Final summary: list all deliverables with status; hand off to QA agent with acceptance criteria
11. Run checkpoint; QA agent reviews and approves or rejects with findings

## Execution

Before executing, read `references/process.md` for detailed instructions.
