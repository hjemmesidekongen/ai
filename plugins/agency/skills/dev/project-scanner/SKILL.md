---
name: project-scanner
user-invocable: false
description: >
  Static analysis of project + workspace: frameworks, language, pkg manager,
  architecture, testing, linting, design tooling, brand files, MCP servers,
  shared config packages, and sibling project stacks. Profile-aware — reads
  active profile for defaults. Output consumed by config-generator.
phase: 1
depends_on: []
writes:
  - ".ai/projects/[name]/dev/findings.md#project-scan"
reads:
  - "package.json, tsconfig.json, go.mod, Cargo.toml, pyproject.toml"
  - "Config files: next.config.*, vite.config.*, tailwind.config.*, etc."
  - ".ai/profiles/*.yml, .mcp.json, mcp.json, .cursor/mcp.json"
  - "packages/*/package.json (shared config detection)"
model_tier: junior
model: haiku
checkpoint:
  type: data_validation
  required_checks:
    - name: "framework_detected"
      verify: "Scan results contain at least 1 detected framework OR explicit 'none detected' marker"
      fail_action: "Re-scan project root; if truly empty, write 'none detected' with reason"
    - name: "language_populated"
      verify: "Language field is one of: typescript, javascript, python, go, rust, other"
      fail_action: "Check file extensions in src/ to determine dominant language"
    - name: "package_manager_populated"
      verify: "Package manager field is one of: npm, yarn, pnpm, bun, unknown"
      fail_action: "Check for lock files; if none found, set to 'unknown'"
    - name: "config_files_checked"
      verify: "At least 3 config file paths were checked (even if not found)"
      fail_action: "Run additional Glob checks for standard config files"
    - name: "design_tooling_checked"
      verify: "findings.md contains a Design Tooling section (even if empty)"
      fail_action: "Run Glob checks for tailwind.config.*, .storybook/, design-tokens.*"
    - name: "findings_exist"
      verify: "findings.md exists at .ai/projects/[name]/dev/findings.md with scan results"
      fail_action: "Write current scan results to findings.md immediately"
    - name: "workspace_scanned"
      verify: "findings.md contains Workspace Context section (even if empty)"
      fail_action: "Scan parent dir for sibling projects; write to Workspace Context"
    - name: "mcp_servers_checked"
      verify: "findings.md contains MCP Servers section (servers listed or 'none found')"
      fail_action: "Check .mcp.json, mcp.json, .cursor/mcp.json for server definitions"
    - name: "shared_configs_checked"
      verify: "findings.md contains Shared Config Packages section (even if not monorepo)"
      fail_action: "Scan packages/ for config packages; write results or 'not a monorepo'"
  on_fail: "Fix issues and re-run checkpoint. Do not advance until all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Project Scanner

Phase 1 of /agency:dev:init. Static analysis of project stack, workspace context, MCP servers, and shared configs. Profile-aware. Output feeds config-generator (Phase 2) via findings.md.

## Context
| Aspect | Details |
|--------|---------|
| **Reads** | Project files, profiles, MCP configs, sibling projects via Glob/Grep/Read |
| **Writes** | `.ai/projects/[name]/dev/findings.md` |
| **Checkpoint** | 9 checks: framework, language, pkg manager, configs, design, findings, workspace, MCP, shared configs |
| **Dependencies** | None — first skill in init flow (reads profile if available) |
## Process Summary

1. Read active profile from `.ai/profiles/` — load stack defaults and shared config refs
2. Read package.json, glob config files, detect language + pkg manager + architecture
3. Detect testing, linting, formatting; map src structure
4. Detect design tooling (Tailwind, CSS vars, Storybook, tokens) and brand files
5. Detect git conventions from commits and .github/ templates
6. **Workspace scan** — scan sibling dirs for tech stacks of other projects
7. **MCP server discovery** — check .mcp.json, mcp.json, .cursor/mcp.json
8. **Shared config detection** — find @repo/* config packages in packages/
9. Save findings (2-Action Rule); run checkpoint (up to 3 fix rounds)

## Rules
- **Findings:** Write to `.ai/projects/[name]/dev/findings.md`. **2-Action Rule:** save after every 2 operations.
- **Errors:** Log to state.yml errors array. Check before retrying — never repeat a failed approach.
- **Execution:** Follow [references/process.md](references/process.md).
