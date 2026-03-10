---
name: accessibility-wcag
description: >
  WCAG 2.1 AA compliance — ARIA, keyboard navigation, screen readers, color
  contrast, and semantic HTML. Covers the POUR principles, semantic-first
  authoring, ARIA as last resort, and practical testing workflows.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "accessibility"
  - "wcag"
  - "aria"
  - "a11y"
  - "screen reader"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "semantic_html_first"
      verify: "Native HTML elements used before ARIA roles — no div/span replacing button, nav, or heading"
      fail_action: "Replace with correct semantic element; remove redundant role attribute"
    - name: "aria_not_hiding_content"
      verify: "aria-hidden does not conceal interactive elements or focusable content"
      fail_action: "Remove aria-hidden from interactive elements; restructure DOM order"
    - name: "color_contrast_aa"
      verify: "Text contrast ≥4.5:1 normal, ≥3:1 large text and UI components"
      fail_action: "Adjust foreground/background values to meet ratio — do not rely on color alone"
    - name: "keyboard_operable"
      verify: "All interactive elements reachable via keyboard; no focus traps outside modal contexts"
      fail_action: "Add tabindex, keyboard handlers, or focus management as required"
    - name: "form_labels_present"
      verify: "Every form input has an associated label (explicit, aria-label, or aria-labelledby)"
      fail_action: "Add visible label or aria-label — placeholder text is not a label"
  on_fail: "Accessibility violations found — resolve before merging"
  on_pass: "WCAG 2.1 AA checks passed"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
---

# accessibility-wcag

Accessibility is structural. Retrofit is expensive — build it in from the first element.

## POUR Principles

**Perceivable** — content and UI components must be presentable in ways users can perceive: text alternatives for non-text content, captions, adaptable layout, sufficient contrast.

**Operable** — all functionality available via keyboard, no timing traps, no content that causes seizures, skip navigation provided.

**Understandable** — text is readable, pages behave predictably, input errors are identified and described.

**Robust** — content is compatible with current and future assistive technologies; valid HTML is the baseline.

## AA vs AAA

Target AA in production. AAA is aspirational — pursue it for high-stakes content (legal, medical, public services) but do not block release on AAA failures. Document AAA gaps explicitly.

## Semantic HTML First

Native elements carry free accessibility: `<button>` handles focus, keyboard activation, and role without ARIA. Use semantic elements before reaching for ARIA. Wrong element + ARIA is always worse than the right element alone.

```
button, a, nav, main, aside, header, footer, section, article,
h1–h6, ul/ol/li, table, form, fieldset, legend, label, input, select, textarea
```

## ARIA as Last Resort

ARIA supplements missing semantics — it does not fix incorrect markup. Rule of thumb: if a native element exists, use it. ARIA is correct when you build custom widgets (combobox, tree, dialog) that have no HTML equivalent.

First rule of ARIA: do not use ARIA if a native element provides the semantics.

See `references/process.md` for the full checklist, ARIA roles/states/properties, keyboard patterns, screen reader testing, React patterns, and testing tools.
