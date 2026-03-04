# SEO Plugin — Domain Addendum

## Domain Knowledge

### How Search Engines Rank Pages

Modern search engines use hundreds of ranking signals, but they broadly fall into four categories: relevance, authority, user experience, and freshness. **Relevance** is determined by keyword matching, semantic understanding, and topical depth — Google's BERT and MUM models understand context beyond exact-match keywords, so content must address search intent, not just contain keywords. **Authority** is measured through backlinks, domain reputation, and E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness) — Google's Quality Rater Guidelines explicitly use E-E-A-T as an evaluation framework. **User experience** signals include Core Web Vitals (LCP, FID, CLS), mobile-friendliness, and HTTPS — these are direct ranking factors since Google's Page Experience update. **Freshness** matters for queries with time-sensitive intent — "best project management tools 2026" expects current content.

The SEO plugin must understand that ranking is not about gaming algorithms but about creating genuinely useful content that satisfies user intent better than competitors. Every recommendation should be grounded in providing value to the searcher, not in keyword stuffing or link schemes.

### Keyword Research Methodology

Effective keyword research follows a three-layer approach: **seed keywords** (broad industry terms), **secondary keywords** (specific variations and modifiers), and **long-tail keywords** (question-based and highly specific phrases). Each keyword should be evaluated on three dimensions: search volume (how many people search for it), difficulty (how hard it is to rank), and search intent (what the searcher wants to accomplish).

Search intent classification is critical and falls into four categories: **informational** (seeking knowledge — "what is project management"), **navigational** (seeking a specific site — "Asana login"), **commercial** (comparing options — "best project management tools"), and **transactional** (ready to buy — "Asana pricing plans"). Content format should match intent — informational queries need guides, commercial queries need comparison pages, transactional queries need landing pages.

The keyword research process should start with the user's business goals and work backward to keywords, not the other way around. A keyword with 50,000 monthly searches but no relevance to the business is worthless, while a keyword with 500 searches that perfectly matches a high-value offering is gold.

### Topic Clusters and Content Architecture

The topic cluster model organizes content into interconnected groups: a **pillar page** (comprehensive, 3000-6000 words) covers a broad topic, and multiple **cluster pages** (1500-3000 words) cover specific subtopics. All cluster pages link back to the pillar page and to each other where relevant. This architecture signals topical authority to search engines and creates a natural internal linking structure.

Each cluster should map to a primary keyword group. The pillar page targets the head term (high volume, high difficulty), while cluster pages target long-tail variations (lower volume, lower difficulty). Over time, the cluster accumulates authority through backlinks and internal links, lifting the pillar page's ranking for the competitive head term.

Content planning should follow a 3-month rolling calendar with clear publishing cadence. Consistency matters more than volume — publishing 2 high-quality posts per week beats publishing 10 mediocre posts in a burst followed by silence.

### Technical SEO Fundamentals

Technical SEO ensures search engines can crawl, index, and render a website correctly. The most impactful technical factors are: **crawlability** (XML sitemap, robots.txt, clean URL structure, no orphan pages), **indexation** (canonical tags, pagination handling, hreflang for multilingual sites), **rendering** (JavaScript SEO considerations, server-side rendering vs. client-side rendering), and **performance** (Core Web Vitals, image optimization, CDN usage, caching).

Core Web Vitals are the most important technical signals since they're direct ranking factors. LCP (Largest Contentful Paint) should be under 2.5 seconds — optimize with image compression, lazy loading, and CDN. FID (First Input Delay) should be under 100ms — optimize by minimizing JavaScript execution. CLS (Cumulative Layout Shift) should be under 0.1 — optimize by setting explicit dimensions on images and embeds.

Structured data (schema.org markup) doesn't directly improve rankings but enables rich results (featured snippets, FAQ dropdowns, star ratings) that dramatically improve click-through rates. Every site should implement Organization, BreadcrumbList, and Article schemas at minimum.

### Link-Building in 2026

Link-building has evolved from quantity-focused tactics to quality and relevance-focused strategies. Google's spam detection has made manipulative link schemes (PBNs, link farms, paid links without nofollow) increasingly risky. Effective modern link-building focuses on: **content-driven acquisition** (creating link-worthy content like original research, tools, and comprehensive guides), **digital PR** (getting coverage in industry publications for newsworthy content), **strategic outreach** (building relationships with relevant sites for guest contributions), and **broken link building** (finding broken links on relevant sites and offering your content as a replacement).

The quality of a backlink is determined by the linking domain's authority, relevance to your niche, the anchor text, and the editorial context. A single link from a highly relevant, authoritative domain is worth more than hundreds of links from irrelevant low-authority sites.

### Competitive Analysis for SEO

Competitor analysis reveals the competitive landscape and uncovers opportunities. The process involves: identifying true SEO competitors (which may differ from business competitors — the sites ranking for your target keywords), analyzing their content strategy (what topics they cover, content depth, publishing frequency), understanding their link profile (where their authority comes from), and finding content gaps (keywords or topics they're weak on or missing entirely).

Content gaps are the highest-value finding from competitive analysis. A keyword where competitors have thin, outdated, or missing content represents a low-difficulty, high-opportunity target. The gap analysis should score each opportunity based on search volume, current competitor strength, and the user's ability to create better content.

---

## Quality Standards

| Standard | Criteria | How to Verify |
|----------|----------|---------------|
| Keyword coverage | At least 30 keywords across primary, secondary, and long-tail categories | Count keywords in each category: 5+ primary, 10+ secondary, 15+ long-tail |
| Search intent accuracy | Every keyword has a correct intent classification | Verify each keyword's intent matches Google's typical SERP for that query |
| Actionable recommendations | Every recommendation includes specific implementation steps | Check that each rule, checklist item, or strategy has an "implementation" or "tactics" field |
| Competitive differentiation | Content gaps identify genuine opportunities, not just missing content | Verify each gap has opportunity_score based on volume, difficulty, and gap severity |
| Technical completeness | Technical checklist covers all critical SEO factors | Verify at least 10 items across crawlability, performance, mobile, and security categories |
| Content planning depth | Topic clusters have sufficient supporting content | Verify each cluster has 1 pillar + 3+ supporting pages with specific keywords |
| Brand alignment | Content recommendations reflect brand voice and values | Cross-reference content guidelines with brand-reference.yml voice and content sections |

---

## Tools and Dependencies

| Tool | Purpose | Required/Optional | Install Command |
|------|---------|-------------------|--------------------|
| Claude Code | Core execution environment | Required | Already installed |
| task-planner plugin | Wave planning, verification, QA | Required | Part of claude-plugins ecosystem |
| brand-guideline plugin | Brand context for content alignment | Required | Part of claude-plugins ecosystem |
| Node.js 18+ | Script execution for validation | Required | `brew install node` or `nvm install 18` |
| pandoc | DOCX export (if requested) | Optional | `brew install pandoc` |

---

## Validation Criteria

| Metric | Target | Industry Benchmark | Tool |
|--------|--------|-------------------|------|
| Primary keywords | 5+ with search data | Enterprise SEO audits typically cover 20-50 | Manual count in seo-strategy.yml |
| Total keywords | 30+ across all categories | Agency strategies typically include 50-200 | Manual count in seo-strategy.yml |
| Competitors analyzed | 3+ with full profiles | Standard competitive analysis covers 3-5 | Manual count in competitors section |
| Content gap opportunities | 5+ scored opportunities | Top agencies identify 10-20 gaps | Count entries in content_gaps array |
| Technical checklist items | 10+ across 4+ categories | Full audits cover 50-100+ items | Count entries in technical.checklist |
| Topic clusters | 3+ with pillar + 3 supporting | Content strategies typically have 5-10 clusters | Count entries in content_plan.topic_clusters |
| Content calendar | 3+ months planned | Annual planning is standard | Check calendar.months_planned field |
| Link-building strategies | 3+ with specific tactics | Agencies typically propose 5-8 strategies | Count entries in link_building.strategies |

---

## Common Mistakes to Avoid

1. **Keyword stuffing over search intent.** Selecting keywords purely by search volume without considering intent. A page targeting "free project management" (informational) shouldn't be a pricing page. Instead: Match content format to search intent classification — informational queries get guides, commercial queries get comparisons, transactional queries get landing pages.

2. **Ignoring keyword difficulty for site authority.** Recommending highly competitive keywords (difficulty 80+) for a site with domain authority 15. The site will never rank. Instead: Prioritize keywords where difficulty is at most 2x the site's domain authority. Focus on long-tail keywords first to build authority, then target harder terms.

3. **Generic technical checklist.** Producing a one-size-fits-all technical SEO checklist that doesn't account for the site's technology stack. A static site doesn't need JavaScript rendering advice; a SPA needs it critically. Instead: Tailor technical recommendations to the project's actual technology and hosting environment.

4. **Content calendar without resource reality.** Planning 5 posts per week when the user is a solo founder who can produce 1. Instead: Ask about content production capacity during the project interview and size the calendar accordingly.

5. **Competitor analysis without actionable gaps.** Listing competitors and their metrics without identifying specific opportunities the user can exploit. Instead: Every competitor entry must include content_weaknesses and every gap must have a recommended_action.

6. **Link-building without brand context.** Recommending generic guest posting without considering the brand's positioning, authority, and industry reputation. Instead: Align outreach targets and messaging with brand identity — a premium brand should target premium publications.

7. **Missing mobile-first perspective.** Treating mobile as an afterthought when Google uses mobile-first indexing. Instead: Lead with mobile requirements in the technical checklist and ensure all content recommendations account for mobile reading patterns.

8. **Schema markup without validation.** Recommending structured data types without specifying required properties, leading to invalid markup that Google ignores. Instead: Every schema recommendation includes the complete list of required properties and a test method (Google Rich Results Test).

9. **Content strategy disconnected from keywords.** Building a content plan based on what sounds interesting rather than what people actually search for. Instead: Every content piece must map to at least one keyword from the keyword research with its search volume and intent documented.

10. **Overlooking E-E-A-T signals.** Producing content recommendations without considering how to demonstrate Experience, Expertise, Authoritativeness, and Trustworthiness. Instead: Include author bylines, cite sources, link to authoritative references, and showcase first-hand experience in content guidelines.
