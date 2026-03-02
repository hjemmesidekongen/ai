---
name: dev-skills
command: "/dev:skills"
description: "(dev) List installed framework-pack skills or diff against upstream sources to detect updates"
arguments:
  - name: subcommand
    type: string
    required: false
    description: "Subcommand to run: 'check' to diff against upstream. Omit to list all skills."
  - name: pack
    type: string
    required: false
    description: "Framework pack name to scope the check (e.g., 'react-nextjs'). Only used with 'check'."
---

# /dev:skills

List all installed framework-pack skills, or diff them against their upstream origin repos to detect available updates.

## Usage

```
/dev:skills                        # list all framework-pack skills by pack
/dev:skills check                  # diff all skills against upstream, report changes
/dev:skills check react-nextjs     # diff only the react-nextjs pack against upstream
```

## Purpose

Framework-pack skills are forked from upstream repositories. Over time, the upstream source may receive improvements or bug fixes. This command lets you see what is installed and detect when a local fork has drifted from its origin.

## Prerequisites

- `plugins/dev/framework-packs/` directory must exist (created by `/dev:init`)
- For `check`: internet access to fetch raw GitHub content from upstream repos

## Input

- `[subcommand]` (optional) — `check` to diff against upstream. Omit to list all installed skills.
- `[pack]` (optional, only with `check`) — scope the upstream diff to a single named framework pack.

## Execution Strategy

This command does NOT use the task-planner — it runs sequentially because the operations are fast and read-only.

### Default: List All Skills

#### Step 1: Scan Framework Packs Directory

Look for pack directories at `plugins/dev/framework-packs/*/`. Each subdirectory is one framework pack. Within each pack, look for skill directories containing a `SKILL.md`.

If no packs found: print "No framework packs installed. Add packs to plugins/dev/framework-packs/." and exit.

#### Step 2: Read Frontmatter for Each Skill

For each `SKILL.md` found, parse the YAML frontmatter to extract:

```
origin        — upstream repo slug (e.g., "vercel-labs/agent-skills")
origin_skill  — skill name in the upstream repo
origin_version — version at time of fork
forked_date   — ISO date the skill was forked
```

If a field is missing, display it as `—` (not set).

#### Step 3: Display Table Per Pack

Print one section per framework pack:

```
Pack: react-nextjs
───────────────────────────────────────────────────────────────────
Skill                    Origin                        Forked       Version
react-best-practices     vercel-labs/agent-skills      2026-03-02   1.0.0
nextjs-routing           vercel-labs/agent-skills      2026-03-02   1.2.1
server-components        vercel-labs/agent-skills      2026-03-02   1.0.0
───────────────────────────────────────────────────────────────────
Pack summary: 3 skills  |  last forked: 2026-03-02

Pack: tailwind-ui
───────────────────────────────────────────────────────────────────
Skill                    Origin                        Forked       Version
utility-patterns         tailwindlabs/skill-pack       2026-02-15   2.0.0
component-tokens         tailwindlabs/skill-pack       2026-02-15   2.0.0
───────────────────────────────────────────────────────────────────
Pack summary: 2 skills  |  last forked: 2026-02-15

Total: 2 packs, 5 skills installed
```

### check Subcommand

#### Step 1: Select Packs to Check

If `[pack]` argument provided: check only `plugins/dev/framework-packs/[pack]/`. If the directory does not exist, error: "Pack '[pack]' not found at plugins/dev/framework-packs/[pack]/."

If no `[pack]` argument: check all packs found under `plugins/dev/framework-packs/*/`.

#### Step 2: Collect Skills with Origin

For each skill in scope, read SKILL.md frontmatter. Only skills that have an `origin` field can be checked. Skills without `origin` are listed as "no origin set — skipped".

#### Step 3: Fetch Upstream and Compare

For each skill with `origin` frontmatter:

1. Construct the GitHub raw URL:
   ```
   https://raw.githubusercontent.com/[origin]/main/skills/[origin_skill]/SKILL.md
   ```
   Fall back to `master` branch if `main` returns 404.

2. Fetch the upstream content via HTTP GET.

3. Compare the fetched content against the local SKILL.md:
   - If identical: status = "up to date"
   - If different: status = "upstream changed" — produce a brief diff summary (which sections changed, lines added/removed)
   - If fetch fails (404, timeout, network error): status = "upstream unavailable" — include the HTTP status or error reason

4. Do NOT overwrite local files. This command is read-only.

#### Step 4: Display Results Per Pack

Print one section per framework pack:

```
Pack: react-nextjs
───────────────────────────────────────────────────────────────────
react-best-practices     up to date
nextjs-routing           upstream changed
                           ~ Step 3: updated error boundary guidance
                           + Added: server action retry pattern (8 lines)
                           - Removed: deprecated getServerSideProps example (12 lines)
server-components        upstream unavailable (HTTP 404 — branch or path not found)
───────────────────────────────────────────────────────────────────

Pack: tailwind-ui
───────────────────────────────────────────────────────────────────
utility-patterns         up to date
component-tokens         no origin set — skipped
───────────────────────────────────────────────────────────────────
```

#### Step 5: Print Summary

```
Check complete: 4 skills checked, 1 up to date, 1 upstream changed, 1 unavailable, 1 skipped (no origin)

Skills with upstream changes:
  react-nextjs/nextjs-routing  →  vercel-labs/agent-skills @ main

To update a skill, manually review the upstream diff and merge changes into the local SKILL.md.
Preserve any local customizations (sections_kept / sections_removed recorded in frontmatter).
```

## Output

**Default (list):**
- Console table showing all installed framework-pack skills grouped by pack, with origin and forked date.
- No files written.

**check:**
- Console report per pack: each skill's upstream status and diff summary.
- No files written. All output is read-only.

## Recovery

Both modes are read-only and idempotent — re-run at any time without side effects.

If `check` reports "upstream unavailable" for a skill, verify:
1. The `origin` frontmatter is correct (`owner/repo` format, no `https://github.com/` prefix)
2. The `origin_skill` matches the directory name in the upstream repo
3. The upstream repo is public and the branch exists

## Error Handling

- **No framework-packs directory:** Warn "plugins/dev/framework-packs/ not found. Run /dev:init or add packs manually." and exit.
- **Malformed SKILL.md frontmatter:** Skip the skill, print "Warning: could not parse frontmatter for [skill path]", continue.
- **Network unavailable during check:** Mark all fetches as "upstream unavailable (network error)", print the summary, exit normally.
- **Single pack not found (check [pack]):** Error message listing available packs, exit.
