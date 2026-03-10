---
name: fumadocs-patterns
description: >
  Fumadocs documentation framework — MDX components, content structure,
  meta.json navigation, LLM integration (llms.txt, getLLMText), and
  docs site conventions. Use when building or editing documentation pages,
  configuring Fumadocs components, or setting up AI-readable doc endpoints.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
reads:
  - "site/content/docs/**/*.mdx"
  - "site/content/docs/meta.json"
  - "site/mdx-components.tsx"
  - "site/source.config.ts"
writes:
  - "site/content/docs/**/*.mdx"
  - "docs/**/*.mdx"
  - "site/content/docs/meta.json"
triggers:
  - "fumadocs"
  - "docs site"
  - "documentation page"
  - "mdx component"
  - "llms.txt"
  - "docs meta.json"
checkpoint:
  type: data_validation
  required_checks:
    - name: "meta_json_entry"
      verify: "Every new page slug appears in meta.json pages array"
      fail_action: "Add the page slug to site/content/docs/meta.json"
    - name: "dual_directory_sync"
      verify: "docs/ and site/content/docs/ contain identical .mdx files"
      fail_action: "Copy the changed file to the other directory"
    - name: "frontmatter_complete"
      verify: "Every .mdx file has title and description in frontmatter"
      fail_action: "Add missing title or description to frontmatter"
  on_fail: "Documentation has structural issues — fix before committing"
  on_pass: "Documentation follows Fumadocs conventions"
_source:
  origin: "dev-engine"
  inspired_by: "https://www.fumadocs.dev/docs/integrations/llms"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New tech skill — Fumadocs framework patterns and LLM integration"
---

# Fumadocs Patterns

Fumadocs is a Next.js documentation framework with MDX, automatic navigation, and built-in LLM integration.

## Default MDX Components (no import needed)

| Component | Usage |
|-----------|-------|
| `Callout` | `<Callout type="info\|warn\|error\|success\|idea">` — notes, warnings, tips |
| `Card` / `Cards` | Navigation cards with icon, description, href |
| `CodeBlock` | Automatic via fenced code blocks (Shiki highlighting) |
| `Heading` | Auto-generated with anchor links from `##` markdown syntax |

## Components Needing Registration in mdx-components.tsx

`Steps`, `Tabs`, `Accordion`/`Accordions`, `Files`, `Banner`, `TypeTable` — import from `fumadocs-ui/components/<name>`.

## Key Rules

- Update `meta.json` when adding or removing pages — missing entries hide pages from navigation
- Frontmatter `description` drives SEO meta tags and search — never skip it
- Use Fumadocs components over raw HTML — they handle dark mode, responsive layout, accessibility
- Dual directory: `docs/` and `site/content/docs/` must stay synced (both committed)

## Anti-patterns

- NEVER use raw `<div>`, `<span>` in MDX — won't pick up theme styles
- NEVER skip meta.json for new pages — page renders but is invisible in sidebar
- NEVER skip heading levels (`##` to `####`) — breaks accessible heading hierarchy

See [references/process.md](references/process.md) for component examples, LLM integration setup, and public-facing page patterns.
