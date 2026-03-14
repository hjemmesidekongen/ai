---
name: profile-status
description: Show active profile, compiled flags, and override status
user_invocable: true
---

# /profile-status

Show the active project configuration at a glance.

## Steps

1. **Read config** — check `.ai/project.yml` for profile binding and overrides
2. **Read cache** — check `.ai/context/kronen-profile-cache` for compiled flag values
3. **Display** — show profile name, all flags with current values, and any active overrides

## Output format

```
Profile: work
Source:  .ai/project.yml

Hook flags:
  tdd_gate:        enabled
  tracing:         light
  doc_checkpoint:  enabled
  verification:    strict
  scope_guard:     enabled  (safety — not overridable)
  push_protection: enabled  (safety — not overridable)

Overrides:
  hooks.tdd_gate: disabled  (overrides work default: enabled)

Dev commands:
  test:  pnpm test
  build: pnpm build
  lint:  pnpm lint
```

4. **If no project.yml** — report "No project.yml found. Using defaults (all enabled)."
5. **If no cache** — report "Cache not compiled. Run session restart to sync."

## Data sources

Read only — never modify:
- `.ai/project.yml`
- `.ai/context/kronen-profile-cache`
- `plugins/kronen/resources/profiles/{name}.yml`
