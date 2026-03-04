# Web Layout — Detailed Process

## Overview

Web layout is the composition layer between component specs and generated code.
Each layout YAML defines a page as an ordered list of sections. Each section
references one component spec by name and provides the props, slot content
placeholders, and layout rules for that instance.

Three downstream skills consume layout YAMLs directly:

- **app-copy** reads `slots` across all layouts to generate placeholder content
- **scaffold** reads `sections[*].component` to generate Next.js page files
- **storybook-generator** reads layouts to generate full-page stories

---

## Layout YAML Format

Save each page layout as `design/layouts/<page-name>.yml`. Use kebab-case
matching the route (e.g., `home.yml`, `pricing.yml`, `blog-post.yml`).

```yaml
page: "home"
route: "/"
title: "Home"
description: "Main landing page — hero, features overview, social proof, CTA"
template: "marketing"   # marketing | app | auth | docs | blog | custom

sections:
  - name: "hero"
    component: "Hero"           # must match name field in components/Hero.yml
    props:
      variant: "primary"
      size: "lg"
      background: "brand"
    slots:
      heading: "Welcome to {brand_name}"
      subheading: "{brand_tagline}"
      cta_primary_label: "Get Started"
      cta_primary_href: "/signup"
      cta_secondary_label: "Learn More"
      cta_secondary_href: "#features"
    layout:
      width: "full"
      padding: "var(--spacing-16) var(--spacing-4)"
      min_height: "60vh"

  - name: "features"
    component: "FeatureGrid"
    props:
      columns: 3
      variant: "card"
    slots:
      heading: "Everything you need"
      subheading: "Built for teams that move fast"
      items: 3               # count only — app-copy fills content
    layout:
      width: "container"
      padding: "var(--spacing-12) var(--spacing-4)"

  - name: "social-proof"
    component: "TestimonialCarousel"
    props:
      variant: "minimal"
      autoplay: true
    slots:
      items: 4
    layout:
      width: "container"
      padding: "var(--spacing-10) var(--spacing-4)"
      background: "var(--color-neutral-50)"

  - name: "cta-banner"
    component: "CTABanner"
    props:
      variant: "primary"
    slots:
      heading: "Ready to get started?"
      body: "Join thousands of teams already using {brand_name}."
      cta_label: "Start Free Trial"
      cta_href: "/signup"
    layout:
      width: "full"
      padding: "var(--spacing-16) var(--spacing-4)"

responsive:
  mobile:
    sections:
      - name: "features"
        props: { columns: 1 }
        layout:
          padding: "var(--spacing-8) var(--spacing-4)"
      - name: "hero"
        layout:
          min_height: "auto"
  tablet:
    sections:
      - name: "features"
        props: { columns: 2 }
```

---

## Navigation Map Format

Save as `design/navigation-map.yml`.

```yaml
navigation:
  primary:
    position: "header"
    items:
      - label: "Home"
        href: "/"
        active_match: "exact"
      - label: "Features"
        href: "/features"
        active_match: "prefix"
      - label: "Pricing"
        href: "/pricing"
        active_match: "exact"
      - label: "Blog"
        href: "/blog"
        active_match: "prefix"
    cta:
      label: "Get Started"
      href: "/signup"
      variant: "primary"
    auth_items:
      signed_out:
        - label: "Log In"
          href: "/login"
          variant: "ghost"
      signed_in:
        - label: "Dashboard"
          href: "/dashboard"
          variant: "ghost"

  mobile_menu:
    type: "hamburger"           # hamburger | drawer | fullscreen
    breakpoint: "md"            # menu collapses below this breakpoint
    includes_cta: true

  breadcrumbs:
    enabled: true
    show_on_templates: ["docs", "blog", "app"]
    home_label: "Home"
    separator: "/"

  footer:
    columns:
      - title: "Product"
        links:
          - label: "Features"
            href: "/features"
          - label: "Pricing"
            href: "/pricing"
          - label: "Changelog"
            href: "/changelog"
      - title: "Company"
        links:
          - label: "About"
            href: "/about"
          - label: "Blog"
            href: "/blog"
          - label: "Careers"
            href: "/careers"
      - title: "Legal"
        links:
          - label: "Privacy Policy"
            href: "/privacy"
          - label: "Terms of Service"
            href: "/terms"
    bottom_bar:
      copyright: "© {year} {brand_name}. All rights reserved."
      social_links: true
```

---

## Field Reference

### `template` values

| Value | Usage |
|-------|-------|
| `marketing` | Public-facing pages: landing, pricing, about, blog |
| `app` | Authenticated app pages: dashboard, settings, profile |
| `auth` | Authentication flows: login, signup, forgot-password |
| `docs` | Documentation pages: guides, API reference |
| `blog` | Blog post detail pages |
| `custom` | One-off pages that don't fit a standard template |

### `layout.width` values

| Value | CSS equivalent |
|-------|---------------|
| `full` | `width: 100%` — edge-to-edge, no side padding from container |
| `container` | `max-width: var(--container-max)` centered with auto margins |
| `narrow` | `max-width: var(--container-narrow)` — for text-heavy content |
| `wide` | `max-width: var(--container-wide)` — for dashboards or galleries |

### `slots` placeholder conventions

| Pattern | Meaning |
|---------|---------|
| `"{brand_name}"` | Replaced with brand name at content-fill time |
| `"{brand_tagline}"` | Replaced with brand tagline |
| `"{year}"` | Replaced with current year |
| `3` (integer) | Slot accepts N repeated items — app-copy generates that many |
| `"text…"` (string) | Direct placeholder text — app-copy may refine |

### Responsive override rules

Only include breakpoint overrides for sections that actually change.
Do not repeat sections that stay identical across breakpoints.

Override keys supported per section:
- `props` — change any prop value at this breakpoint
- `layout` — change width, padding, min_height, background
- `hidden: true` — hide this section at this breakpoint (use sparingly)

---

## Default Page Set

Present this list to the user at the start. Confirm which to include and ask
for any additional pages before generating layouts.

| # | Page | Route | Template | Notes |
|---|------|-------|----------|-------|
| 1 | Home | `/` | marketing | Hero + features + social proof + CTA |
| 2 | Features | `/features` | marketing | Detailed feature showcase |
| 3 | Pricing | `/pricing` | marketing | Pricing tiers + FAQ + CTA |
| 4 | About | `/about` | marketing | Mission, team, values |
| 5 | Blog Index | `/blog` | marketing | Post list with filters |
| 6 | Blog Post | `/blog/[slug]` | blog | Single post with sidebar |
| 7 | Login | `/login` | auth | Email + password, OAuth options |
| 8 | Signup | `/signup` | auth | Registration form |
| 9 | Dashboard | `/dashboard` | app | Main app landing (authenticated) |
| 10 | 404 | `/404` | marketing | Not found page |

Additional pages users commonly request: `/contact`, `/terms`, `/privacy`,
`/docs`, `/careers`, `/changelog`, `/settings`, `/profile`.

---

## Step-by-Step Execution

### Step 1 — Read component specs

```
Read: .ai/projects/[name]/design/components/*.yml
Read: .ai/projects/[name]/brand/brand-summary.yml
```

If the `design/components/` directory is empty or absent, stop:
"component-specs phase must run first. Run /agency:design and complete the
component-specs phase."

Build a component registry: map each spec's `name` field to its file path.
This is the allowed set of values for `section.component` in all layouts.

**Save to findings.md after this step (2-Action Rule checkpoint).**

### Step 2 — Present site map to user

Present the default 10-page set as a table. Ask:

```
Here is the default page set for your site. Which pages should I include?

Reply with:
  - Numbers to exclude (e.g., "skip 5, 6" to omit blog pages)
  - Additional routes to add (e.g., "/contact", "/docs")
  - Or "all" to confirm the full set
```

Wait for confirmation before generating any layouts.

### Step 3 — Compose layouts by template type

Group the confirmed pages by template. Generate all layouts for one template
type, then present them for review before moving to the next group.

For each page:
1. Choose sections appropriate to the page's purpose
2. For each section, pick the most appropriate component from the registry
3. Assign props from the component's `props` spec (use defaults where sensible)
4. Map slot placeholders — use `{brand_name}` / `{brand_tagline}` patterns for
   dynamic copy; use integers for repeated items
5. Set `layout.width` and padding tokens from `variables.css`
6. Flag sections that need responsive overrides (multi-column grids, hero
   min-height, hidden mobile elements)

Ensure every `section.component` value maps to a key in the component registry.
Any component used in a layout that doesn't exist in `components/` is an error.

**Save to findings.md after this step (2-Action Rule checkpoint).**

### Step 4 — Define responsive overrides

After composing all sections for a page, add the `responsive` block:

- **mobile** — override column counts to 1, adjust padding, set auto heights
- **tablet** — override column counts to 2 where 3 columns were used on desktop
- Skip breakpoints where no changes are needed

Rule: every `FeatureGrid`, `CardGrid`, `Gallery`, or similar multi-column
component must have a `mobile` override setting `columns: 1`.

### Step 5 — User review cycle

After generating each template group:

```
Here are the [template] page layouts. Review and let me know:
  - Sections to add or remove from any page
  - Component substitutions (e.g., use Accordion instead of FeatureGrid)
  - Prop or slot adjustments
  - Responsive override changes
Reply "ok" to continue, or list changes.
```

Apply all feedback before writing files.

**Save to findings.md after this step (2-Action Rule checkpoint).**

### Step 6 — Generate navigation-map.yml

After all layouts are approved:

1. Extract all confirmed routes from the layout list — these form the site map
2. Identify which routes belong in primary navigation (typically ≤6 items)
3. Identify footer column structure based on route categories
4. Confirm mobile menu type (hamburger is the default)
5. Set `breadcrumbs.show_on_templates` based on which templates were confirmed

Write `design/navigation-map.yml`.

### Step 7 — Write layout YAML files

Write each layout to: `.ai/projects/[name]/design/layouts/<page-name>.yml`

Filename rules:
- Use the route path with `/` replaced by `-` and leading `-` removed
- Dynamic segments: `[slug]` → `slug` (e.g., `blog-slug.yml`)
- Examples: `/` → `home.yml`, `/blog/[slug]` → `blog-slug.yml`

### Step 8 — Register in asset-registry.yml

Append or update the `layouts` section of `asset-registry.yml`:

```yaml
layouts:
  - path: "design/layouts/home.yml"
    type: "page_layout"
    name: "Home"
    route: "/"
    template: "marketing"
    phase: 4
  - path: "design/navigation-map.yml"
    type: "navigation_map"
    name: "Navigation Map"
    phase: 4
```

Always read the existing `asset-registry.yml` first and merge — do not
overwrite the `tokens` or `components` sections written by earlier phases.

### Step 9 — Run checkpoint

Verify all 5 checkpoint checks pass:

1. **layouts_exist** — count YAML files in `design/layouts/` — must match the
   number of routes confirmed in Step 2
2. **components_referenced** — for every `section.component` value across all
   layouts, verify the name exists in the component registry from Step 1
3. **navigation_map** — `design/navigation-map.yml` exists and contains
   `navigation.primary`, `navigation.footer`, and `navigation.mobile_menu` blocks
4. **responsive_rules** — every layout containing a multi-column component
   (columns > 1) has a `responsive.mobile` override setting `columns: 1`
5. **assets_registered** — count of entries in `asset-registry.yml` layouts
   section matches: layout file count + 1 (navigation-map.yml)

On failure: fix the failing check and re-run verification for that check only.
On pass: update `state.yml` — set web-layout phase to `completed`.

---

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- layouts_exist: at least 1 layout YAML exists per route defined in navigation-map.yml
- components_referenced: every component reference in section.component maps to an existing spec in components/
- navigation_map: navigation-map.yml exists with primary nav, footer, and mobile_menu blocks
- responsive_rules: every layout with multi-column sections includes responsive overrides for mobile
- assets_registered: all layout YAMLs and navigation-map.yml registered in asset-registry.yml

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Page sections are appropriate for each page's purpose (hero on home, no hero on auth pages)
- Primary navigation has ≤6 items; secondary routes are in footer
- Slot placeholders use correct patterns (`{brand_name}`, integers for repeated items)
- Responsive overrides are present for all multi-column grids
- Navigation map reflects the confirmed route set — no orphaned routes

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Common Issues

**Component not in registry:** Every value in `section.component` must exactly
match the `name` field in a spec YAML. Check capitalisation — `"FeatureGrid"`
not `"feature-grid"`. If the component doesn't exist, either add it to
component-specs or choose a different component.

**Slot count vs slot names:** When a slot is an integer (items: 3), app-copy
generates N repeated items. When it is a string, app-copy treats it as a single
placeholder. Don't mix — decide per slot which pattern applies.

**Too many primary nav items:** Primary navigation should have ≤6 items.
Move secondary routes to the footer. If the user insists on more, add a
mega-menu or dropdown structure and note it in the navigation map.

**Missing responsive override for grid:** Any component with `columns > 1`
in its props must have a mobile override. The checkpoint will fail without it.

**Overwriting asset-registry.yml:** Always read first. Three sections exist
after phase 3: `tokens`, `components`. Phase 4 adds `layouts`. Merge carefully.

**Dynamic route pages:** For pages with dynamic segments (e.g., `/blog/[slug]`),
the layout describes the template structure — app-copy fills the slot content.
Note `dynamic: true` in the layout YAML frontmatter if desired.

---

## Trace Protocol

If `state.yml` has `trace.enabled: true`, follow the
[trace protocol](../../../../resources/trace-protocol.md) to write a structured
trace file to `.ai/projects/[name]/traces/`.
