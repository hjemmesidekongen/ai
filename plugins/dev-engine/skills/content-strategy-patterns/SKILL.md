---
name: content-strategy-patterns
description: >
  Content strategy patterns — pillar strategy (40/25/25/10), editorial calendars,
  content templates (blog, social, email, video), repurposing matrix, and
  pre-publishing checklists. Planning framework for consistent content production.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "content strategy"
  - "content planning"
  - "editorial calendar"
  - "content pillars"
  - "blog template"
  - "content repurposing"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "pillar_ratio_maintained"
      verify: "Content mix follows 40% educational, 25% inspirational, 25% conversational, 10% promotional"
      fail_action: "Rebalance content calendar to match pillar ratios"
    - name: "templates_have_structure"
      verify: "Every content piece follows a named template with defined sections"
      fail_action: "Assign the correct template from references/process.md"
    - name: "audience_defined_first"
      verify: "Target audience and their problem are defined before any content is written"
      fail_action: "Complete audience definition before writing"
    - name: "cta_present"
      verify: "Every content piece has a clear call-to-action appropriate to the content type"
      fail_action: "Add a CTA that matches the content's purpose and audience stage"
  on_fail: "Content lacks strategic structure — apply framework before publishing"
  on_pass: "Content follows strategy patterns"
_source:
  origin: "dev-engine"
  inspired_by: "antigravity-awesome-skills/content-creator + content_frameworks"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "Extracted strategy patterns from content-creator into knowledge skill"
---

# content-strategy-patterns

## Content Pillar Strategy

Four pillars with fixed ratios: **Educational 40%** (how-tos, tutorials, best practices) | **Inspirational 25%** (case studies, success stories, vision) | **Conversational 25%** (behind-scenes, Q&As, polls, community) | **Promotional 10%** (product updates, offers, CTAs). Track ratio monthly. Promotional over 15% erodes audience trust.

## Content Templates

**Blog**: how-to guide (hook -> prerequisites -> steps -> troubleshooting -> results -> next steps), listicle (numbered items with why/how/pro-tip/example each), case study (challenge -> solution -> results with 3 metrics), thought leadership (current state -> emerging trend -> implications -> recommendations).

**Social**: LinkedIn (hook -> context -> bullet insights -> story -> takeaway -> question), Twitter/X thread (bold opener -> context -> problem -> better approach in steps -> example -> recap), Instagram (attention line -> story -> 3 numbered points -> audience question).

**Email**: newsletter (personal hook -> main content in bullets -> resource pick -> quick win -> closing), promotional (pain -> agitate -> solution -> 3 benefits -> social proof -> CTA -> urgency).

## Repurposing Matrix

One blog post (2000 words) becomes: 5 social posts (key quotes), 1 LinkedIn article (executive summary), 3 Instagram carousels (main points), 1 newsletter feature, 1 video script, 1 infographic (data points), 1 slide deck. Always adapt format and length — never just truncate.

## SEO Content Structure

URL: `/primary-keyword`. Title tag: Primary Keyword - Benefit | Brand (under 60 chars). Meta: action verb + keyword + benefit + CTA (155 chars). Primary keyword in first 100 words and 2-3 H2s. 2-3 internal links, 1-2 external links. FAQ section for schema markup.

## Pre-Publishing Checklist

Keyword research done, title under 60 chars, meta description written, headers structured (H1/H2/H3), internal links added, images have alt text, CTA clear, proofread, mobile preview checked.

See `references/process.md` for full templates, calendar structures, video scripts, and quality checklists.
