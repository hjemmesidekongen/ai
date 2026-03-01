# SEO Plugin

Generates a comprehensive SEO strategy with keyword research, on-page optimization, technical SEO audits, competitive analysis, and content recommendations tailored to a project's goals and target audience.

## Overview

**What it does:** Creates a complete, actionable SEO strategy for any website or project. Covers keyword research, competitor analysis, on-page optimization rules, technical SEO checklists, content planning with topic clusters, and link-building strategies — all informed by your brand guidelines.
**Who it's for:** Developer or technical marketer (developer-level) — cares about search rankings, organic traffic, and technical site performance
**Dependencies:** task-planner, brand-guideline

## Prerequisites

- Claude Code with task-planner plugin installed
- Brand guidelines generated via `/brand:generate` (provides brand-reference.yml)

## Commands

| Command | Purpose |
|---------|---------|
| `/seo:strategy` | Generates a full SEO strategy through an interactive process with keyword research, competitor analysis, and actionable recommendations |
| `/seo:audit` | Audits an existing website or page against SEO best practices and reports issues with fix recommendations |
| `/seo:content-brief` | Generates a detailed content brief for a specific keyword or topic, including outline, target word count, and SEO requirements |
| `/seo:export` | Exports the SEO strategy as a formatted report in Markdown or DOCX format |

## Output

This plugin produces:

1. **seo-strategy.yml** — Machine-readable YAML stored at `~/.claude/seo/[project-name]/`
2. **SEO strategy document** — Human-readable Markdown document

## How It Works

1. **Wave 1:** Project interview — gather project context, goals, and audience (interactive)
2. **Wave 2:** Keyword research — identify and classify target keywords (interactive)
3. **Wave 3:** Competitor analysis + Technical SEO — analyze competitors and generate technical checklist (parallel)
4. **Wave 4:** On-page optimization — generate on-page SEO rules based on keywords
5. **Wave 5:** Content strategy — create topic clusters and content calendar
6. **Wave 6:** Link building — develop outreach and promotion strategies
7. **Wave 7:** Compile and export — assemble the final strategy document

## Brand Data Usage

This plugin reads the following sections from `brand-reference.yml`:
- **project-interview** uses: identity, audience
- **keyword-research** uses: voice, content
- **content-strategy** uses: voice, audience, content
- **link-building** uses: identity

## Installation

This plugin is part of the claude-plugins ecosystem. Ensure `task-planner` is installed first.
Also requires `brand-guideline` to be installed and at least one brand generated.

## Data Storage

- YAML output: `~/.claude/seo/[project-name]/seo-strategy.yml`
- Documents: `~/.claude/seo/[project-name]/seo-strategy.md`
- State tracking: `~/.claude/seo/[project-name]/state.yml`
