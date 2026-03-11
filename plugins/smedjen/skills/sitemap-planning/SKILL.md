---
name: sitemap-planning
description: >
  Information architecture and sitemap planning — page hierarchy, content siloing,
  header structure, internal linking strategy, schema markup selection, URL
  conventions, and featured snippet optimization.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "sitemap"
  - "information architecture"
  - "site structure"
  - "page hierarchy"
  - "internal linking"
  - "content siloing"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "key_pages_within_three_clicks"
      verify: "Every important page is reachable within 3 clicks from the homepage"
      fail_action: "Flatten hierarchy or add navigation paths to deeply buried pages"
    - name: "one_h1_per_page"
      verify: "Each page has exactly one H1 that matches its primary topic"
      fail_action: "Fix heading hierarchy — one H1, logical H2/H3 nesting"
    - name: "no_orphaned_pages"
      verify: "Every page receives at least one internal link from another page"
      fail_action: "Add internal links from related content to orphaned pages"
    - name: "silos_internally_consistent"
      verify: "Pages within a topic silo link to each other, cross-silo links are rare and intentional"
      fail_action: "Strengthen within-silo linking, reduce irrelevant cross-links"
  on_fail: "Site structure has navigation or hierarchy issues — fix before launch"
  on_pass: "Information architecture is sound"
_source:
  origin: "smedjen"
  inspired_by: "antigravity-awesome-skills/seo-structure-architect + seo-content-planner"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Combined structure architect and content planner into IA knowledge skill"
---

# sitemap-planning

## Page Hierarchy

Key pages within 3 clicks from homepage. Logical parent/child structure. No orphaned pages. URL structure mirrors the hierarchy: `/category/subcategory/page`. Keep URLs under 60 chars, lowercase, hyphens only.

## Content Siloing

Group pages into topical clusters. Each silo has a pillar page (broad topic) linking to cluster pages (specific subtopics). Within-silo linking is dense. Cross-silo linking is rare and intentional. Steps: (1) identify 3-7 core topic areas, (2) assign pages to silos, (3) create pillar page per silo, (4) link cluster pages to their pillar, (5) cross-link only when highly relevant.

## Header Hierarchy

One H1 per page matching the primary topic. H2s for main sections (use keyword variations). H3s for subsections (use related terms). Maintain strict hierarchy — no skipping levels. Headers reflect content structure, not visual styling.

```
H1: Primary Keyword Focus
├── H2: Major Section (Secondary KW)
│   ├── H3: Subsection (LSI term)
│   └── H3: Subsection (Entity)
└── H2: Major Section (Related KW)
    └── H3: Subsection
```

## Internal Linking

2-3 internal links per page minimum. Descriptive anchor text (not "click here"). Link to related content within the same silo first. Pillar pages should receive the most internal links. Distribute link equity intentionally — don't link everything to the homepage.

## Schema Markup Priority

High-impact schemas: Article/BlogPosting, FAQPage, HowTo, Review/AggregateRating, Organization, BreadcrumbList, Product. Choose schema based on page type. Implement as JSON-LD in the page head.

## Featured Snippet Optimization

Lists for step-by-step content. Tables for comparisons. Definition paragraphs (40-60 words) for "what is" queries. FAQ sections with concise answers. Place the snippet-target content immediately after the relevant H2.

See `references/process.md` for sitemap templates, linking matrices, schema JSON-LD examples, and URL structure patterns.
