---
name: typography-color
user-invocable: false
description: >
  Guides the user through color palette selection and typography system design.
  Use when designing color palette, typography system, running /brand:generate
  skill 4 of 9, defining brand colors, or establishing type hierarchy.
  Writes colors and typography sections to brand-reference.yml.
phase: 4
depends_on: [identity-interview, audience-personas, tone-of-voice]
writes:
  - "brand-reference.yml#colors"
  - "brand-reference.yml#typography"
reads:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
  - "brand-reference.yml#voice"
checkpoint:
  type: accessibility_validation
  required_checks:
    - name: "contrast_matrix"
    - name: "wcag_aa_body"
    - name: "wcag_aa_large"
    - name: "colorblind_notes"
    - name: "dark_mode"
    - name: "font_weights"
  on_fail: "Fix issues and re-run checkpoint. Advance to next phase only after all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Typography & Color System

Phase 4 of brand generation. Produces a complete, accessibility-first color system
and a typographic hierarchy. Both sections are written to `brand-reference.yml` and
validated with an `accessibility_validation` checkpoint before advancing.

## Context

**Reads:** `brand-reference.yml` — meta, identity (values, positioning), voice (personality, spectrum)
**Writes:** `brand-reference.yml#colors`, `brand-reference.yml#typography`
**Checkpoint:** accessibility_validation — 6 checks (contrast_matrix, wcag_aa_body, wcag_aa_large, colorblind_notes, dark_mode, font_weights)
**Depends on:** identity-interview, audience-personas, tone-of-voice must be complete

## Process Summary

1. Read brand data — meta, identity.values, voice.personality, voice.spectrum; stop if missing
2. **Part 1 — Color Palette**
   - Step 1: Existing colors check (has colors → skip to Step 3; fresh start → Step 2)
   - Step 2: Palette direction — present exactly 3 directions derived from brand signals
   - Step 3: Generate tint/shade scales (10 steps, 50–900) for primary, secondary, accent + semantic colors
   - Step 4: Generate neutral scale (5–7 shades, near-white to near-black)
   - Step 5: Compute contrast ratios for all foreground/background pairs (WCAG formula)
   - Step 6: Validate WCAG AA compliance — flag failures, suggest nearest passing shade
   - Step 7: Generate colorblind safety notes (protanopia, deuteranopia, tritanopia) per color
   - Step 8: Generate dark mode variants — backgrounds, text, brand adjustments, validated pairs
   - Step 9: Output contrast matrix (EightShapes-style grid of all pairs)
   - Step 10: Define color usage proportions (60/30/10 rule)
3. **Part 2 — Typography System**
   - Step 11: Font selection — personality-to-font mapping, existing fonts check, 3 pairing options
   - Step 12: Define type scale — 9 levels (H1–H6, Body, Body Small, Caption) with px/rem/weight/line-height
   - Step 13: Define font weights — max 4 per family, confirm licensing
4. Present full summary for approval, write to disk only after confirmation
5. Run accessibility_validation checkpoint (6 checks); fix failures, re-run; advance only after all checks pass

## Execution

Before executing, read `references/process.md` for detailed instructions.
