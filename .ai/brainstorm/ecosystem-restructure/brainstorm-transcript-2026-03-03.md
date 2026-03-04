# Brainstorm Session — ecosystem-restructure
**Date:** 2026-03-03
**Duration:** ~45 minutes

---

**User:** Currently our brand-guideline plugin also creates logo, visual identity files (icons, examples, brand-preview). Later tonight you and I will create a designer plugin, a content plugin (converting the brand voice, audience etc. into blog posts). How can we structure this best? Should the brand-guideline only create a "plan" — and the designer then be in charge of design assets like logos, favicons etc.? But not be in charge of implementing a brand-preview, because that's the skill of dev-plugin.

**Claude:** Pushed back on the "plan vs execution" split — creating friction for users. Counter-question: is brand-guideline doing too much, or are its boundaries just slightly wrong? Proposed surgical boundary adjustment: brand keeps logo generation, designer handles brand applications (business cards, social headers, asset variations, design system tokens), dev handles brand preview and component library.

**User:** I want a full-blown agency. Brainstorming loose ideas → structured plans. Creating brand guidelines. Media generation (video/image with scripts). Generating brand assets. Generating website design/prototypes. Development according to brand. Content planning. SEO. And I might have forgotten some.

**Claude:** Mapped out ~9 plugin pipeline from raw idea to live website. Challenged the framing: mixing "roles" with "deliverables." Proposed plugins should map to agency roles. Identified content is 2-3 things (strategist, writer, media). Questioned designer vs website-designer split. Flagged deep dependency chain (5 levels). Identified forgotten areas: analytics/tracking, copy/UX writing, asset management.

**User:** I agree with Copy/UX writing. We need centralized asset handling. We also need Storybook UI components.

**Claude:** Proposed UX copy belongs with content (not designer) — designer owns constraints, content fills them. Proposed shared asset registry (asset-registry.yml) as shared infrastructure. Discussed Storybook as dev concern fed by designer's component specifications. Identified designer plugin needs to output structured component specs (not just visuals) for machine-readable dev consumption. The designer plugin becomes a design system generator.

**User:** Should this perhaps just be a single "agency" plugin? If agents/skills are only read when needed... will this create overhead? Then we are never dependent on other plugins being available/activated?

**Claude:** Analyzed the trade-offs. Skills are lazy-loaded, agents spawn on demand — runtime cost is identical whether 1 plugin or 8. Separate plugins mainly add coordination tax (context loaders, version compatibility, activation management). Single plugin eliminates: inter-plugin dependency management, brand-context-loader pattern, cross-plugin state coordination, duplicate hook/script patterns. Proposed keeping task-planner separate (generic infrastructure) but merging everything else. Caveat: existing plugins (brand-guideline, seo, dev) — migrate, rebuild, or parallel?

**User:** Agency plugin it is. But structured internally by department (media, seo, brand, dev, design etc.). Keep existing plugins, build agency fresh piece by piece. Need to figure out internal dependencies and build order. I have a project where I need everything besides video.

**Claude:** Mapped dependency graph: brand → design → content/dev → seo → media. Proposed 8-phase build order following dependencies. Two key decisions needed: migrate vs rebuild, and project data structure.

**User:** Important note — currently have "switch brand" functionality. We often use turborepo. Multiple brands can live within a turborepo — need some sort of registry.

**Claude:** Proposed agency.yml as root registry with active pointer and project-to-app mapping. Discussed hierarchical vs flat registry. User clarified: brands are fully isolated tenants, shared packages are platform-level.

**User:** Brands do NOT share anything. If they share the same font it's there twice. Everything Ro-specific lives in packages/brand/ro, same with Blik. packages/shared can be consumed by anyone. The system needs to know that when working on Ro, Blik's brand is untouchable.

**Claude:** Simplified to dead simple registry: agency.yml with active project, project list with app + brand_package paths, shared packages list. File-ownership pattern applied at project level — PreToolUse hook enforces brand isolation.

**User:** Perhaps we should build something that can analyze the existing plugins so we won't miss awesome functionality? It took a long time to generate these. We need a very thorough plan. New rule: build everything needed for building Blik the right way. Note down separately what we don't implement, as a base for extending later. When we implement Blik, we'll have MVP of handling existing brand (not generation). Then add features as needed.

**Claude:** Agreed — dogfooding approach. Agency plugin's first customer is Blik. Proposed three pre-steps: (1) analyze existing plugins for valuable logic to port, (2) define Blik's specific needs as MVP scope, (3) create deferred backlog with triggers. Proposed deferred-backlog.yml format categorized by trigger conditions so future projects know exactly what to port.

---

## Key Themes

1. **Single agency plugin** — not 8 separate plugins, internally organized by department
2. **Brand isolation** — projects are tenants, never share, enforced by hooks
3. **Build for Blik** — MVP scope driven by what Blik actually needs
4. **Port don't discard** — analyze existing plugins, migrate valuable logic
5. **Deferred backlog** — track what's not built with trigger conditions
6. **Dogfooding** — agency plugin builds Blik, Blik becomes UI for agency plugin
7. **Foundation first** — brainstorm, pm, memory, review before domain skills
