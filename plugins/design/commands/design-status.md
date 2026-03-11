---
name: design-status
description: "Show design artifact status and availability"
argument-hint: "[NAME]"
---

# Design Status

Shows the status of design artifacts using the design-loader skill.

## Steps

1. **Resolve name** — if argument provided, check `.ai/design/{name}/`.
   If no argument, scan `.ai/design/` for all available designs.

2. **If no designs found**: report and suggest `/design:identity`

3. **If designs found**: invoke design-loader skill for each (or specified name)

4. **Print status** per design:
   - Available artifacts with token counts
   - Missing artifacts with suggested commands
   - Next recommended step
