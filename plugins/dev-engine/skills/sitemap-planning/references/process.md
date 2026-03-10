# Sitemap Planning — Detailed Reference

## Sitemap Template

### SaaS Product Site
```
/                           Homepage (pillar)
├── /features               Features overview (pillar)
│   ├── /features/[name]    Individual feature pages
│   └── /features/compare   Comparison page
├── /pricing                Pricing page
├── /solutions              Solutions by use case (pillar)
│   └── /solutions/[case]   Individual solution pages
├── /customers              Customer stories (pillar)
│   └── /customers/[name]   Individual case studies
├── /blog                   Blog index (pillar)
│   ├── /blog/[category]    Category archives
│   └── /blog/[slug]        Individual posts
├── /docs                   Documentation (pillar)
│   └── /docs/[section]     Doc sections
├── /about                  About page
├── /contact                Contact page
└── /legal                  Legal pages
    ├── /legal/privacy
    └── /legal/terms
```

### Marketing / Agency Site
```
/                           Homepage
├── /services               Services overview (pillar)
│   └── /services/[name]    Individual service pages
├── /work                   Portfolio (pillar)
│   └── /work/[project]     Case studies
├── /about                  About / Team
├── /blog                   Blog (pillar)
│   └── /blog/[slug]        Posts
├── /contact                Contact
└── /resources              Resources (pillar)
    └── /resources/[type]   Guides, templates, tools
```

## URL Structure Rules

- Lowercase only
- Hyphens between words (not underscores)
- Under 60 characters
- Primary keyword early in the URL
- Remove stop words (the, a, an, of, in)
- Mirror the site hierarchy
- No trailing slashes (or be consistent)
- No parameters for content pages

### URL Examples
| Good | Bad |
|------|-----|
| `/features/api-monitoring` | `/features/API_Monitoring` |
| `/blog/reduce-deploy-time` | `/blog/2024/03/how-to-reduce-your-deploy-time-significantly` |
| `/docs/getting-started` | `/docs?page=getting-started&v=2` |

## Content Silo Strategy

### Step-by-Step
1. **Identify core topics** (3-7 silos)
2. **Create pillar page** per silo (broad, comprehensive)
3. **Map cluster pages** (specific subtopics within each silo)
4. **Link cluster → pillar** (every cluster page links to its pillar)
5. **Link pillar → clusters** (pillar page links to all its clusters)
6. **Cross-link sparingly** (only when genuinely relevant)

### Silo Visualization
```
Silo: "Deployment"
├── Pillar: /features/deployment (broad overview)
├── Cluster: /blog/zero-downtime-deploys
├── Cluster: /blog/rollback-strategies
├── Cluster: /docs/deploy-configuration
├── Cluster: /customers/acme-deploy-story
└── Cross-link: /features/monitoring (related silo)
```

### Internal Linking Matrix

For each silo, map which pages link to which:

| From / To | Pillar | Cluster 1 | Cluster 2 | Cluster 3 |
|-----------|--------|-----------|-----------|-----------|
| Pillar | — | link | link | link |
| Cluster 1 | link | — | link | — |
| Cluster 2 | link | — | — | link |
| Cluster 3 | link | link | — | — |

## Header Hierarchy Patterns

### Feature Page
```
H1: [Feature Name] — [Outcome]
├── H2: How [Feature] Works
│   ├── H3: Step 1
│   └── H3: Step 2
├── H2: Key Benefits
│   ├── H3: Benefit 1
│   └── H3: Benefit 2
├── H2: [Feature] vs Alternatives
├── H2: Customer Results
└── H2: Get Started with [Feature]
```

### Blog Post
```
H1: [Title with Primary Keyword]
├── H2: [Context / Why This Matters]
├── H2: [Main Section 1 — Secondary KW]
│   ├── H3: [Subtopic]
│   └── H3: [Subtopic]
├── H2: [Main Section 2 — Related KW]
├── H2: [FAQ / Common Questions]
│   ├── H3: Question 1?
│   └── H3: Question 2?
└── H2: [Conclusion / Next Steps]
```

### Landing Page
```
H1: [Value Proposition — Primary KW]
├── H2: The Problem
├── H2: How [Product] Solves It
├── H2: Key Features
│   ├── H3: Feature 1
│   └── H3: Feature 2
├── H2: What Customers Say
├── H2: Pricing
└── H2: Get Started
```

## Schema Markup (JSON-LD)

### Organization
```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Company Name",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "sameAs": ["https://twitter.com/example", "https://linkedin.com/company/example"]
}
```

### BreadcrumbList
```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com" },
    { "@type": "ListItem", "position": 2, "name": "Features", "item": "https://example.com/features" },
    { "@type": "ListItem", "position": 3, "name": "API Monitoring" }
  ]
}
```

### FAQPage
```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is API monitoring?",
      "acceptedAnswer": { "@type": "Answer", "text": "API monitoring tracks..." }
    }
  ]
}
```

### Article
```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Title",
  "author": { "@type": "Person", "name": "Author Name" },
  "datePublished": "2026-01-15",
  "dateModified": "2026-03-10"
}
```

## Featured Snippet Optimization

### Types and Formats
| Snippet Type | Content Format | Placement |
|-------------|---------------|-----------|
| Paragraph | 40-60 word definition | Right after relevant H2 |
| List | Numbered or bulleted steps | Under "How to" H2 |
| Table | Comparison data | Under "vs" or comparison H2 |

### Optimization Rules
- Target question-based queries
- Place answer immediately after the H2 that matches the query
- Keep paragraph snippets to 40-60 words
- Use ordered lists for processes, unordered for features
- Tables need clear headers and 3+ rows

## Navigation Patterns

### Primary Navigation
- 5-7 top-level items maximum
- Most important pages first
- Dropdown menus for subcategories (max 2 levels)
- Include CTA in navigation ("Get Started", "Free Trial")

### Footer Navigation
- Repeat key links from primary nav
- Add secondary pages (legal, careers, press)
- Include social links
- Sitemap link for crawlers

### Breadcrumbs
- Show on all pages except homepage
- Follow URL hierarchy
- Schema markup (BreadcrumbList) on every breadcrumb
- Last item is current page (not linked)

## Audit Checklist

- [ ] All key pages within 3 clicks from homepage
- [ ] No orphaned pages (every page has inbound links)
- [ ] One H1 per page matching primary topic
- [ ] Logical header hierarchy (no skipped levels)
- [ ] URLs are clean, descriptive, under 60 chars
- [ ] Content organized into topical silos
- [ ] Internal linking follows silo structure
- [ ] 2-3 internal links minimum per page
- [ ] Breadcrumbs on all subpages
- [ ] Schema markup on key page types
- [ ] XML sitemap includes only canonical, indexable URLs
- [ ] Navigation has 5-7 top-level items
