---
name: scan
command: "/dev:scan"
description: "Delta scan — detect file changes since last init/scan, update knowledge with maturity lifecycle"
arguments:
  - name: verbose
    type: boolean
    required: false
    default: false
    description: "Show all changes detected, not just curated ones"
---

# /dev:scan

Delta scan — detect file changes since the last `/dev:init` or `/dev:scan`, update knowledge files with the maturity lifecycle (candidate, established, proven, deprecated), and deduplicate entries via Jaccard similarity.

## Usage

```
/dev:scan                  # standard delta scan
/dev:scan --verbose        # show all changes, including trivial/skipped
```

## Purpose

Lightweight re-scan that keeps project knowledge fresh without expensive full scans. Compares SHA-256 file hashes to detect what changed, curates significant changes into knowledge entries, promotes/deprecates entries based on the maturity lifecycle, and deduplicates via Jaccard similarity.

## Prerequisites

- `/dev:init` must have been run (dev-config.yml must exist at `~/.claude/dev/[project-name]/`)
- `dev-config.yml` must have a `scan` section with `file_hashes` (populated by project-scanner during init)

## Input

- `--verbose` (optional) — show all changes detected (changed, new, deleted), including trivial ones that were skipped during curation. Default behavior only shows curated knowledge updates.

Interactive prompts: none (fully autonomous).

## Execution Strategy

Single skill execution — no task-planner needed.

### Step 1: Validate Prerequisites

Read `~/.claude/dev/[project-name]/dev-config.yml`. Check that:
- The file exists
- `scan.file_hashes` exists and is non-empty

If missing or empty:
- Error: "Project not initialized or never scanned. Run `/dev:init` first."
- Exit

### Step 2: Run Delta Scanner

Read SKILL.md at `plugins/dev/skills/delta-scanner/SKILL.md`, follow its process.

This skill:
- Loads previous file hashes from `dev-config.yml`
- Computes current SHA-256 hashes for all tracked files
- Classifies changes: unchanged, changed, new, deleted
- Curates significant changes into knowledge entries (skips trivial)
- Deduplicates via Jaccard similarity (> 0.8 = merge)
- Applies maturity lifecycle transitions to all existing entries
- Updates `dev-config.yml` scan section and `knowledge/*.yml` files

### Step 3: Display Results

If `--verbose`: display all changes detected, including trivial ones skipped during curation.

Present summary to user:

```
## Scan Complete

Files tracked: [N]
Changes detected: [changed] changed, [new] new, [deleted] deleted
Knowledge updates: [created] created, [updated] updated, [deprecated] deprecated, [promoted] promoted

[If verbose: full change list with classification and curation decision]
```

## Output

- Updated `~/.claude/dev/[project-name]/knowledge/*.yml` — new, modified, and deprecated entries
- Updated `~/.claude/dev/[project-name]/dev-config.yml` — refreshed `scan` section (file_hashes, last_scan_at, changes_detected, knowledge_updates)
- `~/.claude/dev/[project-name]/findings.md` — intermediate scan findings

## Recovery

Idempotent — re-run `/dev:scan` if interrupted. The delta-scanner recomputes all hashes from scratch each time, so partial runs leave no corrupted state.

## Error Handling

- **dev-config.yml missing:** Error message directing user to run `/dev:init` first
- **scan.file_hashes empty:** Same as missing — defer to `/dev:init` for initial scan
- **Hash computation failures:** Logged to state.yml errors array, individual files skipped, scan continues
- **Knowledge file corruption:** Logged to errors array, other knowledge files still processed
