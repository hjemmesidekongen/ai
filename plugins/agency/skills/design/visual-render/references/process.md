# Visual Render — Detailed Process

## Overview

Visual render is the bridge between agency specs and Pencil MCP. It reads all
structured YAML outputs from the design and content pipelines, then produces
a live `.pen` file with design variables, reusable components, composed page
screens, and AI-generated imagery.

Three key integrations drive this skill:

- **Pencil MCP tools** for document creation, variable management, batch design
  operations, image generation, screenshots, and layout inspection
- **Agency design specs** (tokens, components, layouts) for structural input
- **Agency content** (page copy, brand personality) for text and visual direction

---

## Token Mapping Strategy

When converting CSS custom properties from `variables.css` to Pencil variables:

| CSS Variable Pattern | Pencil Variable | Type | Conversion |
|---------------------|----------------|------|------------|
| `--color-*` | `color-*` | color | Direct hex value |
| `--font-family-*` | `font-*` | string | Direct value |
| `--font-size-*` | `font-size-*` | number | rem × 16 → px |
| `--font-weight-*` | `font-weight-*` | string | Direct value |
| `--spacing-*` | `spacing-*` | number | rem × 16 → px |
| `--radius-*` | `radius-*` | number | rem × 16 → px |
| `--shadow-*` | (skip) | — | Pencil handles shadows differently |

Conversion rules:
- Strip the `--` prefix from CSS variable names
- Convert `rem` values to `px` by multiplying by 16
- Keep hex colors as-is (Pencil accepts `#RRGGBB` and `#RRGGBBAA`)
- Quote font family strings

---

## Component Rendering Approach

For each component spec YAML, create a Pencil reusable component:

```
component-spec.yml                    Pencil Component
─────────────────                     ────────────────
name: "Button"           ──────►      frame (reusable: true, name: "Button")
tokens.background:                      ├─ fill: "$color-primary-500"
  primary: "var(--color-primary-500)"   ├─ padding: [$spacing-3, $spacing-6]
tokens.padding:                         ├─ cornerRadius: $radius-md
  md: "var(--spacing-3) var(--spacing-6)"
slots.label:              ──────►       └─ text (id: "label", content: "Button")
  type: "text"                               fill: "$color-white"
  required: true                             fontFamily: "$font-primary"
```

Key rules:
- Use `reusable: true` on the top-level frame
- Map `tokens.*` references to Pencil variable references (`$variable-name`)
- Create child nodes for each slot in the spec
- Text slots → text nodes; content slots → frame placeholders
- Build only the default variant as the reusable component
- Name the component frame exactly as the spec `name` field

---

## Step 1 — Read All Inputs (Prerequisite Gate)

Read every upstream spec file into working memory. Build lookup registries
for downstream steps. Fail fast if any prerequisite is missing.

### Files to Read

```
.ai/projects/{name}/brand/brand-summary.yml     → brand personality, mood, colors
.ai/projects/{name}/design/tokens/variables.css  → CSS custom properties
.ai/projects/{name}/design/tokens/tailwind.config.json → scale values
.ai/projects/{name}/design/components/*.yml      → component specs (all files)
.ai/projects/{name}/design/layouts/*.yml         → page layouts (all files)
.ai/projects/{name}/design/navigation-map.yml    → nav structure
.ai/projects/{name}/content/pages/*.yml          → filled page copy (all files)
```

### Build Registries

```
token_map:       { variable_name → { value, type, pencil_type } }
component_map:   { component_name → { spec, tokens, slots, variants } }
layout_list:     [ { page, route, sections[] } ]  — sorted by route
copy_map:        { route → { page_copy_yaml } }
nav_structure:   { primary_nav, footer, mobile_menu }
brand:           { personality, mood, colors, fonts }
```

### Prerequisite Check

All of these must exist — if any is missing, report which upstream skill
needs to run and exit:

| File | Required Skill |
|------|---------------|
| brand-summary.yml | brand-loader |
| variables.css | design-tokens |
| tailwind.config.json | design-tokens |
| At least 1 component YAML | component-specs |
| At least 1 layout YAML | web-layout |
| navigation-map.yml | web-layout |
| At least 1 page copy YAML | app-copy |

If all present, save to findings.md:
```markdown
## Step 1: Inputs Loaded
- Tokens: {N} CSS custom properties parsed
- Components: {N} specs loaded ({names})
- Layouts: {N} pages ({routes})
- Content: {N} page copy files
- Brand: {personality keywords}
```

---

## Step 2 — Style Guide Selection

Match the brand personality to Pencil's style guide system for visual
inspiration and layout patterns.

### Procedure

1. Call `get_style_guide_tags()` to retrieve available Pencil tags
2. Read `creative-direction.yml` — extract `identity`, `feel`, and `motion_philosophy`
3. Match brand-summary.yml `personality` and `mood` keywords to tags, refined by
   creative-direction.yml `identity` and `feel` keywords:
   - e.g., brand mood "bold, modern" + identity "disruptor" → tags `["modern", "bold", "clean", "website"]`
   - e.g., brand mood "warm, friendly" + feel "approachable" → tags `["friendly", "warm", "organic", "website"]`
   - Always include "website" as a base tag
   - Creative direction `texture` (e.g., "grain", "glass") can add texture-related tags
   - Creative direction `color_strategy` (e.g., "monochromatic", "complementary") refines color tag selection
4. Call `get_style_guide(tags)` for visual inspiration — colors, typography
   pairings, layout patterns
5. Call `get_guidelines("landing-page")` for landing page patterns
   - If project type is "app" or "dashboard", also call `get_guidelines("tailwind")`
6. Present style direction to user:
   ```
   ## Style Direction
   Based on brand personality ({keywords}), I've selected:
   - Style guide: {name}
   - Key visual patterns: {list}
   - Layout approach: {description}

   Does this direction work, or should I explore alternatives?
   ```
7. Wait for user confirmation before proceeding

Save to findings.md:
```markdown
## Step 2: Style Guide
- Tags matched: {tags}
- Style guide: {name}
- Guidelines loaded: {list}
- User confirmed: yes/no
```

---

## Step 3 — Create Document & Set Variables

Create the Pencil document and inject all design tokens as Pencil variables.

### Procedure

1. Check if a `.pen` file already exists at `render/{project-name}.pen`:
   - If yes: call `open_document("{path}")` to resume
   - If no: call `open_document("new")` to create fresh document
2. Parse `variables.css` — extract all `--*` custom properties from `:root {}`:
   ```css
   :root {
     --color-primary-500: #3b82f6;   → { "color-primary-500": { type: "color", value: "#3b82f6" } }
     --spacing-4: 1rem;              → { "spacing-4": { type: "number", value: 16 } }
     --font-primary: "Inter";        → { "font-primary": { type: "string", value: "Inter" } }
     --radius-md: 0.375rem;          → { "radius-md": { type: "number", value: 6 } }
   }
   ```
3. Conversion rules:
   - Color values (`#hex`, `rgb()`, `hsl()`) → type: "color"
   - Numeric values with `rem` → type: "number", multiply by 16
   - Numeric values with `px` → type: "number", strip unit
   - Quoted strings → type: "string"
   - Plain numbers (e.g., font-weight `700`) → type: "number"
4. Call `set_variables()` with the full variable set
5. If brand-summary.yml indicates dark mode support:
   - Add theme axis: `{ "mode": ["light", "dark"] }`
   - Map light/dark token values to each theme
6. Call `get_variables()` to verify — count should match CSS property count

Save to findings.md:
```markdown
## Step 3: Variables Set
- Document: {path or "new"}
- Variables set: {N} ({N} colors, {N} spacing, {N} fonts, {N} radii)
- Dark mode: {yes/no}
- Verification: {match/mismatch}
```

---

## Step 4 — Build Reusable Pencil Components

Create one reusable Pencil component for each component spec YAML.

### Procedure

For each component spec file in `design/components/*.yml`:

1. Read the spec — extract `name`, `tokens`, `slots`, `variants`, `a11y`
2. Plan the component structure:
   - Top frame: `reusable: true`, named after spec `name`
   - Map spec `tokens` to Pencil properties:
     - `tokens.background` → frame `fill` using `$color-*` variable
     - `tokens.text_color` → text `fill` using `$color-*` variable
     - `tokens.font_family` → text `fontFamily` using `$font-*` variable
     - `tokens.font_size` → text `fontSize` using `$font-size-*` variable
     - `tokens.padding` → frame padding using `$spacing-*` variables
     - `tokens.border_radius` → frame `cornerRadius` using `$radius-*` variable
     - `tokens.gap` → frame `gap` using `$spacing-*` variable
   - Create child nodes per slot:
     - Text slots → text node with placeholder content
     - Image slots → frame with placeholder fill
     - Content slots → frame with `fit_content` sizing
3. Build with `batch_design` — max 25 operations per call:
   ```
   btn=I("canvas", { type: "frame", name: "Button", reusable: true,
     fill: "$color-primary-500", cornerRadius: "$radius-md",
     padding: ["$spacing-3", "$spacing-6"], layout: "horizontal", gap: "$spacing-2" })
   U(btn, { children: [
     { type: "text", name: "label", content: "Button", fill: "$color-white",
       fontFamily: "$font-primary", fontSize: "$font-size-base" }
   ] })
   ```
4. For large components (cards, heroes, footers): split across multiple
   `batch_design` calls, building parent frame first, then children
5. After each component: call `get_screenshot()` to visually verify
6. Call `batch_get` to read the component's child structure → record slot
   node IDs for later page composition
7. After building all components, present gallery to user:
   ```
   ## Components Built
   {N} reusable components created:
   - Button (2 slots: icon, label)
   - Card (4 slots: image, title, description, cta)
   - Hero (5 slots: heading, subheading, cta_primary, cta_secondary, background)
   ...

   Review the components in Pencil. Any adjustments needed?
   ```

### Slot Node ID Registry

Maintain a map of component → slot → Pencil node ID for page composition:
```yaml
components:
  Button:
    frame_id: "abc123"
    slots:
      label: "def456"
      icon: "ghi789"
  Card:
    frame_id: "jkl012"
    slots:
      image: "mno345"
      title: "pqr678"
      description: "stu901"
      cta: "vwx234"
```

Save to findings.md after every 2 components built.

---

## Step 5 — Compose Page Screens

Build one full-page screen for each layout YAML, populated with real content.

### Procedure

Read `creative-direction.yml` before composing pages. Apply creative direction
to all page composition decisions:
- `spatial_philosophy` → section padding (e.g., "generous whitespace" = larger padding tokens)
- `hero_approach` → hero section rendering (e.g., "immersive fullscreen" = full viewport, no container)
- `color_strategy` → section background alternation (e.g., "monochromatic" = subtle shade shifts)

For each layout YAML in `design/layouts/` (process `home.yml` first, then
remaining sorted by route):

1. Call `find_empty_space_on_canvas("right", { width: 1440, height: 900 })`
   to position the new screen away from components
2. Create the screen frame:
   ```
   page=I("canvas", { type: "frame", name: "Page: {page_name}",
     width: 1440, height: "fit_content", fill: "$color-white",
     layout: "vertical", gap: 0 })
   ```
3. Build navigation header from `navigation-map.yml`:
   - Read `primary_nav.items[]` for nav links
   - Create header frame with logo placeholder, nav items, CTA button
   - If navigation has `mobile_menu`: skip for desktop, build in Step 7
4. For each section in the layout's `sections[]`:
   a. Get the component name from `section.component`
   b. Look up the component in the slot registry from Step 4
   c. Get page copy from `copy_map[route]` for this section's slots
   d. Create section container:
      ```
      sec=I(page, { type: "frame", name: "Section: {section_name}",
        width: "fill", height: "fit_content",
        padding: [section.layout.padding values mapped to tokens],
        minHeight: section.layout.min_height or null,
        layout: "vertical", gap: "$spacing-8" })
      ```
   e. If the component is reusable and in the registry:
      - Insert as component instance:
        ```
        inst=C("{component_frame_id}", sec, {})
        ```
      - Override slots with real copy content:
        ```
        U(inst+"/slot_node_id", { content: "{copy_text}" })
        ```
   f. If the component is structural (hero, footer, navigation):
      - Build inline following style guide patterns
      - Apply brand colors and typography from tokens
   g. Apply section background (informed by creative-direction `color_strategy`):
      - Default alternation: odd = `$color-white`/`$color-neutral-50`, even = `$color-neutral-100`/`$color-primary-50`
      - If `color_strategy: "monochromatic"` → use subtle shade shifts within one hue
      - If `color_strategy: "complementary"` → alternate between primary and accent tones
      - Hero sections: `$color-primary-900` or gradient (override with `hero_approach` if set)
5. After each page: call `snapshot_layout()` to verify structure
6. Call `get_screenshot()` → save to `render/screenshots/page-{route}.png`
   - For home page, route name is "home"
   - For other pages, use the route slug (e.g., "pricing", "about")

Save to findings.md after every 2 pages composed.

### Page Ordering

1. Home page first (always)
2. Remaining pages sorted by navigation-map primary_nav order
3. Utility pages last (404, login, signup)

---

## Step 6 — Generate Images

Add AI-generated and stock images to appropriate sections.

### Image Selection Strategy

Scan all composed pages for image-worthy sections:

| Section Type | Image Approach | Prompt Pattern |
|-------------|---------------|----------------|
| Hero | AI generation | "{brand_personality} + {page_purpose} + {style_guide_visual}" |
| Features | Stock search | "{feature_description} + icon/illustration" |
| Testimonials | Stock search | "professional headshot diverse" |
| About/Team | Stock search | "team photo professional {industry}" |
| Blog/Content | AI generation | "{article_topic} + editorial illustration" |
| Product | AI generation | "{product_description} + {brand_aesthetic}" |

### Procedure

1. For each page, identify sections with image slots (from component spec)
2. Build image prompts from:
   - Brand-summary personality keywords
   - Section copy context (heading, description)
   - Style guide visual direction from Step 2
3. Call `batch_design` with `G()` operations — max 25 per call:
   ```
   G("hero_image_node_id", "ai", "Modern SaaS dashboard interface, clean minimalist
     design, blue and white color scheme, professional, high quality")
   G("feature_icon_1", "stock", "cloud computing icon flat design")
   G("testimonial_avatar_1", "stock", "professional headshot woman smiling")
   ```
4. After image generation, re-screenshot each page:
   - Call `get_screenshot()` for each page that received images
   - Overwrite previous screenshots in `render/screenshots/`

Save to findings.md:
```markdown
## Step 6: Images Generated
- Total images: {N} ({N} AI-generated, {N} stock)
- Pages with images: {list}
- Re-screenshots taken: {N}
```

---

## Step 7 — Mobile Variants (Optional)

Generate responsive mobile versions of each desktop screen.

### Procedure

1. Ask the user:
   ```
   Generate mobile (375px) variants for all pages?
   This will create a second set of screens sized for mobile.
   ```
2. If user declines, skip to Step 8
3. For each desktop page screen:
   a. Call `find_empty_space_on_canvas("below", { width: 375, height: 812 })`
   b. Copy the desktop screen:
      ```
      mobile=C("{desktop_page_id}", "canvas", { name: "Mobile: {page_name}" })
      ```
   c. Resize to 375px width:
      ```
      U(mobile, { width: 375 })
      ```
   d. Apply responsive overrides from layout YAML:
      - Multi-column sections → single column (`layout: "vertical"`)
      - Reduce padding (typically halve desktop values)
      - Increase font sizes for touch targets
      - Stack horizontal elements vertically
      - Hide desktop-only elements (e.g., wide navigation → hamburger)
   e. Call `get_screenshot()` → save as `render/screenshots/mobile-{route}.png`

Save to findings.md:
```markdown
## Step 7: Mobile Variants
- Generated: {yes/no}
- Pages: {N} mobile screens
- Screenshots: {list}
```

---

## Step 8 — Finalize

Generate manifest, register assets, run checkpoint, update state.

### 8a. Generate Render Manifest

Write `render/render-manifest.yml`:

```yaml
_meta:
  schema: "render-manifest"
  version: "1.0.0"
  plugin: "agency"
  generated_at: "{ISO 8601}"

document: "render/{project-name}.pen"
screenshots_as_ground_truth: true  # screenshots are authoritative visual reference for verification loop

variables:
  count: {N}
  categories:
    colors: {N}
    spacing: {N}
    fonts: {N}
    radii: {N}

components:
  - name: "Button"
    node_id: "abc123"
    slots:
      label: "def456"
      icon: "ghi789"
  - name: "Card"
    node_id: "jkl012"
    slots:
      image: "mno345"
      title: "pqr678"
      description: "stu901"
      cta: "vwx234"

pages:
  - name: "Home"
    route: "/"
    node_id: "yza567"
    screenshot: "render/screenshots/page-home.png"
    sections:
      - name: "hero"
        node_id: "bcd890"
        component: "Hero"
      - name: "features"
        node_id: "efg123"
        component: "FeatureGrid"
  - name: "Pricing"
    route: "/pricing"
    node_id: "hij456"
    screenshot: "render/screenshots/page-pricing.png"
    sections: [...]

mobile_variants:
  generated: true/false
  pages:
    - name: "Mobile: Home"
      node_id: "klm789"
      screenshot: "render/screenshots/mobile-home.png"

images:
  total: {N}
  ai_generated: {N}
  stock: {N}
```

### 8b. Register Assets

Add render outputs to `asset-registry.yml`:

```yaml
- type: "design-mockup"
  format: "pen"
  path: "render/{project-name}.pen"
  description: "Full visual design — {N} pages, {N} components"
  generated_by: "visual-render"

- type: "render-manifest"
  format: "yml"
  path: "render/render-manifest.yml"
  description: "Node ID map for all rendered components and pages"
  generated_by: "visual-render"

- type: "design-reference"
  format: "png"
  path: "render/screenshots/page-{route}.png"  # one entry per page
  description: "Desktop screenshot of {page_name}"
  generated_by: "visual-render"
  ground_truth: true  # authoritative visual reference for visual verification loop (dec-01)
```

### 8c. Run 7-Point Checkpoint

| # | Check | How to Verify | Fail Action |
|---|-------|--------------|-------------|
| 1 | pen_file_created | Check `render/{project}.pen` exists | Re-create with `open_document` |
| 2 | variables_set | Call `get_variables()`, count matches CSS props | Re-run `set_variables` |
| 3 | components_built | `batch_get` for reusable frames, count matches specs | Rebuild missing |
| 4 | pages_composed | `batch_get` for page frames, count matches layouts | Recompose missing |
| 5 | screenshots_captured | Check `render/screenshots/*.png` count | Recapture via `get_screenshot` |
| 6 | manifest_complete | Read manifest, verify all pages + components listed | Regenerate manifest |
| 7 | assets_registered | Read asset-registry, verify render entries | Register missing |

If any check fails:
1. Log error to state.yml `errors[]` with failed check name
2. Attempt automatic fix (see Fail Action column)
3. Re-run that specific check
4. If still failing after 1 retry, report to user and halt

### 8d. Update State

```yaml
# state.yml updates
modules:
  render:
    status: "completed"
    started_at: "{start_time}"
    completed_at: "{now}"
    current_skill: null
    completed_skills: ["visual-render"]
    findings_file: ".ai/projects/{name}/render/findings.md"
current_module: null
current_skill: null
updated_at: "{now}"
recovery_notes: |
  Render module complete. {N} pages rendered in Pencil with {N} components.
  Screenshots saved to render/screenshots/.
  Manifest: render/render-manifest.yml
  Next: /agency:build or /agency:deploy
```

---

## Error Handling

### Pencil MCP Failures

If any Pencil MCP tool call fails:
1. Log error to state.yml `errors[]`
2. Check if the document is still open (`get_editor_state()`)
3. If document closed: re-open with `open_document("{path}")`
4. Retry the failed operation once
5. If still failing: save progress to findings.md and report to user

### Large Component Splits

Components with more than 10 child nodes should be split across multiple
`batch_design` calls:
1. First call: create parent frame + first 10 children
2. Subsequent calls: add remaining children using `U()` on parent
3. Verify with `batch_get` after each call

### Image Generation Failures

If `G()` fails for an image:
1. Try with a simplified prompt (shorter, fewer adjectives)
2. Switch from "ai" to "stock" or vice versa
3. If still failing: insert a colored placeholder frame and note in manifest

### Recovery After /compact

On session resume:
1. Read `render/findings.md` for progress
2. Read `render/render-manifest.yml` (if exists) for completed work
3. Call `get_editor_state()` to check if document is open
4. Resume from the last incomplete step
