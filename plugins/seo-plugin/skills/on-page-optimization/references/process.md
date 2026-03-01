# On-Page Optimization — Detailed Process

Phase 4 of SEO strategy generation. This skill transforms the keyword research output into concrete on-page SEO rules that guide content creation. The output feeds into content-strategy (Phase 5) and the `/seo:audit` command for evaluating existing pages.

## Prerequisites

- Read `docs/seo-plugin-implementation-plan.md` (the "Skill: on-page-optimization" section)
- Read `docs/seo-plugin-addendum.md` (the "Technical SEO Fundamentals" section, specifically structured data)

## Before You Start

Load context from previous phases:

1. Read `seo-strategy.yml` → extract:
   - `project_context.website_url` — the site these rules apply to
   - `project_context.industry` — determines which schema types to recommend
   - `project_context.goals` — shapes optimization priorities
   - `keywords.primary` — used for title tag and H1 optimization
   - `keywords.secondary` — used for meta descriptions and H2/H3 subheadings
   - `keywords.long_tail` — used for H3 headings and FAQ schema opportunities

2. Report what you loaded: "Generating on-page optimization rules for [website_url]. Using [N] primary keywords for title/heading optimization and [N] secondary keywords for meta descriptions."

This skill is **non-interactive** — generate all rules and present them for review.

## Generation Process

### Step 1: Title Tag Pattern

Define the title tag template and rules.

**Pattern format:** `{Primary Keyword} — {Benefit/Modifier} | {Brand Name}`

The pattern should be adaptable — it's a template that content creators follow, not a single hardcoded title.

```yaml
title_tag:
  pattern: "{Primary Keyword} — {Benefit/Modifier} | {Brand Name}"
  max_length: 60
  rules:
    - "Place the primary keyword within the first 3 words of the title"
    - "Include brand name at the end, separated by a pipe character"
    - "Keep total length under 60 characters to prevent truncation in SERPs"
    - "Each page must have a unique title tag — no duplicates across the site"
```

**Customization by industry:**
- E-commerce: `{Product Name} — {Key Feature} | {Brand}` (60 chars)
- SaaS: `{Solution Keyword} — {Benefit Statement} | {Brand}` (60 chars)
- Blog/Media: `{Topic Keyword}: {Specific Angle} | {Brand}` (60 chars)
- Local business: `{Service} in {Location} — {Brand Name}` (60 chars)

**Rules requirements:**
- At least 2 rules required, aim for 3-4
- First rule MUST address primary keyword placement
- One rule MUST address brand name positioning
- Additional rules can cover uniqueness, length, or modifiers

### Step 2: Meta Description Template

Define the meta description pattern and rules.

**Pattern format:** `{Action Verb} {benefit statement} with {solution}. {CTA with keyword}.`

```yaml
meta_description:
  pattern: "{Action Verb} {benefit statement} with {solution}. {CTA with keyword}."
  max_length: 155
  rules:
    - "Include the primary keyword naturally within the first sentence"
    - "Start with an action verb (Discover, Learn, Build, Get, Find, etc.)"
    - "End with a clear call-to-action that encourages the click"
    - "Keep length between 120-155 characters — too short wastes SERP space"
```

**Rules requirements:**
- At least 2 rules required, aim for 3-4
- One rule MUST address keyword inclusion
- One rule MUST address CTA or click motivation
- Avoid keyword stuffing — the description should read naturally

### Step 3: Heading Hierarchy

Define rules for each heading level (H1 through H4). These rules ensure content is structured for both search engines and readers.

```yaml
heading_hierarchy:
  h1:
    rules:
      - "Exactly one H1 per page — it is the page's primary topic"
      - "Must contain the primary target keyword for that page"
      - "Should closely mirror the title tag content (but can be slightly longer)"
      - "Keep under 70 characters for readability"
  h2:
    rules:
      - "Use H2 for major page sections (3-6 per page is typical)"
      - "Include secondary keywords naturally in H2 headings"
      - "Each H2 should represent a distinct subtopic or section"
      - "Use H2 headings that could work as standalone search queries"
  h3:
    rules:
      - "Use H3 for subsections within an H2 block"
      - "Include long-tail keywords where they fit naturally"
      - "Good for FAQ-style questions within a section"
      - "Don't skip from H1 directly to H3 — maintain hierarchy"
  h4:
    rules:
      - "Use sparingly — only for deep nesting within H3 sections"
      - "Appropriate for detailed breakdowns, lists of features, or step sub-points"
      - "If you need H4 frequently, consider restructuring into separate H2 sections"
```

**Customization based on content type:**
- Blog articles: emphasize question-based H2/H3 headings for featured snippets
- Product pages: H2 for features, specs, reviews; H3 for individual feature details
- Landing pages: H2 for value propositions, social proof, pricing sections

### Step 4: Internal Linking Strategy

Define at least 3 internal linking rules. Internal linking distributes page authority, helps search engines discover content, and improves user navigation.

```yaml
internal_linking:
  - rule: "Every page links to at least 3 related pages via contextual body links"
    implementation: "When creating or updating content, identify 3+ relevant existing pages and add natural in-text links. Anchor text should use descriptive phrases (not 'click here')."
  - rule: "Pillar pages link to all cluster content in their topic area"
    implementation: "Maintain a topic cluster map. Each pillar page includes a section linking to all related cluster articles. Update the pillar page when new cluster content is published."
  - rule: "New content links to existing high-authority pages"
    implementation: "Before publishing new content, check analytics for top-performing pages in the same topic area. Add links from new content to these pages to reinforce their authority."
  - rule: "Fix orphan pages — every indexable page must be reachable within 3 clicks from the homepage"
    implementation: "Monthly audit: identify pages with zero internal links pointing to them. Add them to relevant navigation, sidebar, or related-content sections."
```

**Rules requirements:**
- At least 3 rules required, aim for 4-5
- Each rule has both a `rule` (what to do) and `implementation` (how to do it)
- Cover these three linking patterns at minimum:
  1. Contextual links in body content
  2. Pillar-cluster linking structure
  3. New content linking to existing pages

### Step 5: Schema Markup Recommendations

Recommend at least 2 schema markup types based on the project's industry and content types. Schema markup enables rich results in SERPs and provides search engines with structured information about page content.

**Select from these schema types based on industry:**

| Schema Type | Best For | Required Properties |
|-------------|----------|-------------------|
| Organization | All sites (homepage) | name, url, logo, contactPoint, sameAs |
| Article | Blog/content sites | headline, author, datePublished, dateModified, image |
| FAQ | Help/support pages | mainEntity (array of Question+Answer pairs) |
| Product | E-commerce | name, description, image, offers (price, currency, availability) |
| BreadcrumbList | All sites (navigation) | itemListElement (position, name, item URL) |
| LocalBusiness | Local businesses | name, address, telephone, openingHours, geo |
| SoftwareApplication | SaaS products | name, operatingSystem, applicationCategory, offers |
| HowTo | Tutorial content | name, step (array with text and image) |
| Review | Review sites | itemReviewed, reviewRating, author |
| Event | Event-based businesses | name, startDate, location, offers |
| VideoObject | Video content | name, description, thumbnailUrl, uploadDate, contentUrl |

```yaml
schema_markup:
  - type: "Organization"
    required_properties:
      - "name"
      - "url"
      - "logo"
      - "contactPoint"
      - "sameAs (social media URLs)"
    use_case: "Homepage — establishes brand entity in Google's Knowledge Graph and enables Knowledge Panel display"
  - type: "Article"
    required_properties:
      - "headline"
      - "author"
      - "datePublished"
      - "dateModified"
      - "image"
    use_case: "Blog posts and content pages — enables article rich results with publish date, author, and thumbnail in SERPs"
  - type: "BreadcrumbList"
    required_properties:
      - "itemListElement (array)"
      - "position"
      - "name"
      - "item (URL)"
    use_case: "All pages — shows breadcrumb navigation path in search results, improving click-through rate"
```

**Selection criteria:**
- **Always include Organization** — applies to every website
- Add 1-2 types based on the project's industry and content:
  - E-commerce → Product, Review
  - SaaS → SoftwareApplication, FAQ
  - Blog/Media → Article, VideoObject
  - Local business → LocalBusiness, Event
  - Help/Docs → FAQ, HowTo

**Requirements:**
- At least 2 schema types required, aim for 3-4
- Each type has `type`, `required_properties` (array), and `use_case` (string)
- Use case should explain WHERE on the site to apply and WHY it helps SEO

## Writing the Output

Present the complete on-page optimization rules for review:

```
## On-Page Optimization Rules

### Title Tag
Pattern: {Primary Keyword} — {Benefit/Modifier} | {Brand Name}
Max length: 60 characters
Rules: [N]

### Meta Description
Pattern: {Action Verb} {benefit} with {solution}. {CTA}.
Max length: 155 characters
Rules: [N]

### Heading Hierarchy
- H1: [N] rules (primary keyword, one per page)
- H2: [N] rules (secondary keywords, major sections)
- H3: [N] rules (long-tail keywords, subsections)
- H4: [N] rules (deep nesting only)

### Internal Linking
[N] rules covering contextual links, pillar-cluster, and new content linking

### Schema Markup
[N] types recommended: [comma-separated type names]

Does this look comprehensive? I can adjust rules or add schema types.
```

Present for review. Then write the `on_page` section to `seo-strategy.yml`:

```yaml
on_page:
  title_tag:
    pattern: "{Primary Keyword} — {Benefit/Modifier} | {Brand Name}"
    max_length: 60
    rules:
      - "Place the primary keyword within the first 3 words of the title"
      - "Include brand name at the end, separated by a pipe character"
      # ... more rules
  meta_description:
    pattern: "{Action Verb} {benefit statement} with {solution}. {CTA with keyword}."
    max_length: 155
    rules:
      - "Include the primary keyword naturally within the first sentence"
      - "Start with an action verb (Discover, Learn, Build, Get, Find, etc.)"
      # ... more rules
  heading_hierarchy:
    h1:
      rules:
        - "Exactly one H1 per page — it is the page's primary topic"
        # ...
    h2:
      rules: [...]
    h3:
      rules: [...]
    h4:
      rules: [...]
  internal_linking:
    - rule: "Every page links to at least 3 related pages"
      implementation: "..."
    # ... more rules
  schema_markup:
    - type: "Organization"
      required_properties: ["name", "url", "logo", "contactPoint", "sameAs"]
      use_case: "Homepage — establishes brand entity..."
    # ... more types
```

Update `state.yml`:
- Set `current_phase: "on-page-optimization"`
- Add phase entry with `status: "complete"` and checkpoint results

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `title_tag_complete` | Has `pattern` (string), `max_length` (≤ 60), `rules` (≥ 2 entries) | Add missing title tag fields |
| `meta_description_complete` | Has `pattern` (string), `max_length` (≤ 155), `rules` (≥ 2 entries) | Add missing meta description fields |
| `heading_hierarchy_complete` | Has rules for `h1`, `h2`, `h3`, `h4` — each with a `rules` array | Add rules for missing heading levels |
| `internal_linking_rules` | ≥ 3 entries, each with `rule` (string) and `implementation` (string) | Add more linking rules |
| `schema_markup_types` | ≥ 2 entries, each with `type` (string), `required_properties` (array), `use_case` (string) | Add more schema types |

**On pass:** Update state.yml → mark phase 4 complete, write recovery notes, advance to phase 5 (content-strategy).

**On fail:** Fix the failing checks, re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Project: [name] ([industry])
Title tag: max [max_length] chars, [N] rules, pattern: [pattern]
Meta description: max [max_length] chars, [N] rules
Heading rules: H1 ([N]), H2 ([N]), H3 ([N]), H4 ([N])
Internal linking: [N] rules
Schema types: [N] ([comma-separated type names])
```
