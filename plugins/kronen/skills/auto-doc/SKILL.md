---
name: auto-doc
description: >
  Automatically update documentation after task completion. Reads git diff to
  identify what changed, then updates CLAUDE.md structure tree and counts,
  ecosystem.json entries, MEMORY.md facts, and roadmap.yml statuses. Use when
  doc-checkpoint reports stale docs, after multi-file tasks, after adding or
  removing components, or when documentation has drifted from reality.
user_invocable: false
interactive: false
depends_on: [doc-checkpoint]
triggers:
  - "update docs"
  - "fix stale docs"
  - "auto-doc"
  - "sync documentation"
  - "update CLAUDE.md counts"
reads:
  - "CLAUDE.md"
  - "plugins/*/.claude-plugin/ecosystem.json"
  - ".ai/roadmap.yml"
writes:
  - "CLAUDE.md"
  - "plugins/*/.claude-plugin/ecosystem.json"
  - ".ai/roadmap.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "counts_match"
      verify: "CLAUDE.md component counts match filesystem reality"
      fail_action: "Recount and update CLAUDE.md"
    - name: "ecosystem_synced"
      verify: "ecosystem.json arrays match directories on disk"
      fail_action: "Add missing entries or remove ghost entries"
    - name: "no_orphans"
      verify: "No components exist on disk without documentation"
      fail_action: "Add missing entries to CLAUDE.md structure tree"
model_tier: senior
_source:
  origin: "kronen"
  inspired_by: "external-references (H3), RL-019"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "New skill completing the doc governance pipeline. doc-checkpoint detects staleness; auto-doc fixes it."
---

# Auto-Doc

Automatically updates documentation to match codebase reality. Complements
doc-checkpoint (detection) with action (fixing).

## When to trigger

- doc-checkpoint reported `required` items in its checklist
- After multi-file tasks that add/remove/rename components
- CLAUDE.md counts visibly wrong
- ecosystem.json out of sync with filesystem

## What it updates

| Target | What | How |
|--------|------|-----|
| CLAUDE.md structure tree | Component listings | Diff filesystem vs tree, add/remove lines |
| CLAUDE.md counts | Skill/command/agent/hook counts | Count on disk, update parenthetical |
| ecosystem.json | Component arrays | Sync arrays with directories on disk |
| MEMORY.md | Factual counts | Update count references if present |
| roadmap.yml | Delivered items | Mark matching items as done with date |

## What it does NOT do

- Write new prose documentation or READMEs
- Create new reference files
- Make subjective editorial decisions
- Touch ~/CLAUDE.md (that's manual per user rules)

## Full process

For the complete update procedure with filesystem scanning, diff generation,
and safety checks, read [references/process.md](references/process.md).
