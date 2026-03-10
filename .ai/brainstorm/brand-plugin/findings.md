# Brand Plugin — Research Findings

## Reusable Templates (steal/adapt)

### From Digital Brain Skill (Agent-Skills-for-Context-Engineering)
- **voice.md** — 1-10 attribute scales (formal-casual, serious-playful, technical-simple, reserved-expressive, humble-confident), writing patterns at 3 levels (sentence, paragraph, hook), vocabulary (signature phrases, power words, never-use list), platform adaptations, anti-patterns
- **brand.md** — one-liner + elevator pitch + origin story, audience segmentation with pain points, content pillars (80/20 split), UVP with credibility markers, competitive positioning matrix, growth strategy
- **values.yaml** — core values with "in practice" behaviors, beliefs + contrarian views, non-negotiables, decision framework (priorities, tradeoffs)
- **bio-variants.md** — platform-specific bio templates (8+ platforms)
- **Architecture**: 3-level progressive disclosure (L1 router → L2 module instructions → L3 data files). 87% token reduction vs loading everything.

### From Anti-Gravity (content-creator skill)
- **brand_guidelines.md** — voice dimensions, personality archetypes (Expert/Friend/Innovator/Guide/Motivator), persona-to-tone mapping, channel-specific guidelines, grammar + inclusivity rules
- **content_frameworks.md** — blog/social/email templates, pillar strategy (40/25/25/10), repurposing matrix, pre-publishing checklists. Production-ready, steal wholesale for studio content skills.

### From Content Creator (claude-code-templates)
- **brand_voice_analyzer.py concept** — readability scoring, sentence structure analysis, tone assessment. Adaptable as brand guideline validation.
- **SEO optimizer concept** — keyword density, structure assessment, meta suggestions.

### From Design System Patterns (agents/ui-design)
- **design-tokens.md** — primitive vs semantic token mapping, naming convention (`[category]-[property]-[variant]-[state]`), CSS custom properties output, dark/light theme, contrast validation. Directly applicable to design plugin token generation.

### From Superpowers (brainstorming skill)
- **Process flow**: context → one-question-at-a-time → propose 2-3 alternatives → present in sections → approve each → output doc. Hard gate: no execution until design approved. Use as model for brand discovery sparring.

## Architecture Patterns

### Context Resolution (from Digital Brain)
1. Check if artifact exists → load
2. If not → gather minimum from user via interview
3. Append to history log (JSONL)
4. On subsequent use, read existing first
- Critical for brand skills: don't re-ask if guideline exists. Graceful degradation with partial info.

### Module Isolation (from Digital Brain)
- 6 independent modules, each with own files
- Router SKILL.md decides which module to load
- No cross-module data leakage
- Apply to: brand modules (voice, values, positioning) and studio skill categories

### Asset Registration (from Agency)
- Producer registers with type, format, path, tags
- Consumer queries by type, tag, or producer
- Loose coupling through registry, not direct file imports
- Keep for brand → design → dev token flow

## Key Insights

1. Voice codification works best with **numerical scales** (1-10), not prose descriptions. Agents reason about numbers better.
2. Values must have **"in practice" manifestation** — abstract values are useless for downstream skills.
3. Content pillars need **percentage splits** to be actionable (not just topic lists).
4. Platform adaptations are a brand concern (Twitter voice vs LinkedIn voice) — belongs in brand guideline, not content plugin.
5. Brand personality archetypes (Expert/Friend/Innovator/Guide/Motivator) are a useful discovery tool during sparring.
6. Competitive positioning works best as a **2D matrix** (pick two axes relevant to the market).
