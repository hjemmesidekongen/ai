# Tier Assignment — Process Reference

## Scoring Algorithm

### Formula

```
weighted_score = (scope × W_scope) + (reversibility × W_rev) + (ambiguity × W_amb)
               + (impact × W_impact) + (dependencies × W_deps)
```

### Weight Table

| Factor | Weight | Justification |
|--------|--------|---------------|
| Scope | 1.0 | Baseline — file count is a straightforward complexity proxy |
| Reversibility | 0.8 | Slightly discounted — most changes are revertible via git; only destructive ops score high |
| Ambiguity | 1.2 | Premium — unclear requirements are the #1 source of agent failure; ambiguous tasks need stronger models |
| Impact | 1.0 | Baseline — blast radius matters linearly |
| Dependencies | 1.0 | Baseline — coupling creates cascading failure risk |

Total weight sum: 5.0. Score range: 5.0 (all 1s) to 25.0 (all 5s).

### Tier Thresholds

| Score Range | Tier | Model | Rationale |
|-------------|------|-------|-----------|
| 5.0 – 10.0 | junior | haiku | Simple, well-defined, low-risk work. Haiku handles it at lowest cost. |
| 10.1 – 18.0 | senior | sonnet | Moderate complexity, some ambiguity or cross-cutting concerns. Sonnet balances cost and capability. |
| 18.1 – 25.0 | principal | opus | High ambiguity, high impact, or architectural scope. Needs the strongest reasoning. |

## Per-Factor Scoring Rubric

### Scope (how many files/modules touched)

| Score | Criteria |
|-------|----------|
| 1 | 1-2 files in a single module |
| 2 | 2-3 files, same module, well-understood patterns |
| 3 | 3-5 files spanning one module boundary |
| 4 | 5-8 files across 2-3 modules |
| 5 | 8+ files or touches 4+ modules |

### Reversibility (how hard to undo if wrong)

| Score | Criteria |
|-------|----------|
| 1 | Config change, feature flag, easily reverted |
| 2 | New file creation only (delete to revert) |
| 3 | Modifies existing code but changes are additive |
| 4 | Modifies shared interfaces or contracts |
| 5 | Destructive migration, data loss on revert, public API removal |

### Ambiguity (how unclear the requirements are)

| Score | Criteria |
|-------|----------|
| 1 | Exact specification provided, known pattern (e.g., "add field X to model Y") |
| 2 | Clear goal, minor implementation decisions needed |
| 3 | Goal is clear but approach has 2-3 viable paths |
| 4 | Requirements are vague, domain knowledge needed to interpret |
| 5 | Open-ended, no clear success criteria, novel problem space |

### Impact (blast radius of a mistake)

| Score | Criteria |
|-------|----------|
| 1 | Internal utility, no downstream consumers |
| 2 | Used by 1-2 other modules, easy to fix if broken |
| 3 | Shared module with moderate consumer count |
| 4 | Public API or shared library, breaking change affects users |
| 5 | Security-critical, data-integrity-critical, or affects all consumers |

### Dependencies (coupling to other subtasks)

| Score | Criteria |
|-------|----------|
| 1 | Standalone, no upstream or downstream dependencies |
| 2 | 1 upstream dependency, 0-1 downstream |
| 3 | 2 upstream or 2 downstream dependencies |
| 4 | 3+ downstream dependents (high fan-out) |
| 5 | Critical path node — blocks 4+ subtasks or has complex ordering constraints |

## Worked Example 1: "Create API endpoint for listing users"

| Factor | Score | Reasoning |
|--------|-------|-----------|
| Scope | 2 | 2-3 files: route handler, test, maybe a DTO |
| Reversibility | 2 | New files only, delete to revert |
| Ambiguity | 1 | Standard CRUD pattern, clear spec |
| Impact | 3 | Public API — consumers will depend on the contract |
| Dependencies | 2 | Depends on user model, one downstream dep |

```
weighted = (2×1.0) + (2×0.8) + (1×1.2) + (3×1.0) + (2×1.0)
         = 2.0 + 1.6 + 1.2 + 3.0 + 2.0
         = 9.8
```

**Tier: junior** (9.8 falls in 5.0–10.0 range)

However, this touches a public API → override rule applies → **floor at senior**.

**Final tier: senior**

## Worked Example 2: "Write database migration to split users table"

| Factor | Score | Reasoning |
|--------|-------|-----------|
| Scope | 3 | Migration file, model updates, possibly query updates |
| Reversibility | 5 | Destructive migration — data restructuring is hard to undo |
| Ambiguity | 3 | Goal clear but column mapping decisions needed |
| Impact | 5 | Every query touching users is affected |
| Dependencies | 3 | Blocks several downstream subtasks |

```
weighted = (3×1.0) + (5×0.8) + (3×1.2) + (5×1.0) + (3×1.0)
         = 3.0 + 4.0 + 3.6 + 5.0 + 3.0
         = 18.6
```

**Tier: principal** (18.6 falls in 18.1–25.0 range)

Database migration override also applies → confirms principal.

**Final tier: principal**

## Override Rules

Overrides apply after scoring. They can only escalate (raise the floor), never downgrade.

| Pattern | Minimum Tier | Rationale |
|---------|-------------|-----------|
| Database migration | principal | Data loss risk is too high for lower tiers |
| Public API change | senior | Contract stability matters; needs careful review |
| Deletion of shared module | principal | High blast radius, needs full context understanding |
| Security-sensitive files (auth, crypto, secrets) | senior | Security mistakes are expensive |
| 3+ downstream dependents | senior | High fan-out node; errors cascade |

### Override Application Order

1. Calculate weighted score.
2. Determine tier from score range.
3. Check all override patterns.
4. If any override specifies a higher tier, escalate to that tier.
5. Record which override triggered in the justification.

## Edge Cases

### All factors score 1

Weighted total: 5.0. Tier: junior. This is correct — trivially simple tasks should use the cheapest model. No override check needed unless pattern-based overrides apply.

### Borderline scores (10.0, 18.0)

The boundaries are inclusive on the lower end: 10.0 is still junior, 18.0 is still senior. Only scores strictly above the threshold move to the next tier. This avoids unnecessary escalation for borderline cases.

### Score disagrees with override

The override always wins. If a subtask scores 7.0 (junior) but touches auth files, it becomes senior. The justification must note: "Scored 7.0 (junior range) but escalated to senior due to security-sensitive file scope."

### Multiple overrides apply

Take the highest tier among all matching overrides. For example, a database migration that also deletes a shared module: both point to principal, so principal it is. If one said senior and another said principal, principal wins.

### Subtask with no risk vector

This should not happen — the decomposer must provide risk scores. If a subtask arrives without scores, reject it back to task-decomposer. Do not assign tiers without data.

### Cost sanity check

If more than 30% of subtasks in a decomposition are assigned to principal, flag it for review. This usually means the parent task is too complex and should be split further, or the risk scores are inflated.
