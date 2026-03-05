# Storybook Generator — Process Reference

Full process detail for the storybook-generator skill. Read this before
executing any story generation steps.

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


## Step 1 — Read Component Specs

**Source:** `.ai/projects/[name]/design/components/*.yml`

For each component YAML, extract:

| Field | Used For |
|-------|----------|
| `name` | Story file name (`[name].stories.yml`) |
| `props` | Default story prop map; required props flagged |
| `slots` | Slot keys to fill with copy |
| `states` | State variant story names (loading, error, empty, disabled) |
| `a11y.role` | a11y story `role` annotation |
| `a11y.aria_*` | a11y story `aria_label` and other ARIA fields |
| `a11y.keyboard` | a11y story keyboard navigation note |
| `responsive` | Breakpoint names and viewport sizes |
| `tokens` | Reference only — not written into stories |

Stop and report if `design/components/` is empty or component-specs state shows
`status: pending`. Do not generate stories from missing upstream data.

Save findings after reading each batch of 5 components:

```markdown
## findings.md — Component Parse Pass
- Components found: [n]
- Slots total: [n]
- States total: [n]
- Components missing a11y: [list]
- Components missing slots: [list]
```

---

## Step 2 — Read Page Copy YAMLs

**Source:** `.ai/projects/[name]/content/pages/*.yml`

Page copy format produced by app-copy:

```yaml
page: /route
components:
  hero-section:
    headline: "..."
    body: "..."
    cta: "..."
  feature-card:
    title: "..."
    description: "..."
    link_label: "..."
```

Build a lookup map: `component → slot → copy string`.

When the same component appears on multiple pages, prefer the homepage entry
(`/` route) for the Default story. Record all page occurrences for context.

If a component has no page copy (e.g. pure-UI utility components like Spinner,
Divider), mark its slots as `_no_copy: true` — the Default story will use
descriptive placeholder values instead.

Save findings after processing page copy:

```markdown
## findings.md — Copy Map Pass
- Pages processed: [n]
- Components with copy: [n]
- Components without copy (use placeholders): [list]
- Slot coverage gaps: [list]
```

---

## Step 3 — Read UX Copy YAMLs

**Source:** `.ai/projects/[name]/content/ux/*.yml`

Files and their role in stories:

| File | Story variant |
|------|---------------|
| `error-messages.yml` | `error` state story — fills `error.message`, `error.title`, `error.action` |
| `validation-messages.yml` | `invalid` state story — fills `validation.message` |
| `tooltips.yml` | `tooltip` variant — fills `tooltip.content` |
| `confirmations.yml` | `confirm` variant — fills dialog `title`, `body`, `confirm_label`, `cancel_label` |
| `states.yml` | `loading`, `empty`, `disabled` state stories — fills status copy |
| `labels.yml` | All stories — fills `label`, `placeholder`, `aria_label` fields |

UX copy is keyed by component name and state. Example lookup:

```yaml
# error-messages.yml
form-input:
  required:
    code: "FIELD_REQUIRED"
    severity: error
    title: "This field is required"
    description: "Please fill in this field to continue."
    action: "Enter a value and try again."
```

If a component has no UX copy entry for a given state, use the generic
`_global` fallback in that file. If no fallback exists, use the placeholder
pattern `"[component] [state] message"`.

---

## Step 4 — Generate Story YAML Per Component

One `.stories.yml` file per component. File naming: `[component-name].stories.yml`.

### Full Story YAML Format

```yaml
component: hero-section
source_spec: design/components/hero-section.yml
generated_from:
  - content/pages/home.yml
  - content/ux/states.yml
  - content/ux/error-messages.yml

stories:
  - name: default
    description: "Primary rendering with all slots filled and default props"
    props:
      variant: primary
      size: lg
      # ... all required props from component spec
    slots:
      headline: "Build something people love"
      body: "We help ambitious teams ship faster with less friction."
      cta: "Get started free"

  - name: loading
    description: "Skeleton or spinner state while data is fetching"
    props:
      isLoading: true
    slots:
      headline: ""
      body: ""
    ux_copy:
      status: "Loading content…"   # from states.yml

  - name: error
    description: "Error state — failed data fetch or action"
    props:
      isLoading: false
    slots:
      headline: ""
      body: ""
    error:
      code: "FETCH_FAILED"
      title: "Something went wrong"
      description: "We couldn't load this section. Please try again."
      action: "Retry"

  - name: empty
    description: "No data available — first-time user or cleared state"
    props:
      isEmpty: true
    slots:
      headline: "Nothing here yet"
      body: "Content will appear once data is available."
      cta: ""
    ux_copy:
      empty_label: "No content"   # from states.yml

  - name: disabled
    description: "Non-interactive disabled state"
    props:
      disabled: true
    slots:
      headline: "Build something people love"
      body: "We help ambitious teams ship faster with less friction."
      cta: "Get started free"
    ux_copy:
      disabled_reason: "Action unavailable"   # from states.yml

  - name: mobile
    description: "Mobile viewport rendering"
    viewport:
      width: 375
      height: 812
      label: mobile
    props:
      variant: primary
    slots:
      headline: "Build something people love"
      body: "We help ambitious teams ship faster."
      cta: "Get started"

  - name: tablet
    description: "Tablet viewport rendering"
    viewport:
      width: 768
      height: 1024
      label: tablet
    props:
      variant: primary
    slots:
      headline: "Build something people love"
      body: "We help ambitious teams ship faster with less friction."
      cta: "Get started free"

  - name: desktop
    description: "Desktop viewport rendering (default baseline)"
    viewport:
      width: 1280
      height: 800
      label: desktop
    props:
      variant: primary
    slots:
      headline: "Build something people love"
      body: "We help ambitious teams ship faster with less friction."
      cta: "Get started free"

  - name: a11y
    description: "Accessibility annotations — ARIA roles, keyboard navigation"
    props:
      variant: primary
    slots:
      headline: "Build something people love"
      body: "We help ambitious teams ship faster with less friction."
      cta: "Get started free"
    annotations:
      role: "banner"
      aria_label: "Hero section — primary call to action"
      aria_live: "off"
      focus_order:
        - "heading (h1)"
        - "body text"
        - "CTA button"
      keyboard:
        - "Tab: move focus to CTA button"
        - "Enter / Space: activate CTA"
      wcag_criteria:
        - "1.1.1 Non-text Content — decorative images marked aria-hidden"
        - "1.4.3 Contrast — text meets 4.5:1 minimum"
        - "2.1.1 Keyboard — all interactions operable via keyboard"
        - "4.1.2 Name, Role, Value — button has accessible label"
```

### Required Stories Per Component

Every component MUST include:

- `default` — always required
- State variants — only generate stories for states declared in the component spec
- Responsive variants — only generate for breakpoints declared in the component spec
- `a11y` — always required for interactive components; include for display
  components only if they have ARIA requirements in the spec

### Optional / Conditional Stories

Include only when the component spec declares the relevant state or slot:

| Story name | Include when spec has... |
|------------|--------------------------|
| `loading` | `states: [loading]` |
| `error` | `states: [error]` |
| `empty` | `states: [empty]` |
| `disabled` | `props.disabled` or `states: [disabled]` |
| `tooltip` | `slots.tooltip` or `states: [tooltip]` |
| `confirm` | `states: [confirm]` |
| `invalid` | `states: [invalid]` |

---

## Step 5 — User Review

Present stories grouped by component category (layout, navigation, forms,
content, feedback, utility). For each group:

1. Show component name + story count
2. Highlight any slots that used placeholder copy (no source found)
3. Highlight any states that used generic UX copy fallback
4. Ask user to confirm or request changes before proceeding

Do not advance past review without explicit user confirmation per category.

---

## Step 6 — Register in asset-registry.yml

Add all generated `.stories.yml` files under `dev.stories`:

```yaml
dev:
  stories:
    - path: dev/stories/hero-section.stories.yml
      component: hero-section
      story_count: 8
      generated_at: "2026-03-03"
    - path: dev/stories/feature-card.stories.yml
      component: feature-card
      story_count: 6
      generated_at: "2026-03-03"
```

---

## Step 7 — Run Checkpoint

Verify all 5 checks:

1. **stories_exist_per_component** — count `.stories.yml` files in `dev/stories/`,
   compare against component YAML count in `design/components/`
2. **props_covered** — for each story file, confirm `props` map contains all
   `required: true` props from the source component spec
3. **slots_filled_with_copy** — for Default and non-empty state stories, confirm
   every slot key has a non-empty string value (not a placeholder marker)
4. **a11y_annotations_present** — for each `.stories.yml`, confirm an `a11y`
   story exists and has `role`, `aria_label`, and `keyboard` fields
5. **assets_registered** — confirm asset-registry.yml `dev.stories` section
   lists every generated file

On failure: report which check failed and which component files are affected.
Do not mark the skill complete until all 5 checks pass.

On pass: update `state.yml` skill status to `completed`, advance to scaffold.

---

## Placeholder Copy Rules

When no copy source is available for a slot, use these patterns:

| Slot type | Placeholder pattern |
|-----------|---------------------|
| `headline` | `"[ComponentName] heading"` |
| `body` | `"[ComponentName] body copy goes here."` |
| `cta` | `"[Action]"` |
| `label` | `"[ComponentName] label"` |
| `description` | `"[ComponentName] description."` |
| `placeholder` (input) | `"Enter [field name]…"` |
| `tooltip` | `"[ComponentName] tooltip content"` |
| Error `title` | `"Something went wrong"` |
| Error `description` | `"An error occurred. Please try again."` |
| Error `action` | `"Try again"` |

Placeholder slots must be flagged in the story YAML with `_source: placeholder`
so reviewers know they need real copy:

```yaml
slots:
  headline: "[ComponentName] heading"
  _source: placeholder
```

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
