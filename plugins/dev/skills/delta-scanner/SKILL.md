---
name: delta-scanner
description: >
  Lightweight re-scan for /dev:scan — compare file hashes to detect changes
  since last scan, curate knowledge updates using maturity lifecycle
  (candidate → established → proven → deprecated), and deduplicate entries
  via Jaccard similarity. Use when running /dev:scan, detecting project
  changes, updating knowledge entries, promoting or deprecating knowledge,
  or checking for stale observations.
phase: null
depends_on: []
writes:
  - ".ai/dev/[project-name]/knowledge/*.yml (new/updated entries)"
  - ".ai/dev/[project-name]/dev-config.yml (scan section: file_hashes, last_scan_at)"
reads:
  - ".ai/dev/[project-name]/dev-config.yml (scan.file_hashes)"
  - ".ai/dev/[project-name]/knowledge/*.yml (existing entries)"
  - "Project source files (for hash computation)"
model_tier: junior
interactive: false
checkpoint:
  type: data_validation
  required_checks:
    - name: "hash_comparison"
      verify: "files_tracked count in dev-config.yml matches hashes computed (or diff explained by new/deleted)"
      fail_action: "Recompute hashes for missing files, log deleted files"
    - name: "entry_structure"
      verify: "Every new/updated knowledge entry has non-empty tags, valid maturity, and hash"
      fail_action: "Add missing fields to malformed entries"
    - name: "no_duplicates"
      verify: "Jaccard similarity < 0.8 for all entry pairs within the same knowledge file"
      fail_action: "Merge near-duplicate entries (keep the one with higher maturity)"
    - name: "scan_timestamp"
      verify: "dev-config.yml scan.last_scan_at is updated to current timestamp"
      fail_action: "Write current timestamp to scan.last_scan_at"
    - name: "hash_state"
      verify: "dev-config.yml scan.file_hashes reflects current file state"
      fail_action: "Rewrite file_hashes with freshly computed values"
  on_fail: "Fix issues and re-run checkpoint. Stale hashes cause missed changes on next scan."
  on_pass: "Update dev-config.yml scan section. Knowledge files are current."
---

# Delta Scanner

Lightweight re-scan for /dev:scan. Compares file hashes to detect changes since the last scan, curates knowledge updates, and maintains the maturity lifecycle for all knowledge entries.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | dev-config.yml scan.file_hashes, knowledge/*.yml existing entries, project source files |
| **Writes** | knowledge/*.yml (new/updated entries), dev-config.yml scan section |
| **Checkpoint** | data_validation: hash comparison, entry structure, no duplicates, scan timestamp, hash state |
| **Dependencies** | None (standalone, used by /dev:scan) |

## Delta Scan Flow Summary

1. Read `dev-config.yml` `scan.file_hashes` — get previous SHA-256 hashes
2. Read `knowledge/*.yml` — get existing entries with hashes and maturity levels
3. Compute current SHA-256 hashes for all tracked files
4. Compare hashes — identify: changed (mismatch), new (no previous), deleted (file missing)
5. For each changed/new file: analyze change, curate (skip trivial), match to knowledge file by tags
6. Jaccard dedup: similarity > 0.8 → update existing entry; otherwise create new as `candidate`
7. Apply maturity lifecycle to ALL existing entries (promote, deprecate, decay)
8. Update `dev-config.yml` scan section: new hashes, `last_scan_at`, `files_tracked`, `scan_duration_ms`

## Findings Persistence

Write scan findings to `.ai/dev/[project-name]/findings.md`.
**2-Action Rule:** After every 2 file hash comparisons, save detected changes to findings.md immediately.

## Error Logging — Log errors to state.yml errors array. Check errors before retrying.

## Execution — [references/process.md](references/process.md)
