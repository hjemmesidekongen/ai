# Agent Reviewer — Full Reference

## Review philosophy

Reviewers are read-only. Never modify the files under review. Produce a YAML verdict
documenting findings and recommendations. The agent-reviewer skill evaluates agent
definition files (`.md` files in `agents/` directories) for structural validity and
quality across 5 core dimensions.

## Source material

This methodology combines:
- `validate-agent.sh` from claude-code-templates (structural checks)
- `validate-agents.js` from everything-claude-code (batch frontmatter validation)
- The existing `agent-reviewer` agent's 5-dimension framework (D1–D5)
- The `skill-reviewer` skill's 8-step methodology (adapted for agents)

## 8-Step review methodology

### Step 1: Location

Verify the agent lives in the correct place:
- Path follows `plugins/<plugin>/agents/<agent-name>.md`
- Filename is kebab-case
- Filename matches the `name` field in frontmatter
- File extension is `.md`

### Step 2: Frontmatter validity (D1)

All fields must be present and valid:

| Field | Required | Validation |
|-------|----------|-----------|
| `name` | Yes | Kebab-case, 3–50 chars, no generic names (helper, assistant, tool, agent) |
| `description` | Yes | 50–5000 chars, contains `<example>` block(s) |
| `model` | Yes | One of: `inherit`, `haiku`, `sonnet`, `opus` |
| `tools` | Yes | Array present (even if empty); no unknown tool names |
| `color` | No | If present: blue, cyan, green, yellow, magenta, or red |
| `capabilities` | No | Array of strings describing what the agent can do |
| `model_tier` | No | If present: junior, senior, or principal |

Flag missing required fields as CRITICAL. Invalid values as WARNING.

### Step 3: Description quality (D2)

Evaluate the frontmatter `description` field:
- Contains "Use this agent when..." or equivalent trigger pattern
- Has at least one `<example>` block with `<user>` + `<assistant>` tags
- Describes WHAT the agent does, WHEN to use it, and key trigger keywords
- Not vague ("helps with various tasks", "general purpose")
- Under 200 words for the trigger portion (before examples)
- Distinguishes from other agents (no overlap with siblings)

### Step 4: System prompt quality (D3)

The system prompt is everything after the closing `---`:
- Opens with "You are..." in second person
- States the agent's role clearly in first paragraph
- Documents responsibilities, scope, or process
- Specifies output format or deliverable
- Does not use first person "I will..." (agents receive instructions, not self-describe)
- Has sufficient length (minimum 100 characters for meaningful guidance)
- Contains structural elements (headings, lists, tables) for complex agents

### Step 5: Tool scope appropriateness (D4)

Verify tool list follows least-privilege principle:

| Agent type | Permitted tools | Flag if present |
|-----------|----------------|-----------------|
| Read-only (auditors, reviewers, validators) | Read, Grep, Glob | Bash, Write, Edit |
| Writers (creators, fixers) | Read, Grep, Glob, Write, Edit | — |
| Execution agents (TDD, deployment) | All including Bash | — |

Checks:
- Empty tools array `[]` is over-permissive — flag as WARNING (wildcard access)
- Declared tools match the agent's stated capabilities
- Read-only agents must not have Write, Edit, or Bash
- Bash only permitted when the agent's purpose requires shell execution

### Step 6: Model tier justification (D5)

| Tier | Appropriate for |
|------|----------------|
| `haiku` | Pattern matching, simple lookups, data extraction |
| `sonnet` | Multi-file reasoning, balanced quality/cost tasks |
| `opus` | Architecture decisions, complex multi-step reasoning, security review |
| `inherit` | User-controlled — acceptable for general-purpose agents |

Flag:
- Review/audit agents using `haiku` as WARNING (insufficient for quality judgment)
- `inherit` on agents that need deterministic model tier as INFO
- `opus` on simple lookup agents as INFO (overqualified)

### Step 7: Issue identification

Classify all findings by severity:

| Severity | Meaning | Examples |
|----------|---------|---------|
| **critical** | Blocks usability | Missing `model` or `tools` field, empty system prompt, invalid model value, name mismatch |
| **warning** | Quality issue, should fix | Vague description, no `<example>` block, Bash on read-only agent, missing output format |
| **info** | Improvement opportunity | Better trigger keywords, model tier adjustment, add capabilities field |

### Step 8: Recommendations

Generate actionable recommendations:
- Each recommendation maps to a specific finding
- Recommendations include the specific field or section to change
- Prioritized by severity (critical first)
- Estimate effort: trivial (1-2 edits), moderate (section rewrite), significant (restructure)
- Use before/after format for concrete improvements

#### Before/after format

```yaml
finding: "Description lacks triggering examples"
file: "agent-name.md"
section: "frontmatter.description"
before: |
  description: >
    Reviews code for security vulnerabilities and best practices.
after: |
  description: >
    Reviews code for security vulnerabilities, OWASP top 10, and dependency
    risks. Use when reviewing code before merge, auditing for security issues,
    or checking dependencies for known CVEs.

    <example>
    <user>Review this PR for security issues</user>
    <assistant>Reading changed files... security_review: { verdict: PASS, ... }</assistant>
    </example>
effort: moderate
```

#### Positive findings

Include a `strengths` section noting what the agent does well:

```yaml
strengths:
  - "System prompt clearly defines the 5-dimension review framework"
  - "Tool scope is appropriately restricted to read-only"
  - "Description has 2 concrete triggering examples"
```

## Stage 1: Spec Compliance

Mechanical checks. All must pass before Stage 2.

### Check 1: File format

- File starts with `---` (YAML frontmatter delimiter)
- Second `---` exists (frontmatter properly closed)
- Content exists after closing `---` (system prompt present)

### Check 2: Required frontmatter fields

All fields must be present and non-empty:

| Field | Type check |
|-------|-----------|
| `name` | String, kebab-case, 3-50 chars |
| `description` | String, 50+ chars |
| `model` | One of: inherit, haiku, sonnet, opus |
| `tools` | Array (may be empty) |

### Check 3: Name consistency

The `name` field in frontmatter must match:
- The agent's filename (without `.md` extension)
- The entry in `ecosystem.json` agents array

### Check 4: Description has examples

The `description` field must contain at least one `<example>` block with:
- `<user>` tag showing triggering input
- `<assistant>` tag showing expected response pattern

### Check 5: Ecosystem registration

Agent name must appear in the plugin's `ecosystem.json` `agents` array.

### Stage 1 output

```yaml
spec_compliance:
  status: pass | fail
  checks:
    file_format: { status: pass|fail, detail: "" }
    required_fields: { status: pass|fail, missing: [] }
    name_consistency: { status: pass|fail, detail: "" }
    description_examples: { status: pass|fail, example_count: 0 }
    ecosystem_registration: { status: pass|fail, detail: "" }
  failed_count: 0
```

## Stage 2: Quality Review

Judgment-based evaluation. Only runs after Stage 1 passes.

### Description trigger quality

- Are trigger phrases specific enough to activate correctly?
- Could the description cause false activation on unrelated topics?
- Do examples cover the agent's core use cases?
- Is the description distinct from similar agents?

### System prompt effectiveness

- Does the prompt give the agent clear boundaries?
- Is the output format specified precisely enough to be consistent?
- Does the prompt avoid unnecessary preamble?
- Are edge cases or constraints documented?

### Tool scope alignment

- Do the restricted tools match what the system prompt asks the agent to do?
- Could the agent complete its task with fewer tools?
- Are there tools missing that the agent's process requires?

### Model tier match

- Does the agent's complexity justify its model tier?
- Would a different tier produce equivalent results at lower cost?
- Is the tier consistent with similar agents in the plugin?

### Checkpoint coverage (if applicable)

- Does the agent's described process include verification steps?
- Is the output format structured enough for downstream consumption?

## Verdict format

```yaml
agent_review:
  agent: "<agent-name>"
  plugin: "<plugin-name>"
  path: "<file-path>"
  reviewed_at: "<timestamp>"
  status: pass | pass_with_notes | fail
  spec_compliance:
    status: pass | fail
    checks: { ... }
    failed_count: 0
  quality_review:
    status: pass | pass_with_notes | fail
    findings: []
    summary: ""
  strengths:
    - "Specific observable quality that the agent does well"
  recommendations:
    - severity: critical | warning | info
      area: "frontmatter | description | system_prompt | tool_scope | model_tier"
      detail: ""
      file: ""
      effort: trivial | moderate | significant
```

## Common findings

| Finding | Severity | Category | Fix |
|---------|----------|----------|-----|
| Missing required frontmatter field | critical | spec | Add the field per agent-creator spec |
| Empty system prompt | critical | spec | Write role, process, and output format |
| Name doesn't match filename | critical | spec | Rename to match |
| Missing `<example>` blocks in description | warning | quality | Add 1-2 triggering examples |
| No "Use when" trigger pattern | warning | quality | Add trigger scenarios to description |
| Bash tools on a read-only agent | warning | scope | Remove Bash from tools list |
| Empty tools array (wildcard) | warning | scope | Specify required tools explicitly |
| System prompt uses first person | warning | style | Rewrite to second person ("You are...") |
| No output format in system prompt | warning | quality | Define deliverable structure |
| Not registered in ecosystem.json | warning | spec | Add to agents array |
| Model tier mismatch | info | quality | Adjust tier to match complexity |
| Missing capabilities field | info | completeness | Add capabilities array |
| Missing color field | info | cosmetic | Add color for visual distinction |
| Description over 200 words (pre-examples) | info | efficiency | Tighten trigger portion |

## Review checklist

Quick-reference for manual reviews:

- [ ] File starts and ends with proper `---` delimiters
- [ ] All required frontmatter fields present (name, description, model, tools)
- [ ] `name` matches filename (without .md)
- [ ] `description` has concrete trigger phrases
- [ ] `description` contains at least one `<example>` block
- [ ] System prompt opens with "You are..."
- [ ] System prompt defines output format
- [ ] System prompt does not use first person
- [ ] Tool list follows least-privilege principle
- [ ] `model` tier matches agent complexity
- [ ] Registered in ecosystem.json agents array
- [ ] No overlap with existing agent descriptions
- [ ] Agent purpose is distinct from commands (multi-step, autonomous)
