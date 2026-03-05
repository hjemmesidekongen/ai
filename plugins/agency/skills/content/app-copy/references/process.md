# App Copy — Detailed Process

## Inputs

| File | Purpose |
|------|---------|
| `brand/brand-summary.yml` | Voice attributes, tone spectrum, terminology, forbidden words |
| `design/navigation-map.yml` | All page routes and their display names |
| `design/layouts/*.yml` | Per-page component arrangement and section structure |
| `design/components/*.yml` | Slot definitions: name, type, character limits, required |

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


## Step 1 — Read Brand Voice

Load `brand-summary.yml` voice section. Extract:

- **personality** — 3–5 adjectives that describe brand character (e.g. bold, approachable, expert)
- **tone_spectrum** — axis values (formal↔casual, serious↔playful, concise↔expansive)
- **vocabulary** — preferred terms, forbidden terms, industry jargon rules
- **cta_style** — action-oriented phrasing guidance (e.g. imperative vs. gerund)
- **headline_style** — capitalization, punctuation, max word count

If brand-summary.yml is absent or has no voice section, stop and report:
`blocked: brand-summary.yml is required — run brand-loader before app-copy`

---

## Step 2 — Enumerate Pages

Read `design/navigation-map.yml` to get the canonical page list.

```yaml
# navigation-map.yml excerpt (input)
primary_nav:
  - label: Home
    route: /
  - label: About
    route: /about
  - label: Services
    route: /services
  - label: Contact
    route: /contact
footer:
  columns:
    - heading: Company
      links:
        - label: About
          route: /about
```

Build a page list: `/`, `/about`, `/services`, `/contact` (deduplicated from all
nav sections). Include any routes that appear in layout YAMLs but not navigation
(orphan pages — flag these to the user).

---

## Step 3 — Build Page > Section > Component Map

For each page route, load its layout YAML from `design/layouts/`.

```yaml
# Example: design/layouts/home.yml (input)
page: home
route: /
sections:
  - id: hero
    layout: full-width
    components:
      - component: HeroSection
        props:
          variant: primary
  - id: features
    layout: three-column
    components:
      - component: FeatureCard
        props:
          icon: true
      - component: FeatureCard
        props:
          icon: true
      - component: FeatureCard
        props:
          icon: true
  - id: cta-banner
    layout: centered
    components:
      - component: CTABanner
```

Map: `home → [hero/HeroSection, features/FeatureCard×3, cta-banner/CTABanner]`

---

## Step 4 — Extract Slot Definitions

For each component referenced in layouts, read its spec from
`design/components/[component-name].yml`.

```yaml
# Example: design/components/HeroSection.yml (input)
name: HeroSection
slots:
  - name: headline
    type: headline
    required: true
    max_chars: 80
    notes: "Primary value proposition. Bold, action-oriented."
  - name: subheadline
    type: body
    required: true
    max_chars: 160
    notes: "Expands headline with supporting detail."
  - name: primary_cta
    type: cta
    required: true
    max_chars: 30
    notes: "Primary action button label."
  - name: secondary_cta
    type: cta
    required: false
    max_chars: 30
    notes: "Optional secondary action."
```

### Slot Types

| Type | Purpose | Guidance |
|------|---------|---------|
| `headline` | Primary heading | Concise, benefit-led, brand tone |
| `subheadline` | Supporting heading | Expands on headline, 1–2 sentences |
| `body` | Paragraph or multi-sentence | Informative, on-brand, scannable |
| `cta` | Button / link label | Action verb, imperative, ≤5 words |
| `label` | Field label, nav item, tag | Lowercase or title case per brand style |
| `description` | Short descriptive text | 1–3 sentences, supporting context |
| `placeholder` | Form input placeholder | Instructive, never as substitute for label |
| `alt_text` | Image alt text | Descriptive, context-aware, concise |

---

## Step 5 — Generate Page Copy YAMLs

For each page, produce a YAML file at
`.ai/projects/[name]/content/pages/[route-slug].yml`.

```yaml
# Output format: content/pages/home.yml
_meta:
  page: home
  route: /
  generated_at: "2025-01-01T00:00:00Z"
  brand_voice_ref: "brand-summary.yml#voice"

sections:
  hero:
    component: HeroSection
    slots:
      headline: "Transform How Your Team Works"
      subheadline: "Streamline projects, align your team, and deliver results — all in one place."
      primary_cta: "Start Free Trial"
      secondary_cta: "See How It Works"

  features:
    component: FeatureCard
    instances:
      - id: feature-1
        slots:
          headline: "Ship Faster"
          description: "Automate handoffs and eliminate status meetings with real-time progress tracking."
          label: "Velocity"
      - id: feature-2
        slots:
          headline: "Stay Aligned"
          description: "Keep every stakeholder informed with automatic updates and shared visibility."
          label: "Transparency"
      - id: feature-3
        slots:
          headline: "Scale Confidently"
          description: "Built for teams of 5 or 500 — flexible workflows that grow with you."
          label: "Scalability"

  cta_banner:
    component: CTABanner
    slots:
      headline: "Ready to See the Difference?"
      body: "Join thousands of teams who ship faster with less friction."
      primary_cta: "Get Started"
```

### Multi-Instance Components

When the same component appears multiple times in a section (e.g. three
FeatureCards), use the `instances` array with sequential IDs. Each instance
gets its own unique copy — never repeat the same copy across instances.

### Inherited Slots

Navigation labels defined in `navigation-map.yml` are part of the site copy.
Include a `navigation` section in the home page copy YAML (as the primary file):

```yaml
navigation:
  primary:
    - route: /
      label: "Home"
    - route: /about
      label: "About"
    - route: /services
      label: "Services"
    - route: /contact
      label: "Contact"
  footer:
    company_column_heading: "Company"
  cta:
    label: "Get Started"
    route: /signup
```

**2-Action Rule checkpoint:** After generating each page's copy YAML, save progress to `.ai/projects/[name]/content/findings.md` before continuing to the next page.

---

## Step 6 — Brand Voice Application Rules

Apply these rules consistently across all copy:

### Headlines
- Match `headline_style` from brand-summary.yml (title case, sentence case, or all-caps)
- Lead with a benefit or outcome, not a feature
- Stay within `max_chars` from the slot definition
- Use personality adjectives as a lens (bold → short punchy statement; approachable → conversational)

### Body Copy
- Match tone_spectrum positioning (formal↔casual axis)
- Use preferred vocabulary; avoid forbidden terms
- Write in active voice unless brand explicitly uses passive
- Keep sentences under 25 words for scan-friendliness

### CTAs
- Use `cta_style` from brand-summary.yml
- Imperative form by default: "Start", "Get", "See", "Join"
- Match the action to the page context (sign-up page: "Create Account" not "Learn More")
- Avoid generic: "Click Here", "Submit", "OK"

### Labels
- Consistent casing throughout (pick one: Title Case, Sentence case, lowercase)
- Short: 1–3 words for nav; 1–4 words for field labels
- Scannable: use nouns or noun phrases

### Placeholders
- Describe the expected input: "your@email.com", "Full name", "Search..."
- Never substitute for a label — placeholders disappear on focus

---

## Step 7 — User Review Flow

Present copy page by page. For each page:

1. Show the full page copy YAML
2. Highlight slots where defaults were assumed (tone interpretation)
3. Ask: "Approve this page as-is, or flag specific slots to revise?"
4. Accept targeted feedback: "hero.headline: make it shorter and more direct"
5. Revise only flagged slots; re-present the full page after revisions
6. Confirm before moving to next page

**2-Action Rule checkpoint:** After completing user review for each page, save the approved copy and any revision notes to `.ai/projects/[name]/content/findings.md`.

---

## Step 8 — Register in Asset Registry

Add all generated page copy YAMLs to `asset-registry.yml`:

```yaml
content:
  pages:
    - path: ".ai/projects/[name]/content/pages/home.yml"
      page: home
      route: /
      slot_count: 14
    - path: ".ai/projects/[name]/content/pages/about.yml"
      page: about
      route: /about
      slot_count: 9
```

---

## Step 9 — Checkpoint

Run all 5 checks from the SKILL.md checkpoint block:

1. **pages_covered** — count routes in navigation-map.yml; verify one `.yml` per route
2. **slots_filled** — for each layout YAML, verify every slot listed in component specs
   has a non-empty value in the corresponding page copy YAML
3. **brand_voice_applied** — manually verify 3 representative slots (1 headline, 1 body,
   1 CTA) against brand voice rules
4. **slot_types_complete** — verify at least one slot of each type exists across all pages
5. **assets_registered** — verify each generated YAML appears in asset-registry.yml

On failure: identify the failing check, fix the specific gap, re-run that check.
On pass: update `state.yml` phase to completed, set `next_skill` to `ux-writing`.

---

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- `pages_covered` — one copy YAML exists per page route defined in navigation-map.yml
- `slots_filled` — every slot referenced in layout YAMLs has copy in the page YAML
- `brand_voice_applied` — headlines, CTAs, and body copy reflect tone and vocabulary from brand-summary.yml
- `slot_types_complete` — all slot types present: headline, body, cta, label, description, placeholder
- `assets_registered` — all page copy YAMLs registered in asset-registry.yml under content.pages

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Copy matches brand voice tone spectrum (formal/casual axis positioning is accurate)
- No generic placeholder text remaining (no "Lorem ipsum", "TBD", or "placeholder copy")
- CTAs are action-oriented and specific (no "Click Here", "Submit", "OK")
- Slot character limits respected (every slot value is within its `max_chars` bound)
- Multi-instance components have unique copy across all instances

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Error Handling

| Error | Action |
|-------|--------|
| brand-summary.yml missing | Stop — report blocked with message |
| navigation-map.yml missing | Stop — report blocked, web-layout must run first |
| Component spec missing for layout reference | Log warning, generate placeholder copy, flag in YAML |
| Slot max_chars exceeded | Trim copy, note in YAML as `copy_trimmed: true` |
| Component appears in layout but has no slots | Skip silently — no copy needed |

Log all errors to `state.yml` errors array:
```yaml
errors:
  - timestamp: "2025-01-01T00:00:00Z"
    skill: app-copy
    error: "Component 'TestimonialGrid' not found in design/components/"
    attempted_fix: "Generated placeholder copy for all inferred slots"
    result: "Placeholder written — needs component spec review"
    next_approach: "Run component-specs for TestimonialGrid then re-run app-copy"
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
