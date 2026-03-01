---
name: identity-interview
description: >
  Runs an interactive interview to capture the brand's foundation: name, tagline,
  industry, mission, vision, values, brand story, positioning, and competitive
  landscape. Writes the meta and identity sections to brand-reference.yml.
phase: 1
depends_on: []
writes:
  - "brand-reference.yml#meta"
  - "brand-reference.yml#identity"
reads: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "brand_name_present"
      verify: "meta.brand_name is a non-empty string"
      fail_action: "Ask the user for the brand name — this field is mandatory"
    - name: "mission_statement"
      verify: "identity.mission exists and contains more than 10 words"
      fail_action: "Ask a follow-up question to help the user articulate their mission"
    - name: "values_count"
      verify: "identity.values has at least 3 items, each with name and description"
      fail_action: "Prompt the user for additional values until at least 3 are defined"
    - name: "positioning_structure"
      verify: "identity.positioning has all four fields: category, target, differentiator, proof"
      fail_action: "Walk the user through the positioning template to fill gaps"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Identity Interview

Phase 1 of brand generation. This is the first skill that runs — everything else builds on the foundation captured here. The interview produces the `meta` and `identity` sections of `brand-reference.yml`.

## Interview Philosophy

- Ask **one question at a time**. Never present a wall of questions.
- **Offer examples** relevant to the user's industry to help them answer.
- If the user gives a **vague answer**, ask a focused follow-up to sharpen it.
- If the user says **"I don't know"**, suggest 2-3 options based on what you've learned so far about their industry and audience. Let them pick or adapt.
- Keep the tone conversational and encouraging — this is a creative exercise, not a form.
- After each answer, briefly reflect back what you understood before moving on. This catches misunderstandings early.

## Pre-Interview: Load Brainstorm Decisions

Before starting the interview, call the decision-reader skill to check if the
user already made relevant decisions during a brainstorm session:

- **Project:** the brand name being generated
- **Domains:** `brand-identity`, `brand-audience`, `brand-voice`, `brand-visual`

If decisions are found, adjust the interview flow:

| Confidence | Behavior |
|------------|----------|
| **High** | Pre-fill the answer and show for quick confirmation: "From your brainstorm: [decision]. Still good? [Y/n]" — if confirmed, skip the question |
| **Medium** | Present as starting point: "You were leaning toward: [decision]. Go with this, or explore further?" — if accepted, use it; otherwise ask normally with the decision as context |
| **Low** | Mention as context when asking the question: "You mentioned [decision] during brainstorming. Let's discuss..." — then proceed with the normal question |
| **Not found** | Ask normally — this is the default behavior without brainstorming |

Use the decision-reader's `check_decision` method before each question to find
matching decisions. For example, before asking about brand name, check for
decisions matching the `brand_name` field in the `brand-identity` domain.

At the end, note which decisions were applied in state.yml:

```yaml
decisions_applied: [d1, d2, d5]
```

## Interview Flow

The interview has 6 stages. Each stage produces data for a specific part of the schema.

### Stage 1: Brand Basics → `meta` section

Collect the essential identifiers.

**Questions (one at a time):**

1. "What's the name of your brand?"
   - If they give a working name, confirm: "Is this the final name, or a working title?"

2. "Do you have a tagline or slogan? If not, we can create one later."
   - Accept whatever they have. Mark as draft if tentative.

3. "What industry or category does your brand operate in?"
   - Offer examples: "SaaS, E-commerce, Agency, Healthcare, Education, Fintech, etc."
   - If they say something broad like "tech", ask: "Can you narrow that down? For example: developer tools, consumer electronics, B2B SaaS?"

4. "What's your website URL?" *(optional)*

**Output:**

```yaml
meta:
  brand_name: "[answer]"
  tagline: "[answer or empty]"
  industry: "[answer]"
  website: "[answer or empty]"
  generated_date: "[today]"
  version: "1.0"
```

### Stage 2: Mission Statement → `identity.mission`

The mission answers: **Why does this brand exist?**

**Question:**

"Why does your brand exist? What problem are you solving, and for whom?"

**Follow-up triggers:**

| User response | Follow-up |
|---------------|-----------|
| Too short (< 10 words) | "Can you expand on that? A strong mission statement usually captures what you do, who you serve, and why it matters." |
| Too generic ("we help people") | "Help people do what specifically? What changes for them because your brand exists?" |
| Too long (> 50 words) | "That's great context. Let me distill it: [propose condensed version]. Does that capture the core?" |
| "I don't know" | Suggest 2-3 templates based on their industry: e.g., "To [action] for [audience] by [method]" |

**Examples to offer (based on industry):**

- SaaS: "To simplify [complex task] so [audience] can focus on [what matters]."
- E-commerce: "To make [product category] accessible to [audience] without [common frustration]."
- Agency: "To help [client type] [achieve outcome] through [approach]."

**Output:**

```yaml
identity:
  mission: "[final mission statement]"
```

### Stage 3: Vision Statement → `identity.vision`

The vision answers: **Where is this brand going?**

**Question:**

"If your brand fully succeeds, what does the world look like in 5-10 years? What has changed?"

**Follow-up triggers:**

| User response | Follow-up |
|---------------|-----------|
| Sounds like a mission | "That sounds more like what you do today (mission). The vision is aspirational — where are you heading? What's the end state?" |
| Too vague ("be the best") | "Best at what? Paint a picture: who benefits, and what's different about their experience?" |
| "I don't know" | "Try finishing this sentence: 'We envision a world where...' What comes to mind?" |

**Output:**

```yaml
  vision: "[final vision statement]"
```

### Stage 4: Core Values → `identity.values`

Values answer: **What principles guide decisions?**

**Question:**

"What are the 3-5 core values that guide how your brand operates? These aren't aspirational buzzwords — they're the principles you'd use to make a hard decision."

**Follow-up process:**

1. If the user lists values without explanations, ask for each: "What does [value] mean specifically for your brand? Can you give an example of how it shows up in practice?"

2. If they list fewer than 3, prompt: "Most strong brands have 3-5 values. Are there other principles that guide how you work? Think about what you'd refuse to compromise on."

3. If they list generic values ("innovation", "quality", "integrity"), challenge: "Every company says [value]. What makes yours different? How does [value] actually show up in what you do?"

**Common value frameworks to offer:**

| Category | Examples |
|----------|----------|
| Customer-first | Transparency, Empathy, Accessibility |
| Craft-focused | Excellence, Simplicity, Precision |
| Culture-driven | Ownership, Collaboration, Courage |
| Impact-oriented | Sustainability, Inclusion, Community |

**Output (minimum 3, maximum 5):**

```yaml
  values:
    - name: "[Value]"
      description: "[One sentence: what this means for the brand]"
    - name: "[Value]"
      description: "[...]"
    - name: "[Value]"
      description: "[...]"
```

### Stage 5: Positioning Statement → `identity.positioning`

Positioning answers: **How does this brand win?**

Walk the user through the positioning template:

> "For **[target audience]**, **[brand]** is the **[category]** that **[differentiator]** because **[reason to believe]**."

**Questions (one at a time):**

1. "Who is your primary target audience? Be specific — not 'everyone', but the one group you'd choose if you could only serve one."
   → fills `positioning.target`

2. "What category do you compete in? This is the mental shelf the customer puts you on."
   → fills `positioning.category`
   - If vague: "If someone asked 'what is [brand]?', how would you complete the sentence: '[brand] is a ___'?"

3. "What makes you different from the alternatives? What do you do that no one else does, or that you do better?"
   → fills `positioning.differentiator`
   - If generic ("better quality"): "Everyone claims quality. What's the *specific* thing a customer would point to?"

4. "Why should someone believe that claim? What proof do you have?"
   → fills `positioning.proof`
   - Offer prompts: "This could be: years of experience, a unique technology, specific results, customer testimonials, certifications..."

**Output:**

```yaml
  positioning:
    category: "[answer]"
    target: "[answer]"
    differentiator: "[answer]"
    proof: "[answer]"
```

### Stage 6: Brand Story & Competitive Landscape → `identity.brand_story`

These are optional but valuable for later phases (especially tone-of-voice and content).

**Brand story question:**

"How did this brand come to be? What's the origin story — the moment, problem, or insight that started it all?"

- If the user has a story, capture it as a 2-3 paragraph narrative.
- If they don't want to share one, skip it — `brand_story` is optional in the schema.

**Competitive landscape question:**

"Who are your 2-3 main competitors? For each one, what do they do well, and where do they fall short compared to you?"

- This data isn't stored in brand-reference.yml directly, but informs the positioning differentiator and helps later phases (audience personas, content rules).
- Store it in `recovery_notes` for future reference if provided.

**Output:**

```yaml
  brand_story: |
    [2-3 paragraph narrative, or omit if not provided]
```

## Writing the Output

After completing all stages, write two sections to `brand-reference.yml`:

1. **`meta`** — Brand basics (name, tagline, industry, website, date, version)
2. **`identity`** — Mission, vision, values, brand_story, positioning

Before writing, present a summary to the user for approval:

```
Here's what I captured for your brand foundation:

Brand: [name] — "[tagline]"
Industry: [industry]

Mission: [mission]
Vision: [vision]

Values:
  1. [Value] — [description]
  2. [Value] — [description]
  3. [Value] — [description]

Positioning:
  For [target], [brand] is the [category] that [differentiator]
  because [proof].

Does this look right? I can adjust anything before we save.
```

Only write to disk after the user confirms.

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `brand_name_present` | `meta.brand_name` is non-empty | Ask for the brand name |
| `mission_statement` | `identity.mission` exists and is > 10 words | Ask a follow-up to expand the mission |
| `values_count` | `identity.values` has ≥ 3 items, each with `name` + `description` | Prompt for additional values |
| `positioning_structure` | All four fields present: `category`, `target`, `differentiator`, `proof` | Walk through the positioning template |

**On pass:** Update `state.yml` → mark phase 1 complete, write recovery notes summarizing key brand attributes, advance to phase 2 (audience-personas).

**On fail:** Fix the failing checks (ask targeted questions), re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml` for cross-session resume:

```
Brand: [name] ([industry])
Mission: [first 50 chars]...
Values: [comma-separated names]
Positioning: [category] for [target]
Competitive context: [brief if provided]
```

These notes let a future session reconstruct context without re-reading the full brand-reference.yml.
