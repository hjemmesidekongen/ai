# Code Review — Detailed Process

Phase 4a of /agency:build. Audits the full wave diff for quality, patterns, security, convention compliance, and design token usage. Critical findings block QA until fixed.

## Step 1: Load Review Context

```
Read project-state.yml → execution.commit_range (base_sha, head_sha)
Read dev-config.yml → conventions (naming, imports, file organization)
Read knowledge/conventions.yml → project-specific patterns (if exists)
Read design/tokens/ → token files (if exists) — used for dimension f checks

Run: git diff [base_sha]..[head_sha] --name-only → list of changed files
Run: git diff [base_sha]..[head_sha] → full diff content
```

**Save file list and context summary to findings.md (2-Action Rule checkpoint).**

## Step 2: Review Each Changed File

For each changed file, assess 6 dimensions:

| # | Dimension | Scope |
|---|-----------|-------|
| a | Code Quality | readability, function size <50 lines, nesting <4, file size <800, dead code |
| b | Pattern Adherence | conventions.yml, repository pattern, service layer, error handling, API format |
| c | Convention Compliance | naming, import order, file org, no console.log, no hardcoded values |
| d | Security (OWASP Top 10) | SQL injection, XSS, auth bypass, hardcoded secrets, CSRF, input validation, error leaking |
| e | Performance | N+1 queries, unnecessary re-renders, missing indexes, large payloads, sync blocking |
| f | Design Token Compliance | UI files only — no hardcoded colors/spacing/typography; skip if tokens dir absent |

**Save findings after every 2 files reviewed (2-Action Rule checkpoint).**

## Step 3: Rate and Classify Findings

| Severity | Meaning | Action |
|----------|---------|--------|
| **critical** | Must fix before merge | Blocks QA — returned to producing agent for fix |
| **warning** | Should fix — degrades quality | Logged for attention, does not block merge |
| **info** | Suggestion for improvement | Optional — noted for learning |

## Step 4: Write Review Report

Write `review.code_review` to project-state.yml:

```yaml
review:
  code_review:
    status: "passed | failed"  # failed if any critical findings
    reviewer_tier: "senior"
    files_reviewed:
      - "path/to/file.ts"
    findings:
      - file: "src/api/auth.ts"
        severity: "critical"
        message: "SQL injection: user input concatenated into query on line 42"
        line: 42
    summary:
      total_files: 12
      total_findings: 6
      critical: 1
      warnings: 3
      info: 2
      design_token_violations: 1
    completed_at: "2025-01-15T10:30:00Z"
```

**Decision logic:** critical > 0 → status "failed" (blocks qa-validation), else "passed".
Also update: `build.current_phase` → 4, `meta.updated_at` → current timestamp.
**Save final report to findings.md (2-Action Rule checkpoint).**

## Step 5: Handle Critical Findings

1. Set `review.code_review.status = "failed"`
2. For each critical finding: identify producing agent from `execution.dispatched_tasks`, create remediation task (`FIX-[task_id]`), re-dispatch via agent-dispatcher
3. After fix: re-run review on fixed files only — if no criticals, update to "passed"; if still critical, escalate tier or present to user

---

## Step 0: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/{skill-name}-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 — required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` — what happened vs expected; surprises, gaps, confirmations
- `improvement_idea` — actionable suggestion for the skill/pipeline (if any)
- `design_decision` — lasting choice beyond this run (if any)

**Trace-level `reflections` section (REQUIRED — Stop hook enforces):**
```yaml
reflections:
  observations: ["at least one observation about the run"]
  improvement_ideas: []   # optional but encouraged
  design_decisions: []    # optional, only for lasting choices
```

The Stop hook will BLOCK completion if reflections section is missing.

---


> **Extended reference:** See [references/review-dimensions.md](review-dimensions.md) for dimension checklists, severity examples, two-stage verification protocol, error scenarios, and commit protocol.

---

## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED — Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
