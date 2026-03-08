---
name: plan-create
description: Create a wave-based execution plan from a task description
user_invocable: true
arguments:
  - name: description
    description: "Description of the work to plan, or path to a task list file"
    required: true
---

# /plan:create

Generate a wave-based execution plan with dependency ordering, file-ownership isolation, and verification gates.

## Steps

1. **Parse input:**
   - If `$ARGUMENTS` is a file path → read the task list from the file
   - If `$ARGUMENTS` is a description → decompose it into tasks interactively:
     a. Identify the logical units of work
     b. Define dependencies between them
     c. List files each task will write and read
     d. Present the task list for user confirmation

2. **Create plan directory** at `.ai/plans/{plan-name}/`
   - Derive plan name from the description (lowercase, hyphens, concise)

3. **Run plan-engine skill** with the task list:
   - Topological sort into waves
   - File-ownership conflict resolution
   - Model-tier assignment
   - Verification setup

4. **Present the plan** to the user:
   ```
   Plan: {name}
   {total_tasks} tasks across {total_waves} waves

   Wave 1 (parallel): t1, t3
     → Verification: data_validation
   Wave 2 (parallel): t2, t4
     → Verification: data_validation
   Wave 3: t5
     → Verification: integration_test + QA review
   ```

5. **Confirm:** "Plan saved to `.ai/plans/{name}/plan.yml`. Run `/plan:execute` to start."

## Notes

- Plans are domain-agnostic — they work for any type of work, not just plugins
- File-ownership isolation enables safe parallel execution
- The A/B benchmark gate can be included as a verification type for skill-building plans
