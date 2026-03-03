# Component Specs — Detailed Process

## Overview

Component specs are the machine-readable contracts between design and
development. Every spec fully describes a UI component: its configurable
props, which design tokens it uses, where content is injected (slots), how
it behaves across states, its accessibility contract, and its responsive rules.
Three downstream skills consume these specs directly:

- **app-copy** reads `slots` to generate placeholder content
- **storybook-generator** reads `props` and `states` to generate stories
- **scaffold** reads the full spec to generate TypeScript component code

---

## Component Spec YAML Format

Save each component as `design/components/<ComponentName>.yml`.

```yaml
name: "Button"
description: "Primary interactive button component"
category: "interactive"  # interactive | display | layout | navigation | form | feedback

props:
  variant:
    type: "enum"
    values: ["primary", "secondary", "outline", "ghost", "destructive"]
    default: "primary"
    description: "Visual style variant"
  size:
    type: "enum"
    values: ["sm", "md", "lg"]
    default: "md"
    description: "Component size"
  disabled:
    type: "boolean"
    default: false
    description: "Disables interaction and applies reduced opacity"
  loading:
    type: "boolean"
    default: false
    description: "Replaces content with loading indicator"
  icon:
    type: "string"
    required: false
    description: "Icon name to display before label (from icon set)"

tokens:
  background:
    primary: "var(--color-primary-500)"
    secondary: "var(--color-secondary-500)"
    outline: "transparent"
    ghost: "transparent"
    destructive: "var(--color-error-500)"
  text:
    primary: "var(--color-white)"
    secondary: "var(--color-white)"
    outline: "var(--color-primary-500)"
    ghost: "var(--color-primary-500)"
    destructive: "var(--color-white)"
  border_radius: "var(--radius-md)"
  font_family: "var(--font-body)"
  font_weight: "var(--font-weight-semibold)"
  padding:
    sm: "var(--spacing-2) var(--spacing-3)"
    md: "var(--spacing-3) var(--spacing-4)"
    lg: "var(--spacing-4) var(--spacing-6)"

slots:
  label:
    type: "text"
    required: true
    max_length: 40
    description: "Button label text"
  icon:
    type: "icon"
    required: false
    description: "Icon before label text"

states:
  hover:
    background: "shade +10%"
    cursor: "pointer"
  active:
    background: "shade +20%"
    transform: "scale(0.98)"
  focus:
    outline: "2px solid var(--color-primary-300)"
    outline_offset: "2px"
  disabled:
    opacity: 0.5
    cursor: "not-allowed"
  loading:
    opacity: 0.7
    cursor: "wait"

a11y:
  role: "button"
  keyboard:
    Enter: "activate"
    Space: "activate"
  focus_management: "included in tab order"
  aria_attributes:
    aria-disabled: "maps to disabled prop"
    aria-busy: "maps to loading prop"
  contrast: "text/background meets WCAG AA (verified via design-tokens)"

responsive:
  mobile:
    width: "100%"
    size: "lg"   # force large on mobile for touch targets (min 44px)
  tablet:
    width: "auto"
    size: "md"
  desktop:
    width: "auto"
    size: "md"
```

---

## Field Reference

### `category` values

| Value | Examples |
|-------|---------|
| `interactive` | Button, Link, Toggle, Checkbox, RadioButton |
| `display` | Card, Badge, Tag, Avatar, Heading, Paragraph |
| `layout` | Container, Grid, Stack, Divider |
| `navigation` | Navbar, Sidebar, Breadcrumb, Tabs, Pagination |
| `form` | Input, Textarea, Select, DatePicker, FileUpload |
| `feedback` | Alert, Toast, Modal, Tooltip, Spinner, ProgressBar |

### `props` type values

| Type | Usage |
|------|-------|
| `enum` | Fixed set of string options — always include `values` and `default` |
| `string` | Free-form text — note `required: false` if optional |
| `boolean` | True/false flag — always include `default` |
| `number` | Numeric value — include `min`, `max` if bounded |
| `ReactNode` | Arbitrary JSX content (use sparingly; prefer named slots) |

### `tokens` conventions

- Always reference CSS custom properties (`var(--token-name)`) — never hex values
- Token names must exist in `variables.css` or as keys in `tailwind.config.json`
- Map per-variant overrides as nested objects (see `background` above)
- For shade adjustments, use descriptive strings (`"shade +10%"`) — scaffold resolves

### `slots` type values

| Type | Usage |
|------|-------|
| `text` | Plain text content — include `max_length` |
| `rich_text` | Markdown or HTML — note allowed tags |
| `icon` | Icon name string referencing icon set |
| `image` | Image URL or asset path — include `alt` requirement |
| `node` | Arbitrary child components |

### `a11y` requirements by category

**Interactive components** (button, link, toggle, checkbox):
- `role` — explicit ARIA role
- `keyboard` — all keyboard triggers that activate the component
- `focus_management` — tab order position, focus trap if modal
- `aria_attributes` — map all state props to ARIA attributes

**Display components** (card, badge, heading):
- `role` — only if semantically meaningful (e.g., `article`, `status`)
- `contrast` — confirm WCAG AA via design-tokens contrast matrix
- `aria_label` — when visual context doesn't convey meaning to screen readers

**Form components** (input, select, textarea):
- `role` — usually implicit from HTML element
- `label_association` — how the label is linked (`htmlFor`, `aria-label`, `aria-labelledby`)
- `error_announcement` — how validation errors are communicated (`aria-invalid`, `aria-describedby`)
- `keyboard` — navigation within complex widgets (e.g., combobox)

**Navigation components**:
- `role` — `navigation` landmark for primary nav, `menu` for dropdowns
- `aria_current` — mark the active item
- `keyboard` — arrow-key navigation for menus

### `responsive` breakpoints

Use the same breakpoints defined in `tailwind.config.json`:
- `mobile` — default (mobile-first) — up to 640px (sm)
- `tablet` — md breakpoint and above (768px)
- `desktop` — lg breakpoint and above (1024px)
- `wide` — xl breakpoint and above (1280px) — optional

For touch targets: minimum 44×44px on mobile (WCAG 2.5.5).

---

## Core Component Set

These 10 components are the minimum baseline. Present this list to the user
and confirm which to include. Users may exclude any component or add extras.

| # | Component | Category | Notes |
|---|-----------|----------|-------|
| 1 | Button | interactive | 5 variants minimum |
| 2 | Input | form | text, email, password, number, search types |
| 3 | Card | display | content container, may include header/body/footer slots |
| 4 | Navigation | navigation | header nav + mobile hamburger menu |
| 5 | Badge / Tag | display | status labels, category tags |
| 6 | Alert / Toast | feedback | info, success, warning, error variants |
| 7 | Modal / Dialog | feedback | includes focus trap, close on Escape |
| 8 | Avatar | display | image + initials fallback |
| 9 | Heading | display | H1–H6 with token mapping per level |
| 10 | Paragraph | display | body text, lead text, caption variants |

Additional components the user may request: Accordion, Breadcrumb, Checkbox,
Combobox, DataTable, DatePicker, Drawer, Dropdown, FileUpload, Form,
ProgressBar, RadioGroup, Select, Skeleton, Slider, Spinner, Switch, Tabs,
Textarea, Timeline, Toggle, Tooltip.

---

## Step-by-Step Execution

### Step 1 — Read design tokens

```
Read: .ai/projects/[name]/design/tokens/tailwind.config.json
Read: .ai/projects/[name]/design/tokens/variables.css
Read: .ai/projects/[name]/brand/brand-summary.yml
```

If tailwind.config.json does not exist, stop: "design-tokens phase must run
first. Run /agency:design and complete the tokens phase."

Extract from tailwind.config.json:
- All color scale keys (`colors.*`)
- Font family keys (`fontFamily.*`)
- Spacing scale keys (`spacing.*`)
- Border radius keys (`borderRadius.*`)

Extract from variables.css:
- All `--` custom property names in `:root`

Build a token registry (key → CSS variable) to validate references later.

**Save to findings.md after this step (2-Action Rule checkpoint).**

### Step 2 — Present component list to user

Present the 10-component baseline table. Ask:

```
Which components should I spec? I'll generate all 10 by default.
Reply with:
  - Numbers to exclude (e.g., "skip 7, 8")
  - Additional component names to add
  - Or "all" to confirm the full baseline
```

Wait for user confirmation before generating any specs.

### Step 3 — Generate specs by category

Group components by category. Generate all specs for one category, then show
them to the user before moving to the next group. This keeps review batches
manageable.

For each component:
1. Draft the YAML spec using the full format above
2. Map every token reference to a key from the token registry (Step 1)
3. Assign slots to all text/image content areas
4. Add states for all interactive variants
5. Fill a11y requirements appropriate to the component's category
6. Add responsive rules, ensuring mobile touch targets ≥ 44px

### Step 4 — User review cycle

After generating each category batch:
```
Here are the [category] component specs. Review and let me know:
  - Any props to add or remove
  - Token adjustments
  - Content slot changes
  - Accessibility additions
Reply "ok" to move on, or list changes.
```

Apply all feedback before moving to the next category.

**Save to findings.md after this step (2-Action Rule checkpoint).**

### Step 5 — Validate token references

Before writing files, verify every `var(--token-name)` used in the `tokens`
section exists in the token registry from Step 1.

For any invalid reference: stop and either correct the token name or ask the
user to confirm it will be added to the token files.

**Save to findings.md after this step (2-Action Rule checkpoint).**

### Step 6 — Write component YAML files

Write each spec to: `.ai/projects/[name]/design/components/<ComponentName>.yml`

Use PascalCase for filenames matching the `name` field in the YAML
(e.g., `Button.yml`, `Navigation.yml`).

### Step 7 — Register in asset-registry.yml

Append or update the `components` section of `asset-registry.yml`:

```yaml
components:
  - path: "design/components/Button.yml"
    type: "component_spec"
    name: "Button"
    category: "interactive"
    phase: 3
  # ... one entry per component
```

If `asset-registry.yml` was created by design-tokens, merge the new section
rather than overwriting.

### Step 8 — Run checkpoint

Verify all 6 checkpoint checks pass:

1. **components_exist** — count YAML files in `design/components/` — must be ≥ 5
2. **required_fields** — each file must have: name, description, props, tokens,
   slots, a11y, responsive
3. **token_references_valid** — all `var(--*)` references in `tokens` sections
   map to known token keys
4. **slots_defined** — every component whose rendered output contains user-facing
   text has ≥ 1 slot with `type: text` or `type: rich_text`
5. **a11y_requirements** — every component with `category: interactive` or
   `category: form` or `category: navigation` has: role, keyboard, focus_management,
   aria_attributes
6. **assets_registered** — count entries in `asset-registry.yml` components
   section matches file count

On failure: fix the failing check and re-run verification for that check only.
On pass: update `state.yml` — set component-specs phase to `completed`, advance
pointer to `web-layout`.

---

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- components_exist: at least 5 component spec YAML files exist in `design/components/`
- required_fields: every spec has name, description, props, tokens, slots, a11y, responsive
- token_references_valid: all token references map to keys in tailwind.config.json or variables.css
- slots_defined: every component with text content has at least 1 content slot
- a11y_requirements: every interactive component has ARIA roles, keyboard navigation, focus management
- assets_registered: all component specs registered in asset-registry.yml

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Props are complete — no obvious configurable variations are missing
- Token references are semantically appropriate (e.g., brand primary used for CTAs, not neutrals)
- A11y requirements are thorough for interactive/form/navigation components
- Responsive rules enforce minimum 44px touch targets on mobile
- Component set covers all downstream needs (app-copy slots, scaffold code, storybook stories)

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Common Issues

**Token not found:** Check spelling. CSS custom property names are case-sensitive.
Use `grep` on variables.css or scan tailwind.config.json keys.

**Slot missing:** Any text visible to the user that isn't a static label (e.g.,
button variant names) must be a slot. When in doubt, make it a slot.

**A11y incomplete for interactive:** All five — role, keyboard, focus_management,
aria_attributes, contrast — are required for interactive components. Do not skip.

**Touch target too small on mobile:** Set `size: "lg"` in `responsive.mobile` for
button-like components. Document the computed pixel size (lg = 48px+ is safe).

**Overwriting asset-registry.yml:** Always read the file first and merge the
`components` section. design-tokens wrote the `tokens` section — preserve it.
