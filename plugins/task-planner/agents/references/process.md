# QA Reviewer — Stage 2 Quality Review Process

Stage 2 of two-stage verification. All checks here require judgment — content
quality, coherence, completeness beyond schema compliance. Stage 1 (spec
compliance) has already confirmed files exist, schema is valid, and state is
consistent. Do NOT re-verify those.

## When This Runs

The verification-runner or plan-execute calls this agent **only after** the
spec-compliance-reviewer (Stage 1) returns `status: pass`. If Stage 1 failed,
this agent is never invoked.

## Input

From the execution context:
- The plan file — task definitions, wave structure, verification types
- The wave number being reviewed (or "all" for final review)
- The working directory where outputs live
- Stage 1 compliance report (for reference, not for re-checking)
- **Commit range** (subagent mode only): `base_sha` and `head_sha` for this wave

### Git Diff Scoping (Subagent Mode)

When a commit range is provided, start your review by running:

```bash
git diff --stat <base_sha>..<head_sha>
```

This shows exactly which files were created or modified in this wave. Then:

```bash
git diff <base_sha>..<head_sha>
```

Review the full diff to understand what changed. This scoping is critical for
later waves — the working directory contains all prior waves' output, but you
should only judge the current wave's additions and modifications.

Files **outside** the diff are read-only context. Use them for cross-skill
alignment checks (Check 2, Check 5) but do not flag issues in them — those
were reviewed in their own wave.

When no commit range is provided (inline mode), review all files listed in the
wave's task definitions as before.

---

## Check 1: Content Coherence

Do the values produced by this skill make sense together? Does the output
tell a consistent story?

**Procedure:**

1. Read the skill's primary output file(s).
2. Look for internal contradictions:
   - A "playful" brand voice with "formal corporate" writing samples
   - A "minimalist" visual identity with 15 font weights
   - Color palette with clashing aesthetics (neon colors + "elegant luxury" positioning)
   - SEO keywords that contradict the stated target audience
3. Check that related fields reinforce each other:
   - Mission and vision should be distinct but aligned
   - Persona pain points should connect to the brand's value proposition
   - Content pillars should map to audience interests
4. Flag contradictions as `fail` with the specific conflicting values.
   Flag weak-but-not-contradictory connections as `pass_with_notes`.

**Examples:**

```yaml
# FAIL — values contradict
- name: "Content coherence — voice attributes"
  status: "fail"
  notes: "Voice attributes include both 'irreverent' and 'conservative'. These conflict. Choose one direction."
  fix_required: true
  suggested_fix: "Remove 'conservative' from voice.attributes or replace 'irreverent' with a compatible trait."

# PASS_WITH_NOTES — weak but not wrong
- name: "Content coherence — mission/vision alignment"
  status: "pass_with_notes"
  notes: "Mission focuses on 'democratizing design' but vision mentions 'enterprise solutions'. Not contradictory but the connection could be stronger."
```

## Check 2: Brand/Domain Consistency

Does this skill's output align with decisions made by earlier skills?

**Procedure:**

1. Read previous skills' output (brand-reference.yml sections, earlier YAML).
2. Verify this skill references and builds on prior work:
   - Typography choices should complement color palette aesthetics
   - Logo design should use the brand's primary colors
   - Content rules should reference the voice attributes
   - Social media strategy should target the audience personas
   - SEO keywords should align with brand positioning
3. Check for drift — values that were established early but evolved or
   contradicted by later skills:
   - Color hex values that don't match the palette
   - Font names that don't match the typography system
   - Tone descriptions that contradict the voice skill's output
4. Cross-reference integrity is Stage 1's job (do values exist?). Your
   job is: **do the references make sense?** A logo that uses the
   correct primary color but in an aesthetically jarring way is a
   Stage 2 issue, not Stage 1.

**Examples:**

```yaml
# FAIL — inconsistent with earlier decisions
- name: "Brand consistency — social media colors"
  status: "fail"
  notes: "Social media templates use #FF6B35 as accent, but this color doesn't appear in the brand palette. Palette accent is #F97316."
  fix_required: true
  suggested_fix: "Replace #FF6B35 with the brand accent #F97316 in social media template definitions."

# PASS — builds well on earlier work
- name: "Brand consistency — content rules reference voice"
  status: "pass"
  notes: "Content rules correctly reference all 5 voice attributes from tone-of-voice output. Writing samples demonstrate each attribute."
```

## Check 3: Completeness (Beyond Schema)

Schema compliance (Stage 1) checks that required fields exist and aren't empty.
This check goes further: is the content **substantive** enough to be useful?

**Procedure:**

1. Read the output and assess depth:
   - Are personas fleshed out with specific details, or generic archetypes?
   - Are writing samples actual examples, or vague descriptions?
   - Are SEO recommendations actionable, or boilerplate advice?
   - Are color usage descriptions specific to the brand, or generic ("use for CTAs")?
2. Check for thin areas:
   - Sections that meet schema requirements but provide minimal value
   - Arrays with the minimum required items but no depth per item
   - Descriptions that could apply to any brand/project
3. Grade completeness:
   - Deeply specific content → `pass`
   - Meets schema but some areas lack depth → `pass_with_notes`
   - Multiple sections are clearly thin or generic → `fail`

**Examples:**

```yaml
# FAIL — technically complete but generic
- name: "Completeness — audience personas"
  status: "fail"
  notes: "3 personas present (meets schema) but all are generic. 'Tech-Savvy Professional' has no specific behaviors, no quoted language, no day-in-the-life details."
  fix_required: true
  suggested_fix: "Enrich each persona with: specific daily behaviors, quoted language patterns, 3+ specific pain points tied to the brand's domain."

# PASS_WITH_NOTES — mostly good, one area thin
- name: "Completeness — content rules"
  status: "pass_with_notes"
  notes: "Writing standards and content types are thorough. SEO guidelines section has only 2 bullet points — could benefit from expansion."
```

## Check 4: Quality Floor

Is the writing professional, specific, and brand-appropriate?

**Procedure:**

1. Read prose content (descriptions, writing samples, manual sections).
2. Check for quality issues:
   - Generic AI-sounding language ("In today's fast-paced world...")
   - Buzzwords without substance ("synergy", "leverage", "paradigm shift")
   - Placeholder-like content that wasn't fully developed
   - Inconsistent tone within the same section
   - Grammar, spelling, or formatting errors
3. Check for specificity:
   - Content should name specific things, not categories
   - "Use Inter at 16px/24px for body text" > "Use a clean sans-serif"
   - "Target CTR of 3.5% for branded search terms" > "Improve click-through rates"
4. Minor quality issues → `pass_with_notes`. Pervasive quality problems → `fail`.

## Check 5: Cross-Skill Alignment

Do later skills build meaningfully on earlier skills' decisions?

**Procedure:**

1. Review the chain of decisions across skills:
   - Identity → Audience → Voice → Typography/Color → Visual → etc.
2. Check that each skill adds value on top of the previous:
   - Voice attributes should emerge from brand identity + audience needs
   - Typography should serve the voice (playful → rounded fonts, corporate → traditional)
   - Content rules should operationalize the voice for specific formats
3. Look for "islands" — skills that appear to have been generated
   independently without reading prior output.
4. Independent-looking output → `fail`. Weak but present connections →
   `pass_with_notes`.

---

## Final Review (Wave = "all")

When reviewing the entire plan output:

1. **Global consistency sweep.** Re-run Check 2 across all waves, verifying
   the same brand story is told throughout.
2. **Completeness audit.** Verify every task produced output that would be
   useful in a real deliverable. Flag any sections that would embarrass
   the brand if presented to a client.
3. **Overall quality judgment.** Could this deliverable be presented to a
   client as-is, or does it need polish? This is the final gate.

---

## Re-Review Protocol

When re-reviewing after fixes:

1. Increment `review_round` in the report.
2. Re-run ONLY the checks that previously failed or had notes.
3. Keep previous `pass` results unchanged.
4. If the fix introduced new issues, report them.
5. After **3 failed rounds**, escalate:

```yaml
  verdict: "ESCALATED"
  escalation_reason: "3 QA rounds without resolution"
  unresolved_issues:
    - "Personas remain generic after 3 revision attempts"
  action: "Requires human review. Present issues to user via manual_approval."
```

On escalation, the execution engine pauses and presents unresolved issues
to the user.
