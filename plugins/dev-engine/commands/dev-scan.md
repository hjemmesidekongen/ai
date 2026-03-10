---
name: dev-scan
description: "Scan repository to detect tech stack, modules, and architecture"
argument-hint: "[PATH]"
---

# Dev Scan

Runs the project-mapper skill on the current directory or a specified path.

## Steps

1. **Resolve path** — if an argument is provided, use it as the scan root. Otherwise use the current working directory.

2. **Invoke project-mapper** skill with the resolved path.

3. **Print results**:
   - Detected tech stack (languages, frameworks, databases)
   - Module count and names
   - Monorepo status
   - Path to the generated `.ai/project-map.yml`
   - Mermaid C4 context diagram

4. **If project map already exists** and is less than 24 hours old, print the cached results with a note: `Using cached scan from <timestamp>. Pass --force to rescan.`

5. **If `--force`** is passed, ignore the cache and rescan.
