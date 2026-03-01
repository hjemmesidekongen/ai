---
name: export
command: "/seo:export"
description: "Export the SEO strategy as a formatted report in Markdown or DOCX format"
arguments:
  - name: project-name
    type: string
    required: true
    description: "Which project to export (must have a completed strategy)"
  - name: format
    type: string
    required: false
    default: "md"
    description: "Output format: md, docx, or both"
---

# /seo:export

Exports the SEO strategy as a formatted report. Re-generates the strategy document from the current seo-strategy.yml data, optionally converting to DOCX format.

## Usage

```
/seo:export my-project                    # export as markdown (default)
/seo:export my-project --format docx      # export as Word document
/seo:export my-project --format both      # export both formats
```

## Purpose

Exports the SEO strategy as a formatted report in Markdown or DOCX format. Useful for regenerating documents after manual edits to seo-strategy.yml, or for producing a Word document for stakeholder presentation.

## Prerequisites

- task-planner plugin installed
- A completed SEO strategy at `~/.claude/seo/[project-name]/`
- For DOCX output: pandoc must be installed

## Input

- `project-name` (required) — which project to export
- `--format [md|docx|both]` (optional, default: md) — output format

## Execution Strategy

No interactive phases. Single-pass execution:

### Step 1: Load and Validate Strategy

1. Read `~/.claude/seo/[project-name]/seo-strategy.yml`
2. Validate all 8 required top-level sections are present and non-empty:
   - `meta` — project metadata
   - `project_context` — project basics
   - `keywords` — keyword research results
   - `competitors` — competitor analysis
   - `on_page` — on-page optimization rules
   - `technical` — technical SEO checklist
   - `content_plan` — content strategy
   - `link_building` — link-building strategy
3. If any section is missing or empty:
   ```
   Cannot export: seo-strategy.yml is incomplete.
   Missing sections: [list]
   Run `/seo:strategy [project-name] --resume` to complete the strategy first.
   ```

### Step 2: Generate Markdown (if format is "md" or "both")

Use the compile-and-export skill's document generation logic:

1. Read the template from `packages/seo-plugin/resources/templates/seo-strategy-template.md`
2. Replace all template placeholders with data from seo-strategy.yml
3. Generate all 7 sections:
   - Executive Summary (synthesized from project_context + keywords + competitors)
   - Keyword Strategy (primary table, secondary/long-tail summaries)
   - Competitor Landscape (comparison table, content gap table)
   - On-Page Optimization Rules (title, meta, headings, linking, schema)
   - Technical SEO Checklist (CWV targets, checklist table, mobile requirements)
   - Content Plan (topic clusters, content calendar)
   - Link-Building Strategy (strategies, outreach, promotion)
4. Write to `~/.claude/seo/[project-name]/seo-strategy.md`
5. Update `seo-strategy.yml` meta.updated_at

### Step 3: Generate DOCX (if format is "docx" or "both")

1. Check if pandoc is installed:
   ```bash
   which pandoc
   ```
2. If pandoc is available:
   ```bash
   pandoc seo-strategy.md -o seo-strategy.docx \
     --from markdown \
     --to docx \
     --toc \
     --toc-depth=2 \
     --highlight-style=tango
   ```
3. If pandoc is not available:
   ```
   DOCX export requires pandoc. Install it with:
     brew install pandoc  (macOS)
     apt install pandoc   (Ubuntu)

   Markdown export completed successfully.
   ```

### Step 4: Report Results

```
## SEO Strategy Exported

Project: [project-name]
Format: [format]

Files:
  [✓] seo-strategy.md — [word count] words
  [✓/✗] seo-strategy.docx — [generated / pandoc not available]

Location: ~/.claude/seo/[project-name]/
```

## Output

- `seo-strategy.md` at `~/.claude/seo/[project-name]/` (if format includes md)
- `seo-strategy.docx` at `~/.claude/seo/[project-name]/` (if format includes docx and pandoc available)

## Recovery

Not needed — single-pass command.
