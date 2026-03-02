# Audience & Personas — Detailed Process

This skill runs as Phase 2 of brand generation. It reads the brand's identity data from Phase 1
and conducts a conversational interview to identify target audience segments and build detailed
persona cards. Output includes the `audience` section of `brand-reference.yml` and standalone
`persona-card-N.md` files. The persona data feeds directly into tone-of-voice (Phase 3),
content-rules (Phase 7), and social-media (Phase 8).

---

## Pre-Interview: Load Brainstorm Decisions

Before starting the interview, call the decision-reader skill to check if the
user already made relevant decisions during a brainstorm session:

- **Project:** the brand name being generated
- **Domains:** `brand-audience`

If decisions are found, adjust the interview flow:

| Confidence | Behavior |
|------------|----------|
| **High** | Pre-fill persona details and show for quick confirmation: "From your brainstorm: [decision]. Still good? [Y/n]" — if confirmed, use the decision as the answer |
| **Medium** | Present as starting point: "You were leaning toward: [decision]. Go with this, or explore further?" — if accepted, use it; otherwise ask normally with the decision as context |
| **Low** | Mention as context when asking the question: "You mentioned [decision] during brainstorming. Let's discuss..." — then proceed with the normal question |
| **Not found** | Ask normally — this is the default behavior without brainstorming |

Audience decisions may pre-fill market type, segment names, persona
demographics, or channel preferences. Use the decision-reader's
`check_decision` method before each question to find matching decisions.

At the end, note which decisions were applied in state.yml:

```yaml
decisions_applied: [d2, d6]
```

---

## Findings Persistence

During the interview, write intermediate discoveries to the findings file:

```
.ai/brands/[brand-name]/findings.md
```

**What to save:** User responses about market type, segment descriptions, persona details as they're captured, channel preferences, decision factors, and any industry research done to suggest options.

**2-Action Rule:** After every 2 research operations (user question answered, web search, file read), IMMEDIATELY save key findings to findings.md before continuing. Do not wait until all personas are complete.

**Format:**

```markdown
## Audience & Personas Findings

### Market Overview
- Market type: [B2B/B2C/Both]
- Primary market description: "[verbatim]"

### Segments Identified
- [Segment 1]: [brief description]
- [Segment 2]: [brief description]

### Persona: [Name]
- Role: [answer]
- Age range: [answer]
- Goals: [raw user input]
- Frustrations: [raw user input]
- Channels: [raw user input]
- Decision factors: [raw user input]
- Quote: "[verbatim]"

### Research Notes
- [any industry research, channel suggestions, or context gathered]
```

This file persists across `/compact` and session restarts. If context is lost, findings survive.

---

## Error Logging

When errors occur during the interview (validation failures, checkpoint failures, unexpected issues):

1. Log the error to state.yml `errors` array immediately
2. Before retrying any approach, check `errors` for previous failed attempts
3. Never repeat a failed approach — mutate strategy instead
4. The verification-runner logs checkpoint failures automatically

---

## Before You Start

Read the brand's identity data from brand-reference.yml:

- `meta.brand_name` and `meta.industry` — to ground suggestions in the right domain
- `identity.positioning.target` — the user already described their target in Phase 1; use this as a starting point, don't re-ask from scratch
- `identity.positioning.category` — helps frame audience segments
- `identity.mission` — reveals who the brand ultimately serves

Reference this data throughout the interview. Reflect it back: "In the identity phase, you said your target is [positioning.target]. Let's dig deeper into who these people are."

---

## Interview Philosophy

Same rules as identity-interview:

- Ask **one question at a time**. Never present a wall of questions.
- **Offer examples** relevant to the user's industry.
- If the user gives a **vague answer**, ask a focused follow-up.
- If the user says **"I don't know"**, suggest options based on their industry and positioning.
- Keep the tone conversational — this is about understanding real people, not filling out a form.
- After each answer, briefly reflect back what you understood.

---

## Interview Flow

The interview has 4 stages. Each stage builds on the previous one.

### Stage 1: Market Type & Audience Overview → `audience.primary_market`

Start by understanding the broad market context.

**Question:**

"Let's talk about who your brand serves. First — is your primary audience businesses (B2B), consumers (B2C), or both?"

**Follow-ups based on answer:**

| Answer | Follow-up |
|--------|-----------|
| B2B | "What size companies? What department or role is the buyer?" |
| B2C | "What demographic? What life stage or situation are they in?" |
| Both | "Which is the primary revenue driver? Let's start with that audience and add the secondary one." |

Then ask:

"In one or two sentences, how would you describe the market you're going after?"

This becomes `audience.primary_market`. If the user struggles, draft one from their identity data:

> "Based on your positioning, it sounds like your primary market is [draft]. Does that capture it?"

**Output:**

```yaml
audience:
  primary_market: "[answer]"
```

### Stage 2: Audience Segments → identifies how many personas to build

**Question:**

"Now let's break that market into specific groups. Think about the 2-3 types of people who would use or buy from [brand_name]. They might differ by role, goal, experience level, or situation."

**Industry-aware suggestions:**

| Industry | Example segments |
|----------|-----------------|
| B2B SaaS | Decision-maker (VP/Director), End-user (IC/team member), Technical evaluator (Engineer/IT) |
| E-commerce | First-time buyer, Repeat customer, Gift buyer |
| Agency | Startup founder, Marketing director, Enterprise CMO |
| Education | Student, Teacher/instructor, Administrator |
| Healthcare | Patient, Provider, Payer/insurer |
| Fintech | Individual investor, Small business owner, Financial advisor |

"Which of these resonates? Or describe your own segments."

**Follow-ups:**

- If only 1 segment: "Is there a secondary group that also uses your product/service, even if they're not the primary buyer?"
- If more than 3: "Let's focus on the top 2-3. Which segments drive the most revenue or engagement?"
- If too vague: "Can you be more specific? Instead of 'small businesses', think about who at that business is actually making the decision."

Record the segment names — these become the basis for persona cards.

### Stage 3: Persona Deep Dive → `audience.personas[]`

For each segment identified in Stage 2, walk through these questions **one at a time**. Complete one persona fully before starting the next.

Announce the transition: "Great, let's build out the first persona. I'll ask a few questions to bring this person to life."

**Questions per persona:**

1. **Name & demographics**
   "Let's give this persona a name — something memorable that captures who they are. For example, 'Startup Sarah' or 'Enterprise Eddie'. What's their approximate age range and job title?"

   → fills `name`, `role`, `age_range`

2. **Goals**
   "What is [persona name] trying to achieve? What does success look like for them? List 2-3 goals."

   → fills `goals`

   **Follow-up triggers:**

   | Response | Follow-up |
   |----------|-----------|
   | Only 1 goal | "That's a good start. Is there a secondary goal — maybe something personal or career-related tied to using your product?" |
   | Goals too vague ("be successful") | "Success at what specifically? What metric or outcome would they point to?" |
   | Goals don't relate to brand | "How does [brand_name] help them achieve that? Let's connect their goals to what you offer." |

3. **Frustrations / pain points**
   "What frustrates [persona name] about the current options? What's broken, slow, or missing in the solutions they use today?"

   → fills `frustrations`

   **Follow-up triggers:**

   | Response | Follow-up |
   |----------|-----------|
   | Only 1 frustration | "What else? Think about: cost, complexity, time wasted, poor support, missing features..." |
   | Too generic ("bad service") | "Bad in what way? Long wait times? Unhelpful? Can you describe a specific moment of frustration?" |
   | "I don't know" | Suggest 2-3 common frustrations for their industry and ask which resonates |

4. **Channels**
   "Where does [persona name] spend time online? Where do they discover new products or brands like yours?"

   → fills `channels`

   **Offer examples:**

   | Audience type | Common channels |
   |---------------|----------------|
   | B2B decision-makers | LinkedIn, industry publications, conferences, peer recommendations |
   | B2B technical | GitHub, Stack Overflow, dev blogs, Reddit, Discord communities |
   | B2C millennials/GenZ | Instagram, TikTok, YouTube, Reddit, influencer recommendations |
   | B2C professionals | LinkedIn, newsletters, podcasts, Google search |
   | B2C general | Facebook, Google search, word-of-mouth, review sites |

5. **Decision factors**
   "When [persona name] is choosing between you and a competitor, what matters most? Price? Features? Ease of use? Trust? Speed?"

   → fills `decision_factors`

   - If they list only one: "That's the top factor. What's second — the tiebreaker if two options are equal on [first factor]?"

6. **Content preferences** *(optional, ask only if relevant)*
   "How does [persona name] prefer to learn about new products? Quick videos, detailed blog posts, case studies, free trials?"

   → fills `content_preferences`

7. **Persona quote**
   "Finally, sum up [persona name]'s mindset in one sentence — something they'd actually say. For example: 'I don't have time to figure out complicated tools — just show me it works.'"

   → fills `quote`

   - If the user struggles, draft 2-3 options based on their goals and frustrations and let them pick.

**After completing each persona**, reflect back a summary:

```
Here's [Name] so far:

[Name] — [Role], age [range]
"[Quote]"

Goals: [bullet list]
Frustrations: [bullet list]
Channels: [bullet list]
Decision factors: [bullet list]

Does this feel accurate? Anything to add or change?
```

Then move to the next persona: "Now let's do the same for your next segment: [segment name]."

### Stage 4: Primary Persona Selection

After all personas are complete:

**Question:**

"Looking at all [N] personas, which one is your **most important** audience? This is the person you'd optimize for if you had to choose just one."

The selected primary persona becomes the **first item** in the `audience.personas` array. This is the convention — the first persona is always the primary target.

---

## Writing the Output

### 1. brand-reference.yml — `audience` section

After all personas are complete and approved, write the audience section:

```yaml
audience:
  primary_market: "[market description]"
  personas:
    - name: "[Primary Persona Name]"        # Always first
      role: "[job title or life role]"
      age_range: "[e.g. 28-40]"
      quote: "[mindset quote]"
      goals:
        - "[goal 1]"
        - "[goal 2]"
      frustrations:
        - "[frustration 1]"
        - "[frustration 2]"
      channels:
        - "[channel 1]"
        - "[channel 2]"
      content_preferences: "[how they consume info]"
      decision_factors:
        - "[factor 1]"
        - "[factor 2]"
    - name: "[Second Persona Name]"
      role: "..."
      # ...same structure
```

### 2. Persona Card Files

For each persona, create a standalone markdown file in the brand directory:

**Path:** `.ai/brands/[brand]/persona-card-[N].md` (where N = 1, 2, 3...)

**Format:**

```markdown
# [Persona Name]

> "[Quote]"

| | |
|---|---|
| **Role** | [Job title or life role] |
| **Age range** | [Age range] |
| **Primary persona** | [Yes/No] |

## Goals
- [Goal 1]
- [Goal 2]
- [Goal 3]

## Frustrations
- [Frustration 1]
- [Frustration 2]

## Channels
- [Channel 1]
- [Channel 2]

## Decision Factors
- [Factor 1]
- [Factor 2]

## Content Preferences
[How they prefer to consume information]

---
*Generated by /brand:generate — Phase 2: Audience & Personas*
```

### 3. Summary Before Writing

Before writing to disk, present the full summary for approval:

```
Here's the audience profile I captured:

Primary market: [primary_market]

Persona 1 (PRIMARY): [Name] — [Role]
  "[Quote]"
  Goals: [summary]
  Frustrations: [summary]
  Channels: [summary]

Persona 2: [Name] — [Role]
  "[Quote]"
  Goals: [summary]
  Frustrations: [summary]
  Channels: [summary]

[Persona 3 if applicable]

Does this look right? I can adjust anything before we save.
```

Only write to disk after the user confirms.

---

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `personas_count` | `audience.personas` has ≥ 2 items | Ask the user to describe one more audience segment |
| `persona_fields` | Each persona has `name`, `role`, `quote`, `goals` (≥1), `frustrations` (≥1), `channels` (≥1) | Walk through the incomplete persona and ask for missing fields |
| `primary_persona` | First persona is the primary target and `primary_market` is non-empty | Ask which persona is most important and reorder |

**On pass:** Update `state.yml` → mark phase 2 complete, write recovery notes, advance to phase 3 (tone-of-voice).

**On fail:** Fix the failing checks (ask targeted questions), re-run validation. Do NOT advance. Max 3 rounds.

---

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Brand: [name] ([industry])
Audience type: [B2B/B2C/Both]
Primary market: [first 50 chars]...
Primary persona: [name] — [role]
Other personas: [comma-separated names and roles]
Key channels: [top 3 channels across all personas]
Top decision factors: [top 3 factors across all personas]
```

These notes let a future session understand the audience context without re-reading the full brand-reference.yml.
