# Content Plugin — Roadmap Brief

**Status:** Not started — requires dedicated brainstorm
**Depends on:** Brand plugin (voice, tone), SEO plugin (keywords, strategy)
**Brainstorm ref:** dev-hardening d7

## What It Does
All written creation — product copy, blog articles, social media captions, technical docs.

## Key Decisions (from dev-hardening brainstorm)
- Pulls brand voice from brand plugin
- Pulls SEO keywords from SEO plugin
- Separate from design plugin — content produces words, design produces visuals
- Capability-based: one plugin for all written output

## Likely Agents
- Copywriter (product/UI copy, taglines, headlines)
- Blog writer (articles, thought leadership, CEO content)
- Social media writer (captions, threads, engagement posts)
- Technical writer (docs, guides, changelogs, API docs)

## Likely Commands
- /content:write — generate content from brief + brand voice + SEO context
- /content:edit — revise existing content for tone, SEO, or clarity
- /content:calendar — plan content schedule across channels

## Open Questions (for brainstorm)
- How does content approval workflow work?
- Integration with CMS platforms?
- Content versioning — track drafts, revisions, final?
- Multi-language support?
- How does social media writer coordinate with design plugin for post visuals?

## Next Step
`/brainstorm:start content-plugin`
