# Visual Verification -- Detailed Process

## Overview

Visual verification is a three-tier system that runs at section milestones
during the build phase. It compares the implemented code against Pencil design
references (screenshots) to catch structural and visual drift before it
compounds across sections and pages.

The skill is profile-controlled: `visual_verification: true | false | "detect"`.
When set to `"detect"`, verification activates only if Pencil screenshots exist
in the project render directory.

Three downstream integrations:

- **e2e-testing** shares the Playwright instance for screenshot capture
- **implementation-guide** YAMLs inform expected structural alignment
- **design-tokens** provide the token vocabulary for code lint checks

---

## Step 0: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/{skill-name}-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 -- required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` -- what happened vs expected; surprises, gaps, confirmations
- `improvement_idea` -- actionable suggestion for the skill/pipeline (if any)
- `design_decision` -- lasting choice beyond this run (if any)

**Trace-level `reflections` section (REQUIRED -- Stop hook enforces):**
```yaml
reflections:
  observations: ["at least one observation about the run"]
  improvement_ideas: []   # optional but encouraged
  design_decisions: []    # optional, only for lasting choices
```

The Stop hook will BLOCK completion if reflections section is missing.

---

## Step 1: Activation & Profile Check

```
Read .ai/profiles/{profile}.yml
Extract visual_verification setting:
  - true   -> activate all tiers
  - false  -> skip entirely, log "visual verification disabled by profile"
  - "detect" -> check if .ai/projects/[name]/render/screenshots/ exists
    - exists    -> activate
    - not found -> skip, log "no Pencil references found, skipping"
```

If skipping, write a minimal report with `status: skipped` and `reason`.

**Save to findings.md after this step (2-Action Rule checkpoint).**

---

## Step 2: Determine Current Milestone

Evaluate the current build state to identify which milestone(s) apply:

| Milestone | Trigger condition |
|-----------|-------------------|
| **Layout skeleton** | Grid/container setup complete, no content yet |
| **Above the fold** | Hero section + navigation implemented |
| **Full page** | All sections for at least one page implemented |
| **Multi-page** | Two or more pages fully implemented |

Multiple milestones may apply in a single run (e.g., catching up after
several sections were built). Run verification for each applicable milestone
in order.

```
Read .ai/projects/[name]/dev/visual-verification-report.yml (if exists)
Check which milestones already passed
Determine which new milestones are now applicable
Queue unchecked milestones for verification
```

---

## Step 3: Tier 1 -- Code Lint Checks

Static analysis of the implemented code against design token vocabulary. No
rendering or screenshots needed. Fast and deterministic.

### 3.1 Spacing Token Compliance

```
Scan all component/page files for spacing values.
PASS: only design token values used (gap-4, p-8, mt-6, etc.)
FAIL: arbitrary values found (gap-[17px], mt-[2.3rem], padding: 13px)

Report format per violation:
  file: "src/components/Hero.tsx"
  line: 42
  found: "gap-[17px]"
  expected: "gap-4 (16px) or gap-5 (20px)"
  severity: "warning"
```

### 3.2 Grid Consistency

```
Read implementation-guide YAML for expected grid structure.
Check implemented code matches:
  - Column count at each breakpoint
  - Grid template areas (if specified)
  - Container max-width matches layout YAML width value
PASS: grid structure matches implementation guide
FAIL: mismatch logged with expected vs actual
```

### 3.3 Container Consistency

```
Check all container elements:
  - max-width uses token value (--container-max, --container-narrow, etc.)
  - Horizontal padding uses token value
  - Responsive breakpoints adjust correctly
PASS: containers use consistent token-based constraints
FAIL: hardcoded max-width or inconsistent padding
```

### 3.4 Typography Scale Compliance

```
Scan for font-size declarations.
PASS: all sizes from the type scale (text-sm, text-base, text-lg, etc.)
FAIL: arbitrary sizes (text-[15px], font-size: 0.9375rem)
```

### 3.5 Color Token Compliance

```
Scan for color values.
PASS: all colors reference tokens (text-brand-500, bg-neutral-100, etc.)
FAIL: hardcoded hex (#3b82f6), rgb(), hsl() values
Exception: transparent, inherit, currentColor are allowed
```

### Tier 1 Result

Aggregate all checks into a per-milestone lint result:

```yaml
code_lint:
  status: "pass" | "fail" | "warnings"
  checks:
    spacing: { status, violations: [] }
    grid: { status, violations: [] }
    containers: { status, violations: [] }
    typography: { status, violations: [] }
    colors: { status, violations: [] }
  total_violations: 0
  total_warnings: 0
```

**Save to findings.md after Tier 1 (2-Action Rule checkpoint).**

---

## Step 4: Tier 2 -- LLM Vision Check

Screenshot comparison between implemented code (Playwright) and design
reference (Pencil). Checks structural alignment, NOT pixel-perfection.

### 4.1 Capture Playwright Screenshots

Capture at three breakpoints using the shared Playwright instance from
e2e-testing:

| Breakpoint | Width | Label |
|-----------|-------|-------|
| Mobile | 375px | `mobile` |
| Tablet | 768px | `tablet` |
| Desktop | 1280px | `desktop` |

```
For each applicable page at current milestone:
  playwright.screenshot({
    path: ".ai/projects/[name]/dev/screenshots/{page}-{breakpoint}.png",
    fullPage: true
  })
```

If Playwright is not available or page cannot be rendered, log error and
skip to Tier 3 (human escalation) for this milestone.

### 4.2 Load Pencil Ground Truth

```
Read .ai/projects/[name]/render/screenshots/
Match Pencil screenshots to pages by filename convention:
  {page}-desktop.png, {page}-tablet.png, {page}-mobile.png

If a Pencil reference is missing for a breakpoint:
  Log warning: "No Pencil reference for {page} at {breakpoint}"
  Skip that breakpoint comparison (do not fail)
```

### 4.3 Vision Comparison

Send paired screenshots (Playwright + Pencil) to the vision model with a
structured prompt. Compare ONE breakpoint at a time.

**Comparison prompt structure:**

```
Compare these two screenshots of the same page section.
Image 1: Design reference (Pencil mockup)
Image 2: Implementation (Playwright capture)

Evaluate structural alignment on these dimensions:
1. Vertical rhythm -- are section spacings proportionally similar?
2. Grid alignment -- do columns and gutters match the layout structure?
3. Section spacing -- are gaps between sections consistent with the design?
4. Component sizing -- are components proportionally sized correctly?
5. Content hierarchy -- does the visual weight match (headings > body > captions)?

DO NOT check:
- Exact pixel positions (implementation uses responsive units)
- Color accuracy (handled by token compliance in Tier 1)
- Font rendering differences (browser vs design tool variance)
- Placeholder content vs final copy

Rate overall structural alignment from 0.0 to 1.0.
List specific misalignments found.
```

### 4.4 Confidence Scoring

| Score range | Result | Action |
|-------------|--------|--------|
| > 0.85 | **Pass** | Log result, continue |
| 0.6 - 0.85 | **Flag** | Log findings, flag for optional human review |
| < 0.6 | **Fail** | Escalate to Tier 3 (human review required) |

Per-breakpoint results are aggregated. The lowest score across breakpoints
determines the milestone result.

### Tier 2 Result

```yaml
vision_check:
  status: "pass" | "flagged" | "fail"
  breakpoints:
    mobile:
      confidence: 0.87
      findings: []
    tablet:
      confidence: 0.92
      findings: []
    desktop:
      confidence: 0.89
      findings: []
  aggregate_confidence: 0.87
  misalignments: []
```

**Save to findings.md after Tier 2 (2-Action Rule checkpoint).**

---

## Step 5: Tier 3 -- Human Escalation

Triggered when:
- LLM vision confidence is below 0.6 for any breakpoint
- The current milestone is **multi-page** (final milestone always gets human review)
- User has explicitly requested review (via profile or runtime flag)

### 5.1 Prepare Comparison View

Present to the user:

```
## Visual Verification -- Human Review Required

**Milestone:** {milestone_name}
**Page:** {page_name}
**Reason:** {confidence below threshold | final milestone | user requested}

### Side-by-Side Comparison

**Desktop (1280px):**
  Design reference: .ai/projects/[name]/render/screenshots/{page}-desktop.png
  Implementation:   .ai/projects/[name]/dev/screenshots/{page}-desktop.png

**Tablet (768px):**
  Design reference: .ai/projects/[name]/render/screenshots/{page}-tablet.png
  Implementation:   .ai/projects/[name]/dev/screenshots/{page}-tablet.png

**Mobile (375px):**
  Design reference: .ai/projects/[name]/render/screenshots/{page}-mobile.png
  Implementation:   .ai/projects/[name]/dev/screenshots/{page}-mobile.png

### Code Lint Summary
{tier_1_summary}

### LLM Vision Findings
{tier_2_findings}

### Actions
1. **Approve** -- mark this milestone as passed
2. **Request fixes** -- list specific issues to address
3. **Adjust threshold** -- change confidence threshold for future checks
```

### 5.2 Process User Response

```
if user approves:
  Record human_review: { status: "approved", reviewer: "human", notes: "" }
  Continue to next milestone

if user requests fixes:
  Record human_review: { status: "fixes_requested", issues: [...] }
  Return issues to the build process for correction
  Re-run verification after fixes are applied

if user adjusts threshold:
  Update profile visual_verification_threshold
  Re-evaluate Tier 2 results with new threshold
  Record the threshold change in findings.md
```

**Save to findings.md after Tier 3 (2-Action Rule checkpoint).**

---

## Step 6: Milestone Progression

### When Each Milestone Triggers

**Layout skeleton:**
- After grid/container CSS is set up
- Before any content components are added
- Verifies: container widths, grid columns, spacing between grid areas
- Typically only desktop breakpoint is meaningful at this stage

**Above the fold:**
- Hero section + navigation are both implemented
- Verifies: hero height/layout, nav positioning, hero-to-content transition
- All three breakpoints checked (nav responsive behavior is critical)

**Full page:**
- All sections for at least one page are implemented
- Verifies: full vertical rhythm, section spacing consistency, scroll flow
- All three breakpoints checked

**Multi-page:**
- Two or more pages are fully implemented
- Verifies: cross-page consistency (nav, footer, spacing patterns, shared components)
- All three breakpoints checked
- Human review is ALWAYS triggered at this milestone

### Progression Rules

```
Milestones must be checked in order.
A milestone cannot be skipped -- if layout skeleton hasn't passed,
  above-the-fold cannot be checked.
A failed milestone blocks progression until resolved.
Re-running a passed milestone is allowed (e.g., after refactoring).
```

---

## Step 7: Write Report

Write the final report to `.ai/projects/[name]/dev/visual-verification-report.yml`.

### Report Schema

```yaml
visual_verification_report:
  project: "{project_name}"
  generated_at: "{ISO8601 timestamp}"
  profile_setting: "true | false | detect"
  overall_status: "pass | fail | partial"

  milestones:
    layout_skeleton:
      status: "pass | fail | skipped | pending"
      checked_at: "{ISO8601 timestamp}"
      code_lint:
        status: "pass | fail | warnings"
        violations: 0
        warnings: 0
      vision_check:
        status: "pass | flagged | fail | skipped"
        aggregate_confidence: 0.0
        breakpoints:
          mobile: { confidence: 0.0, findings: [] }
          tablet: { confidence: 0.0, findings: [] }
          desktop: { confidence: 0.0, findings: [] }
      human_review:
        required: false
        status: "not_required | approved | fixes_requested"
        notes: ""

    above_the_fold:
      # same structure as layout_skeleton
      status: "pending"

    full_page:
      # same structure as layout_skeleton
      status: "pending"

    multi_page:
      # same structure as layout_skeleton
      # human_review.required is always true for this milestone
      status: "pending"

  summary:
    milestones_passed: 0
    milestones_failed: 0
    milestones_pending: 0
    total_lint_violations: 0
    total_vision_misalignments: 0
    human_reviews_completed: 0
    lowest_confidence: 0.0
    recommendation: "continue | fix_issues | major_revision"

  flagged_issues:
    - milestone: ""
      tier: ""
      breakpoint: ""
      description: ""
      screenshot_path: ""
      severity: "critical | warning | info"
```

---

## Step 8: Run Checkpoint

Verify all 6 checkpoint checks:

1. **code_lint_pass** -- Tier 1 ran for all applicable milestones; results
   recorded in report. Violations are logged (does not require zero violations,
   but all must be catalogued).

2. **screenshot_captured** -- Playwright screenshots exist at
   `.ai/projects/[name]/dev/screenshots/` for all breakpoints (375, 768, 1280)
   for each page checked.

3. **pencil_reference_loaded** -- At least one Pencil ground truth screenshot
   was successfully loaded from `render/screenshots/`. Missing references are
   logged as warnings, not failures.

4. **structural_alignment** -- LLM vision check completed for all applicable
   breakpoints, OR the check was escalated to human review (escalation counts
   as fulfilling this check).

5. **milestone_coverage** -- All milestones applicable to the current build
   state have been checked. No applicable milestone was skipped.

6. **report_written** -- `visual-verification-report.yml` exists, is valid YAML,
   and contains results for all checked milestones.

On failure: fix the failing check and re-run verification for that check only.
On pass: update `state.yml` with verification results.

---

## Integration Points

### e2e-testing Skill

The visual-verification skill shares the Playwright browser instance with
e2e-testing. When both skills run in the same build phase:

```
if e2e-testing has an active Playwright instance:
  reuse it for screenshot capture (avoid double browser launch)
else:
  launch a new Playwright instance
  offer it to e2e-testing for reuse
```

Screenshot capture uses `page.screenshot({ fullPage: true })` at each
breakpoint. The viewport is resized between captures.

### Implementation Guide

Implementation guide YAMLs (from the design phase) define the expected
structural properties for each page section:

- Grid column counts per breakpoint
- Container width tokens
- Section ordering and spacing
- Component placement within sections

Tier 1 (code lint) and Tier 2 (vision check) both reference these guides
to know what "correct" looks like.

### Design Tokens

Design tokens (`variables.css`, `tailwind.config.json`) define the allowed
vocabulary for Tier 1 code lint:

- Spacing scale (gap, padding, margin values)
- Color palette (brand, neutral, semantic colors)
- Typography scale (font sizes, line heights, weights)
- Container constraints (max-widths, breakpoints)

Any value in the codebase that does not map to a token is flagged.

---

## Two-Stage Verification

**Stage 1 -- Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- visual-verification-report.yml exists and is valid YAML
- Report contains results for at least one milestone
- All checked milestones have code_lint and vision_check sections
- Flagged issues array is populated (even if empty)
- Overall status is one of: pass, fail, partial

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 -- Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Code lint violations are actionable (file path + line number + suggestion)
- Vision check confidence scores are plausible (not all 1.0 or all 0.0)
- Human escalation was triggered when required (multi-page milestone)
- Report recommendation matches the actual results
- No milestone was marked passed with unresolved critical issues

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Error Handling

1. **Playwright not available:** Log error, skip Tier 2, escalate directly to
   Tier 3 (human review). Do not fail the entire skill.

2. **No Pencil references found:** If profile is `"detect"`, skip gracefully.
   If profile is `true`, log error and report `pencil_reference_loaded: false`.

3. **Vision model returns unexpected format:** Parse what is available, log
   the raw response, assign confidence 0.5 (triggers flag for review).

4. **Build not running / no rendered pages:** Cannot capture screenshots.
   Log error, suggest running `dev` server first.

5. **Before retrying:** Always check state.yml errors array for previous
   failed attempts. Never repeat the same approach.

---

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only visual-verification-report.yml and findings.md updates
2. Commit: `[plan_name]: visual-verification [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

---

## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED -- Stop hook enforces this)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable

The Stop hook will BLOCK completion if tracing is enabled and the trace file
is missing or has no `reflections:` section.
