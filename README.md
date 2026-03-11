# hjemmesidekongen/ai

AI workflow plugins for Claude Code — planning, brand, design, dev execution, and task management.

## What's Included

| Plugin | What it does |
|--------|-------------|
| **claude-core** | Foundation — planning, brainstorm, tracing, memory governance, verification gates, creator tooling, 12 autonomous agents. |
| **dev-engine** | Multi-agent dev pipeline — task decomposition, agent dispatch, 62 framework-specific skills, completion gates. |
| **taskflow** | Task management — Jira ingestion, contradiction detection, QA handover, PR workflows. |
| **brand** | Brand strategy — voice, values, positioning, audience, content pillars. |
| **design** | Visual identity — color palettes, typography, spacing, design tokens. |

## Quick Start

```bash
git clone https://github.com/hjemmesidekongen/ai.git
cd ai
```

See the [documentation site](https://hjemmesidekongen.dk/ai) for detailed guides, or start with:

- `/brainstorm:start` — explore a problem with structured pushback
- `/dev:scan` — map your project's tech stack
- `/plan:create` — break work into dependency-ordered waves

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed and authenticated
- Node.js 18+

No build step. The plugins are markdown files and YAML — discovered automatically when Claude Code runs from this directory.

## Documentation

- [Installation](/docs/install.mdx)
- [Configuration](/docs/configure.mdx)
- [Workflows](/docs/workflows.mdx)
- [Architecture](/docs/architecture.mdx)
- [Troubleshooting](/docs/troubleshooting.mdx)

## License

MIT
