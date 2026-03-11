---
name: pencil-tokens
user_invocable: false
interactive: false
description: >
  Bridges design tokens to Pencil. Reads tokens.yml and guideline.yml, resolves
  all YAML references to concrete values, maps semantic colors + typography +
  spacing + radius + shadows to Pencil's set_variables format, then calls
  set_variables. Light mode only. One-shot token injection — run before any
  Pencil design work.
depends_on: [visual-identity]
writes: []
reads:
  - ".ai/design/{name}/tokens.yml"
  - ".ai/brand/{name}/guideline.yml"
triggers:
  - pencil tokens
  - set variables
  - load tokens into pencil
  - pencil variables
model_tier: senior
model: sonnet
checkpoint:
  type: token_validation
  required_checks:
    - name: "tokens_yml_exists"
      verify: ".ai/design/{name}/tokens.yml exists and parses as valid YAML"
      fail_action: "Run /segl:design-identity first to generate tokens"
    - name: "references_resolved"
      verify: "All YAML reference strings resolved to concrete hex/number values before sending to Pencil"
      fail_action: "Walk primitives to resolve each reference — Pencil cannot interpret YAML refs"
    - name: "variables_set"
      verify: "set_variables called successfully — expect ~50 variables across all categories"
      fail_action: "Check Pencil is running and .pen file is open"
    - name: "category_coverage"
      verify: "Variables include colors (30+), typography (2+ families), spacing, radius, shadows"
      fail_action: "Check tokens.yml has all sections — may need /segl:design-identity regeneration"
  on_fail: "Report missing tokens and suggest remediation"
  on_pass: "Pencil variables loaded — ready for design work"
_source:
  origin: original
  ported_date: "2026-03-11"
  iteration: 3
  changes: ["initial creation", "audit fixes: depends_on, date, reference resolution, dark mode note, missing tokens", "audit round 2: variable count corrected to ~50, hex casing, status palette docs"]
---

# Pencil Tokens

Reads design tokens from `.ai/design/{name}/tokens.yml` and brand context from
`.ai/brand/{name}/guideline.yml`, then injects them into the active Pencil
document via `set_variables`. Light mode only — dark mode tokens are excluded
by default.

## Process

1. Read `tokens.yml` — parse YAML, extract all sections
2. **Resolve references** — walk all semantic values. Any value matching `"{primitives.color.*}"` must be resolved to the concrete hex from the primitives section. Pencil cannot interpret YAML references.
3. Read `guideline.yml` — extract brand name, tagline for context
4. Map to Pencil variable format (see `references/process.md` for mapping table)
5. Call `set_variables` with the complete variable set (~50 variables)
6. Run checkpoint — verify variables were accepted

## Token Mapping Summary

| tokens.yml section | Pencil variable type | Example |
|---|---|---|
| semantic.color.* (all keys) | color | `primary` → `#e1943d` |
| primitives.color.{palette}.50/100/900 | color | `primary-50` → `#FEF7ED` |
| typography.family.* | string | `font-heading` → `"'Lato', sans-serif"` |
| spacing.scale (selected stops) | number | `spacing-md` → `16` |
| radius.* (all named stops) | number | `radius-xl` → `12` |
| shadow.* (all named stops) | string | `shadow-sm` → CSS shadow value |

## Execution

See `references/process.md` for the full mapping algorithm and edge case handling.
