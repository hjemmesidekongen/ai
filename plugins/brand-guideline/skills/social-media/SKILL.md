---
name: social-media
user-invocable: false
description: >
  Defines social media presence, platform-specific voice adjustments, content
  pillars, hashtag strategy, visual rules, engagement guidelines, and generates
  default social media image templates (OG image, Twitter card, LinkedIn banner).
  Writes the social section to brand-reference.yml and creates SVG templates
  in assets/social/.
  Use when defining social media strategy, platform guidelines, running /brand:generate
  skill 8 of 9, creating content pillars, or generating social images.
phase: 8
depends_on: [identity-interview, audience-personas, tone-of-voice, typography-color, visual-identity, logo-design, content-rules]
writes:
  - "brand-reference.yml#social"
  - "assets/social/og-image.svg"
  - "assets/social/twitter-card.svg"
  - "assets/social/linkedin-banner.svg"
reads:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
  - "brand-reference.yml#audience"
  - "brand-reference.yml#voice"
  - "brand-reference.yml#colors"
  - "brand-reference.yml#visual.logo"
  - "brand-reference.yml#assets.logo"
  - "brand-reference.yml#content"
checkpoint:
  type: data_validation
  required_checks:
    - name: "platforms_count"
    - name: "content_pillars"
    - name: "og_image_svg"
    - name: "twitter_card_svg"
    - name: "profile_picture_variant"
---

# Social Media

Phase 8 of brand generation. Defines the brand's social media presence, generates
platform-specific voice adjustments, establishes content pillars and hashtag strategy,
and creates default social sharing images. Builds on all previous phases.

## Context

**Reads:** `meta`, `identity.positioning`, `audience.personas[].channels`, `voice.personality`,
`voice.spectrum`, `colors.primary/secondary/neutral`, `visual.logo`, `assets.logo`, `content.content_types`

**Writes:** `brand-reference.yml#social` + `assets/social/og-image.svg`,
`twitter-card.svg`, `linkedin-banner.svg`

**Checkpoint:** `data_validation` — platforms_count (≥2 with name/audience/tone_adjustment),
content_pillars (≥3), og_image_svg (1200x630), twitter_card_svg (1200x675),
profile_picture_variant

**Depends on:** identity-interview, audience-personas, tone-of-voice, typography-color,
visual-identity, logo-design, content-rules

## Process Summary

1. Read brand data from brand-reference.yml (all sections)
2. Stage 1 — Platform selection: cross-reference persona channels, confirm 2+ platforms, define audience/purpose per platform → `social.platforms[].name`, `.audience`
3. Stage 2 — Voice adjustments: auto-generate shifts from voice spectrum, confirm per platform, capture post types and frequency → `social.platforms[].tone_adjustment`, `.post_types`, `.frequency`
4. Stage 3 — Content pillars: suggest 3-5 from identity/audience data, define name/description/example_topics for each → `social.content_pillars`
5. Stage 4 — Hashtag strategy: branded, industry, content-specific tags, per-platform counts → `social.hashtag_strategy`
6. Stage 5 — Visual rules: profile picture variant, post style, story style, platform dimension specs → `social.visual_rules`
7. Stage 6 — SVG generation: produce og-image.svg (1200x630), twitter-card.svg (1200x675), linkedin-banner.svg (1584x396) using brand colors and logo
8. Stage 7 — Engagement rules: response time, reply tone, escalation protocol, never-list → `social.engagement`
9. Present full summary for approval, write brand-reference.yml + SVG files
10. Run checkpoint; on pass update state.yml and write recovery notes

## Execution

Before executing, read `references/process.md` for detailed instructions.
