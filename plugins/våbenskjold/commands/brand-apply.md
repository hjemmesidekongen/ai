---
name: brand-apply
description: "Load a brand into the current context or wire it into a project"
argument-hint: "[BRAND_NAME] [--to PATH]"
---

# /våbenskjold:apply

Loads brand guidelines into the current session context. Optionally wires a brand
reference into a project's CLAUDE.md.

## Steps

1. **Resolve brand name** — use the argument if provided. If not, scan `.ai/brand/` and auto-select if only one exists, or list available brands.

2. **Invoke brand-loader** skill with the brand name.

3. **If `--to PATH`** is specified:
   - Add `brand: {name}` declaration to the target path's CLAUDE.md (create if needed)
   - Report: "Wired brand '{name}' into {path}/CLAUDE.md"

4. **Report loaded brand** — name, tagline, voice archetype, top values.
