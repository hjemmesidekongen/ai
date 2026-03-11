# Brand Audit — Detailed Process

## Phase 1: Source Collection

Ask the user to provide brand materials. Accept any combination of:
- Website URL (read with WebFetch if available)
- Content samples (blog posts, social posts, emails, documentation)
- Existing brand docs (style guides, mission statements, about pages)
- Visual references (describe the aesthetic even if you can't see images)
- Customer-facing copy (product descriptions, landing pages, support docs)

For each source, document in `audit-sources.md`:
- Source type and location
- Key extractions (voice patterns, positioning signals, value indicators)
- Confidence level (high/medium/low based on sample quality)

Aim for 5+ diverse samples to ensure extraction accuracy.

## Phase 2: Voice Extraction

Analyze all content samples to derive voice attributes:

### Quantitative Analysis
For each sample, score:
1. **Formal-Casual**: sentence structure, contractions, address style
2. **Serious-Playful**: humor, metaphor, emotional language
3. **Technical-Simple**: jargon density, explanation depth, assumed knowledge
4. **Reserved-Expressive**: exclamation marks, emotional words, intensity
5. **Humble-Confident**: hedging language, qualifiers, assertion strength

Average across samples. Note variance — high variance may indicate inconsistent brand voice.

### Pattern Extraction
- Sentence patterns: average length, structure preferences
- Paragraph patterns: how ideas flow, transition style
- Hook patterns: how content opens
- Vocabulary: recurring words, distinctive phrases, absent words

### Archetype Mapping
Based on scores, identify the closest personality archetype:
- Expert: high technical, high formal, high confident
- Friend: high casual, moderate playful, high expressive
- Innovator: high confident, moderate playful, forward-looking language
- Guide: moderate formal, high simple, supportive language
- Motivator: high expressive, high confident, action-oriented

## Phase 3: Positioning Extraction

From how the brand describes itself and its audience:
- What category does it claim?
- How does it differentiate?
- Who is the implied audience?
- What promise is made (explicitly or implicitly)?

Cross-reference with public information if a website URL is provided.

## Phase 4: Values Inference

Look for:
- Repeated themes across content (what does the brand keep coming back to?)
- Emphasized vs de-emphasized topics
- Implicit beliefs (what does the brand assume is true?)
- Tone during difficult topics (complaints, limitations, competition)

Propose 3-5 values with evidence citations from analyzed sources.

## Phase 5: Draft & Validate

Write all files following the same schemas as brand-strategy output.
Present a summary to the user with evidence for each major finding.

Ask specifically:
- "I scored your voice as [X] on formal-casual. Here's why: [examples]. Does that match?"
- "The strongest value signal is [X]. Here's where I saw it: [citations]. Agree?"

Iterate based on corrections. The user knows their brand better — but challenge
if their perception contradicts the evidence from their own content.

## Phase 6: Finalize

Write final files after user approval. Include audit-sources.md with full
source-to-finding mapping for future reference.
