# Skill Quality Dimensions

When creating skills, target these 8 dimensions. The skill-auditor agent scores against this framework (120 points total).

## Core Formula

> **Good Skill = Expert-only Knowledge − What Claude Already Knows**

A skill's value is its **knowledge delta** — the gap between what it provides and what the model already knows.

## Three Knowledge Types

| Type | Definition | Treatment |
|------|------------|-----------|
| **Expert** | Claude genuinely doesn't know this | Must keep — this is the skill's value |
| **Activation** | Claude knows but may not think of | Keep if brief — serves as reminder |
| **Redundant** | Claude definitely knows this | Delete — wastes tokens |

Target: >70% Expert, <20% Activation, <10% Redundant

## The 8 Dimensions

### D1: Knowledge Delta (20 pts)
Does every paragraph earn its tokens? Avoid: "What is X" explanations, standard tutorials, generic best practices. Include: decision trees, expert trade-offs, real-world edge cases, "NEVER do X because [non-obvious reason]".

### D2: Mindset + Domain Procedures (15 pts)
Transfer thinking patterns ("Before X, ask yourself...") AND domain-specific procedures Claude wouldn't know. Delete generic procedures ("open file, edit, save").

### D3: Anti-Pattern Quality (15 pts)
Specific NEVER lists with WHY. Expert anti-patterns include the non-obvious reason. "NEVER use X because [thing that takes experience to learn]" beats "be careful with X".

### D4: Description Compliance (15 pts)
Description must answer: WHAT (capabilities), WHEN (trigger scenarios), KEYWORDS (searchable terms). Poor description = skill never gets activated, regardless of content quality.

### D5: Progressive Disclosure (15 pts)
Three layers: metadata (always loaded), SKILL.md ≤80 lines (on activate), references/ (on demand). Embed loading triggers in workflow: "MANDATORY — read [file] before proceeding."

### D6: Freedom Calibration (15 pts)
Match constraint to fragility: creative → high freedom (principles), review → medium (priorities), file operations → low (exact scripts). Test: "If agent makes a mistake, what breaks?"

### D7: Pattern Recognition (10 pts)
Five skill patterns:
- **Mindset** (~50 lines): Thinking > technique, strong NEVER list. For creative tasks.
- **Navigation** (~30 lines): Minimal router to sub-files. For multiple scenarios.
- **Philosophy** (~80 lines): Craft emphasis, originality. For art/creation.
- **Process** (~80 lines): Phased workflow, checkpoints. For complex projects.
- **Tool** (~80 lines): Decision trees, code examples. For precise operations.

### D8: Practical Usability (15 pts)
Decision trees for multi-path scenarios. Working examples. Error handling with fallbacks. Edge cases. Immediately actionable — no figuring out needed.

## 9 Failure Patterns to Avoid

1. **The Tutorial**: Explains basics Claude already knows → delete, focus on expert knowledge
2. **The Dump**: Everything in SKILL.md → move heavy content to references/
3. **The Orphan References**: References exist but no loading triggers → add MANDATORY triggers
4. **The Checkbox Procedure**: Mechanical steps → transform to "Before X, ask yourself..."
5. **The Vague Warning**: "Be careful" → specific NEVER + WHY
6. **The Invisible Skill**: Poor description → skill never activated. Fix: WHAT + WHEN + KEYWORDS
7. **The Wrong Location**: Trigger info in body not description → move to description field
8. **The Over-Engineered**: README, CHANGELOG alongside SKILL.md → delete auxiliary files
9. **The Freedom Mismatch**: Wrong constraint level → match freedom to task fragility
