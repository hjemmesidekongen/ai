# Content Writer — Detailed Process

## NEVER List

These patterns destroy content quality. Kill them before delivering.

| Pattern | Why it fails | Fix |
|---------|-------------|-----|
| Opening with project description instead of value prop | Readers bounce in 3 seconds if they don't see what's in it for them | Lead with outcome, not definition |
| Stacking features without benefit bridges | "We have X, Y, Z" tells the reader nothing about value | Add "which means..." after every feature |
| Fabricating metrics or social proof | One caught lie destroys all credibility | Use [NEEDS DATA] placeholders — never invent |
| Cross-posting identical content across platforms | Platform-native audiences reject foreign formats | Adapt structure, length, and tone per platform |
| Writing "In today's world..." or "In an era of..." | Throat-clearing that signals AI-generated content | Start with the reader's problem or a specific fact |
| Using "we" for a solo practitioner | Sounds corporate and fake when it's one person | Match the brand — "I" for solo, "we" for teams |
| Generic CTAs ("Learn more", "Click here") | No urgency, no specificity, no reason to act | Describe what the user gets: "Start free trial", "See pricing" |
| Hedging with "might", "could", "perhaps" | Undermines confidence and brand authority | Make definite statements or cut the sentence |
| Keyword-stuffing for SEO | Reads badly, and search engines penalize it since 2020 | 0.5-1.5% density max, natural placement only |
| Bolding every other phrase | Visual noise that makes nothing stand out | Bold only the one thing per section the reader must not miss |

## Phase 1: Intake

Before generating any content, gather these inputs. Ask if not provided.

### Required Inputs

| Input | Question | Why |
|-------|----------|-----|
| Content type | README, landing page, blog post, social media, email, marketing copy? | Determines template and knowledge skills |
| Audience | Who reads this? Role, expertise level, what they care about | Shapes tone, complexity, and emphasis |
| Purpose | What should the reader do after reading? | Drives CTA and structure |
| Brand | Which brand to apply? (auto-detect if single brand exists) | Voice, vocabulary, constraints |
| Subject | What is this about? Product, feature, project, topic | Core material to work with |
| Fresh or rewrite? | Creating new content or improving existing? | Changes the workflow (see Rewrite section) |

### Optional Inputs

| Input | Default if missing |
|-------|-------------------|
| Tone override | Use brand voice.yml defaults |
| Length target | Content-type default (see templates) |
| SEO keywords | Derive from subject + audience |
| Existing content | Start fresh |
| Platform (social) | Ask — platform determines format |

### Audience Awareness Levels

| Level | Reader knows | Copy focus |
|-------|-------------|------------|
| Unaware | Nothing about the problem | Lead with the problem, build urgency |
| Problem-aware | Has the problem, no solution yet | Validate the pain, introduce solution category |
| Solution-aware | Knows solutions exist, comparing | Differentiate, prove claims, handle objections |
| Product-aware | Knows this product, hasn't acted | Reduce friction, add urgency, risk reversal |

## Phase 2: Load Context

### Voice Priority

When determining tone, follow this hierarchy strictly:

1. **User tone override** — if the user specifies "casual", "formal", "playful", etc., that wins
2. **Brand voice.yml** — loaded via brand-loader at L3
3. **Neutral professional default** — direct, clear, no personality

Quality gate Check 1 validates against whichever level is active. If the user overrides brand voice, Check 1 validates against the override, not voice.yml.

### Brand Loading

1. Invoke brand-loader at L3 (full) — load voice.yml + guideline.yml + dos-and-donts.md
2. If no brand exists, proceed with neutral professional voice and note the gap
3. Extract from voice.yml: personality archetype, formality level, vocabulary (preferred + never-use)
4. Extract from guideline.yml: tagline, positioning, audience, content pillars

### Knowledge Skill Activation

Load relevant knowledge skills based on content type:

```
README         → web-copywriting + seo-fundamentals
Landing page   → web-copywriting + seo-fundamentals + marketing-psychology-patterns
Blog post      → content-strategy-patterns + seo-fundamentals + brand-voice-implementation
Social media   → social-media-patterns + brand-voice-implementation
Email          → content-strategy-patterns + brand-voice-implementation
Marketing copy → web-copywriting + marketing-psychology-patterns + brand-voice-implementation
```

Load only what the content type requires. Never load all skills at once.

## Phase 3: Draft Generation

### README Template

**Target length**: 40-80 lines.

```
# {Project Name}

{One-sentence description: what it does + who it's for}

## What's Included / What It Does
{Feature table or bullet list — benefit-first, not feature-first}
{Use benefit bridge: Feature → "which means" → Outcome}

## Quick Start
{Fastest path to "it works" — 3 steps or fewer}
{Code blocks with copy-paste commands}

## Requirements
{Only hard dependencies — skip obvious ones}

## Documentation
{Links to deeper guides if they exist}

## License
{One line}
```

README rules:
- Lead with what the reader gets, not what the project is
- Show, don't tell — code examples over descriptions
- Every feature listed must pass the "so what?" test
- No version badges or shields unless the project has CI
- No "Table of Contents" for READMEs under 100 lines

#### README Example: Before/After

**Before (typical AI-generated):**
> ## About
> This project is a comprehensive solution that leverages cutting-edge technology to streamline your workflow. It provides robust functionality for managing tasks efficiently.

**After (quality-gated):**
> ## What It Does
> Plan work in dependency-ordered waves, then execute with verification at each step. Built for teams that ship iteratively.

What changed: removed "about" (tells nothing), killed "comprehensive/leverages/cutting-edge/robust/streamline" (AI puffery), replaced with specific outcome + audience.

### Landing Page Template

**Target length**: varies by section count.

```
## Above the Fold
Headline: {Outcome-focused, specific, under 10 words}
Subheadline: {Adds clarity in 1-2 sentences}
Primary CTA: {Action verb describing what user gets}
Social proof: {One line — number of users, notable logos, or key metric}

## Problem
{2-3 sentences articulating the reader's frustration}
{Use the reader's own language — "you" not "users"}

## Solution
{3-5 benefits, each with Feature → Benefit → Outcome bridge}
{One benefit per section, visual breaks between them}

## How It Works
{3-4 numbered steps, dead simple}

## Social Proof
{Testimonials with name + role, or case study snippets}
{Specific numbers over vague praise}

## Objection Handling
{FAQ format, 3-5 common concerns}
{Each answer ends by reinforcing a benefit}

## Final CTA
{Repeat primary CTA with risk reduction}
```

Landing page rules:
- One primary CTA per page, repeated after each major section
- Never stack features without narrative flow
- Every claim must be specific — "2,847 teams" not "many customers"
- Objection handling goes BEFORE the final CTA, not after

#### Landing Page Example: Before/After

**Before (feature dump):**
> Features: AI-powered analytics, real-time collaboration, one-click deploy, custom dashboards, API access, SSO integration.

**After (benefit-driven):**
> **Ship faster.** One-click deploy skips the DevOps setup — your team ships features instead of configuring servers.
>
> **Stay in sync.** See changes as your team makes them. No more version conflicts or lost work.
>
> **Know what's working.** AI surfaces insights you'd miss manually, so you make better decisions in half the time.

What changed: feature list became benefit sections, each with Feature → Benefit → Outcome. Reader understands value, not capabilities.

### Blog Post Template

**Target length**: 800-1500 words.

```
## Title
{SEO keyword + benefit or curiosity hook, under 60 characters}

## Meta Description
{150-160 characters, includes primary keyword, ends with implicit CTA}

## Opening (Hook)
{2-3 sentences — start with the reader's problem or a surprising fact}

## Body Sections (3-5)
{H2 for each major point}
{Each section: claim → evidence → implication}

## Conclusion
{Key takeaway in 2-3 sentences, specific next step or CTA}
```

Blog post rules:
- Keyword in title, first paragraph, one H2, and meta description
- No keyword stuffing — 0.5-1.5% density maximum
- Internal links: 2-3 per post to related content
- One idea per paragraph, 2-4 sentences maximum

### Social Media Templates

**LinkedIn** (1200-1500 characters):
```
{Hook line — curiosity, story, value, or contrarian}

{3-5 short paragraphs developing the point}
{Line breaks between every paragraph}
{Personal perspective: "I" not "we"}

{Takeaway or question for engagement}

{Hashtags: 3-5, relevant}
```

**Twitter/X** (under 280 characters):
```
{Hook: under 100 characters}
{Core point: one sentence}
{CTA or question}
```

**Instagram** (caption, 150-300 words):
```
{Hook in first line — this shows in preview}
{Story or value in 2-3 short paragraphs}
{CTA: question, save prompt, or link reference}
{Hashtags: 15-25, mix of broad and niche}
```

Social media rules:
- Hook must work in the first line (preview text)
- Platform-native format — never cross-post identical content
- Personal voice: "I" for personal brands, brand voice for companies
- One post, one idea — never combine multiple points

### Email/Newsletter Template

**Target length**: 200-500 words for newsletters, 100-200 for campaigns.

```
## Subject Line
{Under 50 characters, specific, creates curiosity or states value}
{Preview text: first 90 characters of body — make them count}

## Opening
{1-2 sentences: why this email, why now}
{Personal — reference a shared context or recent event}

## Body
{One main point per email — never combine topics}
{Short paragraphs, scannable structure}
{Link to full content if the email is a teaser}

## CTA
{Single action — reply, click, read, try}
{Make the ask specific and low-friction}

## Sign-off
{Personal, brief, matches brand voice}
```

Email rules:
- One topic per email, one CTA per email
- Subject line is 80% of whether the email gets read
- Preview text (first line) must reinforce the subject, not repeat it
- No "Dear valued customer" — use the recipient's name or skip the salutation

### Marketing Copy Template

```
## Headline
{Single most important benefit, outcome-focused}

## Subheadline
{Clarifies the headline, adds specificity}

## Body Copy
{Problem → Solution → Proof → CTA flow}
{Each paragraph: one benefit with evidence}

## CTA
{Action verb + what user gets}
{Risk reduction nearby: guarantee, trial, no commitment}
```

Marketing copy rules:
- Feature → Benefit → Outcome bridge for every claim
- Customer language over company language
- Proof before ask — social proof and evidence precede the CTA
- No superlatives without substantiation

## Phase 4: Quality Gate

Run these checks sequentially on the completed draft.

### Check 1: Voice Compliance

Validate against the active voice source (user override > brand voice.yml > neutral default):
- Formality level matches the target scale
- Personality comes through (Guide, Friend, Expert, etc.)
- Never-use vocabulary is absent
- Preferred vocabulary is present where natural
- Platform adaptations match (social vs documentation vs marketing)

If the user provided a tone override, validate against the override. Do NOT reject a casual draft because voice.yml says "formal" when the user explicitly asked for casual.

Fail action: rewrite non-compliant sections using the active voice patterns.

### Check 2: AI Pattern Sweep

Apply writing-clearly-and-concisely rules:
- No puffery (pivotal, crucial, vital, testament, enduring legacy)
- No empty -ing phrases (ensuring reliability, showcasing features)
- No promotional adjectives (groundbreaking, seamless, robust, cutting-edge)
- No overused AI vocabulary (delve, leverage, multifaceted, foster, realm)
- No hedge phrases (it's important to note, it's worth mentioning)
- No em dash overuse
- Active voice throughout
- One idea per sentence, front-load important information

Fail action: rewrite every flagged phrase. No exceptions.

### Check 3: Structural Compliance

Verify the draft follows the template for its content type:
- All required sections present
- Section order matches template
- Length within target range
- CTAs positioned correctly
- Headers follow hierarchy (H1 → H2 → H3, no skips)
- Feature → Benefit → Outcome bridge present where features are mentioned

Fail action: restructure to match template, adding missing sections.

### Check 4: Claims Audit

Scan every factual claim:
- Statistics must have a source or be marked [NEEDS DATA]
- Testimonials must be attributed or marked [PLACEHOLDER]
- Comparisons must be specific and defensible
- No unearned superlatives ("best", "leading", "#1")

Fail action: mark unverified claims with brackets, note for user review.

### Check 5: Scannability

Verify the content is easy to skim:
- Paragraphs are 2-4 sentences maximum
- Headings appear every 3-4 paragraphs (no wall-of-text sections)
- Bullet lists or tables used for 3+ related items
- Key information front-loaded in each paragraph
- No dense blocks of text without visual breaks

Fail action: break long paragraphs, add subheadings, convert dense lists to tables.

## Phase 5: Deliver

Present the draft to the user with:
1. The finished content (formatted for its target platform)
2. A brief summary of voice decisions made
3. Any [NEEDS DATA] or [PLACEHOLDER] markers that need user input
4. Revision notes: what changed during quality gates
5. Suggested next steps (publish, review, iterate)

If the user requests revisions, loop back to Phase 3 with the feedback.

## Content Type Selection Guide

When the content type is ambiguous:

```
Is this about a codebase or technical project?  → README
Is this meant to convert visitors?              → Landing page
Is this educational or thought-leadership?      → Blog post
Is this for a specific social platform?         → Social media (ask which)
Is this an email or newsletter?                 → Email
Is this promoting a product or service?         → Marketing copy
None of the above?                              → Ask the user
```

## Integration Notes

### Brand Loading Fallback

If no brand exists at `.ai/brand/`:
- Use neutral professional voice
- Skip voice compliance check
- Note in delivery: "No brand loaded — voice is neutral. Run /våbenskjold:brand-create to establish brand guidelines."

### Existing Content Rewrite

When rewriting existing content (not creating fresh):
1. Read the existing content first
2. Ask the user: what's wrong with the current version?
3. Identify what to preserve (structure? tone? specific sections?)
4. Draft the rewrite applying the same templates and quality gates
5. Present a diff summary alongside the new version showing what changed and why
