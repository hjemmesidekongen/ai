---
name: brand-voice-implementation
description: >
  Brand voice implementation in code — formality spectrum, tone attributes,
  personality archetypes, UI copy tone selection (plain speech vs brand voice),
  channel-specific guidelines, and voice consistency checking across components.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "brand voice"
  - "brand guidelines"
  - "tone of voice"
  - "brand consistency"
  - "UI voice"
  - "copy tone"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "tone_consistent"
      verify: "All copy within a component uses the same formality level and personality"
      fail_action: "Identify tone shifts and normalize to the declared brand voice"
    - name: "plain_speech_default"
      verify: "Product UI, docs, errors, settings use plain speech unless context calls for personality"
      fail_action: "Strip brand personality from functional UI — save it for empty states, onboarding, 404s"
    - name: "you_over_we"
      verify: "Copy addresses the user (you/your) more than the company (we/our)"
      fail_action: "Rewrite company-centric copy to be user-centric"
    - name: "no_banned_words"
      verify: "No weak intensifiers (very, really, just), no jargon (synergy, leverage), no hedging (maybe, hopefully)"
      fail_action: "Replace banned words with specific, concrete alternatives"
  on_fail: "Brand voice has consistency or tone issues — fix before shipping"
  on_pass: "Brand voice is consistent and appropriate"
_source:
  origin: "dev-engine"
  inspired_by: "antigravity-awesome-skills/brand-guidelines + content-creator/brand_guidelines"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Combined brand voice framework and UI tone guidelines into knowledge skill"
---

# brand-voice-implementation

## Formality Spectrum

Four levels: **Formal** (legal, investor, crisis), **Professional** (B2B, whitepapers, case studies), **Conversational** (blog, social, email), **Casual** (community, behind-scenes). Pick one level per context and hold it consistently.

## Tone Attributes

Choose 3-5 for the brand: Authoritative, Friendly, Trustworthy, Educational, Inspiring, Innovative, Witty (use sparingly). These stay constant — formality shifts by context, personality doesn't.

## Personality Archetypes

Pick one primary, one secondary: **The Expert** (knowledgeable, data-driven), **The Friend** (warm, supportive, relatable), **The Innovator** (bold, forward-thinking), **The Guide** (wise, step-by-step, patient), **The Motivator** (energetic, empowering, action-oriented).

## Plain Speech vs Brand Voice

| Plain Speech (default) | Brand Voice (earned moments) |
|------------------------|------------------------------|
| Product UI, buttons, labels | 404 pages, empty states |
| Documentation, help text | Onboarding flows |
| Error messages, settings | Loading states, celebrations |
| Billing, payment flows | Marketing copy, announcements |

Plain speech: clear, direct, functional. Brand voice: adds personality where users have time to appreciate it. Default to plain speech.

## Writing Rules

Active voice 80%+. "You/your" more than "we/our". One idea per sentence. Benefits before features. Lead with the main point. Short paragraphs (2-3 sentences for web). Avoid: very, really, just, maybe, hopefully, synergy, leverage, innovative, disruptive. Replace with specific alternatives.

## Grammar Defaults

Oxford comma always. One exclamation mark max per piece. Title Case for H1, sentence case for H2+. Spell out 1-9, numerals for 10+. Gender-neutral language.

See `references/process.md` for persona-to-tone mapping, channel guidelines, messaging pillars, inclusivity rules, and the brand voice consistency checklist.
