# Templates

Reusable prompt templates organized by category. Each template provides a
starting structure — adapt fields to the specific task.

---

## Technical

### Debug

**When to use:** Investigating a bug, unexpected behavior, or failing test.

```
Role: Senior debugger specializing in [language/framework]
Situation: [Describe the bug — what happens vs what should happen]
Constraints: Don't modify [protected files/areas]. Focus on [specific scope].
Instructions:
  1. Reproduce the issue from the information given
  2. Identify the root cause (not just the symptom)
  3. Propose the minimal fix
  4. Explain why this fix won't introduce regressions
Format: Root cause in 1-2 sentences, then the fix as a diff.
```

### Refactor

**When to use:** Improving code structure without changing behavior.

```
Role: [Language] developer focused on maintainability
Task: Refactor [target] to [specific improvement goal]
Constraints:
  - No behavior changes (all existing tests must still pass)
  - Keep the public API identical
  - Reduce total line count if possible
Format: Refactored code in a code block. Below it, a bullet list of what changed and why.
```

### Code Review

**When to use:** Reviewing a PR, diff, or code snippet for quality issues.

```
Role: Code reviewer with expertise in [domain]
Situation: [Context — what the code does, what the PR is for]
Constraints: Flag only actionable issues. Skip style nitpicks unless they
  affect readability. Severity levels: critical, warning, info.
Instructions: Review for correctness, security, performance, and maintainability.
Format:
  ## Findings
  - [severity] [file:line] — [issue] → [suggested fix]
  ## Verdict
  [approve/request-changes] — [1-sentence summary]
```

### Architecture

**When to use:** Designing system structure, evaluating tradeoffs, or planning
technical approach.

```
Role: Software architect with [domain] experience
Objective: [What architectural decision needs to be made]
Details:
  - Current state: [what exists now]
  - Requirements: [what needs to change]
  - Constraints: [team size, timeline, tech stack, scale]
Format:
  ## Recommendation
  [Recommended approach in 2-3 sentences]
  ## Tradeoffs
  | Option | Pros | Cons |
  ## Migration Path
  [Ordered steps to get from current to recommended state]
```

---

## Creative

### Brainstorm

**When to use:** Generating ideas for features, names, approaches, or solutions.

```
Role: Creative technologist with [domain] background
Task: Generate [N] ideas for [topic]
Constraints:
  - Each idea must be distinct (no variations of the same concept)
  - Include at least one unconventional option
  - Rate each idea: feasibility (1-5), impact (1-5)
Format: Numbered list. Each entry: idea name, 1-sentence description, feasibility, impact.
```

### Naming

**When to use:** Naming a project, feature, variable, or concept.

```
Task: Generate [N] name candidates for [thing being named]
Details:
  - Purpose: [what it does]
  - Tone: [technical/playful/professional/etc.]
  - Constraints: [max length, must be unique, domain available, etc.]
Format: Table with columns: Name, Why It Works, Potential Issues.
```

### UX Writing

**When to use:** Writing UI copy, error messages, tooltips, or onboarding text.

```
Role: UX writer for [product type]
Objective: Write [type of copy] for [feature/screen]
Details:
  - Audience: [who sees this]
  - Tone: [brand voice — helpful/minimal/friendly/etc.]
  - Constraints: [max character count, accessibility requirements]
Examples:
  Good: [example matching desired style]
  Bad: [example of what to avoid]
Format: Each piece of copy on its own line with a label (e.g., "Heading:", "CTA:", "Error:").
```

---

## Analysis

### Performance

**When to use:** Analyzing runtime performance, bundle size, or resource usage.

```
Role: Performance engineer
Situation: [What's slow, what the metrics show, what the target is]
Instructions:
  1. Identify the bottleneck from the data provided
  2. Explain why it's slow (mechanism, not just symptom)
  3. Propose fixes ordered by impact-to-effort ratio
Constraints: Don't suggest rewriting the entire system. Focus on changes
  that can ship this sprint.
Format: Bottleneck analysis (2-3 sentences), then a ranked list of fixes
  with estimated impact.
```

### Security

**When to use:** Reviewing code or architecture for security vulnerabilities.

```
Role: Application security engineer
Task: Audit [target] for security vulnerabilities
Constraints:
  - Focus on [OWASP Top 10 / auth / data handling / specific area]
  - Severity: critical (exploitable now), high (exploitable with effort),
    medium (defense-in-depth), low (hardening)
Format:
  - [severity] [category] — [vulnerability description]
    Evidence: [code reference or pattern]
    Fix: [specific remediation]
```

### Comparison

**When to use:** Evaluating multiple options, tools, libraries, or approaches.

```
Task: Compare [Option A] vs [Option B] for [use case]
Details:
  - Evaluation criteria: [list specific dimensions that matter]
  - Context: [team size, scale, existing stack, timeline]
  - Priority: [which criteria matter most]
Format:
  | Criterion | Option A | Option B |
  Then a clear recommendation with reasoning (not "it depends").
```

---

## Transformation

### Migration

**When to use:** Moving from one technology, pattern, or version to another.

```
Role: Migration specialist for [source] → [target]
Situation: [Current state, what's being migrated, why]
Instructions:
  1. Identify breaking changes between [source] and [target]
  2. Create a migration checklist ordered by dependency
  3. Write the migration code/config for each step
  4. Add rollback instructions for each step
Constraints: Zero downtime. No data loss. Backward compatible during transition.
Format: Numbered checklist. Each step: what to change, the code, rollback command.
```

### Summarization

**When to use:** Condensing long documents, threads, or codebases into key points.

```
Task: Summarize [source] into [target format]
Constraints:
  - Max [N] words/bullets/paragraphs
  - Preserve: [key details that must not be lost]
  - Audience: [who will read this — determines detail level]
Format: [Bullet list / executive summary / TL;DR + details]
```

### Format Conversion

**When to use:** Converting data or content between formats.

```
Task: Convert [input format] to [output format]
Input: [the data or a representative sample]
Constraints:
  - Preserve [specific fields/structure/semantics]
  - Handle edge cases: [nulls, special characters, nested structures]
Format: Output in a code block with the target format. Note any lossy
  conversions or edge cases encountered.
```
