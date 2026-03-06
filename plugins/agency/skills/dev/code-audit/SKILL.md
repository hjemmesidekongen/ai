---
name: code-audit
user-invocable: false
description: >
  Scans existing codebases to discover conventions and coding patterns. Analyzes
  50-100 representative files for export style, state management, styling approach,
  component structure, test patterns, and naming conventions. Outputs
  project-conventions.yml for user review — user picks canonical patterns where
  the codebase is inconsistent. Profile-controlled via code_audit flag.
phase: dev
depends_on: [project-scanner]
reads:
  - ".ai/profiles/{profile}.yml"
  - ".ai/projects/{project}/dev/findings.md"
writes:
  - ".ai/projects/{project}/dev/project-conventions.yml"
model_tier: senior
model: sonnet
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "profile_checked"
      verify: "Profile code_audit flag was read before analysis"
      fail_action: "Read profile and check code_audit flag"
    - name: "conventions_file_exists"
      verify: "project-conventions.yml exists at .ai/projects/{project}/dev/"
      fail_action: "Generate conventions file from analysis"
    - name: "all_categories_analyzed"
      verify: "All 6 categories present: export_style, state_management, styling, component_structure, test_patterns, naming"
      fail_action: "Run analysis for missing categories"
    - name: "inconsistencies_flagged"
      verify: "Each category with <80% consistency has alternatives listed"
      fail_action: "Re-analyze and flag inconsistent categories"
    - name: "conventions_reviewed"
      verify: "User explicitly confirmed or edited the conventions"
      fail_action: "Present conventions to user and wait for confirmation"
  on_fail: "Fix issues and re-run checkpoint. Do not advance until user confirms."
  on_pass: "Update state.yml, write recovery_notes, mark conventions as reviewed."
---

# Code Audit

Behavioral analysis of an existing codebase. Unlike /agency:scan (structural), this skill discovers coding conventions and patterns by sampling 50-100 representative files. Profile-controlled: `code_audit: true` runs it (work default), `code_audit: false` skips it (personal default).

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | Profile (code_audit flag), findings.md (scan results for file list) |
| **Writes** | project-conventions.yml (user-reviewed convention overlay) |
| **Checkpoint** | data_validation: profile checked, file exists, 6 categories, inconsistencies flagged, user reviewed |
| **Dependencies** | project-scanner (provides file inventory) |

## Analysis Categories

1. **Export style** -- default vs named exports, barrel files
2. **State management** -- patterns, libraries, local vs global
3. **Styling** -- CSS modules, Tailwind, styled-components, plain CSS
4. **Component structure** -- file organization, prop patterns, composition
5. **Test patterns** -- naming, structure, coverage approach
6. **Naming conventions** -- file casing, variable casing, component naming

## Process Summary

1. Read profile -- skip if `code_audit: false`
2. Sample 50-100 representative source files
3. Analyze each category, calculate consistency percentages
4. Generate project-conventions.yml with findings + recommendations
5. Present to user -- user picks canonical pattern for inconsistent areas
6. Save reviewed conventions as project-specific overlay

## Execution

Follow the detailed process in [references/process.md](references/process.md).
