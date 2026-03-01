---
name: keyword-research
description: >
  Conducts keyword research identifying primary, secondary, and long-tail
  keywords with search volume estimates, difficulty scores, and search intent
  classification. Writes the keywords section to seo-strategy.yml.
phase: 2
depends_on: [project-interview]
writes:
  - "seo-strategy.yml#keywords"
reads:
  - "seo-strategy.yml#project_context"
  - "brand-reference.yml#voice (via brand-context-loader)"
  - "brand-reference.yml#content (via brand-context-loader)"
brand_sections_needed:
  - "voice.vocabulary"
  - "voice.attributes"
  - "content.seo_guidelines"
checkpoint:
  type: data_validation
  required_checks:
    - name: "primary_keywords_count"
      verify: "keywords.primary has at least 5 entries, each with keyword, search_volume (number), difficulty (0-100), search_intent (enum), and priority (enum)"
      fail_action: "Generate more primary keywords and ask user to confirm"
    - name: "secondary_keywords_count"
      verify: "keywords.secondary has at least 10 entries, each with search_volume, difficulty, and search_intent"
      fail_action: "Generate more secondary keywords from seed variations"
    - name: "longtail_keywords_count"
      verify: "keywords.long_tail has at least 15 entries, each with search_volume, difficulty, and search_intent"
      fail_action: "Generate more long-tail keywords (question-based, specific phrases)"
    - name: "intent_classification"
      verify: "Every keyword has search_intent set to one of: informational, navigational, commercial, transactional"
      fail_action: "Classify any unclassified keywords"
    - name: "no_duplicates"
      verify: "No duplicate keywords across primary, secondary, and long_tail arrays"
      fail_action: "Remove duplicate keywords, keeping the one in the highest-priority category"
  on_fail: "Fix issues and re-run checkpoint. Do NOT advance to next phase."
  on_pass: "Update state.yml, write recovery_notes, advance to next phase."
---

# Keyword Research

Phase 2 of SEO strategy generation. This skill builds on the project context from Phase 1 to identify target keywords organized by priority and search intent. The output feeds directly into competitor-analysis (Phase 3), on-page-optimization, and content-strategy.

## Prerequisites

- Read `docs/seo-plugin-implementation-plan.md` (the "Skill: keyword-research" section)
- Read `docs/seo-plugin-addendum.md` (the "Keyword Research Methodology" section) for domain knowledge
- Read `docs/ecosystem-strategy.md` Section 6 for the brand-reference.yml schema

## Before You Start

Load the context from previous phases:

1. Read `seo-strategy.yml` → extract `project_context`:
   - `industry` — grounds keyword suggestions in the right domain
   - `goals` — each goal's metric area suggests keyword themes
   - `target_audience` — segment names and search behaviors shape keyword intent
   - `current_status.top_keywords` — existing keywords to build on (don't re-research from scratch)

2. Call `brand-context-loader` to read brand-reference.yml:
   - `voice.vocabulary` — brand-specific terms to include as seed keywords
   - `voice.attributes` — tone characteristics that influence keyword phrasing
   - `content.seo_guidelines` — any existing SEO guidance from brand setup
   - `content.writing_rules` — terminology preferences

3. Report what you loaded: "I found your project context for [industry] with [N] goals and [N] audience segments. [Brand data loaded / No brand data found.]"

## Research Process

The research has 5 stages. The approach works backwards from business goals to keywords — a keyword is only valuable if it connects to the project's objectives.

### Stage 1: Generate Seed Keywords

Generate a list of at least 10 seed keywords based on:

1. **Industry terms** — core terminology for the project's industry
2. **Goal-aligned terms** — keywords that map to each SEO goal's metric area
   - If goal is "increase organic traffic" → broad industry head terms
   - If goal is "improve keyword rankings" → specific product/service terms
   - If goal is "grow backlink profile" → resource-worthy, link-magnet terms
   - If goal is "increase conversions" → transactional and comparison terms
3. **Audience-driven terms** — what each target segment would search for at their awareness level
   - Unaware → problem-symptom keywords ("why is my site slow")
   - Problem-aware → problem-definition keywords ("website performance issues")
   - Solution-aware → comparison keywords ("best CDN providers")
   - Product-aware → brand + product keywords ("[brand] pricing")
4. **Brand vocabulary** — if brand data is loaded, include terms from `voice.vocabulary`
5. **Existing keywords** — include any `current_status.top_keywords` as seeds

Present the seed list to the user:

```
Here are the seed keywords I generated based on your project context:

 1. [keyword] — from [source: industry/goal/audience/brand]
 2. [keyword] — from [source]
 3. ...
10. [keyword] — from [source]

Which keywords should I keep? Remove any that aren't relevant,
and add any I missed. This list drives everything that follows.
```

**One interaction round:** show list → get feedback → finalize seeds.

### Stage 2: Expand to Secondary and Long-Tail

For each confirmed seed keyword, generate variations:

**Secondary keywords (2-3 per seed):**
- Add modifiers: "best [seed]", "[seed] for [industry]", "[seed] tools"
- Related terms: synonyms, adjacent concepts, feature-specific terms
- Localized variants if relevant: "[seed] [location]"

**Long-tail keywords (3-5 per seed):**
- Question-based: "how to [seed]", "what is [seed]", "why [seed] matters"
- Specific phrases: "[seed] for [audience segment]", "[seed] vs [alternative]"
- Problem-solution pairs: "fix [problem] with [seed]", "[seed] best practices"
- Year-qualified: "best [seed] 2026", "[seed] guide 2026"

Do NOT present every variation to the user — this is a generation step. The user reviews the final organized list in Stage 4.

### Stage 3: Estimate Search Metrics

For each keyword (primary, secondary, long-tail), estimate:

**Search volume (monthly searches):**
- Use industry benchmarks from the addendum as a baseline
- Head terms (1-2 words): typically 1,000-100,000+ depending on industry
- Mid-tail (2-3 words): typically 100-10,000
- Long-tail (4+ words): typically 10-1,000
- Adjust based on industry size: B2B niches have lower volumes than B2C consumer categories

**Difficulty (0-100 scale):**
- 0-20: Low — new or small sites can rank
- 21-40: Medium-low — some competition, achievable with good content
- 41-60: Medium — established competition, need strong content + links
- 61-80: Hard — dominant players, need authority + exceptional content
- 81-100: Very hard — major brands dominate, consider alternatives

**Search intent classification:**
- **Informational** — seeking knowledge ("what is", "how to", "guide", "tutorial")
- **Navigational** — seeking a specific site/page ("[brand] login", "[product] docs")
- **Commercial** — comparing options ("best", "vs", "review", "top 10", "comparison")
- **Transactional** — ready to act ("buy", "pricing", "signup", "free trial", "download")

Use the query's natural language as the primary intent signal. A keyword can only have ONE intent — choose the dominant one.

### Stage 4: Present and Prioritize

Present the complete keyword list organized by category:

```
## Primary Keywords (your main targets)

| # | Keyword | Volume | Difficulty | Intent | Priority |
|---|---------|--------|------------|--------|----------|
| 1 | [keyword] | [vol] | [diff] | [intent] | ? |
| 2 | [keyword] | [vol] | [diff] | [intent] | ? |
...

For each primary keyword, set a priority:
- High — actively target within the first 3 months
- Medium — target in months 3-6
- Low — monitor and target when resources allow

## Secondary Keywords ([N] keywords)
[Show in table format, no priority needed]

## Long-Tail Keywords ([N] keywords)
[Show in table format, no priority needed]
```

Ask the user to:
1. Set priority (high/medium/low) for each primary keyword
2. Remove any keywords that don't fit
3. Flag any missing terms they want added

### Stage 5: Deduplicate and Validate

Before writing:

1. **Check for duplicates** across all three arrays (primary, secondary, long_tail)
   - If a keyword appears in multiple categories, keep it in the highest-priority category
   - "best project management tools" in both primary and secondary → keep in primary

2. **Validate counts:**
   - Primary: at least 5 keywords
   - Secondary: at least 10 keywords
   - Long-tail: at least 15 keywords
   - If short, generate more variations and ask user to confirm

3. **Verify every keyword has:**
   - `keyword` (string, non-empty)
   - `search_volume` (number, > 0)
   - `difficulty` (number, 0-100)
   - `search_intent` (one of: informational, navigational, commercial, transactional)
   - `priority` (primary keywords only: high, medium, or low)

## Writing the Output

After validation, present a summary:

```
Keyword Research Summary:

Primary: [N] keywords ([N] high, [N] medium, [N] low priority)
Secondary: [N] keywords
Long-tail: [N] keywords
Total: [N] unique keywords

Intent breakdown:
  Informational: [N] ([%])
  Commercial: [N] ([%])
  Transactional: [N] ([%])
  Navigational: [N] ([%])

Average difficulty: [avg] (scale 0-100)

Ready to save?
```

Only write to disk after the user confirms.

Write the `keywords` section to `seo-strategy.yml`:

```yaml
keywords:
  primary:
    - keyword: "project management software"
      search_volume: 12000
      difficulty: 72
      search_intent: "commercial"
      priority: "high"
    - keyword: "..."
      # ...

  secondary:
    - keyword: "project management for startups"
      search_volume: 1200
      difficulty: 38
      search_intent: "commercial"
    - keyword: "..."
      # ...

  long_tail:
    - keyword: "how to choose project management software for remote teams"
      search_volume: 320
      difficulty: 22
      search_intent: "informational"
    - keyword: "..."
      # ...
```

Update `state.yml`:
- Set `current_phase: "keyword-research"`
- Add phase entry with `status: "complete"` and checkpoint results

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `primary_keywords_count` | ≥ 5 primary keywords, each with `keyword`, `search_volume` (number), `difficulty` (0-100), `search_intent` (enum), `priority` (enum) | Generate more primary keywords |
| `secondary_keywords_count` | ≥ 10 secondary keywords with `search_volume`, `difficulty`, `search_intent` | Generate more secondary variations |
| `longtail_keywords_count` | ≥ 15 long-tail keywords with `search_volume`, `difficulty`, `search_intent` | Generate more long-tail phrases |
| `intent_classification` | Every keyword has valid `search_intent` (informational/navigational/commercial/transactional) | Classify unclassified keywords |
| `no_duplicates` | No duplicate keyword strings across all three arrays | Remove duplicates, keep in highest category |

**On pass:** Update state.yml → mark phase 2 complete, write recovery notes, advance to phase 3 (competitor-analysis).

**On fail:** Fix the failing checks, re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Project: [name] ([industry])
Primary keywords: [top 5 by priority, comma-separated]
Total keywords: [N] (primary: [N], secondary: [N], long-tail: [N])
Intent mix: [N]% informational, [N]% commercial, [N]% transactional, [N]% navigational
Top difficulty: [highest difficulty keyword and score]
Brand vocabulary included: [yes/no]
```

These notes let a future session understand the keyword landscape without re-reading the full seo-strategy.yml.
