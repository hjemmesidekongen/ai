---
name: tone-of-voice
user-invocable: false
description: >
  Defines how the brand speaks and writes. Builds a voice spectrum, personality
  attributes with do/don't examples, messaging framework, channel-specific tone
  variations, vocabulary guide, and writing samples. Writes the voice section
  to brand-reference.yml. Use when defining brand voice, creating tone
  guidelines, running /brand:generate skill 3 of 9, or establishing messaging
  framework.
phase: 3
depends_on: [identity-interview, audience-personas]
writes:
  - "brand-reference.yml#voice"
reads:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
  - "brand-reference.yml#audience"
checkpoint:
  type: data_validation
  required_checks:
    - name: "spectrum_dimensions"
    - name: "personality_attributes"
    - name: "channel_variations"
    - name: "writing_samples"
---

# Tone of Voice

Phase 3 of brand generation. Translates the brand's identity (Phase 1) and audience (Phase 2) into a concrete voice framework: how the brand sounds, what it says, and what it never says. The output drives content creation, social media strategy, website copy, and all future brand communications.

## Context

**Writes:** `brand-reference.yml#voice`
**Reads:** `brand-reference.yml#meta`, `brand-reference.yml#identity`, `brand-reference.yml#audience`
**Checkpoint:** data_validation — spectrum_dimensions, personality_attributes, channel_variations, writing_samples
**Depends on:** identity-interview (phase 1), audience-personas (phase 2)

## Process Summary

1. Check findings.md (including context from phases 1 and 2) and state.yml errors from any previous session
2. Read identity and audience data: values, positioning, mission/vision, primary persona channels and goals
3. Call decision-reader for domain `brand-voice` — apply brainstorm decisions by confidence level
4. Stage 1 — Voice Spectrum: place brand on 4 dimensions (formality, humor, enthusiasm, technicality 1-10) → write `voice.spectrum`
5. Stage 2 — Voice Personality: build 3-4 "we are / we are not" pairs with descriptions → write `voice.personality`
6. Stage 3 — Channel Variations: define tone shifts for website, social, email, support (min 2 channels)
7. Stage 4 — Vocabulary Guide: preferred words, banned words, jargon policy
8. Stage 5 — Messaging Framework: tagline, 3 value propositions, elevator pitch, optional boilerplate → write `voice.messaging`
9. Stage 6 — Writing Samples: generate 3 good/bad/why examples covering homepage, social, email → write `voice.writing_samples`
10. Present full summary for approval, write brand-reference.yml, run checkpoint; on pass update state.yml and advance to phase 4

## Execution

Before executing, read `references/process.md` for detailed instructions.
