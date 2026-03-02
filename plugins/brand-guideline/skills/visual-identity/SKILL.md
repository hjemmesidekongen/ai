---
name: visual-identity
description: >
  Defines the brand's overall visual language: imagery direction, iconography
  rules, shape language, layout principles, and mood board description.
  Use when defining visual language, imagery direction, iconography rules,
  running /brand:generate skill 5 of 9, or establishing layout principles.
  Creates the visual framework that the logo design skill (Phase 6) must follow.
phase: 5
depends_on: [identity-interview, audience-personas, tone-of-voice, typography-color]
writes:
  - "brand-reference.yml#visual"
reads:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
  - "brand-reference.yml#voice"
  - "brand-reference.yml#colors"
  - "brand-reference.yml#typography"
checkpoint:
  type: data_validation
  required_checks:
    - name: "visual_style_dimensions"
    - name: "iconography_rules"
    - name: "layout_grid"
    - name: "shape_language"
  on_fail: "Fix issues and re-run checkpoint. Advance to next phase only after all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Visual Identity

Phase 5 of brand generation. Translates identity, voice, colors, and typography
into a cohesive visual language — the rules governing how the brand looks across
all touchpoints. Defines the visual framework that logo design (Phase 6), content
rules (Phase 7), and social media (Phase 8) build on.

This skill defines the visual environment for the logo; logo creation happens in Phase 6.

## Context

**Reads:** brand-reference.yml — meta, identity (values, positioning), voice (personality, spectrum), colors.primary, colors.accent, typography.primary.family
**Writes:** `brand-reference.yml#visual` (all sections except visual.logo)
**Checkpoint:** data_validation — 4 checks (visual_style_dimensions, iconography_rules, layout_grid, shape_language)
**Depends on:** identity-interview, audience-personas, tone-of-voice, typography-color must be complete

## Process Summary

1. Read all brand data — meta, identity, voice, colors, typography; connect decisions back to brand signals throughout
2. **Stage 1:** Visual direction overview — present exactly 3 directions derived from brand signals; get user's baseline choice
3. **Stage 2:** Imagery style — medium (photo/illustration/mixed), mood, subjects, avoidance; write `visual.imagery`
4. **Stage 3:** Iconography — style (outline/filled/duotone/hand-drawn), stroke width, corner radius, grid size; write `visual.iconography`
5. **Stage 4:** Shape language — direction (rounded/angular/mixed), primary shapes, accent shapes, rationale; write `visual.shape_language`
6. **Stage 5:** Layout principles — grid system, whitespace philosophy, image treatment; write `visual.layout`
7. **Stage 6:** Mood board description — draft 3-5 sentence prose capturing overall visual feeling; write `visual.mood_board`
8. Present full summary for approval; write to disk only after confirmation
9. Run data_validation checkpoint (4 checks); fix failures; advance only after all checks pass
10. Write recovery notes to state.yml including logo constraints for Phase 6

## Execution

Before executing, read `references/process.md` for detailed instructions.
