# Fumadocs Reference

## Page Template

Every `.mdx` file requires YAML frontmatter with `title` and `description`.

```mdx
---
title: Page Title
description: One-line summary for SEO and search.
---

# Page Title

Introductory paragraph.

## Section

Content here.
```

## meta.json

Controls sidebar ordering. Every page must be listed by slug (filename without `.mdx`). Missing entries render the page but hide it from navigation.

```json
{
  "title": "Documentation",
  "pages": [
    "index",
    "install",
    "configure",
    "architecture",
    "troubleshooting"
  ]
}
```

## Component Examples

### Callout

Available types: `info`, `warn`, `error`, `success`, `idea`. No import needed.

```mdx
<Callout type="info">
This is an informational note.
</Callout>

<Callout type="warn">
This action cannot be undone.
</Callout>
```

### Card and Cards

No import needed. Use for navigation grids.

```mdx
<Cards>
  <Card
    title="Getting Started"
    href="/docs/install"
    description="Install and configure the plugins."
  />
  <Card
    title="Architecture"
    href="/docs/architecture"
    description="How the plugin system works."
  />
</Cards>
```

Cards support an optional `icon` prop (React node).

### Steps

Requires registration in `mdx-components.tsx`:

```tsx
import { Step, Steps } from 'fumadocs-ui/components/steps';
```

```mdx
<Steps>
  <Step>
    ### Clone the repository
    Run `git clone` to get started.
  </Step>
  <Step>
    ### Install dependencies
    Run `pnpm install` in the project root.
  </Step>
</Steps>
```

### Tabs

Requires registration. Supports `persist` (remembers selection) and `groupId` (syncs across instances).

```tsx
import { Tab, Tabs } from 'fumadocs-ui/components/tabs';
```

```mdx
<Tabs items={['pnpm', 'npm', 'yarn']}>
  <Tab value="pnpm">pnpm install</Tab>
  <Tab value="npm">npm install</Tab>
  <Tab value="yarn">yarn add</Tab>
</Tabs>
```

### Accordion

Requires registration. Use for FAQ sections or collapsible content.

```tsx
import { Accordion, Accordions } from 'fumadocs-ui/components/accordion';
```

```mdx
<Accordions>
  <Accordion title="How do I install?">
    Clone the repo and run the install command.
  </Accordion>
</Accordions>
```

### Files

Displays file tree structure. Requires registration.

```tsx
import { Files, File, Folder } from 'fumadocs-ui/components/files';
```

```mdx
<Files>
  <Folder name="plugins" defaultOpen>
    <Folder name="claude-core">
      <File name="plugin.json" />
      <File name="ecosystem.json" />
    </Folder>
  </Folder>
</Files>
```

### TypeTable

For documenting configuration options, props, or types. Requires registration.

```tsx
import { TypeTable } from 'fumadocs-ui/components/type-table';
```

```mdx
<TypeTable
  type={{
    name: { type: 'string', description: 'Project name', required: true },
    verbose: { type: 'boolean', description: 'Enable verbose output', default: 'false' },
  }}
/>
```

---

## LLM Integration

Reference: https://www.fumadocs.dev/docs/integrations/llms

### llms.txt and llms-full.txt

Generated automatically by Fumadocs using the Loader API. `llms.txt` provides a page index; `llms-full.txt` includes complete page content for AI consumption.

Requires `includeProcessedMarkdown` in the source config:

```ts
// source.config.ts
export const docs = defineDocs({
  dir: 'content/docs',
  docs: {
    schema: pageSchema,
  },
});
```

### getLLMText — Individual Page Markdown

The `.mdx` extension pattern allows AI agents to fetch individual page content as raw markdown by appending `.mdx` to any doc path.

Route handler setup:

```ts
// app/llms.mdx/docs/[[...slug]]/route.ts
import { getLLMText } from 'fumadocs-core/llm-text';
import { source } from '@/lib/source';

export function generateStaticParams() {
  return source.getPages().map((page) => ({
    slug: page.slugs,
  }));
}

export async function GET(
  _req: Request,
  { params }: { params: { slug?: string[] } }
) {
  const page = source.getPage(params.slug);
  if (!page) return new Response('Not found', { status: 404 });

  return new Response(getLLMText(page), {
    headers: { 'Content-Type': 'text/markdown' },
  });
}
```

Next.js rewrites in `next.config.mjs`:

```js
async rewrites() {
  return [
    { source: '/docs/:path*.mdx', destination: '/llms.mdx/docs/:path*' },
  ];
}
```

### Accept Header Negotiation

Detect when AI agents prefer markdown content:

```ts
import { isMarkdownPreferred } from 'fumadocs-core/llm-text';

// In middleware or route handler
if (isMarkdownPreferred(request)) {
  // Return markdown content instead of HTML
}
```

---

## Public-Facing Page Patterns

### Roadmap Page Structure

Based on industry best practices for public product roadmaps:

1. **Short intro** — what the project does, one paragraph
2. **Summary table** — all features with status labels and anchor links
3. **Feature sections** — grouped by theme, not by internal phase
4. **Recently Shipped** — 5-8 highlights showing momentum
5. **Disclaimer** — priorities may shift, via `<Callout type="info">`

### Status Labels

Use 3-5 categories max:

| Label | Meaning |
|-------|---------|
| In development | Actively being built |
| Next | Queued, coming soon |
| Planned | Committed direction, no timeline |
| Future | Directional, may change |

### Writing Feature Descriptions

Write as user benefits, not technical specs:

| Do | Don't |
|----|-------|
| "Automated screenshot comparison against design mockups" | "Playwright screenshot diff integration with Pencil MCP node comparison" |
| "One-command deploy with health check verification" | "CLI wrapper around provider SDK with HTTP polling loop" |
| "Long-term recall of what was tried across projects" | "Episodic memory layer with temporal decay and two-tier storage" |

### What NOT to Include on Public Pages

- Internal IDs or tracking numbers (RL-XXX)
- Task counts or phase progress bars
- Full backlog dumps
- Implementation details or architecture specifics
- Specific delivery dates (use status labels instead)

---

## Anti-patterns

| Anti-pattern | Problem | Fix |
|--------------|---------|-----|
| Raw HTML in MDX (`<div>`, `<span>`) | Won't inherit theme styles, dark mode, or responsive behavior | Use Fumadocs components (Callout, Card, etc.) |
| Missing meta.json entry | Page renders at URL but invisible in sidebar navigation | Add slug to the `pages` array in meta.json |
| Heading level skip (`##` to `####`) | Breaks accessible heading hierarchy, screen reader confusion | Use sequential levels: `##` then `###` |
| Unstyled inline badges (`<span className="badge">`) | No default styling in Fumadocs — renders as plain text | Use italic text (`*Status*`) or Callout |
| Dual directory drift | `docs/` and `site/content/docs/` diverge silently | Copy changed files to both directories after every edit |
| Giant tables without scroll hint | Wide tables overflow on mobile despite wrapper | Prefer description lists or Cards for navigation-heavy content |
| Inline component imports | Clutters individual .mdx files, duplicates across pages | Register components once in `mdx-components.tsx` |
