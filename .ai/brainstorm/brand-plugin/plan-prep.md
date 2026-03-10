# Brand Plugin — Plan Prep

## What We're Building

A standalone brand strategy plugin that produces brand guidelines. No design, no code, no tokens. Pure brand DNA: who you are, how you sound, what you stand for, what you never do.

## Plugin Identity

- **Name**: `brand`
- **Location**: `plugins/brand/`
- **Dependency**: claude-core only
- **Version**: v0.1.0

## Skills

### 1. brand-strategy (core creation skill)
**Purpose**: Interactive sparring session that produces a complete brand guideline from scratch.
**Flow**:
1. Context resolution — check if .ai/brand/{name}/ exists
2. Market research phase — detect domain, run Perplexity for competitive landscape
3. Sparring session (brainstorm pattern):
   - Personality archetype discovery (Expert/Friend/Innovator/Guide/Motivator)
   - Audience definition (primary + secondary with pain points)
   - Positioning (UVP, competitive matrix, differentiation)
   - Content pillars with percentage splits
   - One question at a time, propose alternatives, section-by-section approval
4. Voice codification:
   - 1-10 attribute scales (formal-casual, serious-playful, etc.)
   - Writing patterns (sentence, paragraph, hook levels)
   - Vocabulary (signature phrases, power words, never-use)
   - Platform adaptations
5. Values extraction with "in practice" behaviors
6. Dos and donts compilation
7. Output: .ai/brand/{name}/ with guideline.yml, voice.yml, values.yml, dos-and-donts.md

**Reads**: existing brand materials (if any), market research results
**Writes**: .ai/brand/{name}/*
**Interactive**: yes
**Model tier**: principal (requires nuanced creative judgment)

### 2. brand-audit (codification skill)
**Purpose**: Analyze existing brand materials (website, copy samples, style guides) and extract a structured brand guideline.
**Flow**:
1. Gather existing materials — user provides URLs, files, documents
2. Analyze voice patterns (readability, sentence structure, tone)
3. Extract implicit positioning, values, audience
4. Present findings section-by-section for validation
5. User approves/corrects each section
6. Output: same format as brand-strategy

**Reads**: user-provided materials, existing website content
**Writes**: .ai/brand/{name}/*
**Interactive**: yes
**Model tier**: senior

### 3. brand-evolve (reinvention skill)
**Purpose**: Guided update of an existing brand guideline. Preserves what works, evolves what doesn't.
**Flow**:
1. Load existing guideline from .ai/brand/{name}/
2. User describes what's changing and why (pivot, new audience, market shift)
3. Optional: fresh market research for new positioning context
4. Walk through each guideline section: keep / modify / replace
5. For modified sections: propose 2-3 evolution directions
6. Output: updated guideline files + changelog entry

**Reads**: .ai/brand/{name}/*
**Writes**: .ai/brand/{name}/* (updated)
**Interactive**: yes
**Model tier**: senior

### 4. brand-loader (read-only utility)
**Purpose**: Load brand context for use by other skills/plugins. Pure reader.
**Flow**:
1. Resolve brand name (from argument, local CLAUDE.md, or .ai/brand/ scan)
2. Load requested layer: L1 (overview), L2 (module), L3 (specific file)
3. Return brand context to caller

**Reads**: .ai/brand/{name}/*
**Writes**: nothing
**Interactive**: no
**Model tier**: junior

## Commands

| Command | Maps to | Purpose |
|---------|---------|---------|
| `/brand:create` | brand-strategy skill | New brand from scratch |
| `/brand:audit` | brand-audit skill | Codify existing brand |
| `/brand:evolve` | brand-evolve skill | Reinvent existing brand |
| `/brand:apply` | brand-loader + config | Wire brand into package context |
| `/brand:status` | read .ai/brand/ | Show available brands and their state |

## Output Schema

### .ai/brand/{name}/ structure
```
.ai/brand/{name}/
├── guideline.yml         # Positioning, audience, pillars, UVP, competitive matrix
├── voice.yml             # 1-10 scales, writing patterns, vocabulary, platform adaptations
├── values.yml            # Core values + "in practice", beliefs, non-negotiables
├── dos-and-donts.md      # Human-readable rules and anti-patterns
└── market-research.md    # Competitive landscape (generated during creation)
```

### guideline.yml schema
```yaml
brand_name: ""
tagline: ""
elevator_pitch: ""     # 30-second version
origin_story: ""       # Why this brand exists

audience:
  primary:
    description: ""
    pain_points: []
    aspirations: []
  secondary:
    description: ""
    pain_points: []
    aspirations: []

positioning:
  unique_value_proposition: ""
  credibility_markers: []
  competitive_matrix:
    axes: ["", ""]      # Two dimensions for positioning
    position: ""         # Where we sit
    competitors: []      # Where others sit

content_pillars:
  - name: ""
    percentage: 40       # Share of content
    description: ""
  - name: ""
    percentage: 25
    description: ""

visual_direction: ""     # Abstract: "premium, clean, trustworthy" — NOT hex codes

personality_archetype: "" # Expert / Friend / Innovator / Guide / Motivator (or blend)
```

### voice.yml schema
```yaml
attributes:
  formal_casual: 7         # 1=very formal, 10=very casual
  serious_playful: 4
  technical_simple: 6
  reserved_expressive: 5
  humble_confident: 7

writing_patterns:
  sentence_structure: ""   # Short/compound/variety
  paragraph_style: ""      # Length, whitespace
  hook_patterns: []        # Opening formulas with examples

vocabulary:
  signature_phrases: []
  power_words: []          # Gravitate toward
  never_use: []            # Words that sound wrong for this brand

platform_adaptations:
  twitter: ""
  linkedin: ""
  long_form: ""
  email: ""

anti_patterns: []          # What doesn't sound like this brand
```

### values.yml schema
```yaml
core_values:
  - name: ""
    description: ""
    in_practice: ""        # Concrete behavior, not abstract
beliefs: []
contrarian_views: []       # What we believe that others don't
non_negotiables: []        # Lines we won't cross

decision_framework:
  when_uncertain: ""
  priorities: []
  tradeoffs: ""            # What we sacrifice for what
```

## Plugin Infrastructure

### plugin.json
- Hooks: minimal. PreToolUse to check brand state before writes (prevent stale reads).
- No PostToolUse hooks needed (brand doesn't cascade).
- SessionStart: optional brand detection (scan .ai/brand/ for available brands).

### ecosystem.json
- 4 skills, 5 commands, 0 agents (uses claude-core brainstorm infrastructure)

### Brand declaration (consumer side)
In a package's local CLAUDE.md or project CLAUDE.md:
```
## Brand
brand: ro
brand_path: .ai/brand/ro/
```
One line. Any skill that needs brand context reads this, then loads from the path.

## Templates to Adapt

| Source | Adapt for | Priority |
|--------|----------|----------|
| Digital Brain voice.md | voice.yml schema | High |
| Digital Brain brand.md | guideline.yml schema | High |
| Digital Brain values.yaml | values.yml schema | High |
| Anti-Gravity brand_guidelines.md | Comprehensive voice checklist | Medium |
| Superpowers brainstorming | brand-strategy sparring flow | High |
| Anti-Gravity content_frameworks.md | Future studio content skills | Deferred |
| Design tokens deep dive | Future design plugin | Deferred |

## Estimated Scope

| Component | Count | Effort |
|-----------|-------|--------|
| Plugin scaffold | 1 | Small |
| Skills | 4 | Medium (brand-strategy is largest) |
| Commands | 5 | Small (thin wrappers) |
| Output schemas | 3 YAML + 1 MD | Small |
| Templates/references | ~3 files | Medium |

## Build Order (suggested waves)

1. **Plugin scaffold** — plugin.json, ecosystem.json, directory structure
2. **Schemas + templates** — output format definitions, adapted templates from external references
3. **brand-loader skill** — simplest skill, read-only, enables testing
4. **brand-strategy skill** — core creation flow with sparring + market research
5. **brand-audit skill** — codification from existing materials
6. **brand-evolve skill** — reinvention of existing brand
7. **Commands** — /brand:create, /brand:audit, /brand:evolve, /brand:apply, /brand:status
8. **Self-review** — audit against plugin standards, test with real brand creation
