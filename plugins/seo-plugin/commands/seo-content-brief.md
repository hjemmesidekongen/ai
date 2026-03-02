---
name: seo-content-brief
command: "/seo:content-brief"
description: "(seo) Generate a detailed content brief for a specific keyword or topic with outline, SEO requirements, and internal linking suggestions"
arguments:
  - name: keyword
    type: string
    required: true
    description: "The target keyword or topic to create a content brief for"
  - name: project
    type: string
    required: false
    description: "Use an existing project's strategy for keyword context, content plan, and competitor data"
---

# /seo:content-brief

Generates a detailed content brief for a specific keyword or topic. When used with `--project`, enriches the brief with keyword data, content plan context, and competitor gap analysis from the existing strategy.

## Usage

```
/seo:content-brief "project management for remote teams"                     # standalone brief
/seo:content-brief "project management for remote teams" --project my-saas   # with project context
```

## Purpose

Generates a detailed content brief for a specific keyword or topic, including outline, target word count, SEO requirements, and internal linking suggestions. Designed for content creators who need a structured plan before writing.

## Prerequisites

- task-planner plugin installed
- Recommended: an existing SEO strategy at `.ai/seo/[project-name]/` for richer briefs

## Input

- `keyword` (required) — the target keyword or topic
- `--project [name]` (optional) — use existing project's strategy for context

## Execution Strategy

### Interactive Phases

#### Step 1: Load Context (if --project provided)

If `--project` is specified:
1. Read `.ai/seo/[project-name]/seo-strategy.yml`
2. Extract relevant context:
   - Check if the keyword exists in `keywords.primary`, `keywords.secondary`, or `keywords.long_tail` — if found, use its `search_volume`, `difficulty`, and `search_intent`
   - Check if the keyword is a `target_keyword` in any `content_plan.topic_clusters` — if found, use the planned `word_count`, `content_type`, and related cluster pages for internal linking
   - Check if the keyword matches any `competitors.content_gaps` — if found, reference the `recommended_action` and `opportunity_score`
   - Load `on_page` rules for title tag pattern, meta description template, and heading hierarchy

If no project, proceed with general SEO best practices.

#### Step 2: Select Content Type

Ask the user to select a content type:

```
What type of content should this be?

1. Ultimate guide (3000-6000 words — comprehensive deep-dive)
2. How-to (1500-3000 words — step-by-step instructions)
3. Listicle (1500-2500 words — numbered list with descriptions)
4. Case study (1500-2500 words — problem → solution → results)
5. Comparison (2000-3000 words — feature-by-feature comparison)
6. Tutorial (1500-3000 words — practical walkthrough)
```

If the keyword is already planned in the content strategy, suggest the planned content type.

#### Step 3: Confirm Angle and Audience

Ask the user to confirm the content angle:

```
Here's my suggested angle for "[keyword]":

Title: [suggested title based on keyword and content type]
Target audience: [segment from project strategy or general description]
Angle: [unique perspective or value proposition]

Does this work, or would you like to adjust the angle?
```

### Autonomous Execution

#### Step 4: Research Competing Content

Analyze what currently ranks for the target keyword:
1. Identify common topics and subtopics covered by top-ranking pages
2. Note content gaps — topics competitors miss or cover shallowly
3. Determine the expected depth and comprehensiveness needed to compete

#### Step 5: Generate Content Brief

Produce the complete brief:

```
# Content Brief: [Title]

## Overview
- **Target keyword:** [keyword]
- **Search volume:** [volume] (if known from project)
- **Difficulty:** [score] (if known)
- **Search intent:** [intent]
- **Content type:** [selected type]
- **Target word count:** [range based on type]

## Title Tag
[Generated using on_page.title_tag.pattern if project exists]
Max length: 60 characters

## Meta Description
[Generated using on_page.meta_description.pattern if project exists]
Max length: 155 characters

## Content Outline

### H1: [Main heading with primary keyword]

### H2: [Section 1 heading]
- Key points to cover
- [Supporting detail]

### H2: [Section 2 heading]
- Key points to cover
- [Supporting detail]

### H2: [Section 3 heading]
...

[Continue for all planned sections — typically 4-8 H2s for guides, 3-5 for how-tos]

## SEO Requirements
- [ ] Primary keyword in H1 and first paragraph
- [ ] Secondary keywords to include: [list from project or generated]
- [ ] Internal links to: [related pages from content plan or suggestions]
- [ ] External links to: [authoritative sources]
- [ ] Schema markup: [recommended type based on content type]
- [ ] Images: [N] with descriptive alt text containing keyword variations

## Competitor Analysis
- Top competing pages: [summary of what ranks]
- Content gap opportunity: [what competitors miss]
- Differentiation angle: [how to stand out]

## Internal Linking Suggestions
[If project exists:]
- Link TO: [related pillar/supporting pages from content plan]
- Link FROM: [existing pages that should link to this new content]
[If no project:]
- Identify 3+ related pages on your site to link to and from
```

## Output

- Content brief printed to stdout
- If `--project` provided: also saved to `.ai/seo/[project-name]/briefs/[keyword-slug].md`
  - `keyword-slug` is the keyword in kebab-case (e.g., "project-management-for-remote-teams")

## Recovery

Not needed — single-pass command.
