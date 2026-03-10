---
name: prompt-optimizer
description: >
  Sharpens vague prompts into precise instructions using proven frameworks.
  Mode A (auto-sharpen): hook-triggered, infers missing context from codebase,
  rewrites the prompt, shows the sharpened version, proceeds. Mode B (prompt
  builder): command-triggered via /prompt:create, takes rough intent, applies
  best framework, outputs a polished prompt for copy or execution.
user_invocable: false
interactive: false
depends_on: []
triggers:
  - "sharpen prompt"
  - "optimize prompt"
  - "rewrite prompt"
  - "prompt builder"
  - "create prompt"
  - "vague request"
  - "improve instructions"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "framework_applied"
      verify: "Output prompt uses at least one named framework (RSCIT, RTF, RISEN, RODES, CoT)"
      fail_action: "Re-apply framework selection and structuring"
    - name: "audit_passed"
      verify: "Output passes all 6 audit checklist items"
      fail_action: "Address failing audit items and regenerate"
  on_fail: "Re-run framework selection and apply audit checklist"
  on_pass: "Present sharpened prompt (Mode A) or formatted output (Mode B)"
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "antigravity prompt engineering research"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Initial creation — hook-triggered auto-sharpen + /prompt:create builder"
---

# prompt-optimizer

Transforms vague or underspecified prompts into precise, structured instructions.

## Two Modes

**Mode A (auto-sharpen)** — Triggered by hook context when a prompt is too vague.
Infer missing context from codebase, apply RSCIT framework, present "I'll approach
this as: [sharpened version]", then proceed with the sharpened interpretation.

**Mode B (prompt builder)** — Triggered by `/prompt:create`. Takes rough intent,
categorizes it (Technical/Creative/Analysis/Transformation), selects the best
framework, asks 2-3 clarifying questions if needed, outputs a polished prompt
in a code block, then asks "Copy this, or execute it here?"

## When to trigger

- Hook detects a vague or ambiguous user prompt (Mode A)
- User invokes `/prompt:create` (Mode B)
- User asks to improve, sharpen, or optimize a prompt

## Process

See `references/process.md` for the full methodology, diagnostic patterns,
and audit checklist.

## Frameworks

See `references/frameworks.md` for the five supported frameworks with usage
guidance and example structures.

## Templates

See `references/templates.md` for reusable prompt templates organized by
category: Technical, Creative, Analysis, Transformation.

## Key Principles

Instruction hierarchy: `[System Context] > [Task] > [Examples] > [Input] > [Output Format]`

Progressive disclosure — add complexity one level at a time:
1. Direct instruction → 2. Add constraints → 3. Add reasoning (CoT) → 4. Add examples
