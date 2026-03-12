# Studio Skills Build — Learnings

(Appended after each iteration. Read this FIRST every iteration.)

## Iteration 1: web-copywriting
- Synthesized 3 external sources (copywriting 251L, copy-editing 443L, brand-guidelines 169L) into 71-line SKILL.md + process.md
- Key adaptation: collapsed the interactive 5-phase workflow into a knowledge reference. External source was an executor skill (asks questions, waits for confirmation). Dev-engine pattern is knowledge-only (loaded by context-assembler, no interaction).
- Seven Sweeps framework is the highest-value pattern — sequential editing passes. Worth referencing from other studio skills.
- UI text patterns (errors, empty states, buttons, tooltips) are directly useful for frontend-dev agent context.
- Pattern: external sources are 200-800 lines each. SKILL.md captures the decision framework and anti-patterns. process.md holds templates, checklists, and examples.
- External references are at `/Users/mvn/Personal/hjemmesidekongen-ai/external-references/antigravity-awesome-skills-main/skills/`

## Iteration 2: content-strategy-patterns
- Extracted from content-creator SKILL.md (248L) + content_frameworks.md (535L)
- The 40/25/25/10 pillar ratio is the core insight — everything else is templates
- Content repurposing matrix is high-value: one blog post -> 10+ social pieces
- Video script template was included even though it's light — the format structure matters

## Iteration 3: seo-fundamentals
- Combined 4 external SEO skills (fundamentals 176L, audit 488L, keyword 95L, meta-optimizer 92L) into one skill
- SEO Health Index scoring model (0-100 weighted composite) is the key framework
- E-E-A-T is NOT a ranking factor — it's a quality evaluation framework. Important distinction.
- Meta tag character limits are the most immediately actionable: title 50-60, meta desc 150-160, URL <60

## Iteration 4: marketing-psychology-patterns
- Combined marketing-psychology (262L) and marketing-ideas (228L)
- PLFS and MFS scoring systems are the core value — decision frameworks, not theory dumps
- Journey-stage model mapping (awareness/consideration/decision/retention) gives agents context for which psychology to apply
- Max 5 recommendations rule prevents information overload
- Ethical guardrails section is essential — prevents dark pattern generation

## Iteration 5: brand-voice-implementation
- Combined brand-guidelines (169L) and brand_guidelines.md (200L)
- Plain speech vs brand voice decision matrix is the key insight
- Personality archetypes (Expert/Friend/Innovator/Guide/Motivator) give agents a mental model
- Hit 82 lines initially — trimmed by merging Writing Rules and Words to Avoid sections

## Iteration 6: social-media-patterns
- Extracted from social-content (813L) — the longest external source
- Platform-specific strategy is the core value — what works/doesn't per platform
- Hook formulas (curiosity/story/value/contrarian/social proof) are reusable patterns
- Content pillar ratios differ from content-strategy (30/25/25/15/5 vs 40/25/25/10) — social has a "personal" pillar

## Iteration 7: sitemap-planning
- Combined seo-structure-architect (108L) with domain knowledge
- Content siloing strategy is the key insight — within-silo dense, cross-silo rare
- Schema JSON-LD examples in process.md are directly copy-pasteable
- "3 clicks from homepage" rule is simple but enforces good IA

## Iteration 8: design-to-code-patterns
- Original skill, no external reference to adapt
- Token extraction workflow is the most actionable content — step-by-step from design file to CSS vars
- Component decomposition rules (repeated group = component, variants = props) bridge design and code thinking
- Anti-patterns table is high-value: hardcoded values, arbitrary pixels, wrong naming

## Cross-cutting patterns
- SKILL.md ≤80 lines works well: decision frameworks, core principles, anti-patterns
- process.md holds templates, checklists, examples, code snippets
- Every skill follows: "what to do" in SKILL.md, "how to do it" in process.md
- Checkpoint checks should verify the OUTPUT, not the INPUT (e.g., "benefits over features" not "read the brief")
- Studio skills naturally group into: content (copywriting, content-strategy, social), marketing (psychology, ideas), technical (SEO, sitemap), implementation (brand-voice, design-to-code)
