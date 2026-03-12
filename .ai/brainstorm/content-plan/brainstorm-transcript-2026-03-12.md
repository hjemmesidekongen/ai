# Brainstorm: hjemmesidekongen.dk Content Plan
**Date:** 2026-03-12
**Goal:** Lock decisions on sitemap, launch scope, content approach, and SEO strategy

## Context loaded
- Brand foundation: guideline.yml, voice.yml, values.yml, dos-and-donts.md
- Visual identity + tokens: just rebuilt
- Previous content layer deleted — rebuilding from scratch
- No client projects yet (empty portfolio at launch)

## Decision areas
1. Sitemap / IA
2. Competitor landscape
3. Launch scope
4. Content strategy
5. SEO approach
6. Conversion architecture

---

## Session transcript

### Research: Competitor landscape (Danish market)

**Direct competitors in Kolding area:**
- **Kolding Webbureau** (koldingwebbureau.dk) — agency, "360 graders digitale løsninger", WordPress, SEO, Facebook ads. Exactly the agency-speak hjemmesidekongen positions against.
- **Tribe Media** (tribe.dk) — agency in Kolding. Three tiers: design from 9.950, design+dev from 19.950, full service from 29.950. WordPress. Classic agency structure.
- **Jalte** (Giig.dk) — freelancer in Kolding, 300-450 kr/t, 23 years old, "digital expert and website developer"

**Danish freelancer market (Giig.dk snapshot):**
- Rates: 150-900 kr/t. Most popular: 450-600 kr/t range
- Most are WordPress or Webflow specialists
- Profiles are generic — "erfaren webudvikler" with bullet lists of tech
- Very few have distinctive personal brands

**DNWEB.dk (Silkeborg freelancer — closest comparable):**
- Timepris: 700 kr/t
- Packages: hjemmeside fra 14.995, webshop fra 17.495
- WordPress + Laravel specialist
- Clean site, clear pricing, testimonials

**Pattern observed:** Most Danish freelancers either have no website at all (just a Giig/LinkedIn profile) or a generic WordPress theme with stock photography. Almost nobody has a strong content play (blog, SEO content). The bar is low.

**International best practice patterns (Finxter analysis):**
- Domain + simple site
- Niche + customer problem front and center
- Trust elements (portfolio, testimonials, social proof)
- One clear CTA
- Value proposition obvious from first screen

---

---

### PIVOT: This is not the freelance site

**Session redirect.** We're building for **ai.hjemmesidekongen.dk** — a product/documentation site for the hjemmesidekongen-ai repo (the Claude Code plugin ecosystem: kronen, smedjen, herold, våbenskjold, segl).

- Audience: developers (colleagues, open-source community)
- Language: English (with Danish plugin names preserved)
- Tone: inherits hjemmesidekongen vibe but adapted for dev audience
- Product: free, open-source — treat like SaaS showcase but no commercial intent
- Scope: landing page + documentation + blog (end-to-end workflow showcases)
- Sub-brand: "hjemmesidekongen/AI" — needs its own brand adaptation + visual identity
- hjemmesidekongen.dk (root domain) will be for freelance practice later — separate concern

**Logo:** Crown + curly braces (geometric angular orange crown, grey braces). Keep crown. Play with "/AI" or "AI." suffix — potentially different color treatment for the AI part.

---

### Research: Documentation site best practices

**Fumadocs / Nextra / Docusaurus pattern:**
- Landing page with: Hero, Sponsors, About, Stats, How It Works, Features, CTA, FAQ, Footer
- Documentation sidebar with nested navigation
- Search (critical for large component counts)
- MDX for interactive code examples

**Developer blog best practices:**
- Personal troubleshooting stories get 40% more engagement than pure code (Reddit analysis)
- 62% of devs prefer tutorials with personal experience alongside technical explanation (Stack Overflow)
- Structure: Hook → Problem statement → Step-by-step guide → Conclusion → CTA
- Code snippets should be concise, executable, focused on one concept
- "Why" alongside "how" accelerates comprehension
- Blogs with embedded quizzes/interactive elements see 35% more retention

**Plugin ecosystem documentation:**
- Each plugin/module needs its own section
- Well-defined interfaces/APIs as the organizing principle
- "Drop folder to add features" mental model resonates with devs
- Lifecycle documentation matters (install, configure, use, extend)

---

### Sparring continues

