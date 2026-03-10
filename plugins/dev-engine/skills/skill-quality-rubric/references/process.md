# Skill Quality Rubric — Process Reference

## Per-Dimension Rubric Descriptors

### 1. Accuracy (weight: 1.5x)
- **5**: All facts, APIs, and code examples verified correct against current docs.
- **4**: One minor inaccuracy that does not cause runtime errors.
- **3**: Contains deprecated patterns but still functional.
- **2**: Multiple inaccuracies or an API that changed significantly.
- **1**: Fundamentally wrong information that would break code.

### 2. Completeness (weight: 1.0x)
- **5**: Covers every major use case implied by the skill name.
- **4**: Covers 80%+ of expected scope. Minor gaps documented.
- **3**: Core scenarios covered, edge cases missing.
- **2**: Significant gaps — common scenarios not addressed.
- **1**: Covers less than half the expected scope.

### 3. Code Quality (weight: 1.5x)
- **5**: All examples compile, follow idiomatic patterns, and are copy-paste safe.
- **4**: Examples work but have minor style inconsistencies.
- **3**: Examples work but mix patterns or have non-obvious setup requirements.
- **2**: Some examples would fail without undocumented modifications.
- **1**: Examples don't compile or use fundamentally wrong patterns.

### 4. Anti-pattern Coverage (weight: 1.0x)
- **5**: Dedicated anti-patterns section with concrete bad examples and explanations.
- **4**: Anti-patterns mentioned inline with good coverage.
- **3**: A few anti-patterns noted but not comprehensive.
- **2**: Anti-patterns mentioned vaguely ("be careful with...").
- **1**: No anti-patterns mentioned despite known pitfalls.

### 5. Up-to-dateness (weight: 1.0x)
- **5**: References the latest stable version. No legacy patterns.
- **4**: References a recent version (within 1 minor release).
- **3**: References a version that is stable but not latest.
- **2**: References a version with known breaking changes in newer releases.
- **1**: References a deprecated or EOL version.

### 6. Progressive Disclosure (weight: 1.0x)
- **5**: SKILL.md is a complete quick-start. All depth in process.md.
- **4**: SKILL.md mostly concise. One section could move to process.md.
- **3**: SKILL.md has some depth that belongs in process.md.
- **2**: SKILL.md is too detailed — reads like a reference doc.
- **1**: No separation — all content in SKILL.md or all in process.md.

### 7. Trigger Discoverability (weight: 0.5x)
- **5**: Triggers match natural user phrasings. No jargon-only triggers.
- **4**: Most triggers are natural. One uses internal terminology.
- **3**: Triggers work but require knowing the skill name.
- **2**: Triggers are too generic (would false-match) or too specific.
- **1**: Triggers are missing or non-functional.

### 8. Reference Depth (weight: 1.0x)
- **5**: process.md covers edge cases, config options, and migration paths.
- **4**: process.md has good depth. Minor edge cases undocumented.
- **3**: process.md exists and is useful but shallow.
- **2**: process.md is mostly a repeat of SKILL.md.
- **1**: process.md is missing or a stub.

## Scoring Template

```yaml
# .ai/audits/skill-quality-<skill-name>.yml
skill: "<skill-name>"
audited_at: "2026-03-10T10:00:00Z"
auditor: "dev-engine/skill-quality-rubric"

scores:
  accuracy: { score: 4, weight: 1.5, justification: "..." }
  completeness: { score: 3, weight: 1.0, justification: "..." }
  code_quality: { score: 5, weight: 1.5, justification: "..." }
  anti_patterns: { score: 4, weight: 1.0, justification: "..." }
  up_to_dateness: { score: 3, weight: 1.0, justification: "..." }
  progressive_disclosure: { score: 5, weight: 1.0, justification: "..." }
  trigger_discoverability: { score: 4, weight: 0.5, justification: "..." }
  reference_depth: { score: 4, weight: 1.0, justification: "..." }

aggregate:
  weighted_sum: 34.0
  max_possible: 42.5
  percentage: 80.0
  verdict: "PASS"

remediations:
  - dimension: "completeness"
    issue: "Missing coverage of ISR patterns"
    action: "Add ISR section to process.md with revalidate examples"
  - dimension: "up_to_dateness"
    issue: "Still references getServerSideProps (Pages Router)"
    action: "Update to App Router server component patterns"
```

## Aggregation Method

1. Multiply each dimension score by its weight
2. Sum weighted scores → `weighted_sum`
3. Calculate max: sum of (5 x weight) for all dimensions → `max_possible` (42.5)
4. Percentage: `(weighted_sum / max_possible) x 100`
5. Verdict:
   - >=80%: **PASS**
   - 60-79%: **NEEDS_IMPROVEMENT**
   - <60%: **FAIL**

## Reporting

Output the YAML audit file to `.ai/audits/skill-quality-<skill-name>.yml`. Include:
- All 8 dimension scores with justifications (mandatory)
- Aggregate score and verdict
- Remediation notes for every dimension scored below 3
- Recommendations section for dimensions scored 3 (optional improvements)
