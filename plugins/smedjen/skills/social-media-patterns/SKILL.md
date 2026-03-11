---
name: social-media-patterns
description: >
  Social media content patterns — platform-specific strategies for LinkedIn,
  Twitter/X, Instagram, TikTok. Post templates, hook formulas, content pillars,
  repurposing workflows, and engagement optimization.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "social media"
  - "social content"
  - "linkedin post"
  - "twitter thread"
  - "instagram content"
  - "social strategy"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "platform_adapted"
      verify: "Content is formatted for the specific platform (length, tone, features)"
      fail_action: "Adapt format to platform norms — don't cross-post without modification"
    - name: "hook_first_line"
      verify: "First line stops the scroll — uses a proven hook formula"
      fail_action: "Rewrite opener using curiosity, story, value, or contrarian hook pattern"
    - name: "pillar_ratio_maintained"
      verify: "Content mix follows pillar ratios — promotional under 10%"
      fail_action: "Rebalance toward educational and conversational content"
    - name: "cta_or_question"
      verify: "Every post ends with a clear CTA or engagement question"
      fail_action: "Add a question or next-step prompt at the end"
  on_fail: "Social content has platform or engagement issues — fix before posting"
  on_pass: "Social content is platform-optimized and engagement-ready"
_source:
  origin: "smedjen"
  inspired_by: "antigravity-awesome-skills/social-content"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Extracted platform strategies and templates into knowledge skill"
---

# social-media-patterns

## Platform Quick Reference

**LinkedIn**: B2B, thought leadership. 3-5x/week. 1200-1500 chars. Hook before "see more". Links in comments, not post body. Personal stories + business lessons work best.

**Twitter/X**: Tech, real-time, communities. 3-10x/day (including replies). Under 100 chars for tweets. Threads: strong hook in tweet 1, one idea per tweet. Quote tweets with insight beat plain retweets.

**Instagram**: Visual brands, lifestyle. 1-2 feed + 3-10 Stories/day. Reels get 2x reach. Carousels: 10 slides with educational content. First frame of Reels must hook immediately.

**TikTok**: Awareness, younger audiences. 1-4x/day. Native, unpolished > produced. Hook in first 1-2 seconds. Under 30 seconds to start. Vertical only. Use trending sounds.

## Hook Formulas

**Curiosity**: "I was wrong about [belief]." | "The real reason [outcome] happens isn't what you think." | "Nobody talks about [insider knowledge]."

**Story**: "Last week, [unexpected thing] happened." | "3 years ago, I [past state]. Today, [current state]."

**Value**: "How to [outcome] without [pain]:" | "[Number] things that [outcome]:" | "Stop [mistake]. Do this instead:"

**Contrarian**: "Unpopular opinion: [bold statement]" | "[Common advice] is wrong. Here's why:"

## Post Templates

**LinkedIn Story**: Hook (unexpected outcome) -> Scene -> Challenge -> What happened -> Turning point -> Result -> Lesson -> Question. **LinkedIn List**: "[X] things I learned about [topic] after [credibility]: 1. Point — explanation..." **Twitter Tutorial Thread**: Tweet 1 hook + promise -> Tweets 2-7 one step each -> Final tweet summary + CTA. **Instagram Carousel**: Slide 1 bold statement -> Slides 2-9 one point each -> Slide 10 summary + CTA.

## Content Pillars

5 pillars with ratios: **Industry insights 30%** | **Behind-the-scenes 25%** | **Educational 25%** | **Personal 15%** | **Promotional 5%**. Track monthly. Promotional over 10% erodes trust.

## What Kills Reach

LinkedIn: links in post body, corporate speak, generic quotes. Twitter: threads without hooks, ignoring replies, pure self-promotion. Instagram: low-quality images, ignoring Reels/Stories. All platforms: cross-posting without adaptation, only promotional content, ignoring comments.

See `references/process.md` for full post templates, repurposing workflows, platform-specific format tips, and engagement metrics.
