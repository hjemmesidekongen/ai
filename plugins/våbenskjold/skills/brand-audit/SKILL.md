---
name: brand-audit
description: >
  Codifies an existing brand from materials, samples, and references. Analyzes
  provided content to extract voice patterns, values, and positioning. Produces
  the same guideline format as brand-strategy. Use when a brand already exists
  but isn't documented, or when /våbenskjold:audit is invoked.
user_invocable: false
interactive: true
model_tier: principal
depends_on: []
triggers:
  - "audit brand"
  - "codify existing brand"
  - "extract brand from content"
  - "/våbenskjold:audit"
reads:
  - "plugins/våbenskjold/resources/guideline-schema.yml"
  - "plugins/våbenskjold/resources/voice-schema.yml"
  - "plugins/våbenskjold/resources/values-schema.yml"
writes:
  - ".ai/brand/{name}/guideline.yml"
  - ".ai/brand/{name}/voice.yml"
  - ".ai/brand/{name}/values.yml"
  - ".ai/brand/{name}/dos-and-donts.md"
  - ".ai/brand/{name}/audit-sources.md"
checkpoint:
  type: data_validation
  required_checks:
    - name: "sources_analyzed"
      verify: "audit-sources.md lists all analyzed materials with extraction notes"
      fail_action: "Document what was analyzed and what was extracted from each"
    - name: "guideline_complete"
      verify: "guideline.yml exists with name, tagline, positioning, audience"
      fail_action: "Fill gaps by asking the user about missing elements"
    - name: "voice_extracted"
      verify: "voice.yml has voice_attributes with all 5 scales derived from samples"
      fail_action: "Re-analyze samples for voice patterns"
    - name: "user_approved"
      verify: "User confirmed the extracted brand matches their intent"
      fail_action: "Present findings and ask for corrections"
  on_fail: "Address gaps before finalizing"
  on_pass: "Brand audit complete at .ai/brand/{name}/"
_source:
  origin: "våbenskjold"
  inspired_by: "Digital Brain identity module"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New skill for brand plugin — extract brand from existing materials"
---

# Brand Audit

Extracts and codifies a brand from existing materials into structured guidelines.

## Process

1. **Gather sources** — ask for: website URL, sample content, existing docs, any brand materials
2. **Analyze** — read all materials, extract patterns for voice, positioning, values
3. **Score voice** — derive 1-10 scales from actual writing samples (not user opinion)
4. **Draft guideline** — write all files based on extracted patterns
5. **Validate** — present findings to user, ask: "does this match how you see the brand?"
6. **Refine** — adjust based on corrections, write final files

## Analysis Approach

- Voice scales: analyze 5+ content samples, count sentence patterns, measure formality
- Values: look for repeated themes, what the brand emphasizes vs ignores
- Positioning: infer from how the brand describes itself and its audience
- Document every extraction in `audit-sources.md` with source → finding mapping

## Output

Files at `.ai/brand/{name}/`. See `references/process.md` for detailed workflow.
