# Agency Plugin — Manual Test Plan

**Tiers covered:** T3 (Pipeline Logic) + T4 (Integration)
**Prerequisites:** `bash plugins/agency/tests/smoke-test.sh` passes (35/35)

---

## Tier 3: Pipeline Logic (6 tests)

### T3-01: /agency:init creates correct structure

**Steps:**
1. Remove any existing test project: `rm -rf .ai/projects/test-smoke .ai/agency.yml`
2. Run `/agency:init test-smoke --app-path apps/test-smoke --skip-scan`
3. Verify directories created:

- [ ] `.ai/projects/test-smoke/brand/`
- [ ] `.ai/projects/test-smoke/design/logos/`
- [ ] `.ai/projects/test-smoke/design/tokens/`
- [ ] `.ai/projects/test-smoke/design/components/`
- [ ] `.ai/projects/test-smoke/design/layouts/`
- [ ] `.ai/projects/test-smoke/design/previews/`
- [ ] `.ai/projects/test-smoke/content/`
- [ ] `.ai/projects/test-smoke/dev/`
- [ ] `.ai/projects/test-smoke/devops/`

4. Verify files created:

- [ ] `.ai/projects/test-smoke/state.yml` — has `project: test-smoke`, `status: created`, all 5 modules `not_started`
- [ ] `.ai/projects/test-smoke/asset-registry.yml` — has `project: test-smoke`, `assets: []`
- [ ] `.ai/agency.yml` — has `active: test-smoke`, project entry with `app_path: apps/test-smoke`

**Pass criteria:** 9 dirs + 3 files exist with correct content.

---

### T3-02: State transitions work

**Steps:**
1. After T3-01 passes, run `/agency:design` on the test-smoke project
2. Check `.ai/projects/test-smoke/state.yml` during execution:

- [ ] `status` changes from `created` to `in_progress`
- [ ] `current_module` is set to `design`
- [ ] `current_skill` updates as each design skill runs

3. After design completes:

- [ ] `modules.design.status` is `completed`
- [ ] `modules.design.completed_skills` lists design skills

**Pass criteria:** State file accurately reflects pipeline progress.

---

### T3-03: Dependency enforcement

**Steps:**
1. With a fresh test-smoke project (T3-01), attempt to run `/agency:build` before `/agency:design`
2. The pipeline should check `depends_on` and state.yml:

- [ ] Build refuses to start (scaffold depends on config-generator and design-tokens)
- [ ] Error message mentions missing prerequisites
- [ ] State.yml logs the error

**Pass criteria:** Pipeline blocks execution when prerequisites are unmet.

---

### T3-04: Checkpoint catches failures

**Steps:**
1. Run `/agency:design` but provide invalid/missing brand data
2. After a skill runs, its checkpoint should fire:

- [ ] Checkpoint detects missing required output
- [ ] Error is logged to `state.yml` errors array
- [ ] Pipeline halts at the failed skill (does not advance)
- [ ] `on_fail` action from SKILL.md frontmatter is reported

**Pass criteria:** Checkpoint stops pipeline on failure, error logged to state.yml.

---

### T3-05: /agency:status accuracy

**Steps:**
1. With an in-progress project (partially through design), run `/agency:status`
2. Compare output against `state.yml`:

- [ ] Active project name matches
- [ ] Module statuses match (not_started / in_progress / completed)
- [ ] Current skill matches
- [ ] Error count matches
- [ ] Recovery notes shown if present

**Pass criteria:** Status output is consistent with state.yml.

---

### T3-06: --from resume skips completed phases

**Steps:**
1. Complete the design phase on test-smoke project
2. Run `/agency:content` — should start from content, not re-run design
3. Verify:

- [ ] Design skills are NOT re-executed
- [ ] Content skills start immediately
- [ ] `modules.design.status` remains `completed` (not reset)

**Pass criteria:** Completed phases are skipped, only requested phase runs.

---

## Tier 4: Integration (4 tests)

### T4-01: Full pipeline init -> design -> content -> build -> deploy

**Steps:**
1. `rm -rf .ai/projects/full-test .ai/agency.yml`
2. `/agency:init full-test --app-path apps/full-test --brand .ai/brands/full-test/brand-reference.yml`
3. `/agency:design`
4. `/agency:content`
5. `/agency:build`
6. `/agency:deploy`

**Verify at each stage:**

- [ ] Brand: brand-summary.yml created, assets registered
- [ ] Design: tokens, component-specs, web-layout produced
- [ ] Content: app-copy.yml, ux-microcopy.yml produced
- [ ] Build: scaffold generated, features decomposed, code reviewed
- [ ] Deploy: deploy config generated, deployment attempted
- [ ] Final state.yml: all 5 modules `completed`

**Pass criteria:** End-to-end pipeline completes without errors.

---

### T4-02: Error recovery (interrupt + resume)

**Steps:**
1. Start `/agency:design` on a project
2. Interrupt mid-execution (Ctrl+C or stop Claude)
3. Restart session — session-recovery hook fires
4. Resume work:

- [ ] Session recovery shows correct active project
- [ ] Session recovery shows current module/skill
- [ ] Re-running `/agency:design` continues from interrupted skill
- [ ] No duplicate work — already-completed skills are skipped
- [ ] State.yml `recovery_notes` is meaningful

**Pass criteria:** Session recovery correctly identifies interrupted state; resume works.

---

### T4-03: Multi-project isolation

**Steps:**
1. `/agency:init project-a --app-path apps/a --skip-scan`
2. `/agency:init project-b --app-path apps/b --skip-scan`
3. Active project is now `project-b`
4. Attempt to write to `.ai/projects/project-a/state.yml`:

- [ ] PreToolUse hook fires project-isolation-check.sh
- [ ] Write is BLOCKED with message mentioning `project-a` vs `project-b`
- [ ] Suggestion to use `/agency:switch project-a` is shown

5. Write to `.ai/projects/project-b/state.yml`:

- [ ] Write is ALLOWED (same project)

**Pass criteria:** Cross-project writes blocked, same-project writes allowed.

---

### T4-04: /agency:switch propagation

**Steps:**
1. With project-a and project-b from T4-03:
2. Run `/agency:switch project-a`
3. Verify:

- [ ] `.ai/agency.yml` `active` field is now `project-a`
- [ ] `/agency:status` shows project-a's state (not project-b)
- [ ] Session recovery would now show project-a
- [ ] Isolation check now allows writes to project-a, blocks project-b

**Pass criteria:** Switch updates active project and all downstream behavior follows.

---

## Results Summary

| Test | Status | Notes |
|------|--------|-------|
| T3-01 | [ ] | |
| T3-02 | [ ] | |
| T3-03 | [ ] | |
| T3-04 | [ ] | |
| T3-05 | [ ] | |
| T3-06 | [ ] | |
| T4-01 | [ ] | |
| T4-02 | [ ] | |
| T4-03 | [ ] | |
| T4-04 | [ ] | |

**Tested by:** _______________
**Date:** _______________
**All manual tests passed:** [ ] Yes / [ ] No
