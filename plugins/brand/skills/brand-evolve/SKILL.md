---
name: brand-evolve
description: >
  Guided reinvention of an existing brand guideline. Loads current brand from
  .ai/brand/{name}/, identifies what to keep vs change, and walks the user
  through targeted evolution. Preserves brand equity while updating positioning,
  voice, or values. Use when refreshing a brand or when /brand:evolve is invoked.
user_invocable: false
interactive: true
model_tier: principal
depends_on: []
triggers:
  - "evolve brand"
  - "refresh brand"
  - "update brand strategy"
  - "/brand:evolve"
reads:
  - ".ai/brand/{name}/guideline.yml"
  - ".ai/brand/{name}/voice.yml"
  - ".ai/brand/{name}/values.yml"
  - "plugins/brand/resources/guideline-schema.yml"
  - "plugins/brand/resources/voice-schema.yml"
  - "plugins/brand/resources/values-schema.yml"
writes:
  - ".ai/brand/{name}/guideline.yml"
  - ".ai/brand/{name}/voice.yml"
  - ".ai/brand/{name}/values.yml"
  - ".ai/brand/{name}/dos-and-donts.md"
  - ".ai/brand/{name}/evolution-log.md"
checkpoint:
  type: data_validation
  required_checks:
    - name: "existing_brand_loaded"
      verify: "At least guideline.yml or voice.yml existed before evolution started"
      fail_action: "Run brand-strategy or brand-audit first — nothing to evolve"
    - name: "changes_documented"
      verify: "evolution-log.md records what changed and why"
      fail_action: "Write evolution log with before/after for each changed element"
    - name: "user_approved"
      verify: "User confirmed the evolved brand"
      fail_action: "Present changes summary and ask for approval"
  on_fail: "Address gaps before finalizing"
  on_pass: "Brand evolution complete at .ai/brand/{name}/"
_source:
  origin: "brand"
  inspired_by: "brainstorm-session iterative refinement"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New skill for brand plugin — guided reinvention of existing brand"
---

# Brand Evolve

Guided reinvention of an existing brand. Loads current state, identifies what to
keep vs change, walks through targeted updates.

## Process

1. **Load** — read all files from `.ai/brand/{name}/`, present current state summary
2. **Diagnose** — ask: "What's working? What feels off? What's changed in your market?"
3. **Scope** — agree on which elements to evolve (positioning, voice, values, or all)
4. **Evolve** — for each scoped element, present current → proposed change
5. **Approve** — section-by-section confirmation
6. **Write** — update files, write evolution-log.md with before/after reasoning

## Rules

- Always load existing brand first. If no brand exists, redirect to brand-strategy.
- Preserve what works. Default to keeping existing values unless user wants change.
- Track every change in evolution-log.md with rationale.
- Challenge unnecessary changes — "is this actually broken, or just boring?"

## Output

Updated files at `.ai/brand/{name}/`. Evolution log at `evolution-log.md`.
