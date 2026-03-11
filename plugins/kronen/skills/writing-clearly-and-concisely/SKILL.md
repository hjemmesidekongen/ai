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
model_tier: junior
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

## Key Rules (Most Tasks)

10. **Use active voice** — "He repaired the car" not "The car was repaired by him"
11. **Put statements in positive form** — "dishonest" not "not honest"
12. **Use definite, specific, concrete language** — avoid vague generalities
13. **Omit needless words** — "the question as to whether" → "whether"
16. **Keep related words together** — don't split subject from verb unnecessarily
18. **Place emphatic words at end of sentence**

Full 18 rules (grammar, punctuation, composition): `references/process.md`

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

See [signs-of-ai-writing.md](references/signs-of-ai-writing.md) for the full field guide. Reference file index: `references/process.md`
