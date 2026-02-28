# Wave Decomposer

Takes a flat list of tasks with dependencies and produces an optimized wave plan that maximizes parallelism while respecting dependency ordering and file-ownership constraints.

## Input

The consuming plugin provides:

```yaml
name: "plan-name-here"
verification_profile: "brand"   # optional — brand | web | seo | content

tasks:
  - id: "t1"
    name: "Human-readable task name"
    depends_on: []                          # task ids — empty for root tasks
    files_written: ["path/to/file.yml#section"]  # ownership claims
    files_read: ["other-file.yml"]          # read-only, no conflicts
    estimated_minutes: 5                    # optional
```

### Input Rules

- Every `id` must be unique within the plan
- `depends_on` may only reference ids that exist in the task list
- `depends_on` must not contain cycles (A→B→A is invalid)
- `files_written` must be present even if empty — it drives conflict detection

## Algorithm

### Step 1: Dependency Resolution (Topological Sort)

Find all tasks whose `depends_on` list is empty or fully satisfied by already-assigned tasks. These form the next wave.

```
remaining = all tasks
wave_number = 1

while remaining is not empty:
  ready = [t for t in remaining where all t.depends_on are assigned]

  if ready is empty and remaining is not empty:
    ERROR: circular dependency detected

  assign ready tasks to wave_number
  remove ready from remaining
  wave_number += 1
```

### Step 2: File-Ownership Conflict Check

Within each wave, check that no two tasks write to overlapping files. Overlap rules:

| Task A writes | Task B writes | Conflict? |
|---------------|---------------|-----------|
| `file.yml#colors` | `file.yml#typography` | No — different sections |
| `file.yml#colors` | `file.yml#colors` | **Yes** — same section |
| `file.yml` | `file.yml` | **Yes** — whole-file overlap |
| `file.yml` | `file.yml#colors` | **Yes** — whole-file includes all sections |
| `assets/icons/*` | `assets/logos/*` | No — different directories |
| `assets/icons/*` | `assets/icons/*` | **Yes** — same glob |
| `assets/*` | `assets/icons/*` | **Yes** — parent glob includes child |

When a conflict is found within a wave, move the conflicting task (the one with fewer dependents downstream) to the next wave. Re-run conflict check on the modified wave.

```
for each wave:
  conflicts = find_overlapping_files(wave.tasks)

  while conflicts is not empty:
    task_to_move = pick_task_with_fewer_dependents(conflicts)
    move task_to_move to next wave (create new wave if needed)
    conflicts = find_overlapping_files(wave.tasks)
```

### Step 3: Set Parallel Flag

A wave is `parallel: true` when it has more than one task and no file conflicts remain. A wave with a single task is `parallel: false`.

### Step 4: Compute Wave Dependencies

For each wave, `depends_on_waves` is the set of waves that contain any task referenced in the current wave's tasks' `depends_on` lists:

```
for each wave W:
  W.depends_on_waves = unique set of wave numbers containing
    any task id referenced in any W.task.depends_on
```

### Step 5: Assign Verification

Each wave needs a `verification` block. The type is determined by what the wave produces:

| Wave produces | Verification type |
|---------------|-------------------|
| YAML data sections | `data_validation` |
| Asset files (SVG, PNG) | `file_validation` |
| Code files | `web_lint` + `web_build` |
| Final compilation | `schema_validation` |

If a `verification_profile` is provided, use its `after_each_wave` types. Otherwise, infer from `files_written` patterns.

Generate `checks` that are specific to this wave's tasks — not generic. Each check should name the concrete artifact being verified.

### Step 6: Set QA Review Flag

- The **final wave** always has `qa_review: true`
- If the verification profile specifies `qa_frequency: "every_wave"`, all waves get `qa_review: true`
- Otherwise, only the final wave

### Step 7: Emit Plan

Output the plan in the format defined by `resources/plan-schema.yml`. All statuses start as `pending`. All verification `passed` fields start as `null`.

## Output

The output conforms to `plan-schema.yml`:

```yaml
plan:
  name: "plan-name-here"
  created_at: "2026-02-28T14:30:00Z"
  total_tasks: <count>
  total_waves: <count>
  estimated_minutes: <sum of task estimates>
  status: pending
  verification_profile: "brand"

  tasks:
    - id: "t1"
      name: "..."
      depends_on: []
      files_written: [...]
      files_read: [...]
      estimated_minutes: 5
      status: pending
    # ... all tasks from input, with status: pending added

  waves:
    - wave: 1
      parallel: true
      tasks: ["t1", "t2"]
      depends_on_waves: []
      rationale: "..."
      status: pending
      verification:
        type: "data_validation"
        checks: ["...", "..."]
        passed: null
      qa_review: false
    # ... remaining waves

  recovery_notes: null
  last_session_id: null
```

## Example: Brand Guideline Generation

### Input

```yaml
name: "brand-generate-acme-corp"
verification_profile: "brand"

tasks:
  - id: "t1"
    name: "Generate color palette"
    depends_on: []
    files_written: ["brand-reference.yml#colors"]
    estimated_minutes: 5

  - id: "t2"
    name: "Generate typography system"
    depends_on: []
    files_written: ["brand-reference.yml#typography"]
    estimated_minutes: 5

  - id: "t3"
    name: "Generate logo concepts"
    depends_on: ["t1", "t2"]
    files_written: ["assets/logo/svg/*"]
    estimated_minutes: 15

  - id: "t4"
    name: "Generate icon library"
    depends_on: ["t1"]
    files_written: ["assets/icons/*"]
    estimated_minutes: 10

  - id: "t5"
    name: "Generate favicons"
    depends_on: ["t3"]
    files_written: ["assets/favicons/*"]
    estimated_minutes: 5

  - id: "t6"
    name: "Generate app icons"
    depends_on: ["t3"]
    files_written: ["assets/app-icons/*"]
    estimated_minutes: 5

  - id: "t7"
    name: "Generate social images"
    depends_on: ["t3"]
    files_written: ["assets/social/*"]
    estimated_minutes: 5

  - id: "t8"
    name: "Compile brand manual"
    depends_on: ["t1", "t2", "t3", "t4", "t5", "t6", "t7"]
    files_written: ["brand-manual.md", "brand-manual.docx"]
    estimated_minutes: 10
```

### Algorithm Trace

**Step 1 — Dependency resolution:**

- Wave 1: t1, t2 (no dependencies)
- Wave 2: t3 (needs t1, t2), t4 (needs t1) — all met after wave 1
- Wave 3: t5, t6, t7 (all need t3) — met after wave 2
- Wave 4: t8 (needs all) — met after wave 3

**Step 2 — File-ownership check:**

- Wave 1: t1 writes `brand-reference.yml#colors`, t2 writes `brand-reference.yml#typography` → different sections, no conflict
- Wave 2: t3 writes `assets/logo/svg/*`, t4 writes `assets/icons/*` → different directories, no conflict
- Wave 3: t5, t6, t7 each write to separate directories → no conflict
- Wave 4: single task → no conflict possible

No tasks need to be moved.

**Step 3 — Parallel flags:** Waves 1, 2, 3 have multiple tasks → `parallel: true`. Wave 4 has one task → `parallel: false`.

**Step 4 — Wave dependencies:** Wave 1 → none. Wave 2 → [1]. Wave 3 → [2]. Wave 4 → [1, 2, 3].

**Step 5 — Verification:** Profile is "brand", so `after_each_wave` uses `data_validation`. But waves 2 and 3 produce files, so `file_validation` is more appropriate. Final wave uses `schema_validation`.

**Step 6 — QA:** Brand profile has `qa_frequency: "final"`, so only wave 4 gets `qa_review: true`.

### Output

```yaml
plan:
  name: "brand-generate-acme-corp"
  created_at: "2026-02-28T14:30:00Z"
  total_tasks: 8
  total_waves: 4
  estimated_minutes: 60
  status: pending
  verification_profile: "brand"

  tasks:
    - id: "t1"
      name: "Generate color palette"
      depends_on: []
      files_written: ["brand-reference.yml#colors"]
      estimated_minutes: 5
      status: pending
    - id: "t2"
      name: "Generate typography system"
      depends_on: []
      files_written: ["brand-reference.yml#typography"]
      estimated_minutes: 5
      status: pending
    - id: "t3"
      name: "Generate logo concepts"
      depends_on: ["t1", "t2"]
      files_written: ["assets/logo/svg/*"]
      estimated_minutes: 15
      status: pending
    - id: "t4"
      name: "Generate icon library"
      depends_on: ["t1"]
      files_written: ["assets/icons/*"]
      estimated_minutes: 10
      status: pending
    - id: "t5"
      name: "Generate favicons"
      depends_on: ["t3"]
      files_written: ["assets/favicons/*"]
      estimated_minutes: 5
      status: pending
    - id: "t6"
      name: "Generate app icons"
      depends_on: ["t3"]
      files_written: ["assets/app-icons/*"]
      estimated_minutes: 5
      status: pending
    - id: "t7"
      name: "Generate social images"
      depends_on: ["t3"]
      files_written: ["assets/social/*"]
      estimated_minutes: 5
      status: pending
    - id: "t8"
      name: "Compile brand manual"
      depends_on: ["t1", "t2", "t3", "t4", "t5", "t6", "t7"]
      files_written: ["brand-manual.md", "brand-manual.docx"]
      estimated_minutes: 10
      status: pending

  waves:
    - wave: 1
      parallel: true
      tasks: ["t1", "t2"]
      depends_on_waves: []
      rationale: "No dependencies — colors and typography are independent"
      status: pending
      verification:
        type: "data_validation"
        checks:
          - "brand-reference.yml colors section complete"
          - "brand-reference.yml typography section complete"
        passed: null
      qa_review: false

    - wave: 2
      parallel: true
      tasks: ["t3", "t4"]
      depends_on_waves: [1]
      rationale: "Both need wave 1 outputs. Logo and icons write to separate directories."
      status: pending
      verification:
        type: "file_validation"
        checks:
          - "SVG logos exist and are valid"
          - "Icon SVGs exist with consistent viewBox"
        passed: null
      qa_review: false

    - wave: 3
      parallel: true
      tasks: ["t5", "t6", "t7"]
      depends_on_waves: [2]
      rationale: "All need logo mark from wave 2. Each writes to a separate directory."
      status: pending
      verification:
        type: "file_validation"
        checks:
          - "Favicon SVG exists with dark mode media query"
          - "iOS app icons present in all required sizes"
          - "OG image is 1200x630"
        passed: null
      qa_review: false

    - wave: 4
      parallel: false
      tasks: ["t8"]
      depends_on_waves: [1, 2, 3]
      rationale: "Final compilation — needs all previous outputs"
      status: pending
      verification:
        type: "schema_validation"
        checks:
          - "brand-reference.yml validates against schema"
          - "brand-manual.md has all required sections"
        passed: null
      qa_review: true

  recovery_notes: null
  last_session_id: null
```

## Example: File-Ownership Conflict Resolution

When two tasks in the same wave write to overlapping files, the decomposer must split them.

### Input (Conflict Case)

```yaml
name: "conflict-example"

tasks:
  - id: "t1"
    name: "Write header styles"
    depends_on: []
    files_written: ["styles/global.css"]

  - id: "t2"
    name: "Write footer styles"
    depends_on: []
    files_written: ["styles/global.css"]

  - id: "t3"
    name: "Write page layout"
    depends_on: ["t1", "t2"]
    files_written: ["styles/layout.css"]
```

### Algorithm Trace

**Step 1:** t1 and t2 have no dependencies → both assigned to wave 1.

**Step 2:** Conflict — t1 and t2 both write to `styles/global.css`. t3 depends on both, so both have equal downstream dependents. Break tie by task order: keep t1 in wave 1, move t2 to wave 2.

**Step 3:** Wave 1 now has one task → `parallel: false`. Wave 2 has one task → `parallel: false`.

### Output

```yaml
plan:
  name: "conflict-example"
  created_at: "2026-02-28T14:30:00Z"
  total_tasks: 3
  total_waves: 3
  estimated_minutes: null
  status: pending

  tasks:
    - id: "t1"
      name: "Write header styles"
      depends_on: []
      files_written: ["styles/global.css"]
      status: pending
    - id: "t2"
      name: "Write footer styles"
      depends_on: []
      files_written: ["styles/global.css"]
      status: pending
    - id: "t3"
      name: "Write page layout"
      depends_on: ["t1", "t2"]
      files_written: ["styles/layout.css"]
      status: pending

  waves:
    - wave: 1
      parallel: false
      tasks: ["t1"]
      depends_on_waves: []
      rationale: "t2 moved to wave 2 due to file conflict on styles/global.css"
      status: pending
      verification:
        type: "file_validation"
        checks: ["styles/global.css exists and is valid CSS"]
        passed: null
      qa_review: false

    - wave: 2
      parallel: false
      tasks: ["t2"]
      depends_on_waves: [1]
      rationale: "Writes to styles/global.css — must run after t1 (same file)"
      status: pending
      verification:
        type: "file_validation"
        checks: ["styles/global.css updated with footer styles"]
        passed: null
      qa_review: false

    - wave: 3
      parallel: false
      tasks: ["t3"]
      depends_on_waves: [1, 2]
      rationale: "Depends on both header and footer styles being written"
      status: pending
      verification:
        type: "file_validation"
        checks: ["styles/layout.css exists and is valid CSS"]
        passed: null
      qa_review: true

  recovery_notes: null
  last_session_id: null
```

## Error Cases

### Circular Dependency

If step 1 produces an empty `ready` set while tasks remain, there is a cycle:

```
ERROR: Circular dependency detected.
Tasks involved: [t1, t3, t5]
Cycle: t1 → t3 → t5 → t1
Resolution: The consuming plugin must fix the dependency graph before re-running.
```

### Duplicate Task IDs

```
ERROR: Duplicate task id "t3" found.
Resolution: Every task id must be unique within the plan.
```

### Missing Dependency Reference

```
ERROR: Task "t4" depends on "t99" which does not exist.
Resolution: All depends_on entries must reference valid task ids.
```
