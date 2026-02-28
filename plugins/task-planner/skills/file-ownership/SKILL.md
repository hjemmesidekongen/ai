# File Ownership

Assigns and enforces file-level and section-level ownership across tasks within a wave plan. Prevents parallel agents from writing to the same files. Produces a `file-ownership-registry.yml` that the execution engine uses to validate agent writes at runtime.

## When This Skill Runs

1. **During plan creation** — The wave-decomposer calls this skill in step 2 to detect and resolve conflicts before the plan is finalized.
2. **Before plan execution** — The `plan-execute` command calls this skill as a pre-flight check to validate the plan is conflict-free.
3. **On demand** — The `check-file-conflicts.sh` script wraps the same logic for use in CI or hooks.

## Input

A wave plan conforming to `resources/plan-schema.yml`. The skill reads two fields from each task:

- `files_written` — Paths this task will write to (ownership claims)
- `files_read` — Paths this task reads from (no ownership, no conflicts)

## Ownership Model

### Path Types

Paths in `files_written` come in three forms:

| Form | Example | Meaning |
|------|---------|---------|
| Exact file | `styles/global.css` | Task owns the entire file |
| Section | `brand-reference.yml#colors` | Task owns one YAML top-level key in the file |
| Glob | `assets/icons/*` | Task owns all files matching the pattern |

### Section-Level Ownership

Shared YAML files (like `brand-reference.yml`) can have multiple writers in the same wave as long as each writer claims a different section. A section is a YAML top-level key, referenced with `#`:

```yaml
# Two tasks in the same wave — NO conflict:
- task: "t1"
  files_written: ["brand-reference.yml#colors"]
- task: "t2"
  files_written: ["brand-reference.yml#typography"]

# Two tasks in the same wave — CONFLICT:
- task: "t1"
  files_written: ["brand-reference.yml#colors"]
- task: "t2"
  files_written: ["brand-reference.yml#colors"]
```

### Overlap Detection Rules

Two paths overlap when one task's write could clobber another task's write. Checked pairwise within each wave:

| Path A | Path B | Overlap? | Reason |
|--------|--------|----------|--------|
| `file.yml#colors` | `file.yml#typography` | No | Different sections |
| `file.yml#colors` | `file.yml#colors` | **Yes** | Same section |
| `file.yml` | `file.yml` | **Yes** | Same whole file |
| `file.yml` | `file.yml#colors` | **Yes** | Whole-file claim includes all sections |
| `assets/icons/*` | `assets/logos/*` | No | Different directories |
| `assets/icons/*` | `assets/icons/*` | **Yes** | Identical glob |
| `assets/*` | `assets/icons/*` | **Yes** | Parent glob includes child |
| `assets/icons/check.svg` | `assets/icons/*` | **Yes** | Exact file inside glob |
| `src/a.ts` | `src/b.ts` | No | Different files |

### Path Comparison Algorithm

```
function paths_overlap(a, b):
  a_file, a_section = split_on_hash(a)
  b_file, b_section = split_on_hash(b)

  # Step 1: Do the base files/globs overlap?
  if not files_match(a_file, b_file):
    return false

  # Step 2: If both have sections, compare sections
  if a_section and b_section:
    return a_section == b_section

  # Step 3: If one has a section and the other doesn't,
  # the whole-file claim includes all sections
  return true


function files_match(a, b):
  # Exact match
  if a == b: return true

  # Glob containment (either direction)
  if glob_contains(a, b): return true
  if glob_contains(b, a): return true

  return false


function glob_contains(pattern, path):
  # "assets/*" contains "assets/icons/check.svg"
  # "assets/*" contains "assets/icons/*"
  # Uses standard glob matching with ** for recursive
  return path matches pattern, or
         pattern is a parent directory of path
```

## Conflict Resolution

When two tasks in the same wave have overlapping `files_written`, one must move to a later wave. The resolution strategy:

1. **Count downstream dependents** — For each conflicting task, count how many other tasks (directly or transitively) depend on it.
2. **Keep the task with more dependents** — Moving it would cascade more disruption.
3. **Move the other task to the next wave** — If no next wave exists, create one.
4. **Tie-break by task order** — If dependent counts are equal, keep the task that appears first in the task list (lower index stays).
5. **Re-check the modified wave** — Moving a task may resolve all conflicts or reveal new ones. Loop until the wave is clean.
6. **Re-check the target wave** — The moved task may conflict with tasks already in the next wave. Run the same check there.

```
function resolve_conflicts(plan):
  for wave_index in 0..plan.waves.length:
    wave = plan.waves[wave_index]

    conflicts = find_conflicts(wave.tasks, plan.tasks)

    while conflicts is not empty:
      # Pick which task to move
      task_a, task_b, conflicting_path = conflicts[0]
      dependents_a = count_downstream(task_a, plan.tasks)
      dependents_b = count_downstream(task_b, plan.tasks)

      if dependents_a > dependents_b:
        victim = task_b
      elif dependents_b > dependents_a:
        victim = task_a
      else:
        # Tie-break: keep the one with lower index in task list
        victim = whichever appears later in plan.tasks

      # Move victim to next wave
      remove victim from wave.tasks
      next_wave = get_or_create_next_wave(plan, wave_index)
      add victim to next_wave.tasks

      # Update wave metadata
      if wave.tasks.length == 1:
        wave.parallel = false
      next_wave.depends_on_waves = union(next_wave.depends_on_waves, [wave.wave])

      # Re-check current wave
      conflicts = find_conflicts(wave.tasks, plan.tasks)

    # After current wave is clean, later waves will be checked
    # in subsequent iterations of the outer loop
```

## Output: file-ownership-registry.yml

After resolving all conflicts, the skill emits a registry file listing every agent's ownership claims and read permissions:

```yaml
# file-ownership-registry.yml
# Generated from plan: brand-generate-acme-corp
# Generated at: 2026-02-28T14:30:00Z

plan: "brand-generate-acme-corp"

ownership:
  - task: "t1"
    agent: null          # Assigned during execution
    wave: 1
    owns:
      - "brand-reference.yml#colors"
    reads:
      - "brand-reference.yml#identity"

  - task: "t2"
    agent: null
    wave: 1
    owns:
      - "brand-reference.yml#typography"
    reads:
      - "brand-reference.yml#identity"

  - task: "t3"
    agent: null
    wave: 2
    owns:
      - "assets/logo/svg/*"
    reads:
      - "brand-reference.yml#colors"
      - "brand-reference.yml#typography"

  - task: "t4"
    agent: null
    wave: 2
    owns:
      - "assets/icons/*"
    reads:
      - "brand-reference.yml#colors"

  - task: "t5"
    agent: null
    wave: 3
    owns:
      - "assets/favicons/*"
    reads:
      - "assets/logo/svg/*"

  - task: "t6"
    agent: null
    wave: 3
    owns:
      - "assets/app-icons/*"
    reads:
      - "assets/logo/svg/*"

  - task: "t7"
    agent: null
    wave: 3
    owns:
      - "assets/social/*"
    reads:
      - "assets/logo/svg/*"
      - "brand-reference.yml#colors"

  - task: "t8"
    agent: null
    wave: 4
    owns:
      - "brand-manual.md"
      - "brand-manual.docx"
    reads:
      - "brand-reference.yml"
      - "assets/**"

# Conflict summary
conflicts_found: 0
conflicts_resolved: 0
tasks_moved: []
```

### When Conflicts Were Resolved

If the skill moved tasks during resolution, the registry documents what happened:

```yaml
conflicts_found: 1
conflicts_resolved: 1
tasks_moved:
  - task: "t2"
    from_wave: 1
    to_wave: 2
    reason: "File conflict on styles/global.css with t1"
    resolution: "t1 kept in wave 1 (equal dependents, lower task index)"
```

## Runtime Enforcement

During plan execution, the execution engine uses the registry to validate agent behavior:

1. **Before an agent starts** — Load the registry entry for its task. The agent receives its `owns` and `reads` lists.
2. **Write validation** — If an agent attempts to write to a path not in its `owns` list, the write is blocked and logged.
3. **Cross-wave safety** — Between waves, ownership transfers implicitly. Wave 2 agents can read outputs from wave 1 even if wave 1 agents owned those files — ownership is scoped to the wave.

## Validation: check-file-conflicts.sh

The `scripts/check-file-conflicts.sh` script performs the same conflict detection as a standalone check. It reads the plan file, checks for overlapping `files_written` within each wave, and exits 0 (clean) or 1 (conflicts found). Use it in CI, pre-commit hooks, or as a manual sanity check.
