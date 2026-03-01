---
name: project-interview
description: >
  Runs an interactive interview to gather project context for SEO strategy:
  website URL, industry, business model, SEO goals, target audience segments,
  and current SEO status. Writes the meta and project_context sections to
  seo-strategy.yml.
phase: 1
depends_on: []
writes:
  - "seo-strategy.yml#meta"
  - "seo-strategy.yml#project_context"
reads:
  - "brand-reference.yml#identity (via brand-context-loader)"
  - "brand-reference.yml#audience (via brand-context-loader)"
brand_sections_needed:
  - "identity.mission"
  - "identity.values"
  - "identity.positioning"
  - "audience.segments"
checkpoint:
  type: data_validation
  required_checks:
    - name: "website_url_valid"
      verify: "project_context.website_url starts with http:// or https://"
      fail_action: "Ask the user for a valid website URL"
    - name: "industry_present"
      verify: "project_context.industry is a non-empty string"
      fail_action: "Ask the user to specify their industry"
    - name: "goals_count"
      verify: "project_context.goals has at least 2 entries, each with goal, metric, target, and timeframe"
      fail_action: "Ask for additional SEO goals until at least 2 are defined"
    - name: "audience_count"
      verify: "project_context.target_audience has at least 2 segments, each with segment, search_behavior, and preferred_content"
      fail_action: "Ask for additional audience segments until at least 2 are defined"
    - name: "current_status_complete"
      verify: "project_context.current_status has domain_authority (number), indexed_pages (number), and known_issues (array)"
      fail_action: "Ask about missing current SEO status fields"
    - name: "meta_complete"
      verify: "meta has plugin_name, project_name, created_at, version, and generated_by"
      fail_action: "Fill in missing meta fields from context"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Project Interview

Phase 1 of SEO strategy generation. This is the first skill that runs — everything else builds on the project context captured here. The interview produces the `meta` and `project_context` sections of `seo-strategy.yml`.

## Prerequisites

- Read `docs/seo-plugin-implementation-plan.md` (the "Skill: project-interview" section)
- Read `docs/seo-plugin-addendum.md` (the "Domain Knowledge" section) for SEO context
- Read `docs/ecosystem-strategy.md` Section 6 for the brand-reference.yml schema

## Findings Persistence

During the interview, write intermediate discoveries to the findings file:

```
~/.claude/seo/[project-name]/findings.md
```

**What to save:** User responses about website, industry, business model, SEO goals, audience segments, current SEO status, any research done to suggest options, brand context loaded.

**2-Action Rule:** After every 2 research operations (user question answered, web search, file read), IMMEDIATELY save key findings to findings.md before continuing. Do not wait until all stages are complete.

**Format:**

```markdown
## Project Interview Findings

### Project Basics
- Project name: [answer]
- Website URL: [answer]
- Industry: [answer]
- Brand context: [loaded/not loaded]

### SEO Goals
- Goal 1: [goal] → [metric] (target: [target], [timeframe])
- Goal 2: [goal] → [metric] (target: [target], [timeframe])

### Target Audience
- [Segment 1]: [search_behavior] — prefers [content_format]
- [Segment 2]: [search_behavior] — prefers [content_format]

### Current Status
- Domain authority: [estimate]
- Indexed pages: [count]
- Top keywords: [list or "none"]
- Known issues: [list or "none"]

### Research Notes
- [any industry research, goal suggestions, or context gathered]
```

This file persists across `/compact` and session restarts. If context is lost, findings survive.

## Error Logging

When errors occur during the interview (validation failures, checkpoint failures, unexpected issues):

1. Log the error to state.yml `errors` array immediately
2. Before retrying any approach, check `errors` for previous failed attempts
3. Never repeat a failed approach — mutate strategy instead
4. The verification-runner logs checkpoint failures automatically

## Interview Philosophy

- Ask **one question at a time**. Never present a wall of questions.
- **Offer examples** relevant to the user's industry to help them answer.
- If the user gives a **vague answer**, ask a focused follow-up to sharpen it.
- If the user says **"I don't know"**, suggest 2-3 options based on their industry. Let them pick or adapt.
- Keep the tone conversational and practical — this is gathering context, not filling a form.
- After each answer, briefly reflect back what you understood before moving on.

## Pre-Interview: Load Brainstorm Decisions

Before starting the interview, call the decision-reader skill to check if the
user already made relevant decisions during a brainstorm session:

- **Project:** the project name being created
- **Domains:** `seo`, `brand-identity` (for brand positioning context)

If decisions are found, adjust the interview flow:

| Confidence | Behavior |
|------------|----------|
| **High** | Pre-fill the answer and show for quick confirmation: "From your brainstorm: [decision]. Still good? [Y/n]" — if confirmed, skip the question |
| **Medium** | Present as starting point: "You were leaning toward: [decision]. Go with this, or explore further?" — if accepted, use it; otherwise ask normally with the decision as context |
| **Low** | Mention as context when asking the question: "You mentioned [decision] during brainstorming. Let's discuss..." — then proceed with the normal question |
| **Not found** | Ask normally — this is the default behavior without brainstorming |

Use the decision-reader's `check_decision` method before each question to find
matching decisions. For example, before asking about SEO goals, check for
decisions matching the `goals` field in the `seo` domain.

At the end, note which decisions were applied in state.yml:

```yaml
decisions_applied: [d1, d5, d8]
```

## Pre-Interview: Load Brand Context

Before starting the interview, attempt to load brand context:

1. Call `brand-context-loader` to read brand-reference.yml
2. Extract these sections if available:
   - `identity.mission` — brand's purpose (helps suggest relevant goals)
   - `identity.values` — brand's principles (informs content approach)
   - `identity.positioning` — category, target, differentiator (shapes audience segments)
   - `audience.segments` — existing audience definitions (pre-populates target audience)
3. If brand data is found, note it — you'll use it to pre-fill and suggest answers
4. If no brand data exists, that's fine — proceed without it

## Interview Flow

The interview has 5 stages. Each stage produces data for a specific part of the schema.

### Stage 1: Project Basics → `meta` section

Collect project identifiers and initialize the data file.

**Questions (one at a time):**

1. "What's the name of this project?"
   - Must be usable as a directory name (kebab-case). If they give "My Cool Project", suggest "my-cool-project"
   - This becomes the project_name in meta and the directory name at `~/.claude/seo/[project-name]/`

2. "What's your website URL?"
   - Validate: must start with `http://` or `https://`
   - If they give a bare domain like "example.com", prepend "https://"
   - If they don't have a site yet, accept a placeholder URL and note it

**Output:**

```yaml
meta:
  plugin_name: "seo-plugin"
  project_name: "[kebab-case name]"
  created_at: "[ISO 8601 timestamp]"
  updated_at: "[ISO 8601 timestamp]"
  version: "1.0"
  generated_by: "seo-plugin v1.0.0"
  brand_name: "[brand name if loaded, or empty]"
```

Initialize the seo-strategy.yml file at `~/.claude/seo/[project-name]/` with the meta section.

### Stage 2: Industry & Business Model → `project_context.industry`

**Question:**

"What industry does your project operate in, and what's your business model?"

- Offer examples: "SaaS, E-commerce, Agency, B2B Services, Media, Education, Fintech, Healthcare"
- If brand identity is loaded, suggest based on `identity.positioning.category`
- If they give something broad like "tech", ask: "Can you narrow that? For example: developer tools, marketing SaaS, consumer fintech?"

**Output:**

```yaml
project_context:
  industry: "[answer]"
```

### Stage 3: SEO Goals → `project_context.goals`

**Question:**

"What are your 2-3 primary SEO goals? I'll pair each one with a measurable metric."

Present goal-metric pairs as examples:

| Goal | Metric | Example Target |
|------|--------|----------------|
| Increase organic traffic | monthly_organic_sessions | 50,000/month |
| Improve keyword rankings | average_position | Top 10 for 20 keywords |
| Grow backlink profile | referring_domains | 500 domains |
| Increase conversions from organic | organic_conversion_rate | 3% conversion rate |
| Reduce bounce rate on key pages | bounce_rate | Below 40% |
| Improve local search visibility | local_pack_appearances | Top 3 for 10 queries |

**Follow-up for each goal:**

1. Confirm the metric makes sense for the goal
2. Ask for a target value: "What's a realistic target for [metric]?"
3. Ask for timeframe: "In what timeframe? 3 months, 6 months, 12 months?"

If fewer than 2 goals, prompt: "Most effective SEO strategies target at least 2 goals. What else matters to you?"

**Output (minimum 2):**

```yaml
  goals:
    - goal: "[description]"
      metric: "[metric_name]"
      target: "[target_value]"
      timeframe: "[timeframe]"
    - goal: "[description]"
      metric: "[metric_name]"
      target: "[target_value]"
      timeframe: "[timeframe]"
```

### Stage 4: Target Audience → `project_context.target_audience`

**If brand audience personas are loaded:**

Present the existing personas from `audience.segments`:

"I found these audience segments from your brand profile:
1. [Segment name] — [brief description from brand data]
2. [Segment name] — [brief description from brand data]

For SEO, I need to understand how each segment searches. Let me add search behavior for each."

Then for each segment, ask:
- "How search-aware is [segment]?" — offer the four levels:
  - **Unaware** — doesn't know they have a problem yet
  - **Problem-aware** — knows the problem but not solutions
  - **Solution-aware** — knows solutions exist, comparing options
  - **Product-aware** — knows your product, deciding to buy
- "What content format does [segment] prefer?" — examples: blog posts, video tutorials, comparison guides, case studies, technical docs

**If no brand data:**

"Who are your 2-3 main audience segments? For each, I need:
- A segment name (e.g., 'small business owners', 'enterprise developers')
- Their search behavior level
- Their preferred content format"

Walk through the same search_behavior options for each segment.

**Output (minimum 2):**

```yaml
  target_audience:
    - segment: "[name]"
      search_behavior: "[unaware|problem-aware|solution-aware|product-aware]"
      preferred_content: "[format]"
    - segment: "[name]"
      search_behavior: "[level]"
      preferred_content: "[format]"
```

### Stage 5: Current SEO Status → `project_context.current_status`

**Question:**

"Let me understand where your site stands today. Don't worry if you don't have exact numbers — estimates are fine."

Ask these one at a time:

1. "What's your estimated domain authority? (0-100 scale, where 0 is brand new and 100 is Wikipedia)"
   - If they don't know: "A brand new site starts at 0-5. A small business site is typically 10-30. A well-known industry site is 40-70."
   - Accept a number or a range (take the midpoint)

2. "Roughly how many pages are indexed by Google?"
   - If they don't know: "You can check with `site:yourdomain.com` in Google. If you're unsure, give your best guess — 10 pages? 100? 1000?"
   - Accept a number

3. "Are you currently ranking for any keywords?"
   - If yes, capture as array of `{ keyword, position }` (position is 1-100)
   - If no, set to empty array

4. "Are there any known SEO issues or penalties?"
   - Offer examples: "Slow page speed, mobile usability issues, duplicate content, manual penalty, thin content, broken links"
   - Capture as array of strings
   - If none, set to empty array

**Output:**

```yaml
  current_status:
    domain_authority: 25
    indexed_pages: 150
    top_keywords:
      - keyword: "[term]"
        position: 12
    known_issues:
      - "Slow page load times"
      - "Missing meta descriptions on 40% of pages"
```

## Writing the Output

After completing all stages, present a summary for confirmation:

```
Here's your project context for SEO strategy:

Project: [name] — [industry]
Website: [url]
Brand: [brand name or "none loaded"]

Goals:
  1. [goal] → [metric] (target: [target], [timeframe])
  2. [goal] → [metric] (target: [target], [timeframe])

Target Audience:
  1. [segment] — [search_behavior] — prefers [content_format]
  2. [segment] — [search_behavior] — prefers [content_format]

Current Status:
  Domain Authority: [da]
  Indexed Pages: [count]
  Ranking Keywords: [count or "none"]
  Known Issues: [list or "none"]

Does this look right? I can adjust anything before we save.
```

Only write to disk after the user confirms.

Write to `~/.claude/seo/[project-name]/seo-strategy.yml`:
- `meta` section (all fields)
- `project_context` section (all sub-sections)

Also initialize `~/.claude/seo/[project-name]/state.yml`:

```yaml
command: "seo:strategy"
project_name: "[project-name]"
brand_name: "[brand or empty]"
started_at: "[ISO 8601]"
current_phase: "project-interview"
phases:
  - name: "project-interview"
    status: "complete"
    completed_at: "[ISO 8601]"
    checkpoints:
      - website_url_valid: true
      - industry_present: true
      - goals_count: true
      - audience_count: true
      - current_status_complete: true
      - meta_complete: true
verification_results: []
```

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `website_url_valid` | `project_context.website_url` starts with `http://` or `https://` | Ask for a valid URL |
| `industry_present` | `project_context.industry` is non-empty string | Ask to specify industry |
| `goals_count` | `project_context.goals` has ≥ 2 entries, each with `goal`, `metric`, `target`, `timeframe` | Ask for more goals |
| `audience_count` | `project_context.target_audience` has ≥ 2 segments, each with `segment`, `search_behavior`, `preferred_content` | Ask for more segments |
| `current_status_complete` | `current_status` has `domain_authority` (number), `indexed_pages` (number), `known_issues` (array) | Ask about missing fields |
| `meta_complete` | `meta` has all required fields: `plugin_name`, `project_name`, `created_at`, `version`, `generated_by` | Fill from context |

**On pass:** Update state.yml → mark phase 1 complete, write recovery notes, advance to phase 2 (keyword-research).

**On fail:** Fix the failing checks (ask targeted questions), re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to state.yml for cross-session resume:

```
Project: [name] ([industry])
Website: [url]
Goals: [comma-separated goal summaries]
Audience: [comma-separated segment names]
DA: [domain_authority], Pages: [indexed_pages]
Brand context: [loaded/not loaded]
```

These notes let a future session reconstruct context without re-reading the full seo-strategy.yml.
