---
name: logo-design
description: >
  Runs a 5-phase logo design process: discovery, concept generation (20-25 SVG
  concepts), refinement, finalization, and optional professional refinement.
  Use when designing brand logo, generating logo concepts, running /brand:generate
  skill 6 of 9, or creating logo system with SVG variants. Produces all logo SVG
  variants, brand icon variants, clear space rules, misuse examples, and an
  interactive HTML preview page.
phase: 6
depends_on: [identity-interview, audience-personas, tone-of-voice, typography-color, visual-identity]
writes:
  - "brand-reference.yml#visual.logo"
  - "brand-reference.yml#assets.logo"
  - "brand-reference.yml#assets.brand_icon"
  - "assets/logo/svg/*.svg"
  - "assets/brand-icon/*.svg"
  - "preview/brand-preview.html"
reads:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
  - "brand-reference.yml#audience"
  - "brand-reference.yml#voice"
  - "brand-reference.yml#colors"
  - "brand-reference.yml#typography"
  - "brand-reference.yml#visual"
checkpoint:
  type: file_validation
  required_checks:
    - name: "logo_svg_variants"
    - name: "brand_icon_variants"
    - name: "svg_validity"
    - name: "svg_file_size"
    - name: "preview_html"
    - name: "logo_mark_small_size"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Logo Design

Phase 6 of brand generation. Takes all brand data from Phases 1-5 and produces a
complete logo system through a structured 5-phase design process. Produces 6 logo
SVG variants, 4 brand icon variants, an HTML preview page, and logo usage rules.

The visual-identity skill (Phase 5) already defined the visual rules the logo must follow.

## Context

**Reads:** brand-reference.yml — meta, identity, audience, voice, colors, typography, visual (all sections)
**Writes:** visual.logo, assets.logo, assets.brand_icon in brand-reference.yml; 10 SVG files; preview/brand-preview.html
**Checkpoint:** file_validation — 6 checks (logo_svg_variants, brand_icon_variants, svg_validity, svg_file_size, preview_html, logo_mark_small_size)
**Depends on:** All of Phases 1-5 must be complete

## Process Summary

1. Read all brand data — meta, identity, voice, colors, typography, visual; logo is a distillation of everything
2. **Phase 1 — Discovery:** Reflect brand context summary → logo type preference (wordmark/lettermark/abstract/combination/emblem) → reference logos → what to avoid → design brief summary; wait for user confirmation
3. **Phase 2 — Concept Generation:** Generate 20-25 diverse SVG concepts via 4 parallel sub-agents (wordmarks, abstract marks, combination marks, mixed/wildcard); create HTML preview page at preview/brand-preview.html; ask user to pick 3-5 favorites
4. **Phase 3 — Refinement:** Generate 3-4 variations per picked concept (weight/spacing/proportion/detail/color); multi-size testing (200px, 80px, 40px, 16px); background testing (white, dark, brand color, photography, light gray); update preview; get final selection
5. **Phase 4 — Finalization:** Generate 6 logo SVG variants (full-light, full-dark, wordmark-light, wordmark-dark, mark, mark-mono) → generate 4 brand icon variants → define clear space and minimum size → document misuse rules → update preview with final logo system section → present summary for confirmation; write all files only after confirmation
6. **Phase 5 — Optional professional refinement:** Inform user about Figma/Illustrator import, print production (CMYK, Pantone), and trademark search; note in brand reference
7. Write brand-reference.yml sections (visual.logo, assets.logo, assets.brand_icon)
8. Run file_validation checkpoint (6 checks); fix failures; do not advance until all pass
9. Write recovery notes to state.yml

## Execution

Before executing, read `references/process.md` for detailed instructions.
