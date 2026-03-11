# Process

## Mode A: Auto-Sharpen

Triggered when a hook detects a vague or underspecified prompt.

### Flow

1. **Receive hook context** — The hook passes the original user prompt along with
   a flag indicating it was classified as vague.

2. **Analyze the prompt** — Identify what's missing: role, constraints, format,
   grounding, scope. Use the diagnostic patterns table below.

3. **Gather codebase context** — Read relevant files to infer intent. Check:
   - Recent git changes (what was the user working on?)
   - Active plan state (is there a plan in progress?)
   - File context (what files are open or recently modified?)
   - MEMORY.md and CLAUDE.md for preferences

4. **Apply RSCIT framework** — Structure the sharpened prompt:
   - **Role**: What role should the agent assume?
   - **Situation**: What's the current state and background?
   - **Constraints**: What boundaries apply?
   - **Instructions**: What exactly needs to happen?
   - **Template**: What format should the output take?

5. **Present sharpened version** — Show the user:
   > I'll approach this as: [sharpened prompt]

   Then proceed immediately with the sharpened interpretation. Don't wait
   for confirmation unless the rewrite substantially changes the intent.

6. **Proceed with execution** — Execute the sharpened prompt as the task.

### When NOT to auto-sharpen

- The prompt is already specific and actionable
- The user is giving a direct command (e.g., "commit", "run tests")
- The prompt is a question, not a task instruction
- The user has explicitly said "do exactly this"

### NEVER

- **Never auto-sharpen direct commands.** "Run tests", "commit", "show status" are
  instructions, not vague prompts. Sharpening them wastes time and annoys the user.
- **Never change the user's core intent.** Sharpening adds structure and specificity —
  it does not redirect the task. If the user said "refactor auth", the sharpened version
  must still be about refactoring auth, not redesigning the auth architecture.
- **Never over-engineer simple tasks.** A prompt asking to fix a typo does not need RISEN
  with five steps. Match framework weight to task weight.
- **Never ask more than 3 clarifying questions in Mode B.** Beyond 3, you're stalling
  momentum. If you can't build a good prompt from the intent + 3 questions, the user
  needs to think more, not answer more questions.
- **Never output a sharpened prompt longer than the task warrants.** A 500-word structured
  prompt for a 5-minute task is a smell. The prompt should be proportional to the work.
- **Never apply frameworks mechanically.** The framework is a thinking aid, not a form to
  fill in. Skip sections that don't apply. An RTF prompt with an empty Format field is
  worse than a plain instruction with no framework at all.

---

## Mode B: Prompt Builder

Triggered by `/prompt:create` command.

### Flow

1. **Receive rough intent** — The user describes what they want in plain language.

2. **Categorize** — Classify the intent into one of four categories:
   - **Technical**: Code generation, debugging, review, architecture
   - **Creative**: Brainstorming, naming, copy, UX writing
   - **Analysis**: Performance, security, comparison, complexity
   - **Transformation**: Migration, conversion, summarization

3. **Select framework** — Choose the best framework based on category and complexity:
   | Category | Default Framework | Upgrade When |
   |----------|------------------|--------------|
   | Technical | RTF | Multi-step → RISEN |
   | Creative | RODES | Simple → RTF |
   | Analysis | Chain-of-Thought | Design/arch → RODES |
   | Transformation | RTF | Complex → RISEN |

4. **Ask clarifying questions** — If the intent is ambiguous, ask 2-3 targeted
   questions. Keep them specific, not open-ended. Examples:
   - "What's the target audience for this output?"
   - "Should the output include code examples or just prose?"
   - "What's the max acceptable length?"

   Skip clarifying questions when:
   - The intent is clear enough to produce a good prompt
   - The user said "just do it" or similar urgency signals

5. **Apply framework** — Build the prompt using the selected framework structure.
   Follow the instruction hierarchy:
   `[System Context] → [Task Instruction] → [Examples] → [Input Data] → [Output Format]`

6. **Run audit checklist** — Verify the prompt against all six checks before output.

7. **Present output** — Show the polished prompt in a code block, then ask:
   > Copy this, or execute it here?

---

## Diagnostic Patterns

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| Vague output | Vague prompt | Add specifics, constraints, output format |
| No structure | Missing format spec | Add explicit output format (bullets, table, code block) |
| Hallucination | No grounding | Add grounding context, verification step, source constraints |
| Verbose output | No length constraint | Add word/line limits, compression instruction |
| Inconsistent results | Ambiguous instructions | Lower temperature, add examples, remove wiggle room |
| Off-topic tangents | Missing scope | Add "do not" constraints, narrow the domain |
| Wrong tone | No role defined | Add explicit role and audience |

### How to use this table

When analyzing a prompt (Mode A) or building one (Mode B), scan for symptoms
that the current prompt would produce. Then apply the corresponding fix before
the prompt is finalized.

---

## Audit Checklist

Run this against every prompt before it's considered complete.

1. **Clear role defined** — Does the prompt specify who the agent should be?
   If not, add a role statement.

2. **Explicit output format** — Does the prompt say what the output looks like?
   (Code block, bullet list, YAML, prose paragraph, table, etc.)

3. **Edge case handling** — Does the prompt account for unusual inputs or
   ambiguous situations? Add "if X, then Y" clauses for known edge cases.

4. **Appropriate length/detail** — Is there a length constraint? Does the
   requested detail level match the task? Over-specifying simple tasks wastes
   tokens; under-specifying complex tasks produces garbage.

5. **Tested on variations** — Would this prompt produce consistent results
   across different inputs? If not, add examples or tighten constraints.

6. **Hallucination risk addressed** — Is the prompt grounded? Does it reference
   specific files, data, or context? If the task involves facts, add a
   verification step or source constraint.

### Scoring

- 6/6: Ship it.
- 4-5/6: Acceptable, note which items are weak.
- Below 4: Rework before presenting.
