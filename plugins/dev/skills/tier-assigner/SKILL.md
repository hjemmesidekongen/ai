---
name: tier-assigner
description: >
  Self-tiering logic for domain specialist agents — assesses task complexity at
  Haiku cost, declares appropriate model tier, and auto-escalates on failure.
  Use when assigning model tiers, running agent dispatch, checking model floors,
  escalating failed tasks, or optimizing agent cost.
depends_on: []
writes:
  - "Tier assignment object returned to agent-dispatcher"
reads:
  - "Task brief (description, scope, files_affected)"
  - "Agent role definition (model floor, capabilities)"
  - ".ai/dev/[project-name]/state.yml (errors array for escalation)"
model_tier: junior
interactive: false
checkpoint:
  type: data_validation
  required_checks:
    - name: "tier_valid"
      verify: "Tier is one of: junior, senior, principal, blocked"
      fail_action: "Default to senior if assessment is inconclusive"
    - name: "model_floor_respected"
      verify: "Tier respects model floor for the agent role (code-reviewer, security-expert, designer >= senior)"
      fail_action: "Raise tier to senior for floor-protected roles"
    - name: "escalation_recorded"
      verify: "If escalated: previous tier and failure reason are recorded"
      fail_action: "Read state.yml errors array to find previous failure details"
    - name: "reasoning_present"
      verify: "Reasoning is non-empty (at least 1 sentence explaining the assessment)"
      fail_action: "Generate reasoning from the dominant complexity factor"
  on_fail: "Fix issues and re-run checkpoint. Do not return tier until all checks pass."
  on_pass: "Return tier assignment to caller."
---

# Tier Assigner

Utility skill called by agent-dispatcher. Assesses task complexity at Haiku cost and declares the appropriate model tier. Auto-escalates when previous attempts failed at a lower tier.

## Complexity Assessment

Evaluate 4 factors, take the **highest** tier as baseline:

| Factor | Junior (Haiku) | Senior (Sonnet) | Principal (Opus) |
|--------|---------------|-----------------|------------------|
| Files affected | 1 file | 2-5 files | 6+ files |
| Spec ambiguity | Clear requirements | Some design choices | Unclear scope |
| Risk level | Isolated change | Feature-scoped | Critical path / system-wide |
| Cross-cutting | No shared concerns | Touches shared utils | Architectural change |

## Model Floors

Some roles have minimum tiers that cannot be lowered:
- **Code Reviewer:** floor = senior (Sonnet)
- **Security Expert:** floor = senior (Sonnet)
- **Designer:** floor = senior (Sonnet)
- All other specialists can tier down to junior (Haiku)

## Auto-Escalation

1. Check `state.yml` errors array for previous failures on this task
2. If task failed at junior → escalate to senior
3. If task failed at senior → escalate to principal
4. If task failed at principal → return `{ tier: "blocked", reason: "Failed at maximum tier" }` — PM must escalate to user

## Output Format

```yaml
tier: "junior" | "senior" | "principal" | "blocked"
reasoning: "1-2 sentences explaining the assessment"
escalated_from: null | "junior" | "senior"
```

## Findings Persistence

Write assessment details to `.ai/dev/[project-name]/findings.md`.
**2-Action Rule:** After every 2 assessment evaluations, save findings immediately.

## Error Logging — Log errors to state.yml errors array. Check errors before retrying.
