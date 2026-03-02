# Brainstorm Session — dev-hardening
**Date:** 2026-03-02
**Duration:** ~45 minutes

---

**User:** Ok so now for the dev plug-in we need to add some MCPs: the untitled UI MCP, the Next Vercel, the Railway MCP, and the Neon Postgres. We also need to reference some external skills from /Users/mvn/.claude/skills/custom and /Users/mvn/Personal/hjemmesidekongen/.claude/skills. Skills like Neon Postgres, Figma, Untitled UI, Next.js, React, etc. should be added as dependencies but not owned by us. We need to make the dev plugin more hardened and professional with better agents, skills, and knowledge. Should also have LLMs added.

**Claude:** Pushed back on the stack specificity — MCPs and skills are heavily weighted toward Next.js/React/Tailwind. Asked whether the dev plugin is a general-purpose team or a Next.js-specific team.

**User:** Clarified: Vue 3/Nuxt 4 is just as modern as Next.js 16 — different stack, not legacy. Projects are either Nuxt 2/3/4 + Vue 2/3 or Next.js 16 + React + Tailwind. Backend is Next.js + Prisma + Neon when needed. Not all projects have backends. Wants generic orchestration with swappable framework packs.

**Claude:** Identified the external skills relationship problem — skills in ~/.claude/skills/custom aren't versioned with the plugin. Proposed three options: vendor, reference by path, or shared dependency.

**User:** Custom skills should live in claude-local-workspace, not global config. Wants external skills (Figma, Vercel, Next.js maintained) as npm-style dependencies. Goal is marketplace distribution — colleagues download the plugin and get everything.

**Claude:** Researched — found that Claude Code plugins can't declare skill dependencies. Plugins are self-contained, can't reference outside their directory once cached. Proposed /dev:init checking for missing skills and prompting install.

**User:** Pointed to skills.sh (Vercel's skills ecosystem) and npx skills add as the package manager. Many skills ARE from external sources.

**Claude:** Researched skills.sh — found the full ecosystem. Verified globally installed skills (neon-postgres, prisma-*, railway, etc.) and skills.sh marketplace. Confirmed third-party teams maintain their own skills. Proposed: plugin ships dependency manifest, /dev:init checks and installs missing, MCPs declared in plugin.json.

**User:** Raised update problem — what if plugin evolves and needs different skills? Users running stale dependencies.

**Claude:** Proposed version-aware dependency manifest + SessionStart hook for passive checking. Also suggested /dev:doctor command.

**User:** Pivoted — instead of referencing external skills, fork them locally. Two buckets: Custom (written by user) and External (copied from skills.sh, trimmed). Reason: external skills often have more than needed, hard to remove bits since they're from external sources.

**Claude:** Proposed directory structures — by stack vs flat. Suggested origin tracking in frontmatter rather than directory split. Noted that once forked, a skill IS custom — the origin field is just for update tracking.

**User:** Agreed on origin tracking. Wants ability to check upstream changes and cherry-pick updates.

**Claude:** Proposed /dev:skills check command for upstream diffing. Mapped skills to existing tag system from dev plugin design. Proposed framework-packs directory structure with tag-based loading.

**User:** Asked about MCPs and code examples. Wants reference implementations that override AI defaults for component structure etc.

**Claude:** Researched MCP support in plugins — confirmed plugin.json can declare mcpServers. Proposed examples/ directory in each framework pack. Discussed conditional MCP activation.

**User:** Questioned whether unused MCPs matter. Suggested all MCPs always available, skills reference which ones to use.

**Claude:** Agreed — overhead is minimal, agents only call MCPs when needed. Architecture: all MCPs in plugin.json, skills reference relevant ones, /dev:init validates API keys.

**User:** Asked what else we might be missing.

**Claude:** Identified gaps: agents are empty, project-level overrides, designer agent workflow, plugin scope boundaries. Noted global agents exist in ~/.claude/agents/ with full content.

**User:** Confirmed self-tiering is the desired model, not junior/senior/principal agent split. Wants global agents moved into this repo. Proposed a separate Design plugin for visual creation (Pencil + Untitled UI), distinct from dev plugin's design-aware implementer.

**Claude:** Pushed on design plugin scope — proposed capability-based plugin organization: Brand (identity), Design (visual creation), Content (written creation), Dev (code), SEO (strategy).

**User:** Agreed strongly. Asked about videographer and photographer plugins using external AI (not Claude).

**Claude:** Proposed execution sequence: Wave 1 harden dev, Wave 2 design plugin, Wave 3 content plugin, Wave 4 media plugins. Noted media plugins establish pattern of orchestrating external AI.

**User:** Wants persistent plans for each future plugin so they don't get lost. Also wants a /dev:refactor command for reshaping existing code to match conventions without breaking functionality.

**Claude:** Proposed /dev:refactor with stronger safety: test-first, smaller waves, per-component commits, mandatory QA, full regression, conservative tier assignment.

**User:** Emphasized production safety is critical — breaking client code in production is the worst outcome. Agreed on the cautious approach.
