# brand-guideline

Agency-grade brand guideline generator for Claude Code. Runs an interactive interview across nine phases — from brand identity and audience personas through visual identity, logo design, content rules, and social media — then compiles everything into a machine-readable `brand-reference.yml` (consumed by other plugins) and a polished brand manual document (for humans).

## Who It's For

- **Business owners** building a brand from scratch
- **Marketers** who need a comprehensive, consistent brand system
- **Developers** building branded products who need design tokens, color scales, and typography specs in a structured format

## Prerequisites

- Claude Code with `task-planner` plugin installed

## Commands

| Command | Purpose |
|---------|---------|
| `/brand:generate` | Full brand generation — guided interview through all 9 phases, then automated asset creation. Supports resume if interrupted. |
| `/brand:analyze` | Reverse-engineer brand guidelines from an existing website, document, or social profile |
| `/brand:audit` | Audit an existing `brand-reference.yml` for gaps, inconsistencies, accessibility issues, and asset integrity |
| `/brand:switch` | Set the active brand context for all brand-aware plugins, or list available brands |

## Skills

Skills execute in strict order — personality and audience inform aesthetics, not the reverse.

| Phase | Skill | Purpose |
|-------|-------|---------|
| 1 | `identity-interview` | Captures brand foundation: name, tagline, mission, vision, values, story, positioning |
| 2 | `audience-personas` | Identifies target audience segments and builds detailed persona cards |
| 3 | `tone-of-voice` | Defines voice spectrum, personality traits, messaging framework, channel-specific tone variations |
| 4 | `typography-color` | Selects color palette and typography system with WCAG AA compliance, dark mode support, contrast validation |
| 5 | `visual-identity` | Establishes visual language: imagery direction, iconography, shape language, layout principles |
| 6 | `logo-design` | 5-phase logo process producing 20-25 SVG concepts, refinements, variants, and HTML preview |
| 7 | `content-rules` | Defines writing standards, content types, SEO guidelines, legal requirements, review checklist |
| 8 | `social-media` | Platform-specific voice, content pillars, hashtag strategy, OG/Twitter/LinkedIn image templates |
| 9 | `compile-and-export` | Validates schema, generates brand manual (md + docx), asset conversion script, QA review |

## Execution Flow

The phase order is intentional and enforced:

```
identity-interview (who are we?)
  → audience-personas (who do we serve?)
    → tone-of-voice (how do we sound?)
      → typography-color (what do we look like — type + color)
        → visual-identity (visual language + imagery)
          → logo-design (the mark itself)
            → content-rules (how do we write?)
              → social-media (how do we show up online?)
                → compile-and-export (assemble everything)
```

Each skill has a checkpoint that must pass before advancing. Interactive phases (1-3) require user input; later phases can run more autonomously using data from earlier phases.

## Output

### Machine-readable: `brand-reference.yml`

Structured YAML consumed by other plugins (SEO, website-builder, content-engine):

```yaml
_meta:
  plugin_name: "brand-guideline"
  plugin_version: "1.0.0"
  schema_version: "1.0.0"
  created_at: "2026-03-01T12:00:00Z"
  updated_at: "2026-03-01T12:00:00Z"
  migrated_from: null

meta:
  brand_name: "Acme Corp"
  tagline: "Building the future, today"
  industry: "B2B SaaS"
  website: "https://acme.example.com"

identity:
  mission: "To simplify infrastructure management so teams can ship faster"
  vision: "A world where deployment is instant and invisible"
  values:
    - name: "Simplicity"
      description: "We remove complexity, not hide it"
  positioning:
    category: "Developer tools"
    target: "Engineering teams at mid-size companies"
    differentiator: "Zero-config deployments"
    proof: "Used by 2,000+ teams"

colors:
  palette:
    primary:
      base: "#2563EB"
      scale: { 50: "#EFF6FF", 100: "#DBEAFE", ..., 900: "#1E3A5F" }
    # secondary, accent, neutral...
  semantic:
    success: "#16A34A"
    error: "#DC2626"
    warning: "#D97706"

# ... audience, voice, typography, visual_identity, logo, content_rules,
#     social_media, assets sections follow the same pattern
```

### Human-readable: brand manual

- `brand-manual.md` — Markdown document with all brand guidelines
- `brand-manual.docx` — Styled DOCX via pandoc (optional)

### Assets (~85 files)

Logo variants (SVG, PNG), color swatches, typography specimens, social media templates, favicons, OG images, and more.

## Data Storage

All brand data lives at:

```
.ai/brands/[brand-name]/
├── brand-reference.yml          # Main data file (all sections)
├── state.yml                    # Progress tracking and recovery
├── brand-manual.md              # Human-readable document
├── brand-manual.docx            # Styled document (optional)
├── persona-card-1.md            # Individual persona cards
├── persona-card-2.md
├── assets/
│   ├── logo/
│   │   ├── svg/                 # Logo SVG variants
│   │   └── png/                 # Rasterized versions
│   ├── colors/                  # Color swatches, palette files
│   ├── typography/              # Font specimens
│   ├── social/                  # Platform-specific templates
│   └── favicon/                 # Favicons and app icons
└── scripts/
    └── convert-assets.sh        # SVG → PNG batch conversion
```

## Brand Context Loader

Other plugins access brand data through the shared `brand-context-loader` skill (located at `shared/brand-context-loader/`). It handles:

- **Brand discovery** — finds the active brand via `--brand` flag, `.ai/active-brand.yml`, or interactive selection
- **Section loading** — plugins declare which sections they need (e.g., `identity`, `colors`, `voice`); the loader returns only those
- **Version checking** — calls `version-compatibility-checker` before loading to ensure data is compatible with the consuming plugin
- **State recovery** — reads `state.yml` to detect incomplete runs and resume from the right point

Consuming plugins declare their dependency in their `ecosystem.json`:

```json
{
  "dependencies": ["task-planner", "brand-guideline"],
  "shared_skills": ["brand-context-loader"]
}
```

## Hooks

The plugin uses Claude Code hooks for context engineering and safety:

| Hook | Trigger | Purpose |
|------|---------|---------|
| **PreToolUse** | Before any tool call | Re-reads `state.yml` to ensure the agent has current phase context and doesn't repeat completed work |
| **Stop** | Before session ends | Prevents premature completion — blocks if the current phase hasn't passed its checkpoint |
| **SessionStart** | When a session begins | Runs recovery: loads `state.yml`, reports progress, identifies the resume point |

These hooks ensure that multi-session brand generation stays consistent and never loses progress.

## Findings and Error Persistence

- **`findings.md`** — Skills that perform research (identity-interview, audience-personas) store intermediate findings here. The file persists between sessions so context isn't lost on `/compact` or session restart.
- **Error tracking** — Errors encountered during generation are logged to `state.yml` under each phase's `checkpoint` block. This creates a history of what failed and why.
- **2-Action Rule** — When a skill encounters a checkpoint failure, it gets at most 2 attempts to fix the issue before escalating to the user. This prevents infinite retry loops.

## Brainstorm Integration

If the user ran `/brainstorm:start` before `/brand:generate`, interview skills automatically check for pre-existing decisions:

- **`identity-interview`** checks domain `brand-identity` for decisions about brand name, mission, values, positioning
- **`audience-personas`** checks domain `brand-audience` for market type, segment names, persona details
- **`tone-of-voice`** checks domain `brand-voice` for voice spectrum, personality traits, messaging preferences

Decisions are matched by confidence level:
- **High confidence** — pre-filled, shown for quick confirmation
- **Medium confidence** — presented as a starting point, user can accept or explore further
- **Low confidence** — mentioned as context when asking the question

This avoids re-asking questions the user already explored during brainstorming.

## Version and Migration

- **Current version:** 1.0.0 (set in `.claude-plugin/plugin.json`)
- **Migrations directory:** `migrations/` with `MIGRATION-REGISTRY.yml`
- **Archived schemas:** `resources/schemas/archive/v1.0.0.yml`
- **Version stamping:** `compile-and-export` calls `version-meta-stamper` to add/update the `_meta` block in `brand-reference.yml`
- **Changelog:** `CHANGELOG.md` tracks version history

To bump the version: `/plugin:version brand-guideline bump [major|minor|patch]`
To migrate existing projects: `/plugin:migrate brand-guideline --project [name]`

## Installation

This plugin is part of the `claude-plugins` ecosystem. Install `task-planner` first, then add `brand-guideline` to your packages.
