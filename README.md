# hjemmesidekongen/ai

Five plugins that turn Claude Code into a full development studio — planning, building, branding, designing, and managing tasks. Named after the Danish king's court because the name was already ridiculous, so we leaned in.

## Plugins

| Plugin | What you get |
|--------|-------------|
| **kronen** — The Crown | Plan work in waves, brainstorm with structured pushback, trace decisions, govern memory, and let 12 autonomous agents handle verification, review, and creation. The foundation everything else runs on. |
| **smedjen** — The Forge | Hand off development to agents that know 62 frameworks. Task decomposition, parallel dispatch, completion gates, and a content writer that drafts brand-aware copy. |
| **herold** — The Herald | Pull tasks from Jira, detect contradictions in requirements, generate QA handovers, and ship PRs — without leaving the terminal. |
| **våbenskjold** — The Coat of Arms | Build a brand from scratch, audit an existing one, or evolve it. Voice, values, positioning, audience, content pillars — all codified in YAML. |
| **segl** — The Royal Seal | Generate visual identity systems and export design tokens to Tailwind, CSS custom properties, or DTCG format. |

## Quick Start

```bash
git clone https://github.com/hjemmesidekongen/ai.git
cd ai
```

No build step. The plugins are markdown and YAML — Claude Code discovers them automatically when it runs from this directory. Start with any of these:

```
/kronen:brainstorm-start    — explore a problem before writing code
/kronen:plan-create         — break work into dependency-ordered waves
/smedjen:dev-scan           — map your project's tech stack
/våbenskjold:brand-create   — build a brand from scratch
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI, installed and authenticated
- Node.js 18+

## Documentation

- [Installation](docs/install.mdx)
- [Configuration](docs/configure.mdx)
- [Workflows](docs/workflows.mdx)
- [Architecture](docs/architecture.mdx)
- [Troubleshooting](docs/troubleshooting.mdx)

## License

MIT
