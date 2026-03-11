---
name: design-page
description: "Orchestrate full Pencil design workflow — tokens to agents in one command"
argument-hint: "[BRAND_NAME] [--pages PAGE_LIST]"
---

# Design Page

Orchestrates the full Pencil design workflow: load brand tokens, set up the
canvas, fetch style guide, spawn designer agents, verify deliverables.

**Core principle:** Pencil's spawn_agents produces better design work than manual
batch_design. Always use swarm for creative work; reserve batch_design for
targeted fixes only.

**MCP constraint:** Pencil MCP tools (set_variables, spawn_agents, batch_design)
are session-scoped — they only work in the main conversation thread. Do NOT
attempt to use Claude Code's Agent tool for design parallelism. Use Pencil's
native spawn_agents instead.

## File Storage

Pencil files are stored at `.ai/design/{name}/{name}.pen`. The user must Save As
manually — Claude cannot save .pen files. When resuming work, open from this path
via `open_document`. Remind the user to save after design work completes.

## Prerequisites (verified at runtime)

- Brand exists at `.ai/brand/{name}/` (run `/våbenskjold:brand-create` first)
- Design tokens exist at `.ai/design/{name}/tokens.yml` (run `/segl:design-identity` first)
- Pencil is running with a `.pen` file open (checked via `get_editor_state`)
- `spawn_agents` tool is available — if missing, swarm mode is disabled. Fix: add `"-enable_spawn_agents"` to `~/.claude.json` `mcpServers.pencil.args`

## Steps

1. **Resolve brand** — if argument provided, use it. Otherwise scan `.ai/brand/`
   for available brands. If only one, use it. If multiple, ask.

2. **Verify artifacts exist** (runtime check):
   - `.ai/brand/{name}/guideline.yml` — needed for brand context in agent prompts
   - `.ai/brand/{name}/voice.yml` — needed for tone guidance
   - `.ai/design/{name}/tokens.yml` — needed for Pencil variables
   - If any missing: report what's missing and which command to run. Stop.

3. **Check Pencil state** — call `get_editor_state` to confirm a `.pen` file is
   open and `spawn_agents` tool is registered. If Pencil not open: instruct user
   to open or create one, or call `open_document("new")`. If spawn_agents missing:
   report the config fix and stop. If resuming work, open existing file from
   `.ai/design/{name}/{name}.pen`.

4. **Load tokens into Pencil** — invoke the `pencil-tokens` skill. This reads
   `tokens.yml`, resolves all YAML references, and calls `set_variables` with
   ~30 design tokens.

5. **Select icon library** — check if `untitledui` MCP is configured for this
   project. If yes, default to Untitled UI Pro. If not, ask:
   > Which icon library for this project?
   > 1. **Untitled UI Pro** (needs MCP setup)
   > 2. **Heroicons** (free, no MCP needed)
   > 3. Other (specify)

   Pass the selected library to component agents so icons are sourced correctly.

6. **Collect page descriptions** — if `--pages` provided, use those. Otherwise ask
   the user what pages to design. For each page, collect:
   - Page name (e.g., "Forside", "About", "Contact")
   - Section breakdown with copy/content descriptions
   - Any special requirements (e.g., "include pricing table")

7. **Create placeholder frames** — lay out frames in a horizontal grid, not stacked:

   **Canvas layout:**
   - Each page is a **group** with mobile (390px) + desktop (1440px) side-by-side
   - 100px gap between mobile and desktop within a group
   - 200px gap between page groups
   - Groups placed left-to-right across the canvas
   - Use `find_empty_space_on_canvas` for the starting position

   **Per page, create via `batch_design`:**
   - **Mobile frame**: 390px wide, height ~800px per content section
   - **Desktop frame**: 1440px wide, height ~600px per section
   - Name frames: `{PageName} — Mobile`, `{PageName} — Desktop`
   - **Group** the mobile + desktop frames together after creation

   **Required deliverable frames** (also grouped, also in the grid):
   - `Foundations — Mobile`, `Foundations — Desktop`
   - `Components — Mobile`, `Components — Desktop`

8. **Fetch style guide** — call `get_style_guide_tags` to see available tags,
   then `get_style_guide` with relevant tags for the design direction. Note the
   returned style guide name. If fetch fails: warn and continue — agents can
   still work without a style guide, but quality may be lower.

9. **Fetch guidelines** — call `get_guidelines` with relevant topics (e.g.,
   `landing-page`, `web-app`, `mobile-app`). If fetch fails: warn and continue
   without passing guideline names to agents — they still have brand context,
   tokens, and the style guide to work from.

10. **Spawn designer agents** — batch pages into groups of 3-4 (N-1 pattern:
   N spawned agents + 1 caller slot = N+1 total cursors; exceeding pool size
   causes silent failures where agents never start).

   For each batch, call `spawn_agents` with one agent per page. Each agent gets:
   - **Brand context**: name, tagline, personality, tone (from guideline.yml + voice.yml). Describe identity in natural language.
   - **Section breakdown**: what each section contains, actual copy text
   - **Container nodes**: the frame IDs from step 7 (both mobile and desktop)
   - **Guideline names**: from step 9
   - **Style guide name**: from step 8
   - **Icon library**: from step 5 (for component agents)
   - **Mobile-first instruction**: "Design the mobile layout first, then adapt to desktop."

   **Agent prompt rules** — do NOT include any of these in agent prompts:
   - Color values, hex codes, or variable names
   - Pixel dimensions, spacing values, or font sizes
   - Layout instructions (grid columns, flex direction, etc.)

   Agents read `set_variables` tokens from the document directly and apply
   guidelines autonomously. Over-specifying layout details degrades output quality.

   Wait for batch to complete before spawning next batch. After each batch,
   screenshot all frames to detect silent failures (agents that never started).

11. **Screenshot and verify** — after all agents complete:
    - `get_screenshot` each frame
    - Compare completed frames against expected output — if any frame is still
      empty, that agent silently failed. Re-spawn in a smaller batch.
    - Check deliverables (see checklist below)

12. **Targeted fixes** — for design issues found during verification that don't
    require a full re-spawn (e.g., wrong alignment, missing section divider,
    incorrect spacing), use `batch_design` Update/Replace operations. This is
    the only appropriate use of manual batch_design — targeted corrections, not
    creative work.

13. **Remind user to save** — "Save the .pen file to `.ai/design/{name}/{name}.pen`
    via File → Save As in Pencil."

14. **Report** — summarize:
    - Pages completed (with screenshot confirmation)
    - Missing deliverables
    - Fixes applied via batch_design
    - Suggested follow-up actions

## Deliverables Checklist

Per ~/CLAUDE.md rules, every website design must include all of these. Verify
after spawn_agents complete:

### Foundations page (both breakpoints)
- [ ] Colors — full palette swatches with hex labels + semantic mappings
- [ ] Typography — font families, weight scale, size scale (display → caption) with rendered examples
- [ ] Spacing — visual scale showing each step (4px → 96px)
- [ ] Border radius — visual examples at each stop (sm → 2xl → full)
- [ ] Shadows — cards showing each elevation level
- [ ] Grid/layout — column structure at both breakpoints

### Components page (both breakpoints)
- [ ] Buttons: primary, secondary, ghost — states: default, hover, active, focus, disabled
- [ ] Form inputs: text, textarea, select — states: empty, filled, focus, error, disabled
- [ ] Labels/badges: status variants, sizes
- [ ] Text styles: body, links (default + hover), lists, blockquotes, code blocks
- [ ] Cards: default, feature variant, elevated
- [ ] Icons: sample set from selected icon library (step 5) — arrow, check, menu, close, search, mail, phone, etc.
- [ ] Skeletons: loading states for cards, text blocks, images
- [ ] Navigation: header (desktop), hamburger menu (mobile — closed AND opened)
- [ ] Accordions: closed + open state
- [ ] Dropdowns: closed + open state

### All content pages
- [ ] Both breakpoints — mobile (390px) and desktop (1440px)

Pencil has no prototype toggle mode — show all component states as explicit
separate frames. If any deliverables are missing after the initial spawn, spawn
a dedicated agent batch to fill the gaps. Foundations and components are
required — not optional.

## Error Handling

- **Pencil not running**: "Open Pencil and a .pen file, then re-run."
- **spawn_agents not available**: "Swarm mode disabled. Add `-enable_spawn_agents` to `~/.claude.json` `mcpServers.pencil.args`, then restart Claude Code."
- **Agent pool exhaustion** (frames still empty after spawn): reduce batch size to 2-3 and retry failed pages only.
- **Token loading fails**: check tokens.yml structure, may need regeneration via `/segl:design-identity`.
- **Style guide fetch fails**: warn and continue. Agents produce acceptable work without a style guide, but quality is higher with one.
- **Guidelines fetch fails**: warn and continue. Agents still have brand context and tokens.
