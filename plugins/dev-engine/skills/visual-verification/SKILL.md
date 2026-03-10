---
name: visual-verification
description: >
  Captures Playwright screenshots at 3 breakpoints and verifies UI output
  against design intent. Three verification tiers: automated layout checks,
  LLM vision comparison, and human escalation for low-confidence results.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "visual verification"
  - "screenshot check"
  - "UI verification"
  - "visual regression"
reads:
  - "changed UI files (components/, pages/, layouts/, styles/)"
writes:
  - ".ai/tasks/visual/<task-id>/"
checkpoint:
  type: data_validation
  required_checks:
    - name: "screenshots_captured"
      verify: "Screenshots exist at all 3 breakpoints for each changed view"
      fail_action: "Retry screenshot capture"
    - name: "comparison_complete"
      verify: "Each screenshot has a verification result (pass/fail/escalate)"
      fail_action: "Run comparison on missing screenshots"
    - name: "no_unresolved_escalations"
      verify: "All human-escalated items have been reviewed or acknowledged"
      fail_action: "Flag unresolved escalations in gate results"
  on_fail: "Visual verification incomplete — capture missing screenshots or resolve escalations"
  on_pass: "Visual output matches intent at all breakpoints"
_source:
  origin: "dev-engine"
  inspired_by: "agency visual-verification + D-019"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Built for dev-engine with 3-tier verification and Playwright MCP integration"
---

# Visual Verification

Screenshots at 3 breakpoints, compared against intent. Only triggered for UI changes.

## Breakpoints

| Name | Width | Represents |
|------|-------|-----------|
| mobile | 375px | iPhone SE |
| tablet | 768px | iPad |
| desktop | 1280px | Standard laptop |

## Trigger Detection

Activated when changed files match: `components/`, `pages/`, `layouts/`,
`styles/`, `*.css`, `*.scss`, `*.tsx` with JSX, `*.vue` with template.

## Three Verification Tiers

1. **Automated** — Screenshot captured, basic layout assertions (no overflow,
   no overlapping elements, correct breakpoint width).
2. **LLM Vision** — Compare screenshot to design reference or stated intent.
   Check color, spacing, typography, alignment against spec.
3. **Human Escalation** — If LLM confidence < 0.7, flag for human review.
   Provide side-by-side comparison with specific concern noted.

## Screenshot Storage

Screenshots saved to `.ai/tasks/visual/<task-id>/`:
- `mobile.png`, `tablet.png`, `desktop.png`
- `comparison.yml` — verification results per breakpoint

See `references/process.md` for Playwright config, comparison algorithm, and escalation rules.
