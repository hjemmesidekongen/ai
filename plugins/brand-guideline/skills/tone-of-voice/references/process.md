# Tone of Voice — Detailed Process

This skill runs as Phase 3 of brand generation. It reads identity and audience data from Phases 1
and 2 and conducts a conversational interview to define the brand's complete voice framework.
Output is the `voice` section of `brand-reference.yml`, covering spectrum, personality, messaging,
and writing samples. Channel variations and vocabulary data are also captured in recovery_notes for
use by content-rules (Phase 7) and social-media (Phase 8).

---

## Pre-Interview: Load Brainstorm Decisions

Before starting the interview, call the decision-reader skill to check if the
user already made relevant decisions during a brainstorm session:

- **Project:** the brand name being generated
- **Domains:** `brand-voice`

If decisions are found, adjust the interview flow:

| Confidence | Behavior |
|------------|----------|
| **High** | Pre-fill voice direction and show for quick confirmation: "From your brainstorm: [decision]. Still good? [Y/n]" — if confirmed, use the decision as the answer |
| **Medium** | Present as starting point: "You were leaning toward: [decision]. Go with this, or explore further?" — if accepted, use it; otherwise ask normally with the decision as context |
| **Low** | Mention as context when asking the question: "You mentioned [decision] during brainstorming. Let's discuss..." — then proceed with the normal question |
| **Not found** | Ask normally — this is the default behavior without brainstorming |

Voice decisions may pre-fill tone direction, formality level, personality
attributes, or vocabulary preferences. Use the decision-reader's
`check_decision` method before each question to find matching decisions.

At the end, note which decisions were applied in state.yml:

```yaml
decisions_applied: [d2, d7]
```

---

## Findings Persistence

During the interview, write intermediate voice decisions to the findings file:

```
.ai/brands/[brand-name]/findings.md
```

**What to save:** Spectrum positions with user reasoning, personality attribute choices, channel variation decisions, vocabulary preferences, and messaging drafts.

**2-Action Rule:** After every 2 research operations (user question answered, web search, file read), IMMEDIATELY save key findings to findings.md before continuing.

**Format:**

```markdown
## Tone of Voice Findings

### Spectrum Decisions
- Formality: [N] — [user's reasoning]
- Humor: [N] — [user's reasoning]
- Enthusiasm: [N] — [user's reasoning]
- Technicality: [N] — [user's reasoning]
- Archetype: [name]

### Personality Attributes
- [attribute], not [not] — [user's explanation]

### Channel Variations
- Website: [user's preference]
- Social: [user's preference]
- Email: [user's preference]

### Vocabulary
- Preferred words: [list with reasons]
- Banned words: [list with reasons]
- Jargon policy: [decision]
```

Also read findings.md for context from previous phases (identity-interview, audience-personas) — this data informs voice suggestions.

---

## Before You Start

Read the brand's existing data from brand-reference.yml:

- `meta.brand_name` and `meta.industry` — to ground voice suggestions in the right domain
- `identity.values` — values directly shape voice (a brand that values "transparency" speaks differently than one that values "exclusivity")
- `identity.positioning` — the differentiator and target audience influence tone
- `identity.mission` and `identity.vision` — reveal the brand's aspiration and energy level
- `audience.personas` — the primary persona's channels, goals, and frustrations determine what voice will resonate

Reference this data throughout the interview. Connect voice decisions back to identity and audience:

> "Your brand values transparency and simplicity, and your primary persona is a busy startup founder. That suggests a voice that's direct and jargon-free. Let's explore where exactly on the spectrum you land."

---

## Interview Philosophy

Same rules as previous phases:

- Ask **one question at a time**. Never present a wall of questions.
- **Offer examples** relevant to the user's industry and audience.
- If the user gives a **vague answer**, ask a focused follow-up.
- If the user says **"I don't know"**, suggest options based on their identity and audience data. Let them pick or adapt.
- Keep the tone conversational — this is about finding the brand's authentic voice, not filling in blanks.
- After each answer, briefly reflect back what you understood.

---

## Interview Flow

The interview has 6 stages. Each stage builds on the previous one.

### Stage 1: Voice Spectrum → `voice.spectrum`

Start by establishing the brand's tone on 4 dimensions. Present one dimension at a time.

**Introduction:**

"Now let's figure out how your brand actually *sounds*. I'll give you four scales — each one is a spectrum from 1 to 10. Place your brand where it feels right. There are no wrong answers."

**Dimensions (present one at a time):**

1. **Formality** (1 = very casual, 10 = very formal)

   "First: how formal is your brand? A 1 would be texting a friend. A 10 would be a legal document. Most brands land somewhere in between."

   **Industry anchors to offer:**

   | Position | Examples |
   |----------|----------|
   | 1-3 (casual) | Slack, Mailchimp, Innocent Drinks |
   | 4-6 (balanced) | Stripe, Notion, Airbnb |
   | 7-10 (formal) | McKinsey, Goldman Sachs, IBM |

2. **Humor** (1 = never, 10 = always)

   "How much humor does your brand use? A 1 means strictly serious — no jokes ever. A 10 means humor is core to your identity."

   | Position | Examples |
   |----------|----------|
   | 1-3 (serious) | Deloitte, Mayo Clinic, Bloomberg |
   | 4-6 (occasional) | Apple, Basecamp, Airtable |
   | 7-10 (playful) | Old Spice, Wendy's, Cards Against Humanity |

3. **Enthusiasm** (1 = reserved, 10 = excitable)

   "How energetic is your brand? A 1 is calm and measured. A 10 is high-energy, exclamation marks, let's-go vibes."

   | Position | Examples |
   |----------|----------|
   | 1-3 (reserved) | Muji, Aesop, The Economist |
   | 4-6 (warm) | Shopify, Figma, Patagonia |
   | 7-10 (excitable) | Duolingo, Red Bull, Nike |

4. **Technicality** (1 = layperson, 10 = expert-only)

   "How technical is your language? A 1 means anyone can understand it. A 10 means you speak to experts and don't simplify."

   | Position | Examples |
   |----------|----------|
   | 1-3 (simple) | Apple, IKEA, Headspace |
   | 4-6 (balanced) | Stripe, Linear, Vercel |
   | 7-10 (technical) | Datadog, Cloudflare, arXiv |

**Follow-up triggers:**

| Response | Follow-up |
|----------|-----------|
| User gives a range ("3-5") | "If you had to pick one number, what feels most true? You can always adjust later." |
| User picks extreme (1 or 10) | "That's a strong position. Can you give me an example of how that shows up in practice?" |
| User is unsure | Suggest a position based on their identity values and primary persona, then ask: "Does that feel right?" |

**After all 4 dimensions**, reflect back the profile:

```
Here's your voice spectrum:

Formality:    [N]/10 — [casual/balanced/formal]
Humor:        [N]/10 — [serious/occasional/playful]
Enthusiasm:   [N]/10 — [reserved/warm/excitable]
Technicality: [N]/10 — [simple/balanced/technical]

This puts you in the "[archetype]" zone — think brands like [2-3 similar brands].
Does this feel like your brand?
```

**Archetypes (for the reflection):**

| Profile pattern | Archetype | Brand examples |
|-----------------|-----------|----------------|
| Low formality, high humor, high enthusiasm | "The Friend" | Slack, Mailchimp |
| Mid formality, low humor, mid technicality | "The Expert" | Stripe, Linear |
| High formality, low humor, low enthusiasm | "The Authority" | McKinsey, Bloomberg |
| Low formality, mid humor, high enthusiasm | "The Coach" | Nike, Duolingo |
| Mid formality, low humor, high technicality | "The Engineer" | Cloudflare, Datadog |
| Low formality, low humor, low enthusiasm | "The Minimalist" | Muji, Aesop |

**Output:**

```yaml
voice:
  spectrum:
    formality: [1-10]
    humor: [1-10]
    enthusiasm: [1-10]
    technicality: [1-10]
```

### Stage 2: Voice Personality → `voice.personality`

Build 3-4 "we are / we are not" pairs that define the brand's personality boundaries.

**Introduction:**

"Now let's define your brand's personality. I'll help you create 3-4 statements in this format: 'We are **[attribute]**, but not **[what we're not]**.' This sets clear boundaries for anyone writing as your brand."

**Question:**

"Based on your values and voice spectrum, I'd suggest starting with these. Which resonate? You can modify or replace any of them."

**Suggest 3-4 pairs based on identity data:**

| Brand signal | Suggested pair |
|-------------|----------------|
| Values transparency | "Honest, but not blunt" |
| Values simplicity | "Clear, but not oversimplified" |
| Values innovation | "Forward-thinking, but not trendy" |
| Values quality/craft | "Precise, but not cold" |
| Values community | "Warm, but not unprofessional" |
| Values expertise | "Authoritative, but not condescending" |
| Values accessibility | "Approachable, but not dumbed down" |
| Values boldness | "Confident, but not arrogant" |
| Values empathy | "Caring, but not patronizing" |
| Values speed/efficiency | "Direct, but not curt" |
| High humor spectrum | "Witty, but not flippant" |
| Low formality spectrum | "Casual, but not sloppy" |
| High technicality | "Technical, but not exclusionary" |

**Process:**

1. Present 3-4 suggested pairs based on their data
2. For each pair, ask: "Does this feel right? Want to adjust either side?"
3. For each confirmed pair, ask: "In one sentence, what does this mean for your brand specifically?"
   → fills `description`
4. If the user wants to add more, allow up to 5 total
5. If fewer than 3, prompt: "Strong brands usually have 3-4 personality traits. Is there another dimension of how your brand speaks that we should capture?"

**For each confirmed attribute, generate DO/DON'T reasoning:**

After confirming all pairs, explain how each translates to concrete writing guidance. This is captured in the description field and also informs Stage 6 (writing samples).

Example:

> **Confident, but not arrogant**
> - DO: State facts clearly. Use active voice. Lead with what you know.
> - DON'T: Use hedge words ("maybe", "sort of"). But also don't talk down to the reader or dismiss alternatives.

Present this reasoning to the user for confirmation. It doesn't need to be stored verbatim in the schema (the `description` field captures the essence), but it guides the writing samples in Stage 6.

**Output:**

```yaml
voice:
  personality:
    - attribute: "[what we are]"
      not: "[what we're not]"
      description: "[what this means for the brand]"
    - attribute: "..."
      not: "..."
      description: "..."
    - attribute: "..."
      not: "..."
      description: "..."
```

### Stage 3: Channel-Specific Variations

Define how the voice adapts across different communication channels. This data feeds into content-rules (Phase 7) and social-media (Phase 8).

**Introduction:**

"Your brand voice should be consistent, but the *tone* shifts depending on where you're speaking. Think of it like a person who speaks differently in a boardroom vs. a coffee shop — same personality, different register."

**Question (one channel at a time):**

Walk through the channels most relevant to the brand. Start with the ones their primary persona uses (from audience data).

1. **Website copy**

   "How should your website sound? This is usually the 'default' voice — the center of your spectrum. Any specific notes?"

   - If the user struggles: "Think about your homepage. Should it feel like a pitch, a conversation, or a reference guide?"

2. **Social media**

   "Social media is usually more relaxed. How much should the voice shift? Can you use emoji? Slang? Memes? Or should it stay professional?"

   **Follow-up based on persona channels:**
   | Primary channel | Prompt |
   |-----------------|--------|
   | LinkedIn | "LinkedIn tends to be more polished. Do you want to match that, or stand out by being more casual?" |
   | Instagram/TikTok | "Visual platforms are informal. How playful can you get? Can you use humor, trends, hashtags?" |
   | Twitter/X | "Twitter rewards brevity and personality. Can your brand be punchy? Opinionated? Irreverent?" |

3. **Email / Newsletter**

   "How should your emails sound? Friendly and warm? Professional and concise? Think about the difference between a welcome email and a feature announcement."

4. **Customer support**

   "When a customer has a problem, how should your brand respond? Empathetic and patient? Efficient and solution-focused? How much personality do you want in support messages?"

**After each channel**, reflect back:

> "So for social media, you want: [summary]. A bit more [casual/playful/direct] than the website, but still [boundary]. Got it?"

**Record format (for recovery_notes — not in voice schema):**

```
Channel variations:
  Website: [summary — default voice register]
  Social media: [summary — how tone shifts]
  Email/newsletter: [summary — how tone shifts]
  Customer support: [summary — how tone shifts]
```

Only cover channels the user cares about. Minimum 2, maximum 5. Skip channels that aren't relevant (e.g., a B2B SaaS brand may not have a customer support voice distinct from their email voice).

### Stage 4: Vocabulary Guide

Define the words and language patterns the brand uses — and avoids. This data feeds into content-rules (Phase 7).

**Introduction:**

"Let's talk about the specific words your brand uses. Every brand has preferences — words that feel right and words that feel wrong, even if you haven't written them down."

**Questions (one at a time):**

1. **Words we use**

   "Are there words or phrases that feel uniquely 'you'? These could be product terms, values language, or just words you reach for naturally."

   - If the user struggles, offer prompts: "Think about how you describe your product. Do you say 'platform' or 'tool'? 'Customers' or 'users'? 'Simple' or 'intuitive'?"
   - Capture 3-5 preferred words/phrases with brief notes on why

2. **Words we never use**

   "Are there words your brand should *never* use? These might be competitor terms, clichés, or words that feel off-brand."

   **Common examples to offer:**

   | Brand type | Words to avoid | Why |
   |-----------|----------------|-----|
   | Premium brand | "cheap", "deal", "discount" | Undermines perceived value |
   | Casual brand | "leverage", "synergy", "utilize" | Corporate jargon, inauthentic |
   | Inclusive brand | "guys", "manpower", "crazy" | Non-inclusive language |
   | Simple/clear brand | "cutting-edge", "revolutionary", "best-in-class" | Overused marketing superlatives |
   | Technical brand | "easy", "simple", "anyone can" | Oversells, undermines credibility |

   - Capture 3-5 banned words/phrases with reasons

3. **Jargon policy**

   "What's your policy on industry jargon? Should you embrace it because your audience expects it, avoid it to stay accessible, or use it but always explain it?"

   | Audience type | Typical policy |
   |--------------|----------------|
   | Technical experts | Embrace jargon — it builds credibility |
   | Mixed audience | Use jargon but define it on first use |
   | General consumers | Avoid jargon entirely — use plain language |
   | B2B buyers (non-technical) | Limit jargon to widely-understood terms |

**Record format (for recovery_notes):**

```
Vocabulary guide:
  Preferred words: [word] (reason), [word] (reason), ...
  Banned words: [word] (reason), [word] (reason), ...
  Jargon policy: [embrace/define/avoid] — [brief explanation]
```

### Stage 5: Messaging Framework → `voice.messaging`

Build the core messaging components. This uses everything from the previous stages.

**Introduction:**

"Now let's write the core messages that represent your brand. These are the foundation — they'll show up everywhere from your website to your pitch deck."

**Questions (one at a time):**

1. **Tagline**

   "Do you already have a tagline? If the one from Phase 1 still works, we'll keep it. Otherwise, let's craft one."

   - If they have one from `meta.tagline`: "You mentioned '[tagline]' earlier. Does that still feel right with the voice we've defined, or should we evolve it?"
   - If they don't have one, draft 2-3 options based on their positioning, values, and voice personality:

   **Tagline patterns:**

   | Pattern | Example |
   |---------|---------|
   | Action + outcome | "Ship faster, break less" |
   | For [audience] who [desire] | "For founders who think in systems" |
   | [Promise] without [sacrifice] | "Enterprise power without enterprise complexity" |
   | Simple declaration | "Design, simplified." |

   → fills `messaging.tagline`

2. **Value propositions**

   "What are the 3 key benefits your brand offers? Think about what your primary persona cares about most."

   - Connect back to persona goals and frustrations: "Your primary persona [name] wants [goal] and is frustrated by [frustration]. How does your brand solve that?"
   - Each value prop should be one clear sentence
   - If too generic ("we save time"), push: "Everyone saves time. What's the specific way you save time that competitors don't?"

   → fills `messaging.value_propositions`

3. **Elevator pitch**

   "In 2-3 sentences, how would you describe your brand to someone who's never heard of it? Imagine you're at a conference and someone asks 'What does [brand] do?'"

   - Draft one using the positioning statement as a base, adapted to the brand voice:

   > "Based on your positioning and voice, here's a draft: '[pitch]'. How does that sound?"

   → fills `messaging.elevator_pitch`

4. **Boilerplate** *(optional)*

   "Would you like a standard 'about us' paragraph? This is the one you'd use in press releases, partnership pages, and formal docs."

   - Only ask if the brand is B2B or has a formal enough voice (formality ≥ 5)
   - If the user says no, skip it — `boilerplate` is optional in the schema

   → fills `messaging.boilerplate`

**Output:**

```yaml
voice:
  messaging:
    tagline: "[tagline]"
    value_propositions:
      - "[value prop 1]"
      - "[value prop 2]"
      - "[value prop 3]"
    elevator_pitch: "[2-3 sentence pitch]"
    boilerplate: "[about us paragraph, or omit if not needed]"
```

### Stage 6: Writing Samples → `voice.writing_samples`

Generate 3 concrete examples that demonstrate the brand voice in action. Each sample shows a good version, a bad version, and explains why.

**Introduction:**

"Finally, let's see the voice in action. I'll write 3 examples in different contexts — each with a 'right' and 'wrong' version so anyone can see what your voice should and shouldn't sound like."

**Generate 3 samples using the personality, spectrum, and messaging data:**

1. **Homepage hero** (headline + subhead)

   Context: "Homepage hero section"

   Write a good version that embodies all the personality attributes and spectrum positions. Then write a bad version that violates them (too formal, too casual, wrong tone, etc.).

   Explain why the good version works and the bad one doesn't, referencing specific personality traits.

2. **Social media post**

   Context: "Social media post — [primary social channel from persona data]"

   Write a good version that reflects the channel variation from Stage 3. Write a bad version that uses the wrong register (e.g., too formal for Twitter, too casual for LinkedIn).

3. **Customer email**

   Context: "Customer welcome email" or "Customer support response" — pick whichever is more relevant based on the brand's channels.

   Write a good version that demonstrates the email/support voice from Stage 3. Write a bad version that feels off-brand.

**For each sample, present to the user:**

```
Context: [where this copy would appear]

✓ Good:
"[copy that embodies the voice]"

✗ Bad:
"[copy that violates the voice]"

Why: [1-2 sentences explaining the difference, referencing personality traits]
```

Ask: "Do these feel right? Want me to adjust any of them?"

**Output:**

```yaml
voice:
  writing_samples:
    - context: "Homepage hero section"
      good: "[good copy]"
      bad: "[bad copy]"
      why: "[explanation referencing personality traits]"
    - context: "Social media post — [channel]"
      good: "[good copy]"
      bad: "[bad copy]"
      why: "[explanation]"
    - context: "[Email context]"
      good: "[good copy]"
      bad: "[bad copy]"
      why: "[explanation]"
```

---

## Writing the Output

### 1. brand-reference.yml — `voice` section

After all stages are complete and approved, write the voice section:

```yaml
voice:
  personality:
    - attribute: "[what we are]"
      not: "[what we're not]"
      description: "[what this means]"
    - attribute: "..."
      not: "..."
      description: "..."
    - attribute: "..."
      not: "..."
      description: "..."
  spectrum:
    formality: [1-10]
    humor: [1-10]
    enthusiasm: [1-10]
    technicality: [1-10]
  messaging:
    tagline: "[tagline]"
    value_propositions:
      - "[value prop 1]"
      - "[value prop 2]"
      - "[value prop 3]"
    elevator_pitch: "[2-3 sentence pitch]"
    boilerplate: "[about us paragraph or omit]"
  writing_samples:
    - context: "[context 1]"
      good: "[good copy]"
      bad: "[bad copy]"
      why: "[explanation]"
    - context: "[context 2]"
      good: "[good copy]"
      bad: "[bad copy]"
      why: "[explanation]"
    - context: "[context 3]"
      good: "[good copy]"
      bad: "[bad copy]"
      why: "[explanation]"
```

### 2. Summary Before Writing

Before writing to disk, present the full summary for approval:

```
Here's the voice profile I captured:

Voice Spectrum:
  Formality:    [N]/10 — [label]
  Humor:        [N]/10 — [label]
  Enthusiasm:   [N]/10 — [label]
  Technicality: [N]/10 — [label]
  Archetype: "[archetype name]"

Personality:
  1. [Attribute], not [not] — [description]
  2. [Attribute], not [not] — [description]
  3. [Attribute], not [not] — [description]

Channel Variations:
  Website: [summary]
  Social media: [summary]
  Email: [summary]
  Support: [summary]

Vocabulary:
  Use: [preferred words]
  Avoid: [banned words]
  Jargon: [policy]

Messaging:
  Tagline: "[tagline]"
  Value props: [summary]
  Elevator pitch: "[first sentence]..."

Writing Samples:
  1. [Context] — ✓ "[good first few words]..." / ✗ "[bad first few words]..."
  2. [Context] — ✓ "[good first few words]..." / ✗ "[bad first few words]..."
  3. [Context] — ✓ "[good first few words]..." / ✗ "[bad first few words]..."

Does this look right? I can adjust anything before we save.
```

Only write to disk after the user confirms.

---

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `spectrum_dimensions` | `voice.spectrum` has all 4 dimensions with values 1-10 | Present the missing dimension and ask user to place the brand |
| `personality_attributes` | `voice.personality` has ≥ 3 items, each with `attribute`, `not`, and `description` | Ask user to describe one more personality trait |
| `channel_variations` | At least 2 channel-specific tone variations captured in recovery_notes | Ask user to describe tone shifts for 2+ channels |
| `writing_samples` | `voice.writing_samples` has ≥ 3 items, each with `context`, `good`, `bad`, `why` | Generate additional samples from personality/spectrum data |

**On pass:** Update `state.yml` → mark phase 3 complete, write recovery notes, advance to phase 4 (typography-color).

**On fail:** Fix the failing checks (ask targeted questions), re-run validation. Do NOT advance. Max 3 rounds.

---

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Brand: [name] ([industry])
Voice archetype: [archetype name]
Spectrum: formality=[N], humor=[N], enthusiasm=[N], technicality=[N]
Personality: [comma-separated "attribute, not X" pairs]
Tagline: "[tagline]"
Key value prop: [first value proposition]
Channel variations: [comma-separated channel names with brief tone notes]
Vocabulary: prefers [top 2 words], avoids [top 2 words], jargon=[policy]
```

These notes — especially the channel variations and vocabulary data — are consumed by content-rules (Phase 7) and social-media (Phase 8) to build detailed channel guides and terminology lists.
