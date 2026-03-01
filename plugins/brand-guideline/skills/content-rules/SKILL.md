---
name: content-rules
description: >
  Defines writing standards, content type specifications, SEO guidelines, legal
  requirements, and a content review checklist. Builds on the brand's identity,
  audience personas, and tone of voice to produce actionable rules for all brand
  content. Writes the content section to brand-reference.yml.
phase: 7
depends_on: [identity-interview, audience-personas, tone-of-voice]
writes:
  - "brand-reference.yml#content"
reads:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
  - "brand-reference.yml#audience"
  - "brand-reference.yml#voice"
checkpoint:
  type: data_validation
  required_checks:
    - name: "spelling_convention"
      verify: "content.grammar.spelling is a non-empty string (e.g. 'American English')"
      fail_action: "Ask the user which English spelling convention the brand uses"
    - name: "content_types_count"
      verify: "content.content_types has at least 3 items, each with type and at least one of length, tone_adjustment, or structure"
      fail_action: "Walk through additional content types relevant to the user's industry"
    - name: "readability_target"
      verify: "content.review_checklist.readability_target is defined with grade_level and tool"
      fail_action: "Ask the user what reading level their audience expects"
    - name: "seo_guidelines"
      verify: "content.seo has at least meta_description and heading_hierarchy defined"
      fail_action: "Walk through basic SEO writing rules with the user"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Content Rules

Phase 7 of brand generation. This skill translates the brand's voice (Phase 3), audience (Phase 2), and identity (Phase 1) into concrete, enforceable writing rules. The output governs every piece of content the brand produces — from blog posts to error messages, social captions to legal disclaimers.

## Before You Start

Read the brand's existing data from brand-reference.yml:

- `meta.brand_name` and `meta.industry` — to ground suggestions in the right domain
- `identity.values` — values influence what the brand says and avoids
- `identity.positioning` — positioning shapes messaging hierarchy and CTA language
- `audience.personas` — personas determine reading level, jargon tolerance, and content preferences
- `voice.personality` — personality attributes define the "how" of writing
- `voice.spectrum` — formality/humor/technicality levels constrain style choices
- `voice.vocabulary` — preferred/avoided words carry forward into content rules

Reference this data throughout the interview. For example: "Your voice is [formality level] and your primary persona is [persona name] — that suggests [recommendation]."

## Interview Philosophy

Same rules as previous phases:

- Ask **one question at a time**. Never present a wall of questions.
- **Offer sensible defaults** based on the brand's industry and voice profile.
- If the user gives a **vague answer**, propose a concrete rule and ask them to confirm or adjust.
- If the user says **"I don't know"**, recommend the industry standard and move on.
- Keep the tone practical — these are rules that writers will follow daily, so they need to be clear and specific.
- After each answer, briefly reflect back the rule you captured.

## Interview Flow

The interview has 6 stages. Each builds on previous answers.

### Stage 1: Writing Standards → `content.grammar`

Start with the mechanical rules that apply to all content.

**Question 1 — Spelling convention:**

"What English spelling convention does your brand use? American English, British English, or another regional variant?"

- If they're unsure, recommend based on primary market: "Your primary audience is [market]. American English is standard for US-focused brands."

→ fills `grammar.spelling`

**Question 2 — Date format:**

"How should dates be written? For example:"

| Format | Example |
|--------|---------|
| Month DD, YYYY | March 15, 2026 |
| DD Month YYYY | 15 March 2026 |
| MM/DD/YYYY | 03/15/2026 |
| YYYY-MM-DD | 2026-03-15 (ISO) |

- Default recommendation: "Month DD, YYYY" for American English, "DD Month YYYY" for British English.

→ fills `grammar.date_format`

**Question 3 — Number format:**

"How should numbers be written in body text?"

Offer the standard rule as a default: "Spell out one through nine, use numerals for 10 and above. Always use numerals for percentages, measurements, and prices."

- Follow-up if relevant: "What about large numbers? For example: 1,000 vs 1.000 (European)?"

→ fills `grammar.numbers`

**Question 4 — Currency format:**

"What's the primary currency, and how should it appear? For example: $99, USD 99, 99 USD, or €99?"

→ fills `grammar.currency_format`

**Question 5 — Capitalization:**

"What capitalization style do you prefer for headings and titles?"

| Style | Example |
|-------|---------|
| Title Case | "How to Write Better Content" |
| Sentence case | "How to write better content" |

- Default recommendation based on voice: formal voices tend toward Title Case; conversational voices toward sentence case.

→ fills `grammar.capitalization`

**Question 6 — Oxford comma:**

"Do you use the Oxford comma (the comma before 'and' in a list)? For example: 'red, white, and blue' vs 'red, white and blue'."

- Default: yes (reduces ambiguity).

→ fills `grammar.oxford_comma`

**Question 7 — Abbreviations and acronyms:**

"What's your policy on abbreviations and acronyms? The standard rule is: spell out on first use with the abbreviation in parentheses, then use the abbreviation. For example: 'Search Engine Optimization (SEO)'. Does that work for your brand?"

- Follow-up: "Are there any terms your audience already knows that don't need to be spelled out? For example, in tech: API, URL, HTML."

→ fills `grammar.abbreviation_policy`

**Output after Stage 1:**

```yaml
content:
  grammar:
    spelling: "[American English / British English / etc.]"
    date_format: "[format]"
    numbers: "[rule]"
    currency_format: "[format]"
    capitalization: "[Title Case / Sentence case]"
    oxford_comma: true  # or false
    abbreviation_policy: "[rule]"
```

### Stage 2: Dos and Don'ts → `content.dos`, `content.donts`

Build on the voice personality attributes to create concrete writing rules.

**Question:**

"Based on your brand voice, I've drafted some writing dos and don'ts. Let me walk through them — tell me what to keep, change, or add."

**Generate initial suggestions from voice data:**

Use `voice.personality` and `voice.spectrum` to draft rules. For example:

- If formality is low (1-4): add "Use contractions (you're, we'll, it's)" to dos
- If formality is high (7-10): add "Avoid contractions in formal content" to dos
- If humor is high: add "Use wit when appropriate — but never at the customer's expense" to dos
- If technicality is low: add "Explain technical terms in plain language" to dos
- From `voice.vocabulary.avoid`: convert to don'ts ("Don't use '[word]'")

**Present 4-6 dos, then 4-6 don'ts:**

```
Here are the writing dos I'd suggest:

1. Use active voice
2. Lead with benefits, not features
3. Use 'you' to address the reader directly
4. Keep sentences under 20 words when possible
5. [Generated from voice data]
6. [Generated from voice data]

Which of these work? Anything to add or remove?
```

Then repeat for don'ts.

**Follow-up triggers:**

| Response | Follow-up |
|----------|-----------|
| Accepts all | "Great. Are there any brand-specific rules I'm missing? For example, words you always capitalize, topics to avoid?" |
| Removes items | "Got it, I'll drop those. Any replacements?" |
| Adds items | "Good additions. Let me make sure they're specific enough: [rephrase if vague]" |

→ fills `dos` and `donts`

### Stage 3: Terminology → `content.terminology`

**Question:**

"Are there specific terms your brand always uses — or always avoids? This is about consistency: making sure everyone says the same thing."

**Offer examples based on industry:**

| Industry | Example preferred terms |
|----------|----------------------|
| SaaS | "workspace" not "account", "team members" not "users" |
| E-commerce | "order" not "purchase", "shoppers" not "consumers" |
| Healthcare | "patients" not "clients", "care team" not "staff" |
| Finance | "investors" not "traders", "portfolio" not "account" |
| Agency | "partners" not "clients", "projects" not "jobs" |

**For each term the user provides, capture:**

1. The preferred term
2. What to use instead of (the avoided term)
3. Context (when does this apply?)

**Follow-up:**

"Are there any industry-specific terms your audience uses that we should define? These go in a glossary so everyone uses them consistently."

→ fills `terminology.preferred` and `terminology.industry_terms`

**Output:**

```yaml
  terminology:
    preferred:
      - term: "[preferred]"
        not: "[avoid these]"
        context: "[when to use]"
    industry_terms:
      - term: "[term]"
        definition: "[what it means for this brand]"
```

### Stage 4: Content Types → `content.content_types`

**Question:**

"Let's define rules for the types of content your brand produces. I'll suggest some based on your industry — tell me which ones apply and we'll set guidelines for each."

**Suggest content types based on industry and channels:**

Use `audience.personas[].channels` and `audience.personas[].content_preferences` to prioritize.

| Content type | When to suggest |
|--------------|----------------|
| Blog post | Almost always |
| Email marketing | If email is a channel |
| Social media | If any social platform is a channel |
| Product / UI copy | If SaaS, e-commerce, or app-based |
| Case study | If B2B |
| Newsletter | If email is a channel |
| Landing page | Almost always |
| Error messages / microcopy | If SaaS or app-based |
| Help / documentation | If technical product |
| Video scripts | If YouTube/TikTok is a channel |

**For each content type the user selects, ask:**

1. **Length:** "How long should a typical [type] be?" (Offer a range, e.g., "800-1500 words for blog posts is standard.")
2. **Tone adjustment:** "Should the tone shift for [type]? For example, blog posts are often slightly more casual than product pages."
3. **Structure:** "What structure works best? For blog posts, a common pattern is: Hook → Problem → Solution → CTA."

→ fills `content_types[]`

**After capturing 3+ types, reflect back:**

```
Here are the content type rules:

Blog post — 800-1500 words, slightly casual, Hook → Problem → Solution → CTA
Email — 150-300 words, direct and action-oriented, Subject → Key message → CTA
Product copy — As short as possible, functional and clear, Action-oriented verbs

Does this capture the key formats? Any others to add?
```

**Output:**

```yaml
  content_types:
    - type: "Blog post"
      length: "800-1500 words"
      tone_adjustment: "Slightly more casual, educational"
      structure: "Hook → Problem → Solution → CTA"
    - type: "Email marketing"
      length: "150-300 words"
      tone_adjustment: "Direct, action-oriented"
      structure: "Subject → One key message → CTA"
    - type: "Social media"
      length: "Varies by platform"
      tone_adjustment: "Most casual, conversational"
      structure: "Hook → Value → CTA or question"
    - type: "Product / UI copy"
      length: "As short as possible"
      tone_adjustment: "Functional, clear, no personality at cost of clarity"
      structure: "Action-oriented, verb-first"
```

### Stage 5: SEO Writing Guidelines → `content.seo`

**Question:**

"Does your brand publish content online that needs to rank in search engines? If yes, let's set some SEO writing guidelines."

If the user says no or the brand doesn't produce web content, skip this stage and set `content.seo` to null.

**If yes, walk through:**

**5a — Meta descriptions:**

"Meta descriptions appear in search results. The standard rule is: 150-160 characters, include the primary keyword, end with a clear value proposition or CTA. Does that work?"

→ fills `seo.meta_description`

**5b — Heading hierarchy:**

"Headings should follow a logical hierarchy: one H1 per page (the title), H2s for major sections, H3s for subsections. Never skip levels (H1 → H3). Sound right?"

→ fills `seo.heading_hierarchy`

**5c — Keyword approach:**

"How should writers handle keywords? The modern approach is: write naturally first, then ensure the primary keyword appears in the title, first paragraph, and 1-2 subheadings. Avoid stuffing. Does your brand follow this, or do you have a different approach?"

→ fills `seo.keyword_approach`

**5d — Internal linking:**

"Should writers link to related content within articles? A common rule is: 2-5 internal links per 1000 words, linking to relevant pages. Any preference?"

→ fills `seo.internal_linking`

**Output:**

```yaml
  seo:
    meta_description:
      max_length: 160
      rules: "[captured rules]"
    heading_hierarchy: "[captured rules]"
    keyword_approach: "[captured rules]"
    internal_linking: "[captured rules]"
```

### Stage 6: Legal, Compliance & Review Checklist → `content.legal`, `content.review_checklist`

**6a — Legal and compliance:**

"Are there any legal requirements for your brand's content? For example:"

- Required disclaimers (financial advice, medical information, affiliate disclosures)
- Trademark usage (when to use ® vs ™)
- Copyright notice format
- Industry-specific regulations (HIPAA, GDPR language, FTC guidelines)

**Industry-aware suggestions:**

| Industry | Common requirements |
|----------|-------------------|
| Finance/Fintech | "Past performance is not indicative of future results" disclaimer |
| Healthcare | "Not medical advice" disclaimer, HIPAA considerations |
| E-commerce | FTC affiliate disclosure, return policy visibility |
| SaaS | Terms of service references, data processing disclosures |
| Any | Copyright notice format: "© [Year] [Brand Name]. All rights reserved." |

**Trademark rules:**

"How should your brand name appear in content? Standard rules:"

- Use ® after the brand name on first use per page (if registered trademark)
- Use ™ if trademark is pending
- Never use the brand name as a verb or adjective alone
- Always capitalize the brand name consistently

→ fills `legal`

**6b — Content review checklist:**

"Finally, let's define a review checklist that every piece of content should pass before publishing."

**Walk through each check:**

1. **Readability target:**
   "What reading level should your content target? This is measured by Flesch-Kincaid grade level."

   | Grade level | Audience | Example |
   |-------------|----------|---------|
   | 6-8 | General public, B2C | Most consumer brands |
   | 8-10 | Educated professionals | B2B, professional services |
   | 10-12 | Technical/academic | Developer tools, research |

   "Based on your audience ([primary persona name], [role]), I'd recommend grade [N]. Does that feel right?"

   → fills `review_checklist.readability_target`

2. **Voice alignment check:**
   "Should reviewers check content against the brand voice spectrum and personality attributes?"
   - Default: yes. Reference `voice.personality` and `voice.spectrum`.

   → fills `review_checklist.voice_alignment`

3. **Accessibility check:**
   "Should content pass accessibility checks? Standard rules: all images have alt text, headings follow hierarchy, links have descriptive text (not 'click here'), sufficient color contrast for text."
   - Default: yes.

   → fills `review_checklist.accessibility`

**Output:**

```yaml
  legal:
    disclaimers:
      - "[Required disclaimer text, if any]"
    trademark_usage: "[Rules for brand name usage]"
    copyright_format: "© [Year] [Brand Name]. All rights reserved."
  review_checklist:
    readability_target:
      grade_level: "[N]"
      tool: "Flesch-Kincaid"
    voice_alignment: true
    accessibility:
      alt_text: true
      heading_hierarchy: true
      descriptive_links: true
```

## Writing the Output

After completing all stages, present the full summary for approval:

```
Here are the content rules I captured:

Writing Standards:
  Spelling: [spelling]
  Date format: [format]
  Numbers: [rule]
  Currency: [format]
  Capitalization: [style]
  Oxford comma: [yes/no]
  Abbreviations: [policy]

Dos:
  1. [do]
  2. [do]
  ...

Don'ts:
  1. [don't]
  2. [don't]
  ...

Terminology:
  [term] → use instead of [avoided]
  ...

Content Types:
  [type] — [length], [tone], [structure]
  ...

SEO Guidelines:
  Meta descriptions: [rules]
  Headings: [rules]
  Keywords: [approach]
  Internal linking: [rules]

Legal:
  Disclaimers: [list or "none"]
  Trademark: [rules]
  Copyright: [format]

Review Checklist:
  Readability: Grade [N] (Flesch-Kincaid)
  Voice alignment: [yes/no]
  Accessibility: [yes/no]

Does this look right? I can adjust anything before we save.
```

Only write to disk after the user confirms.

### YAML Output Structure

Write the complete `content` section to `brand-reference.yml`:

```yaml
content:
  dos:
    - "[rule]"
    - "[rule]"
  donts:
    - "[rule]"
    - "[rule]"
  terminology:
    preferred:
      - term: "[preferred]"
        not: "[avoided]"
        context: "[when]"
    industry_terms:
      - term: "[term]"
        definition: "[definition]"
  grammar:
    spelling: "[convention]"
    date_format: "[format]"
    numbers: "[rule]"
    currency_format: "[format]"
    capitalization: "[style]"
    oxford_comma: true
    abbreviation_policy: "[rule]"
  content_types:
    - type: "[type name]"
      length: "[range]"
      tone_adjustment: "[how tone shifts]"
      structure: "[pattern]"
  seo:
    meta_description:
      max_length: 160
      rules: "[rules]"
    heading_hierarchy: "[rules]"
    keyword_approach: "[rules]"
    internal_linking: "[rules]"
  legal:
    disclaimers:
      - "[text]"
    trademark_usage: "[rules]"
    copyright_format: "© [Year] [Brand Name]. All rights reserved."
  review_checklist:
    readability_target:
      grade_level: "[N]"
      tool: "Flesch-Kincaid"
    voice_alignment: true
    accessibility:
      alt_text: true
      heading_hierarchy: true
      descriptive_links: true
```

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `spelling_convention` | `content.grammar.spelling` is non-empty | Ask the user which English spelling convention the brand uses |
| `content_types_count` | `content.content_types` has ≥ 3 items, each with `type` and at least one of `length`, `tone_adjustment`, or `structure` | Walk through additional content types relevant to the user's industry |
| `readability_target` | `content.review_checklist.readability_target` has `grade_level` and `tool` | Ask the user what reading level their audience expects |
| `seo_guidelines` | `content.seo` has at least `meta_description` and `heading_hierarchy` defined (or is explicitly null if no web content) | Walk through basic SEO writing rules with the user |

**On pass:** Update `state.yml` → mark phase 7 complete, write recovery notes, advance to phase 8 (social-media).

**On fail:** Fix the failing checks (ask targeted questions), re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Brand: [name] ([industry])
Spelling: [convention]
Capitalization: [style]
Oxford comma: [yes/no]
Content types: [comma-separated type names]
Readability target: Grade [N]
SEO: [yes/no]
Legal disclaimers: [count or "none"]
Key dos: [top 3]
Key don'ts: [top 3]
```

These notes let a future session understand the content rules context without re-reading the full brand-reference.yml.
