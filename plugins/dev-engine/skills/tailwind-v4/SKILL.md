---
name: tailwind-v4
description: >
  Tailwind CSS v4 — migration from v3, CSS-first theme configuration, custom
  utilities, dark mode strategies, container queries, and responsive design.
  Covers @theme, @utility, @variant, @apply usage, and PostCSS integration.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
reads:
  - "**/*.css"
  - "tailwind.config.*"
  - "postcss.config.*"
writes:
  - "**/*.css"
triggers:
  - "tailwind"
  - "tailwind v4"
  - "tailwind css"
  - "utility css"
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_v3_config_file"
      verify: "No tailwind.config.js/ts — v4 uses CSS-first @theme configuration"
      fail_action: "Move theme tokens into @theme block in the main CSS file"
    - name: "css_variables_in_theme"
      verify: "@theme defines variables with -- prefix, not JS objects"
      fail_action: "Convert JS theme values to CSS custom properties inside @theme"
    - name: "no_arbitrary_apply_abuse"
      verify: "@apply not used to recreate component classes that belong in HTML"
      fail_action: "Use @utility for named utilities or keep classes in markup"
    - name: "dark_mode_strategy_explicit"
      verify: "Dark mode uses .dark variant or media query — not both mixed"
      fail_action: "Pick one dark mode strategy and apply it consistently"
  on_fail: "Tailwind v4 patterns have migration gaps — fix before shipping"
  on_pass: "Tailwind v4 configuration is correct"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Original skill, no port"
---

# tailwind-v4

Tailwind v4 replaces the JS config file with CSS-first configuration. Theme, utilities, and variants all live in CSS.

## What Changed from v3

- No `tailwind.config.js` — theme defined in CSS via `@theme`
- No `@tailwind` directives — replaced by `@import "tailwindcss"`
- All theme values become CSS variables automatically
- `@utility` / `@variant` replace plugin APIs; container queries built-in

## Theme Configuration

Define tokens in `@theme` — Tailwind generates CSS variables and utility classes from them. Override defaults by redefining the same variable; remove them with `--color-*: initial`.

## Key Rules

- Import as `@import "tailwindcss"` — not three `@tailwind` directives
- Define theme tokens in `@theme {}` block in the root CSS file
- Use `@utility` for custom utilities — integrates with all variants automatically
- `@apply` is acceptable for base element resets; avoid for component composition
- Dark mode: pick media-based or class-based — not both
- Container queries: `@container` on parent, `@cq-sm:` variants on children

See `references/process.md` for v3→v4 migration, @theme tokens, variant patterns, and anti-patterns.
