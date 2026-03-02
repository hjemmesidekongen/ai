# Delta Scanner — Detailed Process

## Overview

The delta scanner is the lightweight re-scan mechanism for /dev:scan. Instead of
performing a full project analysis (which project-scanner does), it compares
SHA-256 file hashes to detect what changed since the last scan, then curates
knowledge updates using the maturity lifecycle. This keeps project knowledge
fresh without expensive full scans.

## Prerequisites

Before starting, verify:
1. `~/.claude/dev/[project-name]/dev-config.yml` exists with a `scan` section
2. `scan.file_hashes` has at least one entry (from initial project-scanner run)
3. If no `scan` section exists, report error — run /dev:init first
4. If `file_hashes` is empty, this is effectively a first scan — defer to project-scanner

## Step 1: Load Previous State

```
Read dev-config.yml → scan.file_hashes (array of {path, hash} entries)
Read dev-config.yml → scan.last_scan_at (previous scan timestamp)
Read knowledge/*.yml → all existing knowledge entries with maturity and hashes
```

**Save context summary to findings.md (2-Action Rule checkpoint).**

## Step 2: Compute Current Hashes

For every file path in `scan.file_hashes`:

1. Check if the file still exists on disk
2. If exists: compute SHA-256 hash of the file contents
3. If deleted: mark as `deleted` in the comparison results

Also scan tracked directories for new files not in `file_hashes`:
- Check directories listed in `dev-config.yml` `key_directories`
- Any file matching tracked patterns (e.g., `*.ts`, `*.py`) that has no hash → mark as `new`

**Save results after every 2 hash comparisons (2-Action Rule checkpoint).**

## Step 3: Classify Changes

Compare previous hashes with current hashes:

| Classification | Condition | Action |
|---------------|-----------|--------|
| **unchanged** | Hash matches | Skip — no action needed |
| **changed** | Hash mismatch | Analyze and potentially curate |
| **new** | File exists but no previous hash | Analyze and potentially curate |
| **deleted** | Previous hash exists but file missing | Mark related knowledge for review |

## Step 4: Curate Changes

For each **changed** or **new** file, decide whether the change is worth recording
in the knowledge system.

### a. Skip Trivial Changes

Do NOT create knowledge entries for:
- Formatting-only changes (whitespace, indentation, line endings)
- Version bumps in lock files (`package-lock.json`, `yarn.lock`)
- Auto-generated code comments or documentation timestamps
- Build artifacts or compiled output
- Changes to `.gitignore`, `.editorconfig`, or similar config-only files

### b. Keep Significant Changes

DO create or update knowledge entries for:
- New API endpoints or route definitions
- Changed architecture patterns (new service layer, changed data flow)
- New dependencies (added to package.json, requirements.txt, etc.)
- Modified data models (schema changes, new fields)
- New or changed conventions (naming patterns, file organization)
- Security-relevant changes (auth middleware, input validation)
- Performance-relevant changes (caching, indexing, query optimization)

### c. Match to Knowledge File

Determine which knowledge file the entry belongs to by matching tags:

| Tags | Target Knowledge File |
|------|-----------------------|
| api, routes, endpoints | patterns.yml |
| frontend, component, ui | conventions.yml |
| database, schema, model | patterns.yml |
| architecture, structure | architecture.md |
| testing, test-patterns | conventions.yml |
| security, auth | patterns.yml |
| config, environment | conventions.yml |

If no clear match, default to `conventions.yml`.

### d. Positive Framing

Knowledge entries must use positive framing:
- DO: "Use parameterized queries for all database access"
- DON'T: "Don't use string concatenation in SQL queries"

Positive framing performs better (Lindquist research) — stating what to avoid
actually increases the avoided behavior due to cognitive priming.

**Save curation decisions after every 2 files analyzed (2-Action Rule checkpoint).**

## Step 5: Jaccard Deduplication

Before adding a new entry to a knowledge file, check for near-duplicates:

### Jaccard Similarity Algorithm

```
For two entries A and B:
  tokens_A = set of words in A.content (lowercase, strip punctuation)
  tokens_B = set of words in B.content (lowercase, strip punctuation)

  intersection = tokens_A ∩ tokens_B
  union = tokens_A ∪ tokens_B

  jaccard_similarity = |intersection| / |union|
```

### Decision Logic

| Similarity | Action |
|-----------|--------|
| > 0.8 | Near-duplicate — update existing entry instead of creating new |
| 0.5 — 0.8 | Related but distinct — create new entry, consider linking |
| < 0.5 | Clearly different — create new entry |

When updating an existing entry (similarity > 0.8):
- Merge content: keep the more specific/detailed version
- Update `hash` to reflect new content
- Update `updated_at` timestamp
- Keep the higher maturity level

## Step 6: Maturity Lifecycle

Apply maturity transitions to ALL existing knowledge entries:

### State Machine

```
                  confirmed 2+ scans         stable 3+ scans
  candidate  ──────────────────────►  established  ─────────────►  proven
      │                                     │                        │
      │ contradicted                        │ contradicted           │ contradicted
      │ or 90 days stale                    │ or 90 days stale      │ or 90 days stale
      ▼                                     ▼                        ▼
  deprecated                           deprecated                deprecated
```

### Transition Rules

| Current Status | Condition | New Status | Reason |
|---------------|-----------|------------|--------|
| candidate | Evidence confirmed in this scan | established | Seen in 2+ scans |
| established | Stable for 3+ consecutive scans | proven | Consistent across time |
| any | Evidence contradicted (pattern no longer exists in code) | deprecated | Contradicted |
| any | `updated_at` > 90 days ago and not confirmed in this scan | deprecated | Time-based decay |
| deprecated | Evidence reappears in code | candidate | Re-entered lifecycle |

### Tracking Confirmations

Each knowledge entry should have a `scan_count` field:
- Increment `scan_count` when the entry's evidence is confirmed in the current scan
- Reset `scan_count` to 0 when transitioning to `deprecated`
- Promotion thresholds: candidate → established at scan_count >= 2, established → proven at scan_count >= 3

**Save maturity transitions to findings.md (2-Action Rule checkpoint).**

## Step 7: Update Knowledge Files

Write updated entries to `~/.claude/dev/[project-name]/knowledge/*.yml`:

```yaml
entries:
  - id: "entry-001"
    content: "API endpoints follow RESTful naming: /api/v1/{resource}/{id}"
    tags: [api, routes, conventions]
    maturity: established
    scan_count: 3
    hash: "a1b2c3d4..."
    source_file: "src/routes/index.ts"
    created_at: "2025-01-10T08:00:00Z"
    updated_at: "2025-01-15T10:00:00Z"
```

## Step 8: Update dev-config.yml Scan Section

```yaml
scan:
  last_scan_at: "2025-01-15T10:05:00Z"
  files_tracked: 142
  scan_duration_ms: 3200
  file_hashes:
    - path: "src/routes/index.ts"
      hash: "sha256:abcdef1234..."
    - path: "src/models/user.ts"
      hash: "sha256:567890abcd..."
  changes_detected:
    changed: 5
    new: 2
    deleted: 1
  knowledge_updates:
    entries_created: 2
    entries_updated: 3
    entries_deprecated: 1
    entries_promoted: 4
```

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only knowledge files and dev-config.yml updates
2. Commit: `[plan_name]: delta-scanner [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- dev-config.yml scan.file_hashes is non-empty and count matches files_tracked
- dev-config.yml scan.last_scan_at is a valid timestamp
- Every new/updated knowledge entry has non-empty: tags, maturity, hash
- maturity values are one of: candidate, established, proven, deprecated
- No knowledge entry pairs in the same file have Jaccard similarity > 0.8

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Curation quality: no noise entries (trivial changes recorded as knowledge)
- Dedup accuracy: no near-duplicates missed by Jaccard check
- Maturity transitions are correct (not promoting too fast, not missing deprecations)
- Positive framing: entries say "do X" not "don't do Y"
- Tag assignments match content (api-related entries tagged with api, not frontend)

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

## Error Handling

When errors occur during delta scanning:

1. **Hash computation failure:** If SHA-256 cannot be computed (file permissions,
   binary file, symlink), log to state.yml errors array. Skip the file and
   note it in findings.md. Do not fail the entire scan.

2. **Knowledge file corruption:** If a knowledge YAML file cannot be parsed,
   log to errors array. Attempt to load other knowledge files. Report the
   corrupted file for manual inspection.

3. **Large file sets:** If more than 500 files need hashing, batch in groups
   of 50. Save findings after each batch.

4. **Before retrying:** Always check state.yml errors array for previous failed
   attempts. Never repeat the same approach.
