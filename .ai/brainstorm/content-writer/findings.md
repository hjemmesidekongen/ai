# Content Writer Architecture — Research Findings

## Date: 2026-03-11

## What we built so far
- `plugins/smedjen/skills/content-writer/SKILL.md` (80 lines, iteration 2)
- `plugins/smedjen/skills/content-writer/references/process.md` (full templates, NEVER list, examples)
- `plugins/smedjen/commands/content-write.md`
- Registered in ecosystem.json (skill + command)

## Validation Results (Round 1 — 3 agents)

### Skill Auditor: 89/120 (B, 74%)
- depends_on incomplete (3 listed, 6 used) — FIXED in iteration 2
- No consolidated NEVER list — FIXED
- No worked examples — FIXED
- Content Types table had truncated skill names — FIXED

### Description A/B Tester
- Original description: 18/25 findability
- Recommendation: switch to Description B (done)
- Trigger improvements: replaced "generate content" with "write content", added "write email copy" and "write case study"
- User intent match: improved from 4/15 YES to expected ~9/15

### Quality Reviewer: 10 issues found
- depends_on incomplete — FIXED
- Truncated skill names in table — FIXED
- reads list duplicated brand-loader — FIXED
- Tone override vs voice.yml conflict — FIXED (voice priority hierarchy)
- "Which means" bridge in wrong check — FIXED (moved to Check 3)
- Missing scannability gate — FIXED (added Check 5)
- Command description too thin — FIXED
- Marketing copy template too generic — noted, not yet fixed
- No email template — FIXED
- Cross-plugin dep on writing-clearly-and-concisely — noted

## Round 2 validation agents launched (awaiting results)
- Re-audit with skill-auditor
- Re-test findability

## Critical Finding: Architecture Question

External reference analysis (11 repos) reveals a consistent pattern:

### Pattern: Split Architecture
- **AGENTS for broad content roles** (strategy + execution + judgment)
  - content-marketer agent — omnichannel strategy + content production
  - technical-writer agent — documentation architecture + creation
  - documentation-engineer agent — documentation systems + automation
  - seo-specialist agent — technical SEO + content optimization

- **SKILLS for specific content types** (templates + process + knowledge)
  - email-sequence skill — email templates + flows
  - social-content skill — platform-specific hooks + formats
  - blog-writing-guide skill — editorial standards + structure
  - crafting-effective-readmes skill — README-specific guidance
  - wiki-page-writer skill — technical docs + Mermaid diagrams
  - seo-content-writer skill — SEO-optimized articles
  - professional-communication skill — emails + meeting agendas

### Key Insight
NO external repo created ONE combined content generator. They ALL split by:
1. Execution model: agent (autonomous) vs skill (reference)
2. Content type: specialized skills per type
3. Agents orchestrate OTHER agents, not skills directly

### What this means for us
Our current content-writer skill is doing agent-level work (multi-step orchestration,
skill loading, brand loading, quality gates, decision-making) but dressed as a skill.

Options:
A. Keep as one skill (simpler, fewer files, but fights the pattern)
B. Create a content-writer AGENT + keep the skill as orchestration knowledge
C. Split into agent + specialized skills per content type (matches external pattern)

### Recommended: Option B or C
- Create `content-writer` agent in smedjen/agents/
- The agent handles orchestration (intake, brand loading, skill activation, quality gates)
- Keep content-writer skill as the knowledge/template reference the agent uses
- Consider adding specialized skills later (readme-writer, social-content) as volume demands

## Existing smedjen agents for reference
- architect, backend-dev, frontend-dev, test-engineer, code-reviewer, app-security-auditor
- A content-writer agent fits this pattern perfectly

## Status
- Waiting for round 2 validation results
- Need user decision on architecture (skill-only vs agent+skill)
