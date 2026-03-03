# QA Validation — Detailed Process

## Overview

The QA validator is Phase 4b of /agency:build. It validates the entire build against
the original spec, assesses whether the user's stated goal was achieved, calculates
a spec alignment score, and generates a comprehensive build report. This is the
final quality gate before the build is considered complete.

## Prerequisites

Before starting, verify:
1. `.ai/projects/[name]/project-state.yml` has `review.code_review.status == "passed"` (no critical findings)
2. `decomposition` section exists with components and boundaries
3. `execution.dispatched_tasks` has completed tasks with reports
4. `build.feature_description` has the user's original request
5. If code review status is "failed", report error — code review must pass first

## Step 1: Load Validation Context

```
Read project-state.yml → decomposition (components, boundaries, files_affected)
Read project-state.yml → execution.dispatched_tasks (all reports)
Read project-state.yml → review.code_review (findings, status)
Read project-state.yml → build.feature_description (original user intent)
Read .ai/projects/[name]/dev/dev-config.yml → project context (framework, structure)
Read plugins/agency/resources/templates/build-report-template.md → report format
```

**Save context summary to findings.md (2-Action Rule checkpoint).**

## Step 2: QA Assessment — Spec Alignment

For each component in `decomposition.components`, evaluate implementation completeness:

### a. Task Coverage
- Does at least one task in `execution.dispatched_tasks` map to this component?
- If no task maps: component is "missing" — counts against alignment

### b. File Coverage
- Do the `files_changed` from the task report match the `files_affected` in the decomposition?
- Missing files: component is "partial" — counts partially

### c. Gate Results
- Did the component's tasks pass all gates (build_passed, lint_passed, tests_passed)?
- Gate failures: component is "quality_degraded"

### d. Code Review Status
- Are there any critical findings for this component's files?
- Critical findings should already be resolved (code review passed), but verify

### e. Component Scoring

For each component, assign a status:

| Status | Meaning | Score Contribution |
|--------|---------|-------------------|
| **implemented** | Task completed, files match, gates pass | 1.0 |
| **partial** | Task completed, some files missing or extra | 0.5 |
| **quality_degraded** | Implemented but gate failures or warnings | 0.3 |
| **missing** | No corresponding task executed | 0.0 |

**Save findings after every 2 components assessed (2-Action Rule checkpoint).**

## Step 3: Calculate Spec Alignment Score

```
raw_score = sum(component_scores) / total_components × 100

quality_factor:
  1.0 — all gates pass and no code review findings
  0.8 — warnings exist but no critical findings
  0.5 — gate failures exist (even if resolved)

spec_alignment = raw_score × quality_factor
```

**Decision logic:**
- If `spec_alignment >= 70`: status = "passed"
- If `spec_alignment < 70`: status = "failed" — list specific gaps in notes

## Step 4: PO Assessment — End-Goal Alignment

The PO (Product Owner) assessment evaluates whether the implementation achieves
the user's original stated goal, beyond just spec alignment.

### Assessment Criteria

1. **Goal Achievement:** Does the implementation solve the problem the user described?
   - Read `build.feature_description` — the original request
   - Compare against what was actually built (from execution reports)
   - Consider: the user asked for X, did they get X?

2. **Scope Deviations:** Was anything added or omitted beyond the original request?
   - Added: features not in the original description (scope creep)
   - Omitted: requirements mentioned but not implemented (gaps)

3. **Usability:** Can the user actually use what was built?
   - Are there clear entry points?
   - Are dependencies documented?
   - Is the output accessible (not buried in internal files)?

### PO Sign-off

Based on the assessment, record one of:

| Sign-off | Meaning |
|----------|---------|
| **approved** | Implementation achieves the stated goal |
| **revisions_needed** | Specific gaps prevent goal achievement — list each gap |

If `revisions_needed`, include:
```yaml
po_signoff: "revisions_needed"
revision_items:
  - gap: "Description of what's missing or wrong"
    component: "affected component"
    severity: "blocking | nice_to_have"
```

**Save PO assessment to findings.md (2-Action Rule checkpoint).**

## Step 5: Generate Build Report

Use `plugins/agency/resources/templates/build-report-template.md` to generate the
build report. Fill in all template variables from project-state.yml data:

### Required Sections (minimum 8)

1. **Build Summary** — feature description, status, build ID, timestamps, duration
2. **Components Built** — from decomposition, with implementation status per component
3. **Agent Assignments** — table: task ID, description, agent, tier, status, commit SHA
4. **Test Results** — aggregate build/lint/test pass rates across all tasks
5. **Code Review Findings** — summary table by severity from review.code_review.findings
6. **QA Validation** — spec alignment score, PO sign-off, notes
7. **Blockers Encountered** — from project-state.yml errors array (task_id, reason, resolution)
8. **Commit Range** — base_sha, head_sha, total commit count

### Report Generation

```
1. Read plugins/agency/resources/templates/build-report-template.md
2. For each section, extract data from project-state.yml
3. Calculate derived values:
   - Duration: completed_at - started_at
   - Total commits: git rev-list --count base_sha..head_sha
   - Pass rates: (passed_gates / total_gates) × 100
4. Write completed report to .ai/projects/[name]/dev/build-report.md
```

## Step 6: Write QA Report to project-state.yml

Write `review.qa_validation` section:

```yaml
review:
  qa_validation:
    status: "passed | failed"
    spec_alignment: 85          # 0-100 score
    po_signoff: "approved"      # approved | revisions_needed
    revision_items: []          # only if revisions_needed
    components_assessed:
      - name: "auth-module"
        status: "implemented"   # implemented | partial | quality_degraded | missing
        score: 1.0
      - name: "dashboard-ui"
        status: "partial"
        score: 0.5
        notes: "Missing responsive layout for mobile"
    quality_factor: 0.8
    notes: |
      Overall build achieves the stated goal. Two warnings
      from code review on function length — non-blocking.
    build_report_path: ".ai/projects/[name]/dev/build-report.md"
    completed_at: "2025-01-15T11:00:00Z"
```

Also update:
- `build.current_phase` → 4 (review phase)
- `build.status` → "completed" (if passed) or "failed" (if failed)
- `meta.updated_at` → current timestamp

**Save final report to findings.md (2-Action Rule checkpoint).**

## Step 7: Handle Failed Validation

When `spec_alignment < 70` or `po_signoff == "revisions_needed"`:

```
1. Set review.qa_validation.status = "failed"
2. List specific gaps:
   - Components with status "missing" or "partial"
   - PO revision items (if any)
3. Present to user:
   "## QA Validation Failed

   Spec Alignment: [score]% (minimum: 70%)
   PO Sign-off: [signoff]

   Gaps:
   - [component]: [status] — [notes]

   Options:
   a) Create fix tasks for gaps and re-run affected phases
   b) Accept current state as-is (lower the threshold)
   c) Abort and review the decomposition"
4. Wait for user decision
```

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only project-state.yml, build-report.md, and findings.md updates
2. Commit: `[plan_name]: qa-validation [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- project-state.yml review.qa_validation section exists and is non-empty
- review.qa_validation.spec_alignment is a number between 0 and 100
- review.qa_validation.po_signoff is one of: approved, revisions_needed
- If po_signoff is revisions_needed: revision_items array is non-empty
- components_assessed array is non-empty
- build-report.md exists at `.ai/projects/[name]/dev/build-report.md` and has at least 8 markdown headings (## sections)
- completed_at is set to a valid timestamp

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Spec alignment score calculation is accurate (verify against component data)
- PO assessment is meaningful (not rubber-stamped — considers actual goal)
- Build report is comprehensive (all sections filled with real data, not placeholders)
- Component statuses are justified (not all "implemented" when gaps exist)
- Quality factor correctly reflects gate results and code review findings

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

## Error Handling

When errors occur during QA validation:

1. **Missing decomposition:** If project-state.yml has no decomposition section,
   log to errors array. Cannot proceed without a spec to validate against.
   Report error and suggest running feature-decomposer first.

2. **Incomplete execution data:** If dispatched_tasks is missing or has no
   completed tasks, log warning. Score all components as "missing" — the
   spec alignment will be 0%.

3. **Build report template missing:** If `plugins/agency/resources/templates/build-report-template.md`
   is not found, generate a minimal report with available data. Log the missing
   template to errors array.

4. **Before retrying:** Always check project-state.yml errors array for previous failed
   attempts. Never repeat the same approach.
