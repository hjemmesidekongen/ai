---
name: project-config
description: >
  Project-level configuration via .ai/project.yml — profile presets (work/personal),
  hook flag overrides, dev commands, and git conventions. Explains the unified config
  system: how to bind a profile, which flags are overridable vs safety-locked, and
  where to find the full schema. Use when setting up a new project, switching profiles,
  configuring hook behavior, checking which profile is active, understanding override
  precedence, or asking about project.yml fields.
user_invocable: true
interactive: false
model_tier: junior
depends_on: []
triggers:
  - "project config"
  - "set up config"
  - "configure profile"
  - "project.yml"
  - "work profile"
  - "personal profile"
  - "hook flags"
  - "override hooks"
  - "which profile"
  - "disable tdd gate"
reads:
  - ".ai/project.yml"
  - "plugins/kronen/resources/profiles/"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "config_explained"
      verify: "Response covers profile selection, available flags, and override syntax"
      fail_action: "Include all three: profile choice, flag reference, override example"
    - name: "safety_flags_noted"
      verify: "Response mentions that scope_guard and push_protection cannot be disabled"
      fail_action: "Add safety flag note — omitting it is a correctness issue"
  on_fail: "Re-read the profile presets and schema to provide accurate information."
  on_pass: "Configuration guidance delivered with correct flag reference."
_source:
  origin: "kronen"
  inspired_by: "config-rules-distribution plan"
  ported_date: "2026-03-14"
  iteration: 1
  changes: "New skill. Replaces plugin-settings pattern with unified project.yml config."
---

# project-config

Configure project behavior via `.ai/project.yml`. One file controls profile presets,
hook flags, dev commands, and git conventions.

## Quick start

Create `.ai/project.yml`:
```yaml
profile: work          # or: personal
project_name: my-app
dev:
  test: pnpm test
```

## Profiles

| Profile | TDD | Tracing | Doc checkpoint | Verification |
|---------|-----|---------|---------------|-------------|
| `work` | enabled | light | enabled | strict |
| `personal` | disabled | disabled | disabled | light |

## Hook flags

| Flag | Controls | Values | Overridable? |
|------|----------|--------|-------------|
| `tdd_gate` | TDD gate on writes | enabled, disabled | Yes |
| `tracing` | Trace logging | full, light, disabled | Yes |
| `doc_checkpoint` | Doc staleness checks | enabled, disabled | Yes |
| `verification` | Verification strictness | strict, light | Yes |
| `scope_guard` | File write protection | enabled | **No — safety** |
| `push_protection` | Direct push prevention | enabled | **No — safety** |

## Overrides

Override specific flags without changing the profile:
```yaml
profile: work
overrides:
  hooks:
    tdd_gate: disabled    # work profile but no TDD gate
    tracing: full         # more tracing than work default
```

Safety flags (`scope_guard`, `push_protection`) are ignored in overrides.

## Other fields

Beyond hooks, project.yml supports: `git` (branch_prefix, commit_style), `qa` (format,
require_screenshots), `dev` (test, build, lint), `mcp_servers`. See `docs/project-config.md`.

## Never

- Never edit `.ai/context/kronen-profile-cache` directly — always edit `project.yml`
- Never expect safety flag overrides to take effect — they are silently ignored
