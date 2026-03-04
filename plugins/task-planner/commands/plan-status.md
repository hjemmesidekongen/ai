---
name: plan-status
command: "/plan:status"
description: "(plan) Show the current state of a plan: progress, failures, and next steps"
arguments:
  - name: plan_file
    type: string
    required: false
    description: "Path to a specific plan file. If omitted, shows all plans in .ai/plans/"
  - name: verbose
    type: boolean
    required: false
    default: false
    description: "Show detailed check results and recovery notes"
---

# /plan:status

Displays the current state of one or all plans. Shows wave progress, task completion, verification results, and any failures.

## Usage

```
/plan:status                                                        # all plans
/plan:status .ai/plans/brand-generate-acme-corp/plan.yml            # specific plan
/plan:status .ai/plans/brand-generate-acme-corp/plan.yml --verbose
```

## Execution Steps

### Step 1: Find Plans

**If plan_file provided:** Read that plan and its state file.

**If no plan_file:** Scan `.ai/plans/` for all `*/state.yml` files. If no `.ai/plans/` directory or no state files found:

```
No plans found. Run `/plan:create` to generate a plan.
```

### Step 2: Read State

For each plan, read:
1. The state file (`state.yml` in the plan directory) — execution progress
2. The plan file (`plan.yml` in the plan directory) — wave and task definitions

If the state file is missing but the plan file exists, report:
```
Plan exists but has not been executed yet.
Run `/plan:execute .ai/plans/[name]/plan.yml` to start.
```

### Step 3: Display Status

#### Multi-Plan Summary (no plan_file specified)

```
## Plans

| Plan | Status | Progress | Current Wave | Updated |
|------|--------|----------|--------------|---------|
| brand-generate-acme-corp | in_progress | 2/4 waves | Wave 3 | 10 min ago |
| site-build-marketing | completed | 5/5 waves | — | 2 hours ago |
| seo-audit-homepage | failed | 1/3 waves | Wave 2 (failed) | 1 hour ago |

Run `/plan:status .ai/plans/[name]/plan.yml` for details.
```

#### Single Plan Detail

```
## Plan: brand-generate-acme-corp

**Status:** in_progress
**Progress:** 2 of 4 waves completed (5 of 8 tasks done)
**Started:** 2026-02-28 14:30
**Last updated:** 2026-02-28 15:12 (42 min ago)
**Execution mode:** single-agent
**Verification profile:** brand

### Waves

  Wave 1  ✓ completed
    ├─ t1: Generate color palette ✓
    └─ t2: Generate typography system ✓
    Verification: data_validation ✓

  Wave 2  ✓ completed
    ├─ t3: Generate logo concepts ✓
    └─ t4: Generate icon library ✓
    Verification: file_validation ✓

  Wave 3  ● in_progress
    ├─ t5: Generate favicons ✓
    ├─ t6: Generate app icons ● in_progress
    └─ t7: Generate social images ○ pending
    Verification: not yet run

  Wave 4  ○ pending
    └─ t8: Compile brand manual ○ pending
    QA Review: scheduled

### Next Steps
  Currently executing: t6 (Generate app icons)
  After wave 3: file_validation check, then wave 4
```

#### Failed Plan Detail

When a plan has failures, show them prominently:

```
## Plan: seo-audit-homepage

**Status:** failed (wave 2 verification)
**Progress:** 1 of 3 waves completed

### Failure

  Wave 2  ✗ failed (verification)
    ├─ t3: Generate meta descriptions ✓
    └─ t4: Generate structured data ✓
    Verification: data_validation ✗
      ✗ "Structured data missing @type field in 3 entries"
      Fix attempted: 2 of 3 rounds

### Recovery Options
  - `/plan:resume .ai/plans/seo-audit-homepage/plan.yml` — retry from wave 2
  - `/plan:execute .ai/plans/seo-audit-homepage/plan.yml --start-wave 2` — restart wave 2
```

### Step 4: Verbose Output (--verbose)

When `--verbose` is set, additionally show:

1. **Verification details** for each completed wave:
   ```
   Wave 1 verification (data_validation):
     ✓ brand-reference.yml colors section complete
       Found: primary (3), secondary (2), neutral (5), semantic (4)
     ✓ brand-reference.yml typography section complete
       Found: heading, body, mono families with all required fields
   ```

2. **QA report** if QA was run:
   ```
   Wave 4 QA report:
     ✓ Requirements coverage — all 8 tasks satisfied
     ✓ Cross-reference integrity — 23 refs checked, all valid
     ⚠ Output quality — logo-mark-full.svg is 87KB (consider optimizing)
     Verdict: pass_with_warnings
   ```

3. **Recovery notes** from the state file (falls back to plan file):
   ```
   Recovery notes:
     Wave 2 completed. Logo concepts generated in 3 variants
     (full, mark, wordmark). Icon library has 24 icons using
     primary blue. Next: wave 3 generates derived assets from logo.
   ```

4. **File ownership map:**
   ```
   File ownership (wave 3):
     t5 owns: assets/favicons/*
     t6 owns: assets/app-icons/*
     t7 owns: assets/social/*
     No conflicts.
   ```
