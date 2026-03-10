---
name: design-loader
user-invocable: false
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

## Context Resolution

1. Check `.ai/design/` for available design directories
2. If {name} specified, load that design. Otherwise list all available.
3. If no designs exist, report and suggest running /design:identity

## Process

1. Scan `.ai/design/{name}/` for all artifacts
2. Check each artifact category:
   - **Identity**: tokens.yml, identity.yml
   - **Platform tokens**: tokens/tailwind.json, tokens/variables.css, tokens/tokens.dtcg.json
   - **Accessibility**: tokens/contrast-matrix.md
3. Report status per artifact: found / missing
4. If tokens.yml found: report token counts (color palettes, typography families, spacing steps)
5. Suggest next steps based on what's missing

## Status Report Format

```
Design: {name}
Location: .ai/design/{name}/

Artifacts:
  [x] tokens.yml — 3 color palettes, 3 font families, 12 spacing steps
  [x] identity.yml — design rationale documented
  [ ] tokens/tailwind.json — run /design:tokens to generate
  [ ] tokens/variables.css — run /design:tokens to generate
  [ ] tokens/tokens.dtcg.json — run /design:tokens to generate
  [ ] tokens/contrast-matrix.md — run /design:tokens to generate

Next step: /design:tokens
```
