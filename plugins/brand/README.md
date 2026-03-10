# Brand Plugin

Brand strategy toolkit for Claude Code. Produces structured brand guidelines — voice, values, positioning, audience, and content pillars — at `.ai/brand/{name}/`.

Strategy only. No visual design, no tokens, no CSS.

## Commands

| Command | Purpose |
|---------|---------|
| `/brand:create` | Create a new brand from scratch through research and sparring |
| `/brand:audit` | Codify an existing brand from materials and samples |
| `/brand:evolve` | Refresh or reinvent an existing brand |
| `/brand:apply` | Load a brand into context or wire it into a project |
| `/brand:status` | Show brand status and guideline summary |

## Skills

| Skill | Description |
|-------|-------------|
| brand-strategy | Interactive brand creation with market research |
| brand-audit | Extract brand from existing content samples |
| brand-evolve | Guided brand reinvention |
| brand-loader | Progressive disclosure brand loading (L1/L2/L3) |

## Output Format

Brand guidelines are written to `.ai/brand/{name}/`:

- `guideline.yml` — positioning, audience, content pillars, competitive matrix
- `voice.yml` — personality archetype, 1-10 voice scales, vocabulary, writing patterns
- `values.yml` — core values with in-practice behaviors, beliefs, decision framework
- `dos-and-donts.md` — human-readable brand rules
- `market-research.md` — competitive landscape (created by brand-strategy)

## Dependencies

Requires `claude-core`. No other plugin dependencies.

## Brand Resolution

Downstream consumers declare `brand: {name}` in their CLAUDE.md. The brand-loader
reads this to know which brand to load. Single-brand repos auto-resolve.
