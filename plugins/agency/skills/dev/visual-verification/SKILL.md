---
name: visual-verification
user-invocable: false
description: >
  Three-tier visual verification at section milestones during the build phase.
  Compares implemented code against Pencil design references (screenshots) to
  catch structural and visual drift. Tier 1: static code lint for token
  compliance. Tier 2: LLM vision comparison of Playwright screenshots vs Pencil
  ground truth. Tier 3: human escalation when confidence is low or at final
  milestone. Use when verifying layout skeleton, above-the-fold, full page, or
  multi-page visual consistency against design references.
phase: dev
depends_on: [scaffold, visual-render]
reads:
  - ".ai/projects/[name]/render/screenshots/*.png"
  - ".ai/projects/[name]/design/tokens/variables.css"
  - ".ai/projects/[name]/design/tokens/tailwind.config.json"
  - ".ai/projects/[name]/design/implementation-guides/*.yml"
  - ".ai/profiles/{profile}.yml"
writes:
  - ".ai/projects/[name]/dev/visual-verification-report.yml"
model_tier: principal
model: opus
interactive: true
checkpoint:
  type: visual_validation
  required_checks:
    - name: "code_lint_pass"
      verify: "All code lint checks passed or issues logged with locations"
    - name: "screenshot_captured"
      verify: "Playwright screenshots exist at breakpoints (375, 768, 1280)"
    - name: "pencil_reference_loaded"
      verify: "Ground truth Pencil screenshots loaded from render/screenshots/"
    - name: "structural_alignment"
      verify: "LLM vision check passed or escalated to human review"
    - name: "milestone_coverage"
      verify: "All applicable milestones for current build state checked"
    - name: "report_written"
      verify: "visual-verification-report.yml written with per-milestone results"
  on_fail: "Fix flagged issues, re-capture screenshots, re-run failing tier."
  on_pass: "Update state.yml, write recovery_notes, continue build phase."
---

# Visual Verification

Three-tier verification at section milestones during the build phase. Compares
implemented code against Pencil design references to catch structural drift
before it compounds.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | Pencil screenshots (ground truth), design tokens, implementation guides, profile |
| **Writes** | visual-verification-report.yml (per-milestone results, overall pass/fail) |
| **Checkpoint** | visual_validation -- 6 checks: code lint, screenshots, references, alignment, milestones, report |
| **Dependencies** | scaffold (code exists), visual-render (Pencil ground truth exists) |

## Milestones

1. **Layout skeleton** -- grid, containers, spacing before content
2. **Above the fold** -- hero + navigation complete
3. **Full page** -- all sections for a single page
4. **Multi-page** -- cross-page consistency check

## Tiers

1. **Code Lint** -- static token compliance (spacing, grid, color, typography)
2. **LLM Vision** -- Playwright vs Pencil screenshot structural comparison
3. **Human Escalation** -- when confidence < 0.6 or at final milestone

## Findings & Execution

Write intermediate results to `.ai/projects/[name]/dev/findings.md` every 2 actions. Log errors to state.yml -- never repeat a failed approach. Before executing, read `references/process.md` for tier details, milestone triggers, report schema, and integration points.
