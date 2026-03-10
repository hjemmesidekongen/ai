---
name: brand-strategy
description: >
  Creates a brand from scratch through market research and interactive sparring.
  Runs competitive research via Perplexity, then guides the user through
  positioning, audience, voice, values, and content pillars. Produces the full
  brand guideline set at .ai/brand/{name}/. Use when building a new brand,
  defining brand strategy for a product, or when /brand:create is invoked.
user_invocable: false
interactive: true
model_tier: principal
depends_on: []
triggers:
  - "create a brand"
  - "build brand strategy"
  - "brand creation"
  - "/brand:create"
reads:
  - "plugins/brand/resources/guideline-schema.yml"
  - "plugins/brand/resources/voice-schema.yml"
  - "plugins/brand/resources/values-schema.yml"
writes:
  - ".ai/brand/{name}/guideline.yml"
  - ".ai/brand/{name}/voice.yml"
  - ".ai/brand/{name}/values.yml"
  - ".ai/brand/{name}/dos-and-donts.md"
  - ".ai/brand/{name}/market-research.md"
checkpoint:
  type: data_validation
  required_checks:
    - name: "guideline_complete"
      verify: "guideline.yml exists with name, tagline, positioning, audience, content_pillars"
      fail_action: "Complete missing sections through follow-up questions"
    - name: "voice_complete"
      verify: "voice.yml exists with personality_archetype, voice_attributes (all 5 scales), vocabulary"
      fail_action: "Run voice discovery phase"
    - name: "values_complete"
      verify: "values.yml exists with core_values (each has in_practice), non_negotiables"
      fail_action: "Run values phase"
    - name: "dos_and_donts_written"
      verify: "dos-and-donts.md exists with at least 5 dos and 5 donts"
      fail_action: "Generate from voice and values files"
    - name: "user_approved"
      verify: "User explicitly approved the final guideline set"
      fail_action: "Present summary and ask for approval"
  on_fail: "Address gaps before finalizing"
  on_pass: "Brand guideline complete at .ai/brand/{name}/"
_source:
  origin: "brand"
  inspired_by: "brainstorm-session + Digital Brain identity module"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New skill for brand plugin — research-grounded interactive sparring"
---

# Brand Strategy

Creates a brand from scratch through research-grounded interactive sparring.

## Process

1. **Intake** — brand name, domain/market, initial vision
2. **Research** — competitive landscape via Perplexity (focused queries, max 3 results)
3. **Sparring** — one question at a time, section-by-section: positioning, audience, voice (archetype → scales), values, pillars
4. **Draft** — write all files, present summary
5. **Approval** — user reviews and approves (or requests changes)

## Rules

- One question at a time. Prefer multiple choice when exploring.
- Challenge weak positioning — "how is this different from X?"
- Archetypes (Expert/Friend/Innovator/Guide/Motivator) seed voice discovery.
- Present each section for approval before moving on.
- If `.ai/brand/{name}/` has partial files, resume from where it left off.

## Output

Files at `.ai/brand/{name}/`. See `references/process.md` for detailed workflow.
