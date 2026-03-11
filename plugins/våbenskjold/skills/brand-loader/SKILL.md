---
name: brand-loader
description: >
  Loads brand guidelines from .ai/brand/{name}/ and makes them available to the
  current context. Progressive disclosure: L1 confirms brand exists, L2 loads
  summary, L3 loads specific files on demand. Use when a downstream skill or
  user needs brand context, or when /våbenskjold:apply is invoked.
user_invocable: false
interactive: false
model_tier: junior
depends_on: []
triggers:
  - "load brand"
  - "apply brand"
  - "brand context"
  - "/våbenskjold:apply"
reads:
  - ".ai/brand/{name}/guideline.yml"
  - ".ai/brand/{name}/voice.yml"
  - ".ai/brand/{name}/values.yml"
  - ".ai/brand/{name}/dos-and-donts.md"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "brand_exists"
      verify: "At least guideline.yml exists at .ai/brand/{name}/"
      fail_action: "Report: no brand found. Run /våbenskjold:create or /våbenskjold:audit first."
    - name: "brand_loaded"
      verify: "Requested brand files were read and key fields are present"
      fail_action: "Report which files are missing or malformed"
  on_fail: "Report what's missing — suggest creating or auditing brand"
  on_pass: "Brand loaded into context"
_source:
  origin: "våbenskjold"
  inspired_by: "agency brand-loader + Digital Brain L1/L2/L3 pattern"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New skill for brand plugin — progressive disclosure brand loading"
---

# Brand Loader

Loads brand guidelines into the current context using progressive disclosure.

## Loading Levels

- **L1 (discovery)**: Check if `.ai/brand/{name}/` exists. Report available brands.
- **L2 (summary)**: Read `guideline.yml` — name, tagline, positioning summary.
- **L3 (full)**: Read specific files based on what the consumer needs:
  - Content skills → `voice.yml` + `dos-and-donts.md`
  - Strategy skills → `guideline.yml` + `values.yml`
  - All → load everything

## Brand Resolution

1. If `{name}` is specified, load that brand directly
2. If not specified, scan `.ai/brand/` for available brands
3. If only one brand exists, load it automatically
4. If multiple brands exist, list them and ask which to load
5. If no brands exist, report and suggest `/våbenskjold:create`

## Consumer Pattern

Downstream skills declare brand dependency with `brand: {name}` in their config
or local CLAUDE.md. The loader reads this declaration to know which brand to load.

## Output

No files written. Brand data is loaded into conversation context for the
current session. The loader reports what was loaded and key summary points.
