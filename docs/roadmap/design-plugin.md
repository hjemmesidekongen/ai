# Design Plugin — Roadmap Brief

**Status:** Not started — requires dedicated brainstorm
**Depends on:** Brand plugin (brand identity as input), Pencil MCP, Untitled UI Pro
**Brainstorm ref:** dev-hardening d6

## What It Does
All visual creation — prototypes, mockups, logos, social media graphics, marketing collateral.

## Key Decisions (from dev-hardening brainstorm)
- Uses Pencil MCP + Untitled UI Pro component library
- Takes brand identity from brand plugin as input
- Logo design moves here from brand plugin
- Produces finished, approved designs before dev plugin implements them
- Dev plugin's designer agent reads these designs — it doesn't create them

## Likely Agents
- Web designer (pages, dashboards, app screens)
- Logo designer (logos, brand marks, favicons)
- Social media designer (post graphics, story templates, ad banners)
- Marketing designer (brochures, presentations, email templates)

## Likely Commands
- /design:create — create a new design from brief + brand context
- /design:iterate — refine an existing design based on feedback
- /design:export — export assets for dev handoff

## Open Questions (for brainstorm)
- How does client approval workflow work?
- What level of design fidelity — wireframe, mockup, or pixel-perfect?
- How does the Pencil MCP handle multi-page designs?
- Should there be design templates/presets per industry?
- How does handoff to dev plugin work — .pen file reference in task brief?

## Next Step
`/brainstorm:start design-plugin`
