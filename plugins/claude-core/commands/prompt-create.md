---
name: prompt-create
description: Turn rough intent into an expert-level prompt
user_invocable: true
arguments:
  - name: intent
    description: "Rough description of what you want to accomplish"
    required: true
---

# /prompt:create

Build a polished, expert-level prompt from a rough description.

## Steps

1. **Receive intent** — take `$ARGUMENTS` as the raw input
2. **Load prompt-optimizer skill** in Mode B (prompt builder)
3. **Categorize** — determine if the intent is Technical, Creative, Analysis, or Transformation
4. **Select framework** — pick the best fit from RTF, RSCIT, RISEN, RODES, or Chain-of-Thought
5. **Clarify if needed** — ask 2-3 targeted questions when the intent is ambiguous
6. **Apply framework** — structure the prompt using the selected framework
7. **Audit** — verify against the 6-item audit checklist
8. **Present** — output the polished prompt in a code block
9. **Ask** — "Copy this, or execute it here?"
