---
name: skill-quality-rubric
description: >
  8-dimension quality framework for evaluating dev-engine knowledge skills.
  Provides a scoring template for audits with pass/fail thresholds and
  actionable remediation guidance.
user_invocable: false
interactive: false
model_tier: senior
triggers:
  - "skill quality"
  - "audit skill"
  - "quality rubric"
  - "skill review"
reads:
  - "plugins/dev-engine/skills/*/SKILL.md"
  - "plugins/dev-engine/skills/*/references/process.md"
writes:
  - ".ai/audits/skill-quality-<skill-name>.yml"
checkpoint:
  type: data_validation
  required_checks:
    - name: "all_dimensions_scored"
      verify: "All 8 dimensions have a score (1–5) with justification"
      fail_action: "Return to scoring — incomplete rubrics are not valid audit outputs"
    - name: "threshold_check"
      verify: "Overall score computed and pass/fail verdict recorded"
      fail_action: "Compute aggregate score before reporting"
    - name: "remediation_present"
      verify: "Every dimension scored below 3 has a concrete remediation note"
      fail_action: "Add remediation for all failing dimensions"
  on_fail: "Audit incomplete — resolve missing scores or remediations"
  on_pass: "Audit complete — report ready with aggregate score and verdict"
_source:
  origin: "dev-engine"
  inspired_by: "claude-core skill-auditor"
  ported_date: "2026-03-10"
  iteration: 1
---

# Skill Quality Rubric

Structured 8-dimension scoring framework for auditing dev-engine knowledge skills. Use this when a skill needs a formal quality review or before promoting a skill to stable.

## The 8 Dimensions

| # | Dimension | What It Measures |
|---|-----------|-----------------|
| 1 | **Accuracy** | Technical correctness — no wrong facts, no outdated APIs |
| 2 | **Completeness** | Covers the full scope implied by the skill name |
| 3 | **Code Quality** | Examples compile, follow best practices, are copy-paste safe |
| 4 | **Anti-pattern Coverage** | Explicitly calls out what not to do |
| 5 | **Up-to-dateness** | Reflects current library/framework versions |
| 6 | **Progressive Disclosure** | SKILL.md is a quick-start; depth lives in process.md |
| 7 | **Trigger Discoverability** | Triggers match real user phrasings |
| 8 | **Reference Depth** | process.md has enough detail for edge cases |

## Scoring Scale

- **5 — Excellent**: No gaps. Production-ready as written.
- **4 — Good**: Minor gaps. Usable without changes.
- **3 — Acceptable**: Gaps present but skill still delivers value.
- **2 — Weak**: Material gaps that reduce reliability.
- **1 — Failing**: Fundamentally broken or misleading in this dimension.

## When to Audit

- Before promoting a skill from draft to stable.
- After a major framework version change that affects the skill's domain.
- When a skill produces consistently low-quality agent outputs.
- As part of a dev-engine quarterly quality sweep.

See `references/process.md` for per-dimension rubric descriptors, scoring template, aggregation method, and reporting format.
