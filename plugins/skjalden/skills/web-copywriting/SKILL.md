---
name: web-copywriting
description: >
  Web copywriting patterns — headlines, CTAs, microcopy, error messages, empty
  states, and landing page structure. Covers above-fold framework, benefit-driven
  copy, the Seven Sweeps editing method, and UI text guidelines.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "web copy"
  - "copywriting"
  - "landing page copy"
  - "microcopy"
  - "CTA copy"
  - "UI text"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "benefits_over_features"
      verify: "Every feature statement connects to a user benefit via 'which means' bridge"
      fail_action: "Add the benefit bridge: Feature -> Benefit -> Outcome"
    - name: "one_cta_per_section"
      verify: "Each page section drives toward a single action, not competing CTAs"
      fail_action: "Remove secondary CTAs or move them to separate sections"
    - name: "no_fabricated_claims"
      verify: "No invented statistics, testimonials, or guarantees without placeholders"
      fail_action: "Mark unverified claims with [PLACEHOLDER: need real data] brackets"
    - name: "clarity_over_cleverness"
      verify: "Headlines and CTAs are immediately understandable without context"
      fail_action: "Rewrite until the copy feels obvious, not clever"
  on_fail: "Copy has conversion-killing patterns — fix before publishing"
  on_pass: "Copy is clear, benefit-driven, and honest"
_source:
  origin: "smedjen"
  inspired_by: "antigravity-awesome-skills/copywriting + copy-editing + brand-guidelines"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Synthesized three external sources into smedjen knowledge skill"
---

# web-copywriting

## Core Principles

Clarity over cleverness. Benefits over features. Specificity over vagueness. Customer language over company language. One idea per section. Every claim follows: Feature -> Benefit -> Outcome.

## Above-Fold Framework

**Headline**: single most important value proposition, outcome-focused, specific. **Subheadline**: adds clarity in 1-2 sentences. **Primary CTA**: action verb describing what the user gets ("Start free trial", not "Submit").

## Page Structure

Social proof (logos, stats, testimonials) -> Problem articulation -> Solution with 3-5 key benefits -> How it works (3-4 steps) -> Objection handling (FAQ, comparisons, guarantees) -> Final CTA with risk reduction. Never stack features without narrative flow.

## UI Text Rules

**Buttons**: action verbs, 2-3 words, specific ("Create Project" not "Submit"). **Errors**: say what happened, why, and what to do next. **Empty states**: explain what goes here + clear action to populate. **Tooltips**: under 2 sentences, explain the "why". No exclamation marks in UI. No "Please" — just be direct. Sentence case everywhere except page titles.

## Seven Sweeps (Editing)

Sequential passes on existing copy: (1) Clarity — can the reader understand? (2) Voice — is tone consistent? (3) So What — does every claim answer "why should I care"? (4) Prove It — is every claim backed by evidence? (5) Specificity — are numbers, timeframes, and examples concrete? (6) Emotion — does the copy make the reader feel something? (7) Zero Risk — are barriers to action removed near CTAs?

## Anti-Patterns

Kill these on sight: weak intensifiers (very, really, extremely), filler (just, actually, basically), nominalizations ("make a decision" -> "decide"), passive voice, hedging language, marketing speak in UI ("supercharge" -> "speed up"), wall-of-features without benefits, buried CTAs, generic claims ("we help businesses grow").

See `references/process.md` for page structure templates, CTA formulas, specificity upgrades, word-level editing rules, and the full Seven Sweeps checklist.
