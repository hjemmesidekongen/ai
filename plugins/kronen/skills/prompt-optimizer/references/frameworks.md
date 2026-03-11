# Frameworks

Five prompt engineering frameworks, ranked by complexity. Start with the simplest
framework that fits the task. Upgrade only when the simpler version would produce
inadequate results.

---

## 1. RTF (Role-Task-Format)

**Best for:** Simple, well-defined tasks with clear output expectations.

**When to use:**
- Single-step tasks
- The role and output format are obvious
- You don't need multi-phase reasoning

**Structure:**
```
Role: [Who the agent should be]
Task: [What to do — one clear instruction]
Format: [What the output looks like]
```

**Example:**
```
Role: Senior TypeScript developer
Task: Refactor this function to eliminate the nested ternary and improve readability
Format: Return the refactored function in a code block with a 1-line comment explaining the change
```

---

## 2. RSCIT (Role-Situation-Constraints-Instructions-Template)

**Best for:** Tasks requiring context awareness and bounded output. Primary
framework for Mode A auto-sharpening.

**When to use:**
- The task needs situational context to be done well
- There are important constraints (time, format, scope)
- You want to control the output shape precisely

**Structure:**
```
Role: [Who]
Situation: [Current state, background, what led here]
Constraints: [Boundaries — what NOT to do, limits, scope]
Instructions: [Step-by-step what to do]
Template: [Exact output format expected]
```

**Example:**
```
Role: Code reviewer with security focus
Situation: This PR adds user authentication to an Express.js API. The team uses
  JWT tokens and has had past issues with token expiration handling.
Constraints: Review only auth-related files. Don't suggest architectural changes.
  Flag severity as critical/warning/info.
Instructions: Check for token validation gaps, expiration handling, and injection
  vectors. List findings ordered by severity.
Template:
  ## Findings
  - [severity] [file:line] — [issue description]
  ## Summary
  [1-2 sentence overall assessment]
```

---

## 3. RISEN (Role-Instructions-Steps-EndGoal-Narrowing)

**Best for:** Multi-phase projects with a clear end state.

**When to use:**
- The task has multiple sequential phases
- There's a specific deliverable at the end
- You need to narrow scope progressively through steps

**Structure:**
```
Role: [Who]
Instructions: [High-level objective]
Steps:
  1. [First phase]
  2. [Second phase]
  3. [Third phase]
End Goal: [What done looks like — specific deliverable]
Narrowing: [What to exclude, what to defer, what's out of scope]
```

**Example:**
```
Role: Database migration specialist
Instructions: Migrate the users table from PostgreSQL to a new schema that supports
  multi-tenancy.
Steps:
  1. Analyze current schema and identify tenant-specific vs shared columns
  2. Design new schema with tenant_id foreign key and RLS policies
  3. Write migration script with rollback support
  4. Generate test data covering edge cases (null tenants, shared records)
End Goal: A working migration file (up + down) and a test script that validates
  data integrity after migration.
Narrowing: Don't modify application code. Don't handle the deployment process.
  Assume PostgreSQL 15+.
```

---

## 4. RODES (Role-Objective-Details-Examples-SenseCheck)

**Best for:** Complex design or analysis tasks where examples and validation matter.

**When to use:**
- The task is subjective or has quality dimensions that are hard to specify
- Examples would significantly improve output quality
- You want built-in self-validation

**Structure:**
```
Role: [Who]
Objective: [What to achieve]
Details: [Specific requirements, quality criteria, preferences]
Examples:
  Good: [Example of desired output]
  Bad: [Example of what to avoid]
Sense Check: [How to validate the output is correct]
```

**Example:**
```
Role: UX copywriter for a developer tools product
Objective: Write error messages for a CLI tool's authentication flow
Details: Messages should be actionable (tell the user what to do next), concise
  (under 80 chars), and avoid blame language. Use sentence case.
Examples:
  Good: "Token expired. Run `auth login` to refresh."
  Bad: "Error: Your authentication token has expired and is no longer valid.
    Please re-authenticate by running the login command again."
Sense Check: Each message answers "what happened" and "what to do next" in
  under 80 characters.
```

---

## 5. Chain-of-Thought (CoT)

**Best for:** Tasks where the reasoning path determines output quality — not all tasks.

**When CoT adds value:**
- Root cause analysis where symptoms could point to multiple causes
- Multi-factor decisions with competing tradeoffs (architecture, tool selection)
- Tasks where the user needs to verify the reasoning, not just the answer
- Debugging where the fix depends on correctly identifying the mechanism

**When CoT hurts (skip it):**
- Simple lookups, renames, deletions — CoT adds latency without accuracy gain
- Tasks where the answer is obvious but the output format matters (use RTF instead)
- Creative tasks where step-by-step thinking constrains divergent exploration
- Code generation where the spec is already clear — just write the code

**Structure:** Don't use generic "think step by step." Instead, name the specific
reasoning steps relevant to the task. Vague CoT produces vague reasoning.

**Example:**
```
This React component re-renders 47 times when the user types a single character
in the search input. The component tree is: App → Dashboard → SearchPanel → ResultsList.

Reason through these specific steps:
1. Which component owns the search input state? Where does setState fire?
2. Trace the re-render cascade: which parent re-renders trigger which children?
3. What mechanism causes the cascade — prop drilling, context, or missing memoization?
4. What is the minimal change that breaks the cascade without restructuring?

Show evidence at each step (component names, state locations, render triggers)
before giving the fix.
```

---

## Progressive Disclosure Levels

When building a prompt iteratively, add complexity one level at a time.
Stop at the level that produces acceptable output.

| Level | What to Add | When to Upgrade |
|-------|------------|-----------------|
| 1. Direct instruction | Clear task statement | Output is vague or off-target |
| 2. + Constraints | Boundaries, limits, scope | Output is correct but uncontrolled |
| 3. + Reasoning (CoT) | Step-by-step thinking | Output skips important considerations |
| 4. + Examples (few-shot) | Good/bad output examples | Output quality is inconsistent |

Start at Level 1. Only escalate when the current level fails.

---

## Framework Selection Guide

| Signal | Framework |
|--------|-----------|
| Simple, one-step task | RTF |
| Needs codebase context | RSCIT |
| Multi-phase with clear end state | RISEN |
| Subjective quality, needs examples | RODES |
| Reasoning-heavy, show-your-work | Chain-of-Thought |
| Unsure | Start with RTF, upgrade if output is weak |
