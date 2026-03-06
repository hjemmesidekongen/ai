# Brainstorm Session — agency-enhancements
**Date:** 2026-03-06
**Duration:** ~45 minutes

---

**User:** Wants to enhance the development and design process of Claude Local Workspace Agency. Add new features.

**User:** Ran the full flow (brand → design → build) for project "blik". Brand looked fine, logos good, colors and story good, even generated a mockup in Pencil. Then asked to generate a full website from it. Code looked like it would be nice but didn't render properly. Wants verification steps where the agent runs it in the browser, confirms it looks correct, then marks as done. Wants iterative verification — every feature, not just final.

**Claude:** Proposed four approaches: screenshot-diff, dev server + LLM vision, dev server + human-in-the-loop, hybrid. Recommended hybrid (LLM first pass, escalate to human on uncertainty).

**User:** Prefers hybrid with minimal human bottleneck.

**Claude:** Recommended Pencil screenshots as first-class reference artifacts. Proposed per-section milestones instead of per-component (layout skeleton → above the fold → full page → multi-page + interactions). Four-level checklist: broken, structural, visual fidelity, content. LLM auto-passes levels 1, 2, 4. Level 3 gets confidence score, below threshold → human.

**User:** Doesn't want pixel-perfect. Wants structural alignment and visual discipline — consistent gutters, elements respecting grid, aligned baselines, no orphaned whitespace, no mixed alignment patterns. Professional, not pixel-accurate.

**Claude:** Proposed three-tier verification: code lint (static analysis of spacing tokens, grid usage, container consistency), LLM vision (screenshot against reference), human escalation (only when uncertain or at final milestone). Design tokens as single source of truth for code lint.

**User:** Wants error pages (404, 403, 400, 500) as first-class deliverables in design, planning, and implementation. Not necessarily four different designs but basic error pages. Wants logging on error pages to see why people landed there.

**Claude:** Agreed. Error page template + logging instrumentation (URL, referrer, session/request ID, timestamp). Build phase needs error handling pattern, not just pages.

**User:** Wants stack negotiation — interactive selection before config generation. Scanner found Next.js, Tailwind, etc. but user had no opportunity to specify Untitled UI component library and Untitled Icons Pro. Wants MCP server availability to feed into stack recommendations. Plugin should scan available MCP servers and prompt user for each framework choice.

**Claude:** Proposed tiered approach — always ask (framework, CSS, component library, icons), ask if ambiguous (auth, database, API style), never ask (linter, test runner, bundler). Proposed profile system (personal vs work contexts).

**User:** "They do matter to me" — user is a senior lead principal-level engineer. Wants strict ground rules for how to develop. Linter config, test runner, file structure — these ARE the architecture. Wants the agent to be an extension of their arm.

**Claude:** Proposed codex concept — three layers: profile (project context), codex (engineering standards), stack rules (per-technology conventions). Proposed structured files in `.ai/codex/` loaded based on stack.

**User:** Thought of these as skills — Tailwind skill, React skill with generic defaults. Also wants project-specific convention discovery for legacy projects. Example: 5-year-old Nuxt 2 project with many developers and inconsistent styles vs 3-year-old Nuxt 2 project with clean style. Agent should scan, figure out conventions, note them down.

**Claude:** Separated two concepts: generic skills (your defaults, portable) vs project convention scan (audit, discovers patterns from existing code). Proposed `/agency:audit` command.

**User:** Wants TDD by default — pure Red/Green/Refactor. Should be detectable (don't impose tests where project has none). Defaults: vitest for unit, Playwright for e2e. Unit tests live alongside components, e2e in separate `/e2e/` folder.

**Claude:** Proposed TDD as a skill, not a pipeline feature. Two separate skills: tdd.md (implementation discipline) and e2e-testing.md (Playwright conventions).

**User:** Strict TDD — one test, one failing test, least amount added, make it pass, next feature. Example: test renders → div with testid → test shows heading → add heading. Pure cycle.

**Claude:** Acknowledged purest form. Each cycle adds exactly one assertion and exactly enough code.

**User:** TDD is just a development paradigm. Should be a skill. Clean distinction between unit tests and e2e tests. vitest --watch while programming.

**Claude:** Agreed — simplified to a skill the agent follows. Three testing skills: tdd.md, test-utilities.md, e2e-testing.md.

**User:** Wants opinion about shared mocks. Sees full test setup with mocks repeated every time, providers defined a million times with different props. Wants shared test infrastructure.

**Claude:** Proposed test utilities file — renderWithProviders(), factory functions (createMockUser()), MSW handlers. Discipline: check if shared mock exists before writing inline. Applies to both unit and e2e.

**User:** Separate concern from TDD — applies to both unit and e2e.

**User:** Quality of Pencil output — looks like a prototype/mockup, not final design. Wants to understand if that's intentional or if Pencil can do more.

**Claude:** Investigated Pencil capabilities. Found landing-page guidelines are extremely detailed (world-class marketing designer, transformation mapping, anti-slop rules, creative variation). Style guide system has hundreds of tags. Diagnosed: the agency pipeline never fully uses Pencil's capabilities. All phases produce YAML/config files. Pencil rendering is an afterthought via /agency:render, not integrated into design flow. Proposed: full Pencil design phase using guidelines + style guides, screenshots as build reference.

**User:** Wants error pages to include marketing/retention opportunity. "Since you searched for football shirts, could you be interested in these?" Lead user on instead of rejecting. UX writing skill should produce error page copy.

**Claude:** Agreed — different error types deserve different recovery strategies. Content module deliverable, not just dev scaffold.

**User:** Wants strict focus on logging and observability. Three distinct systems: error logging (Sentry), analytics (user behavior, page flows, clicks, UTMs), observability (system health, latency, performance).

**Claude:** Proposed three separate skills. Analytics needs event taxonomy, user identity decisions, funnel definitions. Noted GDPR/consent gating requirement.

**User:** Wants to know as much about the user as possible — UTM source, entry point, etc. Confirms three separate skills.

**User:** Default animation library: Motion.dev (former Framer Motion).

**User:** Watched YouTube video — guy made Gemini implement a website that looked "absolutely insanely awesome" with a single prompt. Shared the full "Cinematic Landing Page Builder" prompt. Wants to understand what made it look so good.

**Claude:** Analyzed the cinematic prompt. Identified four key factors: ships complete design system in prompt (aesthetic intent, not just tokens), prescribes specific interaction patterns (choreography, not abstract specs), has fixed visual texture rules (noise overlay, radius system, magnetic buttons), has anti-generic rules baked in. But pushed back: it's a straitjacket — one kind of website every time. What to steal is the level of specificity, not the specific patterns.

**User:** Wants the agent to make experiential decisions beforehand — how should this feel? What should it look like? How would the target audience feel? How can we make this feel premium? Brand guidelines already capture this. Problem is how to generate implementation context from it.

**Claude:** Agreed — design intent dies on the way to implementation. Proposed design-to-implementation translation skill that produces implementation guide per page (entrance animations, scroll behavior, interaction weight, texture). Build agents get three references: Pencil screenshot, component spec, implementation guide.

**User:** Default animation library is Motion.dev.

**User:** Wants to search for proven, well-tested skills as reference library for design/implementation skill.

**Claude:** Searched and found: Anthropic's frontend-design skill (proven baseline), Bencium's controlled-ux-designer (~830 lines accessibility, ~600 lines responsive, motion spec — most thorough single skill), freshtechbro's motion-framer skill (Motion.dev specific), Claude Code Frontend Design Toolkit (70+ tools). Proposed port strategy: Anthropic base + Bencium depth + motion-framer, integrated into agency plugin.

**User:** Concerned whether end result will be explanatory enough to create beautiful websites like the cinematic prompt.

**Claude:** Honest answer: no, not yet. Identified missing layer: creative direction. Proven skills are defensive (what not to do) and mechanical (timing curves, scales). Cinematic prompt works because of prescriptive creative direction (identity language, component choreography, visual texture rules). Proposed four-layer architecture: anti-slop baseline → mechanical design rules → creative direction (generated per project from brand) → engineering standards (codex). Creative direction document describes identity, feel, motion philosophy, spatial philosophy, texture, interaction weight, color strategy — derived from brand context.

**User:** "If you say so, it does :-)"
