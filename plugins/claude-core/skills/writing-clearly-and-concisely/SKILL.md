---
name: writing-clearly-and-concisely
description: |
  Write clear, concise prose for humans — documentation, commit messages, error messages,
  reports, UI text. Applies Strunk's rules and avoids AI writing patterns. Use when
  writing or editing any text that humans will read.
user_invocable: true
interactive: true
depends_on: []
reads: []
writes: []
triggers:
  - writing
  - documentation
  - readme
  - commit message
  - copyedit
  - prose
  - clear writing
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_ai_patterns"
      verify: "Output contains no AI writing patterns from the avoidance list"
      fail_action: "Revise text to remove detected AI patterns"
  on_fail: "Revise for clarity and concision"
  on_pass: "Text meets Strunk's standards with no AI tells"
model_tier: sonnet
_source:
  origin: original
  ported_date: "2026-03-09"
  iteration: 1
  changes: ["initial creation"]
---

# Writing Clearly and Concisely

Apply Strunk's rules for clarity and force. Avoid AI writing patterns.

## When to Use

Any time you write prose for humans: docs, READMEs, commit messages, PR descriptions,
error messages, UI copy, comments, reports, explanations. If a human reads it, use this.

## Strunk's 18 Rules (Summary)

**Grammar/Punctuation (Rules 1-7):**
1. Form possessive singular with 's
2. Oxford comma in series
3. Enclose parenthetic expressions between commas
4. Comma before conjunction in compound sentence
5. Don't join independent clauses with just a comma
6. Don't break sentences in two
7. Participial phrase at beginning refers to subject

**Composition (Rules 8-18):**
8. One paragraph per topic
9. Begin paragraphs with topic sentence
10. **Use active voice** — "He repaired the car" not "The car was repaired by him"
11. **Put statements in positive form** — "dishonest" not "not honest"
12. **Use definite, specific, concrete language** — avoid vague generalities
13. **Omit needless words** — "the question as to whether" → "whether"
14. Avoid succession of loose sentences
15. Express coordinate ideas in similar form (parallelism)
16. **Keep related words together** — don't split subject from verb unnecessarily
17. Keep to one tense in summaries
18. **Place emphatic words at end of sentence**

**Most tasks need only rules 10-13, 16, 18.** For full text with examples, see references.

## AI Writing Patterns to Avoid

LLMs produce generic, inflated prose. Specific patterns to catch:

- **Puffery:** pivotal, crucial, vital, testament, enduring legacy
- **Empty -ing phrases:** ensuring reliability, showcasing features, highlighting capabilities
- **Promotional adjectives:** groundbreaking, seamless, robust, cutting-edge
- **Overused AI vocabulary:** delve, leverage, multifaceted, foster, realm, tapestry
- **Formatting overuse:** excessive bullets, emoji decorations, bold on every other word
- **Filler openers:** "It's important to note that", "It's worth mentioning that"
- **Hedge phrases:** "It should be noted", "It is interesting to note"
- **Em dashes (—):** Use hyphens (-) or rewrite the sentence. Em dashes are an AI tell — humans rarely type them.

Be specific, not grandiose. Say what it actually does.

See [signs-of-ai-writing.md](references/signs-of-ai-writing.md) for the full field guide.

## Reference Files

| Section | File | Use when |
|---------|------|----------|
| Grammar, punctuation | [02-elementary-rules-of-usage.md](references/elements-of-style/02-elementary-rules-of-usage.md) | Fixing grammar issues |
| Active voice, concision | [03-elementary-principles-of-composition.md](references/elements-of-style/03-elementary-principles-of-composition.md) | Most writing tasks |
| Headings, quotations | [04-a-few-matters-of-form.md](references/elements-of-style/04-a-few-matters-of-form.md) | Formatting decisions |
| Word choice, common errors | [05-words-and-expressions-commonly-misused.md](references/elements-of-style/05-words-and-expressions-commonly-misused.md) | Word-level editing |
| AI pattern detection | [signs-of-ai-writing.md](references/signs-of-ai-writing.md) | Reviewing for AI tells |

**Default:** Load `03-elementary-principles-of-composition.md` — it covers active voice, positive form, concrete language, and omitting needless words.
