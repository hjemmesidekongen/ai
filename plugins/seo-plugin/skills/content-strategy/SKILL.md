---
name: content-strategy
description: >
  Creates a content plan with topic clusters, content calendar framework,
  content types, and SEO-optimized content guidelines aligned with brand voice.
  Writes the content_plan section to seo-strategy.yml.
phase: 5
depends_on: [keyword-research, competitor-analysis]
writes:
  - "seo-strategy.yml#content_plan"
reads:
  - "seo-strategy.yml#keywords"
  - "seo-strategy.yml#competitors"
  - "brand-reference.yml#voice (via brand-context-loader)"
  - "brand-reference.yml#audience (via brand-context-loader)"
  - "brand-reference.yml#content (via brand-context-loader)"
brand_sections_needed:
  - "voice.attributes"
  - "voice.channel_variations"
  - "audience.segments"
  - "audience.personas"
  - "content.content_types"
  - "content.seo_guidelines"
checkpoint:
  type: data_validation
  required_checks:
    - name: "topic_clusters_count"
      verify: "content_plan.topic_clusters has at least 3 entries"
      fail_action: "Group more primary keywords into additional topic clusters"
    - name: "pillar_pages_complete"
      verify: "Each topic cluster has a pillar page with title (string), target_keyword (string), word_count (number 3000-6000), and content_type (string)"
      fail_action: "Add missing pillar page fields — ensure title, target_keyword, word_count (3000-6000), and content_type"
    - name: "supporting_pages_count"
      verify: "Each topic cluster has at least 3 supporting pages with title, target_keyword, search_intent, word_count, content_type, and priority fields"
      fail_action: "Add more supporting pages using secondary and long-tail keywords from the keyword research"
    - name: "content_types_defined"
      verify: "content_plan.content_types has at least 3 entries, each with type (string), word_count_range (string), structure (string), and seo_elements (array)"
      fail_action: "Define more content types with word_count_range, structure, and seo_elements"
    - name: "calendar_months"
      verify: "content_plan.calendar.months_planned is at least 3"
      fail_action: "Extend the content calendar to cover at least 3 months"
    - name: "calendar_schedule"
      verify: "content_plan.calendar.schedule has entries for all planned months with content arrays"
      fail_action: "Add content entries for months missing from the schedule"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Content Strategy

Phase 5 of SEO strategy generation. This skill transforms keyword research and competitive insights into an actionable content plan organized around topic clusters. The output feeds into the `/seo:content-brief` command and provides the content roadmap for the project.

## Prerequisites

- Read `docs/seo-plugin-implementation-plan.md` (the "Skill: content-strategy" section)
- Read `docs/seo-plugin-addendum.md` (the "Topic Clusters and Content Architecture" section)
- Read `docs/ecosystem-strategy.md` Section 6 for the brand-reference.yml schema

## Before You Start

Load context from previous phases:

1. Read `seo-strategy.yml` → extract:
   - `keywords.primary` — these become pillar page topics
   - `keywords.secondary` — these become cluster content topics
   - `keywords.long_tail` — these become supporting page topics
   - `competitors.content_gaps` — priority content opportunities where competitors are weak

2. Call `brand-context-loader` to read brand-reference.yml:
   - `voice.attributes` — content tone (authoritative, conversational, technical, etc.)
   - `voice.channel_variations` — how tone adapts across blog, social, docs
   - `audience.segments` — who the content targets
   - `audience.personas` — detailed audience profiles for content targeting
   - `content.content_types` — existing format guidelines from brand setup
   - `content.seo_guidelines` — existing SEO guidance from brand setup

3. Report what you loaded: "Building content strategy using [N] primary keywords as pillar topics, [N] content gaps as opportunities. [Brand voice loaded / No brand data found.]"

This skill is **non-interactive** — generate the full content plan and present it for review.

## Generation Process

### Step 1: Build Topic Clusters

Group primary keywords into at least 3 topic clusters. Each cluster represents a content ecosystem around one broad topic.

**How to build clusters:**

1. Take each primary keyword as a potential pillar topic
2. Assign related secondary keywords as cluster content
3. Map long-tail keywords to supporting pages within each cluster
4. Cross-reference competitor content gaps — any gap keyword that fits a cluster should be included

**Cluster structure:**

```yaml
topic_clusters:
  - pillar:
      title: "The Complete Guide to [Primary Keyword]"
      target_keyword: "[primary keyword]"
      word_count: 4000
      content_type: "ultimate_guide"
    supporting_pages:
      - title: "How to [Secondary Keyword]: Step-by-Step"
        target_keyword: "[secondary keyword]"
        search_intent: "informational"
        word_count: 2000
        content_type: "how_to"
        priority: "high"
      - title: "Best [Long-Tail Keyword] for [Audience]"
        target_keyword: "[long-tail keyword]"
        search_intent: "commercial"
        word_count: 1800
        content_type: "listicle"
        priority: "medium"
      - title: "[Solution A] vs [Solution B]: Which is Better?"
        target_keyword: "[comparison keyword]"
        search_intent: "commercial"
        word_count: 2500
        content_type: "comparison"
        priority: "high"
```

**Cluster requirements:**
- At least 3 topic clusters
- Each cluster has exactly 1 pillar page
- Each cluster has at least 3 supporting pages
- No keyword duplication across clusters

**Pillar page rules:**
- `title` — descriptive, keyword-rich title for the comprehensive guide
- `target_keyword` — must be from the primary keywords list
- `word_count` — between 3000 and 6000 (comprehensive coverage)
- `content_type` — typically "ultimate_guide" for pillar pages

**Supporting page rules:**
- `title` — specific, focused title for the subtopic
- `target_keyword` — from secondary or long-tail keywords
- `search_intent` — inherited from keyword research data (informational/navigational/commercial/transactional)
- `word_count` — between 1500 and 3000 (focused coverage)
- `content_type` — one of: how_to, listicle, case_study, comparison, tutorial
- `priority` — high (publish first), medium (months 2-3), low (backlog)

### Step 2: Incorporate Content Gaps

Cross-reference `competitors.content_gaps` with the topic clusters:

1. For each content gap with `opportunity_score ≥ 60`:
   - Find the best-fitting topic cluster
   - Add as a supporting page if not already covered
   - Use the gap's `recommended_action` to shape the page's title and approach
   - Set priority based on opportunity_score: ≥ 80 → high, ≥ 60 → medium

2. For gaps that don't fit any cluster:
   - Consider creating a new cluster if there are 3+ related gaps
   - Otherwise, note as a standalone content opportunity

### Step 3: Define Content Types

Define at least 3 content type guidelines. These serve as templates for content creators.

```yaml
content_types:
  - type: "ultimate_guide"
    word_count_range: "3000-6000"
    structure: "Introduction → Overview → Detailed sections (5-8) → Best practices → FAQ → Conclusion with CTA"
    seo_elements:
      - "Primary keyword in H1 and first paragraph"
      - "Table of contents with anchor links"
      - "Secondary keywords in H2 headings"
      - "Internal links to all cluster supporting pages"
      - "Schema markup: Article with datePublished and dateModified"
      - "Custom graphics or diagrams for key concepts"
  - type: "how_to"
    word_count_range: "1500-3000"
    structure: "Problem statement → Prerequisites → Step-by-step instructions → Common mistakes → Summary"
    seo_elements:
      - "Target keyword in H1 and meta description"
      - "Numbered steps with clear action verbs"
      - "HowTo schema markup with step details"
      - "Screenshots or diagrams for complex steps"
      - "Link back to pillar page"
  - type: "listicle"
    word_count_range: "1500-2500"
    structure: "Introduction → Numbered items with descriptions → Comparison criteria → Verdict/recommendation"
    seo_elements:
      - "Number in title (e.g., '10 Best...')"
      - "Target keyword in H1"
      - "Each list item as H2 with pros/cons"
      - "Comparison table with key features"
      - "Link back to pillar page"
  - type: "case_study"
    word_count_range: "1500-2500"
    structure: "Challenge → Solution → Implementation → Results with data → Key takeaways"
    seo_elements:
      - "Target keyword in title and H1"
      - "Quantified results in meta description"
      - "Data visualizations for results"
      - "Testimonial or quote from stakeholder"
      - "Link back to pillar page and related service pages"
  - type: "comparison"
    word_count_range: "2000-3000"
    structure: "Overview of options → Feature-by-feature comparison → Pricing comparison → Use case recommendations → Verdict"
    seo_elements:
      - "'vs' or 'comparison' in title"
      - "Comparison table early in the content"
      - "FAQ schema for common comparison questions"
      - "Pros/cons lists for each option"
      - "Clear recommendation based on use case"
  - type: "tutorial"
    word_count_range: "1500-3000"
    structure: "What you'll learn → Prerequisites → Step-by-step walkthrough → Troubleshooting → Next steps"
    seo_elements:
      - "Target keyword in H1"
      - "Prerequisites section with requirements"
      - "Code blocks or detailed instructions"
      - "HowTo or Article schema"
      - "Link to related tutorials and pillar page"
```

**Select 3-6 types** based on the project's industry and content needs:
- SaaS/Tech: ultimate_guide, how_to, comparison, tutorial
- E-commerce: listicle, comparison, how_to
- Agency/Services: case_study, ultimate_guide, how_to
- Media/Blog: listicle, how_to, tutorial

### Step 4: Content Calendar

Create a 3-month content calendar with a realistic publishing cadence.

**Cadence guidelines by project size:**
- Startup/small team: 2-4 pieces per month
- Mid-size company: 4-8 pieces per month
- Large/established: 8-12 pieces per month

Default to 4 pieces per month if project size is unclear.

```yaml
calendar:
  cadence: "4 pieces per month"
  months_planned: 3
  schedule:
    - month: 1
      content:
        - title: "[Pillar page from highest-priority cluster]"
          target_week: 1
          status: "planned"
        - title: "[High-priority supporting page]"
          target_week: 2
          status: "planned"
        - title: "[Content gap opportunity]"
          target_week: 3
          status: "planned"
        - title: "[Supporting page from same cluster]"
          target_week: 4
          status: "planned"
    - month: 2
      content:
        - title: "[Second pillar page]"
          target_week: 1
          status: "planned"
        # ... more entries
    - month: 3
      content:
        - title: "[Third pillar page]"
          target_week: 1
          status: "planned"
        # ... more entries
```

**Scheduling rules:**
- Publish pillar pages first (week 1 of each month) — they're the anchor
- Follow with cluster content in weeks 2-4
- Prioritize content gap opportunities in month 1 (quick wins)
- Distribute content types — don't publish 4 listicles in a row
- Every content entry has `title`, `target_week`, and `status: "planned"`

### Step 5: Brand Voice Alignment

If brand data is loaded, align the content plan with brand voice:

1. **Tone guidance:** Reference `voice.attributes` to set the content tone
   - e.g., "Content should be authoritative yet approachable, matching the brand's [attribute] voice"

2. **Channel adaptation:** Reference `voice.channel_variations` to note how content tone shifts:
   - Blog → more educational, in-depth
   - Social → more conversational, punchy
   - Docs → more technical, precise

3. **Audience targeting:** Map content to `audience.segments`:
   - Pillar pages → broadest audience segment
   - Supporting pages → specific segments based on search intent

If no brand data is available, skip this step — the content plan works without it.

## Writing the Output

Present the content plan for review:

```
## Content Strategy Summary

### Topic Clusters: [N]

1. Pillar: "[title]" ([target_keyword])
   Supporting pages: [N] ([N] high, [N] medium, [N] low priority)

2. Pillar: "[title]" ([target_keyword])
   Supporting pages: [N]

3. Pillar: "[title]" ([target_keyword])
   Supporting pages: [N]

### Content Types: [N]
[comma-separated type names]

### Content Calendar: [N] months, [cadence]
Month 1: [N] pieces ([list titles])
Month 2: [N] pieces ([list titles])
Month 3: [N] pieces ([list titles])

### Content Gap Coverage
[N] competitor content gaps addressed in the plan

Brand voice: [aligned with brand / not available]

Does this look like a good content roadmap? I can adjust clusters,
priorities, or calendar scheduling.
```

Present for review. Then write the `content_plan` section to `seo-strategy.yml`:

```yaml
content_plan:
  topic_clusters:
    - pillar:
        title: "The Complete Guide to [Primary Keyword]"
        target_keyword: "[primary keyword]"
        word_count: 4000
        content_type: "ultimate_guide"
      supporting_pages:
        - title: "How to [Secondary Keyword]"
          target_keyword: "[secondary keyword]"
          search_intent: "informational"
          word_count: 2000
          content_type: "how_to"
          priority: "high"
        # ... more pages
    # ... more clusters
  content_types:
    - type: "ultimate_guide"
      word_count_range: "3000-6000"
      structure: "Introduction → Overview → Detailed sections → Best practices → FAQ → Conclusion"
      seo_elements:
        - "Primary keyword in H1 and first paragraph"
        - "Table of contents with anchor links"
        # ...
    # ... more types
  calendar:
    cadence: "4 pieces per month"
    months_planned: 3
    schedule:
      - month: 1
        content:
          - title: "[Pillar page title]"
            target_week: 1
            status: "planned"
          # ... more entries
      # ... more months
```

Update `state.yml`:
- Set `current_phase: "content-strategy"`
- Add phase entry with `status: "complete"` and checkpoint results

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `topic_clusters_count` | ≥ 3 topic clusters | Group more primary keywords into clusters |
| `pillar_pages_complete` | Each cluster has pillar with `title`, `target_keyword`, `word_count` (3000-6000), `content_type` | Add missing pillar page fields |
| `supporting_pages_count` | Each cluster has ≥ 3 supporting pages with `title`, `target_keyword`, `search_intent`, `word_count`, `content_type`, `priority` | Add more supporting pages |
| `content_types_defined` | ≥ 3 content types, each with `type`, `word_count_range`, `structure`, `seo_elements` (array) | Define more content types |
| `calendar_months` | `months_planned` ≥ 3 | Extend calendar to 3+ months |
| `calendar_schedule` | Schedule has entries for all planned months with content arrays | Add content entries for missing months |

**On pass:** Update state.yml → mark phase 5 complete, write recovery notes, advance to phase 6 (link-building).

**On fail:** Fix the failing checks, re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Project: [name] ([industry])
Topic clusters: [N] ([comma-separated pillar keywords])
Total content pages: [N] (pillar: [N], supporting: [N])
Content types: [N] ([comma-separated type names])
Calendar: [N] months, [cadence]
Month 1 focus: [top pillar topic]
Content gaps addressed: [N]
Brand voice: [aligned / not available]
```
