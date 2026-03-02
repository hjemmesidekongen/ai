# Implementation Plan: SEO Plugin

## Overview

**What it does:** Generates a comprehensive SEO strategy with keyword research, on-page optimization, technical SEO audits, competitive analysis, and content recommendations tailored to a project's goals and target audience.
**Who it's for:** Developer or technical marketer (developer) — cares about search rankings, organic traffic, and technical site performance
**Dependencies:** task-planner, brand-guideline
**Commands:** 4 — `/seo:strategy`, `/seo:audit`, `/seo:content-brief`, `/seo:export`
**Skills:** 8 — project-interview, keyword-research, competitor-analysis, on-page-optimization, technical-seo, content-strategy, link-building, compile-and-export
**Output:** seo-strategy.yml + Markdown strategy document

---

## Architecture

```
┌──────────────────────────────────┐
│          task-planner             │
│  Waves · Verification · QA       │
└──────────┬───────────────────────┘
           │
    ┌──────▼──────────────────────┐
    │       seo-plugin             │
    │  SEO strategy generator      │
    └──────┬──────────────────────┘
           │
    ┌──────▼──────────────────────┐
    │   brand-context-loader       │
    │   (loads brand data)         │
    └──────┬──────────────────────┘
           │
    ┌──────▼──────────────────────┐
    │    brand-reference.yml       │
    │    .ai/brands/[x]/           │
    └─────────────────────────────┘
```

### Data Flow

```
Input:
  brand-reference.yml (identity, audience, voice, content)
  └── loaded via brand-context-loader

Processing:
  project-interview → keywords → competitors + technical → on-page → content → link-building → compile

Output:
  .ai/seo/[project-name]/
  ├── seo-strategy.yml        ← Machine-readable (consumed by other plugins)
  ├── seo-strategy.md         ← Human-readable strategy document
  └── state.yml               ← Wave progress tracking
```

Other plugins can READ `seo-strategy.yml` to access keyword data, content plans, and technical requirements. The seo-plugin never writes to brand-reference.yml or any other plugin's data directory.

---

## YAML Schema

The `seo-strategy.yml` file contains the complete SEO strategy data:

```yaml
meta:
  plugin_name: "seo-plugin"                  # string — always "seo-plugin"
  project_name: "my-project"                 # string — user's project identifier
  created_at: "2026-03-01T12:00:00Z"         # string — ISO 8601 timestamp
  updated_at: "2026-03-01T14:30:00Z"         # string — ISO 8601 timestamp
  version: "1.0"                             # string — schema version
  generated_by: "seo-plugin v1.0.0"          # string — plugin identifier
  brand_name: "my-brand"                     # string — brand used (if any)

project_context:
  website_url: "https://example.com"         # string — target website URL
  industry: "SaaS"                           # string — business industry
  goals:                                     # array — SEO objectives
    - goal: "Increase organic traffic"       # string — goal description
      metric: "monthly_organic_sessions"     # string — measurable metric
      target: "50000"                        # string — target value
      timeframe: "6 months"                  # string — target timeframe
  target_audience:                           # array — audience segments
    - segment: "startup founders"            # string — segment name
      search_behavior: "solution-aware"      # enum — unaware | problem-aware | solution-aware | product-aware
      preferred_content: "guides"            # string — content format preference
  current_status:                            # object — current SEO assessment
    domain_authority: 25                     # number — estimated DA (0-100)
    indexed_pages: 150                       # number — pages in search index
    top_keywords: []                         # array — currently ranking keywords
    known_issues: []                         # array — identified SEO problems

keywords:
  primary:                                   # array — main target keywords (5+)
    - keyword: "project management software" # string — the keyword phrase
      search_volume: 12000                   # number — estimated monthly searches
      difficulty: 72                         # number — competition score (0-100)
      search_intent: "commercial"            # enum — informational | navigational | commercial | transactional
      current_position: null                 # number | null — current SERP position
      target_position: 5                     # number — target SERP position
      priority: "high"                       # enum — high | medium | low
  secondary:                                 # array — supporting keywords (10+)
    - keyword: "best project management tools"
      search_volume: 8000
      difficulty: 65
      search_intent: "commercial"
      current_position: null
      target_position: 10
      priority: "medium"
  long_tail:                                 # array — long-tail keywords (15+)
    - keyword: "project management software for remote teams"
      search_volume: 800
      difficulty: 35
      search_intent: "commercial"
      current_position: null
      target_position: 3
      priority: "high"

competitors:
  analyzed:                                  # array — competitor profiles (3+)
    - domain: "competitor.com"               # string — competitor domain
      domain_authority: 65                   # number — estimated DA
      top_keywords:                          # array — their ranking keywords
        - keyword: "project management"
          position: 3
          estimated_traffic: 5000
      content_strengths:                     # array — what they do well
        - "Comprehensive guides with 3000+ words"
      content_weaknesses:                    # array — where they fall short
        - "No video content"
      backlink_profile:                      # object
        total_backlinks: 15000               # number
        referring_domains: 800               # number
        top_sources: []                      # array — notable linking domains
  content_gaps:                              # array — opportunity keywords (5+)
    - keyword: "agile project management guide"
      gap_type: "missing"                    # enum — missing | thin | outdated
      opportunity_score: 85                  # number — opportunity rating (0-100)
      recommended_action: "Create comprehensive guide"

on_page:
  title_tag:
    pattern: "[Primary Keyword] — [Brand] | [Modifier]"  # string — template
    max_length: 60                           # number — character limit
    rules:                                   # array — title tag rules
      - "Primary keyword within first 3 words"
      - "Brand name at end, separated by pipe"
  meta_description:
    pattern: "[Action verb] [benefit]. [Feature]. [CTA]."  # string — template
    max_length: 155                          # number — character limit
    rules:                                   # array
      - "Include primary keyword naturally"
      - "End with a call-to-action"
  heading_hierarchy:                         # object — heading structure rules
    h1:
      rules: ["One per page", "Contains primary keyword"]
    h2:
      rules: ["Use for major sections", "Include secondary keywords"]
    h3:
      rules: ["Use for subsections", "Include long-tail keywords where natural"]
    h4:
      rules: ["Use sparingly for deep nesting"]
  internal_linking:                          # array — linking strategy rules (3+)
    - rule: "Every page links to at least 3 related pages"
      implementation: "Add contextual links within body content"
    - rule: "Pillar pages link to all cluster content"
      implementation: "Maintain a topic cluster map"
    - rule: "New content links to existing high-authority pages"
      implementation: "Check existing content for link opportunities"
  schema_markup:                             # array — recommended schemas (2+)
    - type: "Organization"                   # string — schema.org type
      required_properties:                   # array
        - "name"
        - "url"
        - "logo"
      use_case: "Homepage and about page"    # string
    - type: "Article"
      required_properties:
        - "headline"
        - "author"
        - "datePublished"
        - "image"
      use_case: "Blog posts and guides"

technical:
  core_web_vitals:                           # object — CWV targets
    lcp:
      target: 2.5                            # number — seconds
      unit: "seconds"                        # string
      description: "Largest Contentful Paint"
    fid:
      target: 100                            # number — milliseconds
      unit: "milliseconds"
      description: "First Input Delay"
    cls:
      target: 0.1                            # number — score
      unit: "score"
      description: "Cumulative Layout Shift"
  checklist:                                 # array — technical items (10+)
    - item: "XML sitemap generated and submitted"
      priority: "critical"                   # enum — critical | high | medium | low
      status: "pending"                      # enum — pending | in_progress | done | na
      category: "crawlability"              # string — grouping category
    - item: "robots.txt configured correctly"
      priority: "critical"
      status: "pending"
      category: "crawlability"
    - item: "SSL certificate active (HTTPS)"
      priority: "critical"
      status: "pending"
      category: "security"
    - item: "Mobile-responsive design verified"
      priority: "critical"
      status: "pending"
      category: "mobile"
    - item: "Page load time under 3 seconds"
      priority: "high"
      status: "pending"
      category: "performance"
    - item: "Canonical URLs set on all pages"
      priority: "high"
      status: "pending"
      category: "crawlability"
    - item: "Image alt tags on all images"
      priority: "high"
      status: "pending"
      category: "accessibility"
    - item: "Structured data validates without errors"
      priority: "high"
      status: "pending"
      category: "rich_results"
    - item: "404 page returns proper status code"
      priority: "medium"
      status: "pending"
      category: "crawlability"
    - item: "Breadcrumb navigation implemented"
      priority: "medium"
      status: "pending"
      category: "ux"
  mobile_requirements:                       # array
    - "Viewport meta tag set"
    - "Touch targets at least 48x48px"
    - "No horizontal scrolling"
    - "Font size at least 16px base"

content_plan:
  topic_clusters:                            # array — topic clusters (3+)
    - pillar:
        title: "Complete Guide to Project Management"
        target_keyword: "project management"
        word_count: 5000                     # number
        content_type: "ultimate_guide"       # enum — ultimate_guide | how_to | listicle | case_study | comparison | tutorial
      supporting_pages:                      # array — cluster content (3+ per pillar)
        - title: "Agile vs Waterfall: Which Methodology?"
          target_keyword: "agile vs waterfall"
          search_intent: "informational"
          word_count: 2500
          content_type: "comparison"
          priority: "high"
  content_types:                             # array — content format guidelines
    - type: "ultimate_guide"
      word_count_range: "3000-6000"          # string — recommended range
      structure: "Introduction, ToC, sections with H2/H3, conclusion, FAQ"
      seo_elements: ["Schema Article markup", "Internal links to cluster", "Custom images"]
  calendar:                                  # object — publishing framework
    cadence: "2 posts per week"              # string
    months_planned: 3                        # number — minimum 3
    schedule:                                # array — planned content
      - month: 1
        content:
          - title: "Pillar: Complete Guide to Project Management"
            week: 1
            status: "planned"                # enum — planned | drafting | review | published

link_building:
  strategies:                                # array — link-building approaches (3+)
    - name: "Guest Posting"                  # string
      description: "Write expert articles for industry publications"
      estimated_effort: "high"               # enum — low | medium | high
      expected_impact: "high"                # enum — low | medium | high
      timeline: "ongoing"                    # string
      tactics:                               # array — specific actions
        - "Identify 20 target publications in the industry"
        - "Pitch 2 guest posts per month"
  outreach_targets:                          # array — target categories (5+)
    - category: "Industry blogs"             # string
      criteria: "DA > 40, relevant content"  # string
      estimated_count: 20                    # number
    - category: "News sites"
      criteria: "Cover industry news"
      estimated_count: 10
    - category: "Resource pages"
      criteria: "Link roundups, tool lists"
      estimated_count: 15
    - category: "Podcast directories"
      criteria: "Industry podcasts accepting guests"
      estimated_count: 10
    - category: "Professional communities"
      criteria: "Forums, Slack groups, Discord"
      estimated_count: 15
  content_promotion:                         # array — promotion channels (3+)
    - channel: "Social media"                # string
      tactics: ["Share on LinkedIn", "Twitter threads", "Reddit discussions"]
    - channel: "Email outreach"
      tactics: ["Notify mentioned brands", "Newsletter features"]
    - channel: "Community engagement"
      tactics: ["Answer related questions on Stack Overflow", "Contribute to GitHub discussions"]
```

---

## Commands

### /seo:strategy

**Purpose:** Generates a full SEO strategy through an interactive process with keyword research, competitor analysis, and actionable recommendations.

**Input:**
- Arguments: `project-name` (required) — kebab-case identifier for the project
- Flags: `--brand [name]` (optional) — which brand context to use
- Interactive prompts: Project interview questions (website, goals, audience) and keyword selection

**Execution Strategy:**

Interactive phases (cannot be parallelized):
1. Load brand context via brand-context-loader (if `--brand` provided)
2. Run `project-interview` skill — gather project context interactively
3. Run `keyword-research` skill — interactive keyword selection and validation

Planned phases (use task-planner):
After interactive phases, call /plan:create with:
- Tasks: competitor-analysis, technical-seo (parallel), then on-page-optimization, content-strategy, link-building (sequential), then compile-and-export
- Verification profile: seo_plugin_profile
- QA frequency: every_wave

Then call /plan:execute to run the plan.

**Output:**
- `seo-strategy.yml` — written to `.ai/seo/[project-name]/`
- `seo-strategy.md` — written to `.ai/seo/[project-name]/`
- `state.yml` — wave progress tracking

**Recovery:**
If interrupted, check state.yml at `.ai/seo/[project-name]/` and resume from the last completed wave via /plan:resume.

---

### /seo:audit

**Purpose:** Audits an existing website or page against SEO best practices and reports issues with fix recommendations.

**Input:**
- Arguments: `url` (required) — the URL to audit
- Flags: `--project [name]` (optional) — use existing project's strategy as baseline
- Interactive prompts: none

**Execution Strategy:**

No interactive phases. Single-pass autonomous execution:
1. Fetch the target URL and analyze HTML structure
2. Check against on-page SEO rules (title, meta, headings, schema markup)
3. Validate technical SEO elements (canonical, robots, sitemap reference)
4. Score accessibility of SEO elements
5. Generate audit report with findings and recommendations

**Output:**
- Audit report printed to stdout (not saved to file by default)
- If `--project` provided: compare against project's seo-strategy.yml rules

**Recovery:**
Not needed — single-pass command with no state.

---

### /seo:content-brief

**Purpose:** Generates a detailed content brief for a specific keyword or topic, including outline, target word count, and SEO requirements.

**Input:**
- Arguments: `keyword` (required) — the target keyword or topic
- Flags: `--project [name]` (optional) — use existing project's strategy for context
- Interactive prompts: Content type selection, angle confirmation

**Execution Strategy:**

Interactive phases:
1. If `--project` provided, load seo-strategy.yml for keyword data and content plan
2. Ask user to select content type (guide, how-to, listicle, comparison, etc.)
3. Ask user to confirm the content angle and target audience

Autonomous execution:
4. Research competing content for the keyword
5. Generate content brief with outline, target word count, SEO requirements, and internal linking suggestions

**Output:**
- Content brief printed to stdout and optionally saved to `.ai/seo/[project-name]/briefs/[keyword-slug].md`

**Recovery:**
Not needed — single-pass command.

---

### /seo:export

**Purpose:** Exports the SEO strategy as a formatted report in Markdown or DOCX format.

**Input:**
- Arguments: `project-name` (required) — which project to export
- Flags: `--format [md|docx|both]` (optional, default: md) — output format
- Interactive prompts: none

**Execution Strategy:**

No interactive phases. Single-pass execution:
1. Read `seo-strategy.yml` from `.ai/seo/[project-name]/`
2. Validate all required sections are present and non-empty
3. Format the strategy into the requested document format
4. If DOCX requested, apply professional styling

**Output:**
- `seo-strategy.md` and/or `seo-strategy.docx` at `.ai/seo/[project-name]/`

**Recovery:**
Not needed — single-pass command.

---

## Skills

### Skill: project-interview

**Purpose:** Gathers project context including website URL, industry, goals, target audience, and current SEO status through an interactive interview.
**Interactive:** yes
**Depends on:** none

**Inputs:**
- Reads: brand-reference.yml (identity, audience sections via brand-context-loader)

**Process:**
1. Load brand context if available — read identity.mission, identity.values, and audience.segments from brand-reference.yml via brand-context-loader
2. Ask the user for their website URL and validate it's a well-formed URL
3. Ask about their industry and business model — offer examples based on brand identity if available
4. Ask about 2-3 primary SEO goals — suggest goal-metric pairs (e.g., "Increase organic traffic → monthly_organic_sessions")
5. Ask about target audience segments — pre-populate from brand audience personas if available, ask user to confirm or adjust for SEO context
6. Assess current SEO status — ask about domain authority, indexed pages, known issues, and currently ranking keywords
7. Validate all required fields in project_context are populated and non-empty
8. Write the project_context section to seo-strategy.yml with meta section
9. Run checkpoint validation

**Output:**
- Writes: seo-strategy.yml (meta, project_context sections)

**Checkpoint:**
- Type: data_validation
- Checks:
  - project_context.website_url is a valid URL format
  - project_context.industry is non-empty
  - project_context.goals has at least 2 entries, each with goal, metric, and target fields
  - project_context.target_audience has at least 2 segments
  - project_context.current_status has domain_authority, indexed_pages, and known_issues fields
  - meta section has all required fields (plugin_name, project_name, created_at, version)

---

### Skill: keyword-research

**Purpose:** Conducts keyword research identifying primary, secondary, and long-tail keywords with search volume estimates, difficulty scores, and search intent classification.
**Interactive:** yes
**Depends on:** project-interview

**Inputs:**
- Reads: seo-strategy.yml (project_context section)
- Brand sections: voice (vocabulary, tone), content (SEO guidelines, writing rules)

**Process:**
1. Read project_context from seo-strategy.yml — extract industry, goals, and target audience
2. Load brand voice and content sections from brand-reference.yml via brand-context-loader
3. Generate seed keyword list based on industry, goals, and brand vocabulary
4. Present seed keywords to the user — ask them to confirm, remove, or add keywords
5. For each confirmed seed keyword, generate related secondary and long-tail variations
6. Estimate search volume and difficulty for each keyword based on domain knowledge
7. Classify search intent for each keyword (informational, navigational, commercial, transactional)
8. Ask the user to set priority levels (high/medium/low) for primary keywords
9. Organize keywords into primary (5+), secondary (10+), and long_tail (15+) groups
10. Write the keywords section to seo-strategy.yml
11. Run checkpoint validation

**Output:**
- Writes: seo-strategy.yml (keywords section)

**Checkpoint:**
- Type: data_validation
- Checks:
  - At least 5 primary keywords, each with search_volume, difficulty, search_intent, and priority fields
  - At least 10 secondary keywords with all required fields
  - At least 15 long-tail keywords with all required fields
  - Every keyword has search_intent set to one of: informational, navigational, commercial, transactional
  - No duplicate keywords across primary, secondary, and long_tail arrays

---

### Skill: competitor-analysis

**Purpose:** Analyzes top competitors for target keywords, identifying their strengths, weaknesses, content gaps, and backlink profiles.
**Interactive:** no
**Depends on:** project-interview

**Inputs:**
- Reads: seo-strategy.yml (project_context section — industry, website_url, current_status)

**Process:**
1. Read project_context from seo-strategy.yml — extract industry, website URL, and known competitors
2. Identify 3-5 likely competitors based on industry, goals, and target keywords from project context
3. For each competitor, estimate domain authority based on domain knowledge of the industry
4. Identify each competitor's top-ranking keywords and estimated traffic
5. Analyze content strengths — what types of content they produce, depth, frequency
6. Analyze content weaknesses — missing topics, thin content, outdated articles
7. Estimate backlink profile — total backlinks, referring domains, notable sources
8. Identify content gaps — keywords or topics where competitors are weak or absent
9. Score each content gap with an opportunity_score (0-100) based on volume, difficulty, and gap severity
10. Write the competitors section to seo-strategy.yml
11. Run checkpoint validation

**Output:**
- Writes: seo-strategy.yml (competitors section)

**Checkpoint:**
- Type: data_validation
- Checks:
  - At least 3 competitors analyzed with domain, domain_authority, and top_keywords fields
  - Each competitor has at least 2 content_strengths and 2 content_weaknesses entries
  - content_gaps array has at least 5 entries, each with keyword, gap_type, and opportunity_score
  - gap_type is one of: missing, thin, outdated
  - opportunity_score is a number between 0 and 100

---

### Skill: on-page-optimization

**Purpose:** Generates on-page SEO rules including title tag patterns, meta description templates, heading structure, internal linking strategy, and schema markup recommendations.
**Interactive:** no
**Depends on:** project-interview, keyword-research

**Inputs:**
- Reads: seo-strategy.yml (project_context, keywords sections)

**Process:**
1. Read project_context and keywords from seo-strategy.yml
2. Generate title tag pattern based on primary keywords and brand name
3. Set title tag max length to 60 characters and define placement rules
4. Generate meta description template with action verbs, benefits, and CTA structure
5. Set meta description max length to 155 characters
6. Define heading hierarchy rules (H1-H4) with keyword placement guidance
7. Create internal linking strategy with at least 3 rules covering pillar-cluster linking, contextual links, and new content linking
8. Recommend at least 2 schema markup types based on the project type (e.g., Organization, Article, FAQ, Product)
9. For each schema type, list required properties and use cases
10. Write the on_page section to seo-strategy.yml
11. Run checkpoint validation

**Output:**
- Writes: seo-strategy.yml (on_page section)

**Checkpoint:**
- Type: data_validation
- Checks:
  - title_tag has pattern, max_length (≤ 60), and at least 2 rules
  - meta_description has pattern, max_length (≤ 155), and at least 2 rules
  - heading_hierarchy has rules for h1, h2, h3, and h4
  - internal_linking has at least 3 rules, each with rule and implementation fields
  - schema_markup has at least 2 entries, each with type, required_properties, and use_case

---

### Skill: technical-seo

**Purpose:** Produces a technical SEO checklist covering site speed, mobile-friendliness, crawlability, indexation, structured data, and Core Web Vitals targets.
**Interactive:** no
**Depends on:** project-interview

**Inputs:**
- Reads: seo-strategy.yml (project_context section)

**Process:**
1. Read project_context from seo-strategy.yml — extract website URL and current status
2. Define Core Web Vitals targets: LCP ≤ 2.5s, FID ≤ 100ms, CLS ≤ 0.1
3. Generate technical checklist covering categories: crawlability, security, mobile, performance, accessibility, rich_results, ux
4. Assign priority to each item: critical (must fix), high (should fix), medium (nice to have), low (optional)
5. Set all items to status "pending" — actual status is updated during audits
6. Ensure at least 10 checklist items across at least 4 categories
7. Define mobile requirements — viewport, touch targets, scrolling, font size
8. Cross-reference with project_context.current_status.known_issues to flag relevant items
9. Write the technical section to seo-strategy.yml
10. Run checkpoint validation

**Output:**
- Writes: seo-strategy.yml (technical section)

**Checkpoint:**
- Type: data_validation
- Checks:
  - core_web_vitals has targets for lcp (≤ 2.5), fid (≤ 100), and cls (≤ 0.1)
  - checklist has at least 10 items across at least 4 categories
  - Each checklist item has item, priority, status, and category fields
  - priority is one of: critical, high, medium, low
  - mobile_requirements has at least 4 entries

---

### Skill: content-strategy

**Purpose:** Creates a content plan with topic clusters, content calendar framework, content types, and SEO-optimized content guidelines aligned with brand voice.
**Interactive:** no
**Depends on:** keyword-research, competitor-analysis

**Inputs:**
- Reads: seo-strategy.yml (keywords, competitors sections)
- Brand sections: voice (attributes, channel_variations), audience (personas), content (content_types, SEO_guidelines)

**Process:**
1. Read keywords and competitors sections from seo-strategy.yml
2. Load brand voice, audience, and content sections from brand-reference.yml via brand-context-loader
3. Group primary keywords into topic clusters — each cluster has a pillar page and 3+ supporting pages
4. For each pillar page, define title, target keyword, word count (3000-6000), and content type
5. For each supporting page, define title, target keyword, search intent, word count, content type, and priority
6. Define content type guidelines — word count ranges, structure templates, and required SEO elements for each type
7. Create a 3-month content calendar with publishing cadence and scheduled content
8. Align content tone with brand voice attributes — reference voice spectrum and channel variations
9. Incorporate competitor content gaps as content opportunities
10. Write the content_plan section to seo-strategy.yml
11. Run checkpoint validation

**Output:**
- Writes: seo-strategy.yml (content_plan section)

**Checkpoint:**
- Type: data_validation
- Checks:
  - At least 3 topic clusters defined
  - Each topic cluster has a pillar page with title, target_keyword, word_count, and content_type
  - Each topic cluster has at least 3 supporting pages
  - content_types array defines at least 3 content types with word_count_range and structure
  - calendar.months_planned is at least 3
  - calendar.schedule has entries for all planned months

---

### Skill: link-building

**Purpose:** Develops a link-building strategy with outreach targets, content promotion tactics, and authority-building recommendations.
**Interactive:** no
**Depends on:** competitor-analysis, content-strategy

**Inputs:**
- Reads: seo-strategy.yml (competitors, content_plan sections)
- Brand sections: identity (name, positioning, values)

**Process:**
1. Read competitors and content_plan sections from seo-strategy.yml
2. Load brand identity section from brand-reference.yml via brand-context-loader
3. Analyze competitor backlink profiles to identify link opportunity patterns
4. Define at least 3 link-building strategies (e.g., guest posting, resource pages, broken link building, content promotion, digital PR)
5. For each strategy, set estimated_effort, expected_impact, timeline, and specific tactics
6. Identify at least 5 outreach target categories with criteria and estimated counts
7. Create a content promotion plan covering at least 3 channels with specific tactics
8. Align outreach messaging with brand identity and positioning
9. Write the link_building section to seo-strategy.yml
10. Run checkpoint validation

**Output:**
- Writes: seo-strategy.yml (link_building section)

**Checkpoint:**
- Type: data_validation
- Checks:
  - At least 3 strategies defined, each with name, description, estimated_effort, expected_impact, and tactics
  - estimated_effort and expected_impact are one of: low, medium, high
  - At least 5 outreach target categories with category, criteria, and estimated_count fields
  - content_promotion has at least 3 channels, each with channel and tactics array

---

### Skill: compile-and-export

**Purpose:** Compiles all strategy sections into a cohesive SEO strategy document in Markdown format and validates the complete seo-strategy.yml.
**Interactive:** no
**Depends on:** project-interview, keyword-research, competitor-analysis, on-page-optimization, technical-seo, content-strategy, link-building

**Inputs:**
- Reads: seo-strategy.yml (all sections)

**Process:**
1. Read the complete seo-strategy.yml — validate all 7 data sections exist (project_context, keywords, competitors, on_page, technical, content_plan, link_building)
2. Validate each section passes its individual checkpoint criteria
3. Generate Executive Summary — summarize the strategy in 2-3 paragraphs covering goals, key findings, and recommended actions
4. Generate Keyword Strategy section — format primary keywords in a table, summarize secondary and long-tail strategy
5. Generate Competitor Landscape section — competitor comparison table, content gap opportunities
6. Generate On-Page Optimization Rules section — formatting rules, schema markup recommendations
7. Generate Technical SEO Checklist section — prioritized checklist table, Core Web Vitals targets
8. Generate Content Plan section — topic cluster diagram, content calendar table
9. Generate Link-Building Strategy section — strategy summary table, outreach target categories
10. Assemble all sections into seo-strategy.md with table of contents
11. Update seo-strategy.yml meta.updated_at and meta.version
12. Run checkpoint validation

**Output:**
- Writes: seo-strategy.md (complete strategy document)
- Writes: seo-strategy.yml (meta.updated_at, meta.version)

**Checkpoint:**
- Type: file_validation
- Checks:
  - seo-strategy.md exists and is at least 2000 words
  - Document contains all 7 sections: Executive Summary, Keyword Strategy, Competitor Landscape, On-Page Rules, Technical SEO, Content Plan, Link-Building Strategy
  - seo-strategy.yml validates against schema (all 8 top-level sections present: meta, project_context, keywords, competitors, on_page, technical, content_plan, link_building)
  - No placeholder text remains in any output file (no "[project-name]", no "TODO", no "[from design]")

---

## Build Order

| # | Skill | Rationale |
|---|-------|-----------|
| 1 | project-interview | Foundational — gathers all project context that every other skill reads |
| 2 | keyword-research | Core data model — keywords drive on-page, content, and competitor analysis |
| 3 | competitor-analysis | Independent of keywords but needs project context — can be built after keyword-research to verify the dependency model |
| 4 | technical-seo | Independent skill — only needs project context, good for validating autonomous skills |
| 5 | on-page-optimization | Depends on keywords — tests multi-dependency resolution |
| 6 | content-strategy | Depends on keywords + competitors — tests complex dependency chains and brand data integration |
| 7 | link-building | Depends on competitors + content — tests late-stage dependency resolution |
| 8 | compile-and-export | Final skill — depends on everything, validates complete data pipeline |
