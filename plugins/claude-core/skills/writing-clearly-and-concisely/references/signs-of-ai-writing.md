# Signs of AI Writing

Condensed from Wikipedia's field guide for detecting AI-generated content. These patterns emerge because LLMs regress to statistical means — replacing specific facts with generic, positive-sounding language.

## Core Mechanism: Regression to the Mean

LLMs infer statistically likely continuations. Specific, unusual, nuanced facts (rare in training data) get replaced by generic, positive descriptions (common in training data). The subject becomes simultaneously less specific and more exaggerated.

## Pattern Categories

### 1. Undue Emphasis on Symbolism, Legacy, Importance

**Words to watch:** stands/serves as, is a testament/reminder, plays a vital/significant/crucial/pivotal role, underscores/highlights its importance, reflects broader, symbolizing its ongoing/enduring/lasting impact, key turning point, indelible mark, deeply rooted, profound heritage, steadfast dedication

LLMs puff up importance by claiming arbitrary aspects represent broader topics. Even mundane subjects get legacy statements.

### 2. Superficial Analyses via Present Participles

**Words to watch:** ensuring..., highlighting..., emphasizing..., reflecting..., underscoring..., showcasing..., aligns with..., contributing to...

The strongest tell is when inanimate things become subjects of these verbs: "This fact highlights..." A fact cannot highlight anything — that's a narrator's unsubstantiated claim about what something means.

### 3. Promotional and Advertisement-Like Language

**Words to watch:** continues to captivate, groundbreaking (figurative), stunning natural beauty, enduring/lasting legacy, nestled, in the heart of, boasts a, rich tapestry, vibrant community

Neutral topics get tourism-brochure treatment. Companies sound like TV commercials.

### 4. Didactic Disclaimers

**Words to watch:** it's important/critical/crucial to note/remember/consider, may vary, it should be noted

LLMs lecture readers about what's "important to remember" — safety warnings, jurisdiction variations, controversial-topic hedging.

### 5. Forced Summaries and Conclusions

**Words to watch:** In summary, In conclusion, Overall

LLMs add conclusion sections and restate core ideas at paragraph ends, even when the text is short enough not to need summarizing.

### 6. "Despite Challenges" Formula

**Pattern:** "Despite its [positive words], [subject] faces challenges..." → vague positive assessment → speculation about future initiatives

Rigid outline structure with "Challenges and Legacy" or "Future Outlook" sections.

## Overused AI Vocabulary

High-confidence indicators (co-occurrence is the strongest tell — where one appears, others follow):

| Category | Words |
|----------|-------|
| Emphasis | crucial, vital, pivotal, key (adj), notably |
| Legacy | testament, enduring, indelible, profound |
| Analysis | delve, multifaceted, nuanced, intricate, intricacies |
| Action | leverage, foster, enhance, streamline, underscore, underpin |
| Texture | tapestry, landscape, realm, vibrant, seamless, robust |
| Connection | interplay, aligns with, shed light on, garnered |
| Display | showcasing, highlighting, emphasizing, reflecting |

## Punctuation Tells

- **Em dashes (—):** LLMs overuse em dashes where humans would use hyphens (-), commas, or separate sentences. Most developers never type an em dash. If you see "structure — not chaos" in generated text, rewrite to "structure, not chaos" or "structure. Not chaos." One em dash in a doc is suspicious. Three is a pattern.

## Structural Tells

- **List-heavy structure:** Excessive use of bullet points and numbered lists where prose would be more natural
- **Bold overuse:** Bolding every other phrase for artificial emphasis
- **Emoji decoration:** Adding emojis to headers or list items
- **Parallel exhaustiveness:** "Whether X, Y, or Z" constructions that try to cover all cases
- **Triple adjective chains:** "comprehensive, innovative, and forward-thinking"

## Formatting Tells

- Headers with flowery language ("A Rich Tapestry of Cultural Heritage")
- Sections that are suspiciously uniform in length
- Every paragraph following the same structure (claim → evidence → significance)
- Excessive transitional phrases between paragraphs

## How to Fix

1. Delete puffery — if removing a sentence changes nothing, remove it
2. Replace generic claims with specific facts
3. Use active voice with concrete subjects
4. Cut present-participle analysis phrases entirely
5. Remove "it's important to note" and similar hedges
6. Let the reader draw their own conclusions about significance
7. Vary sentence and paragraph structure

Source: Wikipedia's "Signs of AI-generated content" field guide, developed by editors who review thousands of AI-generated submissions.
