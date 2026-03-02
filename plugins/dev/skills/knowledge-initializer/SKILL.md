---
name: knowledge-initializer
description: >
  Generates tagged knowledge files and mermaid architecture diagrams from confirmed
  project config and source analysis. Produces architecture.md, patterns.yml, and
  conventions.yml consumed by agents during builds. Use when initializing project
  knowledge, running /dev:init phase 3, generating architecture diagrams, mapping
  module boundaries, detecting design patterns, or analyzing codebase conventions.
phase: 3
depends_on: [config-generator]
writes:
  - "~/.claude/dev/[project-name]/knowledge/architecture.md"
  - "~/.claude/dev/[project-name]/knowledge/patterns.yml"
  - "~/.claude/dev/[project-name]/knowledge/conventions.yml"
reads:
  - "~/.claude/dev/[project-name]/dev-config.yml"
  - "~/.claude/dev/[project-name]/findings.md"
  - "Project source files (for architecture analysis)"
model_tier: senior
interactive: false
checkpoint:
  type: file_validation
  required_checks:
    - name: "knowledge_files_exist"
      verify: "At least 1 knowledge file created in ~/.claude/dev/[project-name]/knowledge/"
      fail_action: "Generate minimum architecture.md from dev-config.yml structure section"
    - name: "tags_present"
      verify: "All knowledge files have frontmatter with tags array (at least 1 tag per file)"
      fail_action: "Add tags based on file content — architecture, patterns, or conventions"
    - name: "maturity_set"
      verify: "All knowledge files have maturity field set to candidate"
      fail_action: "Set maturity: candidate on all entries"
    - name: "mermaid_present"
      verify: "architecture.md contains at least 1 mermaid code block"
      fail_action: "Generate module boundary diagram from key_directories in dev-config.yml"
    - name: "scan_timestamp_updated"
      verify: "dev-config.yml scan.last_scan_at is a valid ISO 8601 timestamp"
      fail_action: "Set scan.last_scan_at to current ISO 8601 timestamp"
    - name: "file_hashes_populated"
      verify: "dev-config.yml scan.file_hashes array is non-empty"
      fail_action: "Compute SHA-256 hashes for all knowledge files and source entry points"
  on_fail: "Fix issues and re-run checkpoint. Do not advance until all checks pass."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Knowledge Initializer

Phase 3 of /dev:init. Reads dev-config.yml and project source files to generate tagged knowledge files with architecture diagrams, detected patterns, and conventions. Agents load knowledge filtered by tags relevant to their task during /dev:build.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | dev-config.yml, project source files (key_directories entries) |
| **Writes** | architecture.md, patterns.yml, conventions.yml in knowledge/ |
| **Checkpoint** | file_validation: knowledge exists, tags present, maturity set, mermaid present, scan updated, hashes populated |
| **Dependencies** | config-generator (dev-config.yml must exist) |

## Process Summary

1. Read dev-config.yml — extract structure, frameworks, conventions
2. For each key_directory, read representative files and map imports
3. Identify module boundaries — which directories own which concerns
4. Generate architecture.md with mermaid diagram and module descriptions
5. Detect design patterns, state management, error handling → patterns.yml
6. Detect naming, file organization, import ordering → conventions.yml
7. Tag all entries, set maturity to `candidate`, compute content hashes
8. Update dev-config.yml scan section with timestamp and file hashes

## Findings Persistence

Write intermediate discoveries to `~/.claude/dev/[project-name]/findings.md`.
**2-Action Rule:** After every 2 source file reads or Grep operations, IMMEDIATELY save discoveries to findings.md before continuing.

## Error Logging

Log errors to state.yml errors array. Check errors before retrying — never repeat a failed approach.

## Execution — [references/process.md](references/process.md)
