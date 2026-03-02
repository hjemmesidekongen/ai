# Media Plugins — Roadmap Brief

**Status:** Not started — requires dedicated brainstorm
**Depends on:** Brand plugin (visual identity), Design plugin (creative direction)
**Brainstorm ref:** dev-hardening d8

## What They Do
AI-generated video and photography using external AI models (not Claude).

## Key Decisions (from dev-hardening brainstorm)
- Use external AI models (Nano Banana 2, Runway, Midjourney, etc.) for generation
- Plugins are orchestrators — handle briefs, prompt engineering, quality review, asset management
- Establishes architectural pattern: not all plugin agents use Claude as execution engine
- Claude handles the creative brief and quality review; external AI handles generation

## Likely Plugins
### Videographer
- Video generation from creative briefs
- AI model: Runway, Pika, or similar
- Output: short-form video, social media clips, product demos

### Photographer
- AI photography from creative briefs
- AI model: Nano Banana 2, Midjourney, or similar
- Output: product shots, lifestyle images, stock photography, hero images

## Likely Shared Pattern
- Brief builder (from brand context + creative direction)
- Prompt engineer (translates brief to model-specific prompts)
- Quality reviewer (evaluates output against brief)
- Asset manager (organizes, names, stores generated assets)

## Open Questions (for brainstorm)
- Which specific AI models to support?
- How to handle API costs and rate limits?
- Quality review criteria — how does Claude evaluate visual output it can't see?
- Iteration workflow — how to refine generated output?
- Asset management — where do generated files live?
- MCP integration — are there MCPs for these AI models?

## Next Step
`/brainstorm:start videographer-plugin` and `/brainstorm:start photographer-plugin`
(or combined as `/brainstorm:start media-plugins` if the pattern is shared enough)
