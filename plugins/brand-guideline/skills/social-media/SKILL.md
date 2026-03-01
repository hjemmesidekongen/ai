---
name: social-media
description: >
  Defines social media presence, platform-specific voice adjustments, content
  pillars, hashtag strategy, visual rules, engagement guidelines, and generates
  default social media image templates (OG image, Twitter card, LinkedIn banner).
  Writes the social section to brand-reference.yml and creates SVG templates
  in assets/social/.
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
      verify: "social.platforms has at least 2 items, each with name, audience, and tone_adjustment"
      fail_action: "Ask the user which additional platforms they use and define voice adjustments for each"
    - name: "content_pillars"
      verify: "social.content_pillars has at least 3 items, each with name and description"
      fail_action: "Walk through content pillar identification with the user until at least 3 are defined"
    - name: "og_image_svg"
      verify: "assets/social/og-image.svg exists with viewBox='0 0 1200 630'"
      fail_action: "Generate the OG image SVG at 1200x630 using brand colors and logo"
    - name: "twitter_card_svg"
      verify: "assets/social/twitter-card.svg exists with viewBox='0 0 1200 675'"
      fail_action: "Generate the Twitter card SVG at 1200x675 using brand colors and logo"
    - name: "profile_picture_variant"
      verify: "social.visual_rules.profile_picture is defined and references a valid logo variant"
      fail_action: "Ask the user which logo variant to use as the social media profile picture"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Social Media

Phase 8 of brand generation. This skill defines the brand's social media presence, generates platform-specific voice adjustments, establishes content pillars and hashtag strategy, and creates default social sharing images. It builds on every previous phase — identity, audience, voice, visual identity, logo, and content rules.

## Before You Start

Read the brand data from brand-reference.yml:

- `meta.brand_name`, `meta.tagline`, `meta.industry` — for platform suggestions and image content
- `identity.positioning` — to ground content pillars in brand positioning
- `audience.personas` — to match platforms to where personas spend time (their `channels` field)
- `voice.personality`, `voice.spectrum` — the base voice that platform adjustments modify
- `colors.primary`, `colors.secondary`, `colors.neutral` — for social image generation
- `visual.logo.primary_variant` — for profile picture recommendation
- `assets.logo` — to embed logo in social images
- `content.content_types` — to avoid duplicating content type definitions

Cross-reference audience personas' `channels` fields with platform selection. If personas list LinkedIn, Instagram, etc., those platforms should be suggested first.

## Interview Philosophy

Same rules as all previous phases:

- Ask **one question at a time**. Never present a wall of questions.
- **Offer examples** relevant to the user's industry and audience.
- If the user gives a **vague answer**, ask a focused follow-up.
- If the user says **"I don't know"**, suggest options based on their industry, audience channels, and competitors.
- Keep the tone conversational — social media strategy should feel practical, not academic.
- After each answer, briefly reflect back what you understood.

## Interview Flow

The interview has 7 stages. Each stage builds on the previous one.

### Stage 1: Platform Selection → `social.platforms[].name`, `.audience`

Start by understanding which platforms the brand uses or plans to use.

**Pre-analysis:** Before asking, check `audience.personas[].channels` for platform mentions. Use these to inform your suggestions.

**Question:**

"Let's define your social media presence. Based on your audience personas, it looks like your people spend time on [channels from personas]. Which platforms is [brand_name] active on — or planning to be active on?"

**Offer platform options based on industry:**

| Industry | Recommended platforms |
|----------|----------------------|
| B2B SaaS | LinkedIn, X/Twitter, YouTube |
| E-commerce | Instagram, TikTok, Pinterest, Facebook |
| Agency | LinkedIn, Instagram, X/Twitter, Behance/Dribbble |
| Education | YouTube, Instagram, LinkedIn, TikTok |
| Healthcare | LinkedIn, Facebook, YouTube |
| Fintech | LinkedIn, X/Twitter, YouTube |
| Consumer brand | Instagram, TikTok, Facebook, YouTube |

**Follow-ups:**

| Response | Follow-up |
|----------|-----------|
| Only 1 platform | "That's a good start. Is there a secondary platform you'd consider? Even a low-effort presence helps with SEO and discoverability." |
| More than 5 platforms | "That's ambitious. Let's prioritize — which 3-4 platforms drive the most value? Better to be great on a few than mediocre on many." |
| "All of them" | "Let's be strategic. Where does your primary persona ([persona name]) actually spend time? Start there." |
| "I don't know" | Suggest 2-3 based on their industry and personas' channel preferences |

For each selected platform, ask:

"What's the purpose of [brand_name] on [platform]? For example: lead generation, brand awareness, community building, customer support, thought leadership?"

This fills `platforms[].audience` (the audience/purpose for that specific platform).

### Stage 2: Platform Voice Adjustments → `social.platforms[].tone_adjustment`

For each platform, define how the brand voice shifts.

**Explain the concept:**

"Your brand voice stays consistent, but each platform has its own culture. Let's define how your voice adapts. I'll suggest adjustments based on your voice profile — you can refine them."

**Auto-generate suggestions from voice data:**

Read `voice.spectrum` (formality, humor, technicality, enthusiasm, authority levels) and `voice.personality` attributes. For each platform, propose a tone shift:

| Platform | Default adjustment | Spectrum shift |
|----------|-------------------|----------------|
| LinkedIn | More professional, thought-leadership | Formality +1, Authority +1 |
| X/Twitter | More concise, punchy, opinionated | Formality -1, Enthusiasm +1 |
| Instagram | More visual, casual, behind-the-scenes | Formality -1, Humor +1 |
| TikTok | More playful, trend-aware, authentic | Formality -2, Humor +2 |
| Facebook | More community-oriented, conversational | Formality -1 |
| YouTube | More educational, in-depth | Technicality +1, Authority +1 |
| Pinterest | More aspirational, visual-first | Minimal text, focus on imagery |

**Present as:**

"For LinkedIn, I'd suggest shifting your voice to be [adjustment]. Your base voice is [formality level] on formality — on LinkedIn, I'd take that up a notch. Does that sound right?"

Walk through each platform one at a time. Let the user modify each suggestion.

**Also ask for each platform:**

"What types of content will [brand_name] post on [platform]? For example: [suggest based on industry]."

→ fills `platforms[].post_types`

"How often do you plan to post on [platform]?"

→ fills `platforms[].frequency` (optional — skip if the user doesn't know)

### Stage 3: Content Pillars → `social.content_pillars`

Content pillars are recurring themes that anchor all social content.

**Question:**

"Content pillars are the 3-5 core topics or themes you'll consistently post about. They keep your content focused and recognizable. Based on your positioning and audience, here are some ideas:"

**Suggest based on identity and audience data:**

| Data source | Suggested pillar |
|-------------|------------------|
| `identity.mission` | Mission-aligned educational content |
| `identity.values[0]` | Values-driven stories or behind-the-scenes |
| `audience.personas[0].goals` | Content that helps the primary persona achieve their goals |
| `identity.positioning.differentiator` | Content that demonstrates your unique advantage |
| `meta.industry` | Industry news, trends, and commentary |

**Example pillars by industry:**

| Industry | Example pillars |
|----------|----------------|
| B2B SaaS | Product education, Industry insights, Customer success stories, Team culture, Thought leadership |
| E-commerce | Product showcases, Behind-the-scenes, User-generated content, Styling/how-to, Seasonal campaigns |
| Agency | Case studies, Process insights, Industry trends, Team spotlights, Client wins |

**Follow-ups:**

| Response | Follow-up |
|----------|-----------|
| Fewer than 3 | "Can you think of one more theme? Consider: educational content, behind-the-scenes, community stories, or industry commentary." |
| More than 5 | "Let's narrow to the top 3-5. Which themes would you never run out of content for?" |
| Too vague ("good content") | "What specific topic would that cover? For example, instead of 'helpful content', think 'step-by-step tutorials for [persona goal]'." |

For each pillar, capture:

- `name` — short label (2-4 words)
- `description` — what this pillar covers and why it matters
- `example_topics` — 2-3 concrete post ideas (helps the user visualize)

**Output:**

```yaml
social:
  content_pillars:
    - name: "[Pillar name]"
      description: "[What this pillar covers]"
      example_topics:
        - "[Topic 1]"
        - "[Topic 2]"
```

### Stage 4: Hashtag Strategy → `social.hashtag_strategy`

**Question:**

"Let's define your hashtag approach. Do you have any existing branded hashtags (like #YourBrandName or a campaign tag)?"

**Then ask:**

"For industry and community hashtags, which topics or communities should your posts be discoverable in?"

**Build the strategy:**

```yaml
social:
  hashtag_strategy:
    branded:
      - "#[BrandName]"
      - "#[CampaignTag]"  # if applicable
    industry:
      - "#[IndustryTerm1]"
      - "#[IndustryTerm2]"
    content_specific:
      - "#[PillarRelatedTag]"
      - "#[TopicTag]"
    per_platform:
      linkedin: "2-5 hashtags, industry-focused"
      instagram: "15-25 mixed (branded, niche, broad)"
      twitter: "0-2, only if trending or branded"
      tiktok: "3-5, trend-driven"
```

**Follow-ups:**

| Response | Follow-up |
|----------|-----------|
| "We don't use hashtags" | "That's fine for some platforms (like LinkedIn or Facebook). But on Instagram and TikTok, hashtags drive discoverability. Want me to suggest a minimal set for those?" |
| Too many branded tags | "Multiple branded hashtags can dilute recognition. I'd recommend one primary branded hashtag and one for specific campaigns." |
| "I don't know" | Suggest 2-3 industry hashtags based on `meta.industry` and `identity.positioning.category` |

### Stage 5: Visual Rules Per Platform → `social.visual_rules`

**Question:**

"Let's define how your brand looks on social media. First — which logo variant should be your profile picture across platforms?"

**Suggest based on logo data:**

Read `visual.logo.primary_variant` and `assets.logo` paths. Recommend:

- If brand icon exists → use `brand-icon.svg` (works best in small circular crops)
- If only full logo → use `logo-mark.svg` or suggest cropping

"I'd recommend using your [brand icon / logo mark] as the profile picture — it reads well at small sizes and in circular crops. Does that work?"

→ fills `visual_rules.profile_picture`

**Then for each platform:**

"For [platform], here are the key visual specs:"

| Platform | Profile pic | Cover/Banner | Post format |
|----------|------------|--------------|-------------|
| LinkedIn | 400x400 | 1584x396 | 1200x627 images, carousel PDFs |
| X/Twitter | 400x400 | 1500x500 | 1200x675 images |
| Instagram | 320x320 | N/A | 1080x1080 feed, 1080x1920 stories |
| Facebook | 170x170 | 820x312 | 1200x630 images |
| TikTok | 200x200 | N/A | 1080x1920 videos |
| YouTube | 800x800 | 2560x1440 | 1280x720 thumbnails |

"For post templates — should posts follow a consistent visual style (branded colors, logo watermark, specific layout), or be more freeform?"

→ fills `visual_rules.post_style`

"For stories and reels — any specific visual approach? For example: branded frames, text overlays in brand fonts, specific filter/color treatment?"

→ fills `visual_rules.story_style` (optional)

**Output:**

```yaml
social:
  visual_rules:
    profile_picture: "[logo variant reference]"
    post_style: "[description of post visual approach]"
    story_style: "[description of story/reel approach]"
    platform_specs:
      linkedin:
        cover: "1584x396"
        post: "1200x627"
      twitter:
        cover: "1500x500"
        post: "1200x675"
      instagram:
        feed: "1080x1080"
        story: "1080x1920"
```

### Stage 6: Social Media Image Generation

After visual rules are defined, generate default social sharing images. These are the images that appear when pages are shared on social platforms.

**Announce:**

"I'll now generate your default social sharing images — these appear when your website is shared on social platforms. They'll use your brand colors and logo."

**Generate 3 SVGs:**

#### 1. og-image.svg (1200x630) — Facebook, LinkedIn, general Open Graph

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 630" width="1200" height="630">
  <!-- Background: primary brand color -->
  <rect width="1200" height="630" fill="[colors.primary.hex]"/>
  <!-- Logo: centered, sized to ~40% of width -->
  <!-- [Embed logo SVG content or reference] -->
  <!-- Tagline: below logo, in neutral/white -->
  <text x="600" y="420" text-anchor="middle"
        font-family="[typography.heading.family], sans-serif"
        font-size="28" fill="[colors.neutral.lightest or #fff]">
    [meta.tagline]
  </text>
</svg>
```

#### 2. twitter-card.svg (1200x675) — X/Twitter summary_large_image

Same concept as OG image but at Twitter's dimensions (1200x675). Slightly taller, so adjust vertical centering.

#### 3. linkedin-banner.svg (1584x396) — LinkedIn company page banner

Wide and short — different layout:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1584 396" width="1584" height="396">
  <!-- Background: primary or secondary brand color -->
  <rect width="1584" height="396" fill="[colors.primary.hex]"/>
  <!-- Logo: left-aligned or centered, smaller scale -->
  <!-- Tagline: right of logo or below, in contrasting color -->
</svg>
```

**Design rules for all social images:**

- Use `colors.primary.hex` as background (or `colors.secondary.hex` if primary is too light)
- Ensure text contrast meets WCAG AA (check against background)
- Use `typography.heading.family` for any text
- Keep logo at ≤40% of canvas width to leave breathing room
- No complex graphics — these are defaults meant to be clean and recognizable
- Set both `viewBox` and explicit `width`/`height` attributes

**After generating, note:**

"These SVGs are your default social sharing images. To convert to PNG for upload, run an SVG-to-PNG conversion tool (like Inkscape CLI, sharp, or a browser-based renderer). The SVGs are at exact pixel dimensions so conversion is 1:1."

Save to:
- `assets/social/og-image.svg`
- `assets/social/twitter-card.svg`
- `assets/social/linkedin-banner.svg`

### Stage 7: Engagement Rules → `social.engagement`

**Question:**

"Finally, let's define how [brand_name] engages with people on social media. What's a reasonable response time for comments and DMs?"

**Suggest defaults:**

"Most brands aim for within 4 hours during business hours. For smaller teams, within 24 hours is acceptable. What works for your team?"

→ fills `engagement.response_time`

**Then ask:**

"How should [brand_name] sound when replying to comments? Should it match your main voice, or be more casual/personal?"

→ fills `engagement.tone_in_replies`

**Then ask:**

"How should negative feedback or complaints be handled? For example: respond publicly with empathy and move to DM, escalate to support, or something else?"

→ fills `engagement.escalation`

**Finally, define "never" rules:**

"Here are some standard social media 'never' rules. Which apply to [brand_name]?"

Present as a checklist:

- [ ] Never argue publicly with commenters
- [ ] Never delete negative comments (unless abusive or spam)
- [ ] Never use automated replies for complaints
- [ ] Never post without proofreading
- [ ] Never engage with competitor drama
- [ ] Never share unverified information

Let the user select which apply and add their own.

→ fills `engagement.never`

**Output:**

```yaml
social:
  engagement:
    response_time: "[target]"
    tone_in_replies: "[description]"
    escalation: "[protocol]"
    never:
      - "[rule 1]"
      - "[rule 2]"
```

## Writing the Output

### 1. brand-reference.yml — `social` section

After all stages are complete and approved, write the full social section:

```yaml
social:
  platforms:
    - name: "[Platform]"
      audience: "[purpose on this platform]"
      tone_adjustment: "[how voice shifts]"
      post_types:
        - "[type 1]"
        - "[type 2]"
      frequency: "[posting cadence]"
      hashtag_strategy: "[platform-specific hashtag approach]"
      visual_format: "[recommended dimensions]"
    - name: "[Platform 2]"
      # ...same structure
  content_pillars:
    - name: "[Pillar name]"
      description: "[what it covers]"
      example_topics:
        - "[topic 1]"
        - "[topic 2]"
  hashtag_strategy:
    branded:
      - "#[BrandName]"
    industry:
      - "#[Term1]"
    content_specific:
      - "#[Tag1]"
    per_platform:
      linkedin: "[approach]"
      instagram: "[approach]"
      twitter: "[approach]"
  visual_rules:
    profile_picture: "[logo variant]"
    post_style: "[description]"
    story_style: "[description]"
    platform_specs:
      # per-platform dimensions
  engagement:
    response_time: "[target]"
    tone_in_replies: "[description]"
    escalation: "[protocol]"
    never:
      - "[rule]"
```

### 2. SVG files in assets/social/

Write three SVG files:

- `assets/social/og-image.svg` — 1200x630, logo + tagline on brand background
- `assets/social/twitter-card.svg` — 1200x675, same concept adjusted for dimensions
- `assets/social/linkedin-banner.svg` — 1584x396, wide banner layout

### 3. Summary Before Writing

Before writing to disk, present the full summary for approval:

```
Here's the social media profile I captured:

Platforms:
  1. [Platform] — [purpose]
     Voice: [tone adjustment]
     Posts: [post types], [frequency]
  2. [Platform] — [purpose]
     Voice: [tone adjustment]
     Posts: [post types], [frequency]

Content Pillars:
  1. [Pillar] — [description]
  2. [Pillar] — [description]
  3. [Pillar] — [description]

Hashtag Strategy:
  Branded: [tags]
  Industry: [tags]
  Per platform: [summary]

Visual Rules:
  Profile picture: [variant]
  Post style: [description]

Engagement:
  Response time: [target]
  Reply tone: [description]
  Escalation: [protocol]
  Never: [count] rules defined

Social images to generate:
  - og-image.svg (1200x630)
  - twitter-card.svg (1200x675)
  - linkedin-banner.svg (1584x396)

Does this look right? I can adjust anything before we save.
```

Only write to disk after the user confirms.

## Checkpoint: data_validation + file_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `platforms_count` | `social.platforms` has ≥ 2 items, each with `name`, `audience`, `tone_adjustment` | Ask which additional platforms the brand uses |
| `content_pillars` | `social.content_pillars` has ≥ 3 items, each with `name` and `description` | Walk through pillar identification until ≥ 3 defined |
| `og_image_svg` | `assets/social/og-image.svg` exists with `viewBox="0 0 1200 630"` | Generate the OG image SVG |
| `twitter_card_svg` | `assets/social/twitter-card.svg` exists with `viewBox="0 0 1200 675"` | Generate the Twitter card SVG |
| `profile_picture_variant` | `social.visual_rules.profile_picture` references a valid logo variant | Ask which logo variant to use as profile picture |

**On pass:** Update `state.yml` → mark phase 8 complete, write recovery notes, advance to phase 9 (compile-and-export).

**On fail:** Fix the failing checks (ask targeted questions or generate missing files), re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Brand: [name] ([industry])
Active platforms: [comma-separated platform names]
Primary content pillars: [comma-separated pillar names]
Hashtag approach: [branded tag] + [count] industry tags
Profile picture: [logo variant used]
Social images generated: og-image.svg, twitter-card.svg, linkedin-banner.svg
Engagement: [response time target], [count] never-rules
```

These notes let a future session understand the social media strategy without re-reading the full brand-reference.yml.
