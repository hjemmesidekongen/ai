---
name: content-writer
description: >
  Drafts brand-aware written content: READMEs, landing pages, blog posts, social
  posts, product descriptions, email newsletters, and marketing copy. Applies
  brand voice, SEO, and copywriting best practices with automated quality checks.
  Use for any content writing or copywriting task.
user_invocable: true
interactive: true
model_tier: senior
depends_on:
  - web-copywriting
  - seo-fundamentals
  - brand-voice-implementation
  - content-strategy-patterns
  - marketing-psychology-patterns
  - social-media-patterns
triggers:
  - "write README"
  - "write content"
  - "write landing page"
  - "write blog post"
  - "draft marketing copy"
  - "draft social post"
  - "write email copy"
  - "write case study"
reads: ["README.md"]
writes: ["User-specified output path or stdout"]
checkpoint:
  type: data_validation
  required_checks:
    - name: "voice_applied"
      verify: "Content matches brand voice attributes (or user tone override) and avoids banned vocabulary"
      fail_action: "Rewrite sections violating voice.yml or user-specified tone"
    - name: "no_ai_patterns"
      verify: "Zero AI writing anti-patterns (puffery, hedge phrases, promotional adjectives)"
      fail_action: "Run writing-clearly-and-concisely sweep and rewrite flagged sections"
    - name: "structure_compliant"
      verify: "Draft follows the structural template for its content type"
      fail_action: "Restructure to match content type template from process.md"
    - name: "claims_substantiated"
      verify: "No fabricated statistics, testimonials, or unverified claims"
      fail_action: "Mark unverified claims with [NEEDS DATA] placeholders"
    - name: "scannable"
      verify: "Paragraphs 2-4 sentences, headings every 3-4 paragraphs, no wall-of-text"
      fail_action: "Break long paragraphs, add subheadings, convert dense lists to tables"
  on_fail: "Draft has quality issues — fix before delivering"
  on_pass: "Content is voice-aligned, structurally sound, scannable, and free of AI patterns"
_source:
  origin: "smedjen"
  inspired_by: "agent-toolkit/crafting-effective-readmes + awesome-subagents/content-marketer + digital-brain content pipeline"
  ported_date: "2026-03-11"
  iteration: 2
  changes: "Fix depends_on (3→6 skills), add scannability gate, improve description findability, fix skill name refs"
---

# Content Writer

Orchestrate brand context and knowledge skills into quality-gated content drafts.

## When to Trigger

- Write, draft, rewrite, or generate any user-facing content
- Any content task where brand voice consistency or SEO matters

## Content Types

| Type | Skills Used | Output |
|------|------------|--------|
| README | web-copywriting, seo-fundamentals | Audience-matched README |
| Landing page | web-copywriting, seo-fundamentals, marketing-psychology-patterns | Above-fold + CTA sections |
| Blog post | content-strategy-patterns, seo-fundamentals, brand-voice-implementation | Article with SEO metadata |
| Social media | social-media-patterns, brand-voice-implementation | Platform-adapted posts |
| Marketing copy | web-copywriting, marketing-psychology-patterns | Benefit-driven copy |
| Email | content-strategy-patterns, brand-voice-implementation | Newsletter or campaign copy |

## Process

Intake → Load context (brand-loader + skills) → Draft → Quality gate (5 checks) → Deliver.
Voice priority: user override > brand voice.yml > neutral default. See `references/process.md`.
