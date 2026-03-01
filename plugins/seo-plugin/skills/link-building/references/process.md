# Link Building — Detailed Process

Phase 6 of SEO strategy generation. This skill develops a link-building strategy informed by competitor backlink analysis and aligned with the content plan. The output feeds into the final compiled SEO strategy document.

## Prerequisites

- Read `docs/seo-plugin-implementation-plan.md` (the "Skill: link-building" section)
- Read `docs/seo-plugin-addendum.md` (the "Link-Building in 2026" section)

## Before You Start

Load context from previous phases:

1. Read `seo-strategy.yml` → extract:
   - `competitors.analyzed` — each competitor's `backlink_profile` (total_backlinks, referring_domains, top_sources)
   - `content_plan.topic_clusters` — pillar content that will be the primary link targets
   - `project_context.industry` — shapes which outreach categories are relevant
   - `project_context.goals` — prioritize strategies that align with stated goals

2. Call `brand-context-loader` to read brand-reference.yml:
   - `identity.name` — for outreach messaging
   - `identity.positioning` — differentiator and value proposition for pitches
   - `identity.values` — ensures outreach tone matches brand

3. Report what you loaded: "Building link strategy based on [N] competitor backlink profiles. Pillar content targets: [N] pages. [Brand identity loaded / No brand data found.]"

This skill is **non-interactive** — generate the full strategy and present it for review.

## Generation Process

### Step 1: Analyze Competitor Backlink Patterns

Review each competitor's backlink profile from `competitors.analyzed`:

1. For each competitor, note:
   - `total_backlinks` and `referring_domains` — scale of their link profile
   - `top_sources` — what types of sites link to them

2. Identify patterns across competitors:
   - **Common source types:** Industry blogs, news sites, resource pages, tool directories, review sites
   - **Link gap opportunities:** Source types that link to some competitors but not others
   - **Authority tiers:** Which sources have the highest domain authority

3. Summarize findings: "Competitor backlink analysis shows [pattern]. Key opportunity: [insight]."

This analysis informs which strategies and outreach targets to prioritize.

### Step 2: Define Link-Building Strategies

Define at least 3 link-building strategies. Each strategy is a distinct approach to acquiring backlinks.

**Recommended strategies (select based on industry fit):**

```yaml
strategies:
  - name: "Guest Posting"
    description: "Contribute expert articles to industry publications and blogs in exchange for author bio links and contextual mentions. Focus on publications that competitors' top_sources include."
    estimated_effort: "medium"
    expected_impact: "high"
    timeline: "Ongoing — 2-4 guest posts per month starting month 2"
    tactics:
      - "Identify 20+ industry blogs accepting guest contributions — prioritize DA 40+ sites from competitor top_sources"
      - "Develop a pitch template aligned with brand positioning — emphasize unique expertise and data"
      - "Create a content calendar for guest posts that aligns with pillar page topics"
      - "Negotiate contextual links within article body (not just author bio)"

  - name: "Resource Page Outreach"
    description: "Find resource pages and 'best of' lists in the industry that curate links to useful tools, guides, and references. Pitch pillar content for inclusion."
    estimated_effort: "low"
    expected_impact: "medium"
    timeline: "Months 1-3 — batch outreach after pillar content is published"
    tactics:
      - "Search for '[industry] resources', 'best [topic] guides', 'useful [industry] tools' to find resource pages"
      - "Qualify pages: DA 30+, recently updated, relevant to pillar content topics"
      - "Send personalized outreach highlighting what makes the pillar content uniquely valuable"

  - name: "Broken Link Building"
    description: "Find broken outbound links on industry sites that pointed to content similar to ours. Offer our content as a replacement — the site owner fixes a broken link, we gain a backlink."
    estimated_effort: "medium"
    expected_impact: "medium"
    timeline: "Months 2-4 — after enough content exists to offer as replacements"
    tactics:
      - "Use tools to scan competitor top_sources for broken outbound links"
      - "Match broken links to our existing or planned content topics"
      - "Send concise outreach: mention the broken link, suggest our content as replacement"

  - name: "Content Promotion / Digital PR"
    description: "Promote pillar content and original research through industry channels, social media, and PR outreach to earn natural backlinks from coverage and sharing."
    estimated_effort: "high"
    expected_impact: "high"
    timeline: "Ongoing — launch campaign with each pillar page publication"
    tactics:
      - "Create shareable assets for each pillar page: infographics, data summaries, quotable statistics"
      - "Reach out to industry journalists and bloggers who cover the pillar topic"
      - "Submit to relevant industry newsletters and content aggregators"
      - "Amplify through social channels with targeted promotion"

  - name: "Community Engagement"
    description: "Build authority and earn links through active participation in industry communities, forums, Q&A sites, and professional networks."
    estimated_effort: "low"
    expected_impact: "low"
    timeline: "Ongoing — consistent weekly participation"
    tactics:
      - "Answer relevant questions on industry forums and Q&A platforms with links to detailed resources"
      - "Participate in industry discussions on social platforms (LinkedIn, Twitter/X, Reddit)"
      - "Contribute to open-source projects, industry reports, or collaborative resources"
```

**Strategy selection criteria:**
- Include at least 1 high-impact strategy (guest posting or digital PR)
- Include at least 1 low-effort strategy for quick wins (resource pages or community)
- Mix timelines: some starting month 1, others building over months 2-4
- Align with competitor backlink patterns — if competitors get links from news sites, include digital PR

**Required fields per strategy:**
- `name` — clear strategy name
- `description` — what the strategy involves and why it works
- `estimated_effort` — low, medium, or high
- `expected_impact` — low, medium, or high
- `timeline` — when to start and expected cadence
- `tactics` — at least 2 specific, actionable steps

### Step 3: Identify Outreach Targets

Define at least 5 outreach target categories. These represent the types of sites to approach for backlinks.

```yaml
outreach_targets:
  - category: "Industry blogs and publications"
    criteria: "DA 40+, publishes content related to our pillar topics, accepts guest contributions or features industry news"
    estimated_count: 30
  - category: "News and media sites"
    criteria: "DA 60+, covers industry trends, has a technology or business section relevant to our niche"
    estimated_count: 15
  - category: "Resource and directory pages"
    criteria: "DA 30+, curates links to industry tools and guides, recently updated (within 12 months)"
    estimated_count: 25
  - category: "Professional communities and forums"
    criteria: "Active community with 1000+ members, relevant to our industry, allows resource sharing without being spammy"
    estimated_count: 10
  - category: "Partner and complementary businesses"
    criteria: "Non-competing businesses serving the same audience, DA 25+, open to content collaboration or cross-promotion"
    estimated_count: 20
  - category: "Educational and .edu/.gov sites"
    criteria: "High authority (DA 60+), publishes resource lists or research relevant to our industry"
    estimated_count: 10
```

**Target selection criteria:**
- Draw from competitor `top_sources` — sites that already link to competitors are proven targets
- Include a range of DA levels — high-DA targets for impact, medium-DA for volume
- Include category-specific quality filters in `criteria`
- `estimated_count` should be realistic — overestimating dilutes outreach focus

### Step 4: Content Promotion Plan

Define at least 3 promotion channels with specific tactics for each.

```yaml
content_promotion:
  - channel: "Social media"
    tactics:
      - "Share pillar content on LinkedIn, Twitter/X, and relevant industry groups with custom graphics and key takeaways"
      - "Create a thread or carousel format breaking down pillar content highlights for higher engagement"
      - "Tag and mention industry experts referenced in the content to encourage resharing"
  - channel: "Email outreach"
    tactics:
      - "Send personalized emails to industry contacts highlighting new pillar content and requesting feedback"
      - "Include content in company newsletter with a clear value proposition for subscribers"
      - "Follow up with contacts who engaged with previous outreach to build ongoing relationships"
  - channel: "Industry newsletters and aggregators"
    tactics:
      - "Submit pillar content to relevant industry newsletters (e.g., niche-specific roundups, curated digests)"
      - "Post to content aggregation platforms relevant to the industry (e.g., Hacker News, Product Hunt, Industry-specific sites)"
  - channel: "Syndication and republishing"
    tactics:
      - "Republish excerpts or adapted versions on Medium, LinkedIn Articles, or industry platforms with canonical links"
      - "Offer syndication rights to complementary publications with attribution and backlinks"
```

**Required fields per channel:**
- `channel` — name of the promotion channel
- `tactics` — at least 2 specific actions for that channel

### Step 5: Brand Alignment

If brand data is loaded, align outreach messaging with brand identity:

1. **Outreach tone:** Match `identity.values` — professional, casual, data-driven, etc.
2. **Value proposition:** Use `identity.positioning.differentiator` in outreach pitches
3. **Messaging consistency:** Ensure all outreach templates reflect the brand voice

If no brand data is available, use a neutral professional tone and recommend that outreach templates be reviewed against brand guidelines once established.

## Writing the Output

Present the link-building strategy for review:

```
## Link-Building Strategy Summary

### Strategies: [N]

| # | Strategy | Effort | Impact | Timeline |
|---|----------|--------|--------|----------|
| 1 | [name] | [effort] | [impact] | [timeline] |
| 2 | [name] | [effort] | [impact] | [timeline] |
| 3 | [name] | [effort] | [impact] | [timeline] |

### Outreach Targets: [N] categories, ~[total estimated_count] potential targets

| # | Category | Criteria | Est. Count |
|---|----------|----------|------------|
| 1 | [category] | [criteria summary] | [count] |
| 2 | ... | ... | ... |

### Content Promotion: [N] channels

[channel names, comma-separated]

Brand alignment: [aligned with brand / not available]

Does this strategy look right? I can adjust strategies, targets,
or promotion channels.
```

Present for review. Then write the `link_building` section to `seo-strategy.yml`:

```yaml
link_building:
  strategies:
    - name: "Guest Posting"
      description: "..."
      estimated_effort: "medium"
      expected_impact: "high"
      timeline: "Ongoing — 2-4 posts per month"
      tactics:
        - "Identify 20+ industry blogs..."
        - "Develop pitch templates..."
    # ... more strategies
  outreach_targets:
    - category: "Industry blogs and publications"
      criteria: "DA 40+, accepts guest contributions..."
      estimated_count: 30
    # ... more targets
  content_promotion:
    - channel: "Social media"
      tactics:
        - "Share pillar content with custom graphics..."
        - "Create thread format for key highlights..."
    # ... more channels
```

Update `state.yml`:
- Set `current_phase: "link-building"`
- Add phase entry with `status: "complete"` and checkpoint results

## Checkpoint: data_validation

After writing, run these checks:

| Check | Rule | Fail action |
|-------|------|-------------|
| `strategies_count` | >= 3 strategies, each with `name`, `description`, `estimated_effort` (low/medium/high), `expected_impact` (low/medium/high), `timeline`, `tactics` (>= 2 entries) | Add more strategies with all required fields |
| `outreach_targets_count` | >= 5 outreach targets, each with `category`, `criteria`, `estimated_count` (number) | Identify more target categories from competitor analysis |
| `content_promotion_channels` | >= 3 channels, each with `channel` and `tactics` (>= 2 entries) | Add more promotion channels with specific tactics |

**On pass:** Update state.yml, mark phase 6 complete, write recovery notes, advance to phase 7 (compile-and-export).

**On fail:** Fix the failing checks, re-run validation. Do NOT advance. Max 3 rounds.

## Recovery Notes

After checkpoint passes, write recovery notes to `state.yml`:

```
Project: [name] ([industry])
Strategies: [N] ([comma-separated strategy names])
Effort/Impact: [N] high-impact, [N] low-effort quick wins
Outreach targets: [N] categories, ~[total] potential targets
Content promotion: [N] channels ([comma-separated channel names])
Top priority: [highest impact strategy name]
Brand alignment: [aligned / not available]
```
