# Compile & Export — Detailed Process

Phase 7 — the final skill in the SEO strategy generation pipeline. This skill takes everything produced by phases 1-6 and creates a cohesive, readable strategy document alongside a validated data file.

**This is the only skill with a mandatory QA review.** The implementing agent never self-grades — a dedicated QA agent reviews all outputs before the strategy is marked complete.

## Prerequisites

- Read `docs/seo-plugin-implementation-plan.md` (the "Skill: compile-and-export" section)
- Read `plugins/seo-plugin/resources/templates/seo-strategy-template.md` for the document structure

## Before You Start

Read the complete `seo-strategy.yml` and `state.yml`. Verify that all 6 previous phases are marked complete in state.yml. If any phase is incomplete, stop and inform the user which phases still need to run.

Required data sections in `seo-strategy.yml`:
1. `meta` — project metadata
2. `project_context` — project basics, goals, audience, current status
3. `keywords` — primary, secondary, long-tail keywords
4. `competitors` — analyzed competitors and content gaps
5. `on_page` — title tags, meta descriptions, headings, linking, schema
6. `technical` — Core Web Vitals, checklist, mobile requirements
7. `content_plan` — topic clusters, content types, calendar
8. `link_building` — strategies, outreach targets, promotion channels

## Compilation Process

### Step 1: Validate All Data Sections

Before generating the document, validate each section passes its individual checkpoint criteria:

| Section | Minimum Criteria |
|---------|-----------------|
| `project_context` | Has `website_url`, `industry`, `goals` (>= 2), `target_audience` (>= 2), `current_status` |
| `keywords` | Primary (>= 5), secondary (>= 10), long-tail (>= 15), all with required fields |
| `competitors` | >= 3 analyzed competitors with backlink profiles, >= 5 content gaps |
| `on_page` | title_tag, meta_description, heading_hierarchy (h1-h4), internal_linking (>= 3), schema_markup (>= 2) |
| `technical` | core_web_vitals (lcp, fid, cls), checklist (>= 10 items), mobile_requirements (>= 4) |
| `content_plan` | >= 3 topic clusters with pillar + supporting pages, >= 3 content types, calendar (>= 3 months) |
| `link_building` | >= 3 strategies, >= 5 outreach targets, >= 3 promotion channels |

If any section fails validation:
1. Report which section failed and what's missing
2. Do NOT proceed with document generation
3. The user must re-run the corresponding skill

### Step 2: Generate Executive Summary

Write a 2-3 paragraph overview covering:

1. **Project overview and goals** — Summarize from `project_context`:
   - "[Project name] operates in the [industry] industry at [website_url]."
   - "The primary SEO goals are: [goal 1] and [goal 2]."
   - Include current status: DA [number], [N] indexed pages

2. **Key opportunities** — Synthesize from `keywords` and `competitors`:
   - "Keyword research identified [N] primary opportunities, led by [top keyword by priority]."
   - "[N] content gaps were found where competitors are weak, with the highest opportunity in [top gap keyword]."

3. **Recommended first actions** — Actionable next steps:
   - Reference the highest-priority content from the calendar
   - Reference the most impactful link-building strategy
   - Reference the most critical technical SEO items

### Step 3: Generate Keyword Strategy Section

Create the keyword strategy section:

1. **Primary Keywords table:**

| Keyword | Search Volume | Difficulty | Intent | Priority |
|---------|--------------|------------|--------|----------|
| [from keywords.primary] | [volume] | [difficulty] | [intent] | [priority] |

2. **Secondary Keywords summary:** Prose paragraph describing the secondary keyword strategy — how many, key themes, intent distribution

3. **Long-Tail Keywords summary:** Prose paragraph describing the long-tail strategy — question-based queries, specific phrases, quick-win opportunities

### Step 4: Generate Competitor Landscape Section

Create the competitor analysis section:

1. **Competitor comparison table:**

| Domain | DA | Top Keywords | Strengths | Weaknesses |
|--------|-----|-------------|-----------|------------|
| [from competitors.analyzed] | [da] | [count] | [top 2 strengths] | [top 2 weaknesses] |

2. **Content Gap Opportunities table** (top 5 by opportunity_score):

| Keyword | Gap Type | Score | Recommended Action |
|---------|----------|-------|--------------------|
| [from competitors.content_gaps] | [type] | [score] | [action] |

### Step 5: Generate On-Page Optimization Rules Section

Present the on-page rules in a structured format:

1. **Title Tags** — pattern, max length, rules list
2. **Meta Descriptions** — pattern, max length, rules list
3. **Heading Hierarchy** — rules for H1, H2, H3, H4
4. **Internal Linking Strategy** — table with rule and implementation columns
5. **Schema Markup** — table with type, required properties, and use case columns

### Step 6: Generate Technical SEO Checklist Section

Create the technical SEO section:

1. **Core Web Vitals Targets table:**

| Metric | Target | Unit |
|--------|--------|------|
| LCP | <= 2.5 | seconds |
| FID | <= 100 | milliseconds |
| CLS | <= 0.1 | score |

2. **Checklist table** (sorted by priority: critical -> high -> medium -> low):

| Item | Priority | Category | Status |
|------|----------|----------|--------|
| [from technical.checklist] | [priority] | [category] | [status] |

3. **Mobile Requirements** — bulleted list from `technical.mobile_requirements`

### Step 7: Generate Content Plan Section

Create the content plan section:

1. **Topic Clusters** — for each cluster, show the pillar and supporting pages:

```
**Cluster: [pillar target_keyword]**
- Pillar: [title] — targets "[keyword]" ([word_count] words, [content_type])
  - [title] — targets "[keyword]" ([intent], [word_count] words, [priority])
  - [title] — targets "[keyword]" ([intent], [word_count] words, [priority])
  - [title] — targets "[keyword]" ([intent], [word_count] words, [priority])
```

2. **Content Calendar** — month-by-month table:

| Month | Week | Title | Status |
|-------|------|-------|--------|
| [from calendar.schedule] | [week] | [title] | [status] |

### Step 8: Generate Link-Building Strategy Section

Create the link-building section:

1. **Strategies table:**

| Strategy | Effort | Impact | Timeline |
|----------|--------|--------|----------|
| [from link_building.strategies] | [effort] | [impact] | [timeline] |

2. **Outreach Targets table:**

| Category | Criteria | Est. Count |
|----------|----------|------------|
| [from link_building.outreach_targets] | [criteria] | [count] |

3. **Content Promotion table:**

| Channel | Tactics |
|---------|---------|
| [from link_building.content_promotion] | [comma-separated tactics] |

### Step 9: Assemble the Document

Combine all sections into `seo-strategy.md` at `~/.claude/seo/[project-name]/seo-strategy.md`.

Use the template from `plugins/seo-plugin/resources/templates/seo-strategy-template.md` as the structural guide:

1. Header with project name, generation date, and brand name
2. Table of contents with anchor links
3. Horizontal rule between each section
4. All 7 content sections in order

**Replace all template placeholders** with actual data:
- `[Project Name]` -> from `meta.project_name`
- `[date]` -> current date in ISO 8601 format
- `[brand-name]` -> from `meta.brand_name` or "standalone"

### Step 10: Update Meta

Update `seo-strategy.yml`:
- Set `meta.updated_at` to current ISO 8601 timestamp
- Set `meta.version` to "1.0"

### Step 11: Version Stamp

After writing seo-strategy.yml, call the version-meta-stamper skill
(plugins/task-planner/skills/version-meta-stamper/SKILL.md) to
add/update the `_meta` block with the current plugin version.

This ensures every seo-strategy.yml file is traceable to the plugin
version that created it. The `_meta` block is added at the end of the
file with `plugin_name: "seo-plugin"` and `plugin_version` set to
the current version from `plugins/seo-plugin/.claude-plugin/plugin.json`.

## Writing the Output

After assembling the document, present a summary:

```
## SEO Strategy Document Generated

File: ~/.claude/seo/[project-name]/seo-strategy.md

Document sections:
1. Executive Summary (2-3 paragraphs)
2. Keyword Strategy ([N] primary, [N] secondary, [N] long-tail)
3. Competitor Landscape ([N] competitors, [N] content gaps)
4. On-Page Optimization Rules (title tags, meta descriptions, headings, linking, schema)
5. Technical SEO Checklist ([N] items, CWV targets)
6. Content Plan ([N] clusters, [N] total pages, [N]-month calendar)
7. Link-Building Strategy ([N] strategies, [N] outreach categories, [N] promotion channels)

Estimated word count: [count]

Data file: ~/.claude/seo/[project-name]/seo-strategy.yml (validated, [N]/8 sections present)
```

Update `state.yml`:
- Set `current_phase: "compile-and-export"`
- Add phase entry with `status: "complete"` and checkpoint results
- Mark the overall strategy generation as complete

## Checkpoint: file_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `document_exists` | `seo-strategy.md` exists and is at least 2000 words | Regenerate with more detail |
| `document_sections` | Contains all 7 sections: Executive Summary, Keyword Strategy, Competitor Landscape, On-Page Optimization Rules, Technical SEO Checklist, Content Plan, Link-Building Strategy | Add missing sections |
| `yaml_complete` | `seo-strategy.yml` has all 8 top-level sections: meta, project_context, keywords, competitors, on_page, technical, content_plan, link_building | Report missing sections |
| `no_placeholders` | No placeholder text: no `[project-name]`, no `TODO`, no `[from design]` | Replace with actual data |

**On pass:** Update state.yml -> mark phase 7 complete. Trigger QA agent review of all outputs.

**On fail:** Fix the failing checks, re-run validation. Do NOT mark strategy generation as complete. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Project: [name] ([industry])
Strategy document: seo-strategy.md ([word count] words)
Data file: seo-strategy.yml (8/8 sections validated)
Primary keywords: [N] (top: [top 3 by priority])
Competitors: [N] analyzed
Content plan: [N] clusters, [N] pages, [N]-month calendar
Link strategies: [N]
Status: Complete — ready for QA review
```
