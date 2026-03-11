# Brand Evolve — Detailed Process

## Phase 1: Load Current Brand

Read all files from `.ai/brand/{name}/`:
- guideline.yml → positioning, audience, pillars
- voice.yml → archetype, scales, vocabulary
- values.yml → core values, beliefs, non-negotiables

If any file is missing, note it. If no files exist, redirect to brand-strategy.

Present a concise summary: "Here's your current brand in 30 seconds: [summary]"

## Phase 2: Diagnose

Ask targeted questions:
1. "What's working well about the current brand?"
2. "What feels off or outdated?"
3. "Has your market or audience shifted?"
4. "Are there new competitors that change your positioning?"
5. "Has your team's voice naturally drifted from the guidelines?"

Listen for signals: if the user struggles to articulate what's wrong, probe with
specific examples from the current guideline.

## Phase 3: Scope the Evolution

Based on diagnosis, propose which elements to evolve:

| Element | Change Level | Description |
|---------|-------------|-------------|
| Positioning | Refresh / Pivot / Keep | Market category, differentiator, promise |
| Audience | Expand / Narrow / Redefine / Keep | Segments, pain points, channels |
| Voice | Tune / Overhaul / Keep | Archetype, scales, vocabulary |
| Values | Add / Remove / Redefine / Keep | Core values, beliefs |
| Pillars | Rebalance / Replace / Keep | Content themes, percentages |

Ask the user to confirm scope before making changes.

## Phase 4: Evolve Each Element

For each scoped element:

### 4a: Present Current State
Show the current definition with key details.

### 4b: Propose Change
Present 2-3 evolution options. For each:
- What changes
- What stays the same
- Why this direction

### 4c: Challenge
- "Is this change driven by actual market shift, or just fatigue?"
- "Will existing customers recognize the evolved brand?"
- "Does this create inconsistency with the elements you're keeping?"

### 4d: Approve
Get explicit approval before writing.

## Phase 5: Write Evolution Log

Create/update `evolution-log.md`:

```markdown
# Evolution Log — {Brand Name}

## {Date} — {Evolution Summary}

### Changes
- **Positioning**: [before] → [after]. Reason: [why]
- **Voice scale formal_casual**: 4 → 6. Reason: [why]
- ...

### Kept
- Values: unchanged. Still working well.
- ...

### Rationale
[1-2 paragraph summary of why this evolution was needed]
```

## Phase 6: Update Files

Write updated guideline.yml, voice.yml, values.yml, and dos-and-donts.md.
Regenerate dos-and-donts.md from the evolved voice + values.

Present final summary showing before → after for all changed elements.
Ask for final approval.
