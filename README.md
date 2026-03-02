# Claude Local Workspace

Plugins for Claude Code that generate brand guidelines, SEO strategies, and more — through guided interviews, not prompt engineering. You answer questions, Claude builds the deliverables.

## What's Included

| Plugin | What it does |
|--------|-------------|
| **task-planner** | Breaks work into phases, runs them, verifies output. Powers everything else. |
| **brand-guideline** | Generates a complete brand guide: identity, voice, colors, typography, logos, social rules. |
| **seo-plugin** | Builds SEO strategy, audits sites, writes content briefs — uses your brand data automatically. |
| **dev** *(coming soon)* | Development team agents, framework packs, project scaffolding. |

## Workflows

### Build a brand from scratch

```
/brand-generate
```

Walks you through 9 interview phases (identity, audience, tone, colors, etc.). Produces a `brand-reference.yml` and a human-readable brand manual. Takes 30-60 minutes depending on how much detail you provide.

### Reverse-engineer an existing brand

```
/brand-analyze
```

Point it at a website or document. It extracts brand patterns and generates the same structured output as `/brand-generate`.

### Create an SEO strategy

```
/seo-strategy
```

Interviews you about your business, researches keywords, analyzes competitors, and produces an actionable strategy. Pulls from your brand data if you've already run `/brand-generate`.

### Audit a live site

```
/seo-audit
```

Checks a URL against SEO best practices and returns issues ranked by impact with fix recommendations.

### Plan any complex task

```
/plan-create
```

Describe what you want to build. Claude breaks it into sequential phases, assigns verification criteria, and can execute it with `/plan-execute`. Useful for multi-step projects beyond branding and SEO.

### Create a new plugin

```
/brainstorm-start my-plugin    # optional: explore ideas first
/plugin-create my-plugin       # design interview + scaffolding
/plugin-build my-plugin        # guided implementation
```

The generator asks 8 design questions, produces specs, and scaffolds the full plugin structure. All plugins get session recovery, error tracking, and quality checks automatically.

## All Commands

| Command | Plugin | Does what |
|---------|--------|-----------|
| `/brand-generate` | brand | Full brand guide from interview |
| `/brand-analyze` | brand | Extract brand from existing materials |
| `/brand-audit` | brand | Check brand guide for gaps and issues |
| `/brand-switch` | brand | Switch active brand (multi-brand projects) |
| `/seo-strategy` | seo | Full SEO strategy from interview |
| `/seo-audit` | seo | Audit a site against best practices |
| `/seo-content-brief` | seo | Content brief for a keyword/topic |
| `/seo-export` | seo | Export strategy as Markdown or DOCX |
| `/plan-create` | planner | Break work into phases |
| `/plan-execute` | planner | Run the plan |
| `/plan-status` | planner | Check progress |
| `/plan-resume` | planner | Resume after interruption |
| `/plugin-create [name]` | planner | Design and scaffold a new plugin |
| `/plugin-build [name]` | planner | Build a scaffolded plugin step by step |
| `/plugin-version [name]` | planner | Bump version, archive schema |
| `/plugin-migrate [name]` | planner | Run data migrations |
| `/brainstorm-start [name]` | planner | Explore ideas interactively |
| `/brainstorm-decide [name]` | planner | Lock in decisions from brainstorm |
| `/brainstorm-status [name]` | planner | Check brainstorm progress |

## Project Layout

```
plugins/
  task-planner/          # Foundation plugin — planning, generators, brainstorm
  brand-guideline/       # Brand identity (9 interview phases)
  seo-plugin/            # SEO strategy and audits
shared/
  brand-context-loader/  # Loads brand data into any plugin that needs it
docs/                    # Specs and implementation plans
```

Each plugin has its own [README](plugins/task-planner/README.md) with detailed documentation.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Plugins are discovered automatically when you run Claude Code from this directory
