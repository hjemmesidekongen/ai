# Brand Strategy — Detailed Process

## Phase 1: Intake

Ask the user for:
1. **Brand name** (or working name)
2. **Domain/market** — what space does this brand operate in?
3. **Initial vision** — 1-2 sentences on what they're building and why
4. **Existing materials** — any docs, sites, or references that capture the current thinking?

If any of these exist in `.ai/brand/{name}/`, load and confirm rather than re-asking.

Create the brand directory: `.ai/brand/{name}/`

## Phase 2: Market Research

Run 2-3 Perplexity searches (perplexity_search, max_results: 3, max_tokens_per_page: 512):
- "{domain} competitive landscape {year}" — who are the key players?
- "{domain} positioning gaps opportunities" — what's underserved?
- "{domain} audience segments pain points" — who buys and why?

Write findings to `.ai/brand/{name}/market-research.md` with sections:
- Key competitors (name, positioning, strengths, weaknesses)
- Positioning gaps (underserved segments, unoccupied territory)
- Audience signals (who's buying, what they care about)

Present a 3-sentence summary to the user. Ask: "Does this match your read of the market? Anything missing?"

## Phase 3: Positioning & Audience

### 3a: Positioning
Present 2-3 positioning options based on research. For each option:
- Category: what market slot
- Differentiator: what makes it unique
- Promise: what the audience gets

Ask the user to pick one or remix. Challenge weak differentiation:
- "How is this different from [competitor]?"
- "If [competitor] said this same thing, would it still be true?"
- "What would you NEVER do that competitors would?"

### 3b: Audience
From research + positioning, propose 2-3 audience segments. For each:
- Who they are
- Their pain points
- What motivates purchase/adoption
- Where to reach them

Ask: "Is this who you're actually building for? Anyone missing?"

### 3c: Content Pillars
Propose 4-5 content themes with percentage splits (must total 100).
Example: Education (40%) / Behind-the-scenes (25%) / Community (25%) / Promotion (10%)

Write approved positioning, audience, and pillars to `guideline.yml`.

## Phase 4: Voice Discovery

### 4a: Archetype Selection
Present the 5 personality archetypes:
- **Expert**: authoritative, precise, data-driven
- **Friend**: warm, relatable, conversational
- **Innovator**: bold, forward-looking, challenging convention
- **Guide**: supportive, clear, empowering
- **Motivator**: energetic, action-oriented, inspiring

Ask: "Which feels closest? You can blend two."

### 4b: Voice Scales
Walk through each scale one at a time:
1. Formal (1) — Casual (10)
2. Serious (1) — Playful (10)
3. Technical (1) — Simple (10)
4. Reserved (1) — Expressive (10)
5. Humble (1) — Confident (10)

For each, give a concrete example at 3, 5, and 7 so the user can calibrate.

### 4c: Vocabulary
Based on archetype + scales, propose:
- 3-5 signature phrases
- 10-15 power words
- 10-15 never-use words

Ask: "Do these sound like your brand? What would you add or remove?"

### 4d: Writing Patterns
Propose sentence style, paragraph structure, and hook patterns.
Example: "Short punchy sentences. Lead with the benefit. Questions as hooks."

### 4e: Platform Adaptations
If relevant, ask about channel-specific adjustments (social, docs, marketing).

Write approved voice to `voice.yml`.

## Phase 5: Values & Beliefs

### 5a: Core Values
Propose 3-5 values based on everything discussed so far. For each:
- Name and definition
- 3-5 "in practice" behaviors (concrete actions)
- 2-3 violation examples (what breaking this value looks like)

Challenge: "Would you fire someone over this? If not, it's a preference, not a value."

### 5b: Beliefs
Propose 3-5 distinctive beliefs. These should be mildly contrarian or at least opinionated.
Example: "We believe documentation is a product feature, not an afterthought."

### 5c: Non-negotiables
Ask: "What lines would this brand never cross, even if it cost revenue?"

### 5d: Decision Framework
Based on values, propose a priority order and explicit tradeoffs.
Example: "Clarity over cleverness. User trust over growth speed."

Write approved values to `values.yml`.

## Phase 6: Dos and Donts

Generate `dos-and-donts.md` from voice + values. Format:

```markdown
# {Brand Name} — Dos and Donts

## Do
- Write like you're talking to a smart friend, not lecturing a student
- Lead with the benefit, not the feature
- ...

## Don't
- Use jargon without explaining it
- Make promises you can't back up with evidence
- ...
```

At least 8 dos and 8 donts. Present for approval.

## Phase 7: Final Review

Present a complete summary:
- Brand name + tagline
- Positioning statement
- Primary audience
- Voice archetype + key scales
- Top 3 values
- File locations

Ask for final approval. Only write the checkpoint pass after explicit user confirmation.

## Resume Logic

If `.ai/brand/{name}/` contains partial files:
1. Read all existing files
2. Identify which phases are complete (has data) vs incomplete
3. Summarize what exists: "I see you've defined positioning and audience. Voice is partially done (archetype chosen, scales not set). Want to continue from voice scales?"
4. Resume from the earliest incomplete phase
