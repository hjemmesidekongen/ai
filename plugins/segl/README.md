# design

Visual identity creation and design token generation.

**Version:** 0.1.0

## What it does

Takes brand guidelines (from the brand plugin) and produces a complete visual identity system — color palettes, typography, spacing — then transforms those into platform-consumable token formats (Tailwind, CSS, DTCG).

## Skills

| Skill | Purpose |
|-------|---------|
| `visual-identity` | Creates color palettes (OKLCH), typography pairing, spacing system from brand direction |
| `design-tokens` | Transforms tokens.yml into tailwind.json, variables.css, tokens.dtcg.json + contrast matrix |
| `design-loader` | Reads existing design artifacts and reports availability status |

## Commands

| Command | Purpose |
|---------|---------|
| `/segl:identity` | Run visual identity generation |
| `/segl:tokens` | Generate platform token formats |
| `/segl:status` | Check design artifact status |

## Dependencies

- Reads brand plugin output from `.ai/brand/{name}/` (guideline.yml, voice.yml)
- Writes design artifacts to `.ai/design/{name}/`

No hooks. No agents.
