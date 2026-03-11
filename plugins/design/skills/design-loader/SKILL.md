---
name: design-loader
user_invocable: false
interactive: false
description: >
  Loads existing design artifacts from .ai/design/{name}/ and reports what's
  available. Checks for tokens.yml, identity.yml, platform tokens, and contrast
  matrix. Use when checking design status, loading design context for downstream
  skills, or running /design:status.
depends_on: []
writes: []
reads:
  - ".ai/design/{name}/tokens.yml"
  - ".ai/design/{name}/identity.yml"
  - ".ai/design/{name}/tokens/"
triggers:
  - design status
  - load design
  - check design
  - design artifacts
model_tier: junior
model: haiku
checkpoint:
  type: data_validation
  required_checks:
    - name: "design_directory_exists"
      verify: ".ai/design/{name}/ directory exists with at least one file"
      fail_action: "Report no design found — run /design:identity to create one"
    - name: "status_reported"
      verify: "Status summary includes available artifacts and missing artifacts"
      fail_action: "Generate status report from directory contents"
  on_fail: "Report what's missing and suggest next steps"
  on_pass: "Design context loaded — report summary to user"
_source:
  origin: original
  ported_date: "2026-03-10"
  iteration: 1
  changes: ["initial creation"]
---

# Design Loader

Reads existing design artifacts and reports availability status. Non-destructive
read-only skill — loads context, never writes.

## Context

| Aspect | Details |
|--------|---------|
| **Input** | .ai/design/{name}/ directory |
| **Output** | Status report (stdout) — no file writes |
| **Checkpoint** | 2 checks: directory exists, status reported |

## Process

1. Scan `.ai/design/` — if {name} specified, load that design; otherwise list all
2. Check artifact categories: identity (tokens.yml, identity.yml), platform tokens
   (tailwind.json, variables.css, tokens.dtcg.json), accessibility (contrast-matrix.md)
3. If tokens.yml found: parse and report token counts (palettes, families, spacing steps)
4. Suggest next steps based on what's missing

## Edge Cases

- **Multiple designs**: list all with status summary; ask which to load if ambiguous
- **Partial tokens.yml**: report which sections exist vs missing (colors/typography/spacing)
- **Unexpected files**: ignore non-standard files but list them under "unrecognized artifacts"
- **Schema version mismatch**: warn if tokens.yml version != token-schema.yml version
- **Corrupt YAML**: catch parse errors, report file + line number, do not silently skip

## Multi-Design Comparison

When 2+ designs exist, compare token sets side-by-side: palette count, color overlap
(shared hex/OKLCH values), typography families, spacing base units. Flag divergence
that could cause inconsistency if both are consumed downstream.

## Execution

See `references/process.md` for status report format and comparison output template.
