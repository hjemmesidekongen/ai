# instinct-evolve: Process Reference

## Evolution target selection

### Decision tree

```
Is the instinct about a fixed fact (path, count, version)?
  → MEMORY.md entry

Is it a behavioral rule that should always apply across all sessions?
  → CLAUDE.md rule

Does it describe a multi-step repeatable workflow?
  → New skill (use skill-creator)

Is it a user-invocable workflow the user would explicitly trigger?
  → New command (use command-creator)

Is it too context-specific or not generalizable?
  → Discard (do not evolve; mark confidence cap at 0.8 to prevent re-qualifying)
```

### Target-specific guidance

#### MEMORY.md entries

Format: one bullet per instinct, in the most relevant section.
Example: `- **debug-grep-read-bash**: Grep → Read → Bash sequence resolves most debug loops without retries.`

Do NOT evolve to MEMORY.md if a more durable artifact (skill, CLAUDE.md rule) is appropriate.
MEMORY.md is for facts; CLAUDE.md is for behaviors.

#### CLAUDE.md rules

Write in imperative mood. Target the appropriate section (Technical defaults, Verification, etc.).
Example: `- When debugging, use Grep → Read → Bash in sequence before escalating to Bash-only exploration.`

Run `doc-checkpoint` after adding rules to verify placement is correct.

#### New skill

Invoke `skill-creator` with the instinct's `pattern_description` as the core behavior.
The instinct's `domain` maps to a plugin (debug → kronen, plan → kronen, etc.).
Follow TDD baseline: write eval first, then build skill to pass it.

#### New command

Note in `.ai/roadmap.yml` for command-creator invocation. Commands need user-invocable triggers
that don't map well to a skill's automatic triggering.

## Draft artifact templates

### MEMORY.md entry
```markdown
- **{id}**: {pattern_description}
```

### CLAUDE.md rule (one line, imperative)
```markdown
- {imperative restatement of pattern_description}.
```

### Skill skeleton prompt for skill-creator
```
Create a skill named '{domain}-{slug}' that implements the following pattern:
'{pattern_description}'
Evidence: {evidence_count} observations, confidence {confidence}.
Domain: {domain}. Model tier: junior.
```

## Presentation format (step 3)

For each qualifying instinct:

```
---
Instinct: {id}
Pattern: {pattern_description}
Confidence: {confidence} | Evidence: {evidence_count} | Domain: {domain}

Proposed evolution → {target}
Draft:
  {draft artifact text}

[approve / reject / modify / discard]
```

## Post-promotion update

After user approves, update the instinct entry:

```yaml
status: evolved
evolved_to: "MEMORY.md" | "CLAUDE.md" | "skills/{name}" | "commands/{name}"
```

Leave all other fields unchanged — the historical record is valuable.

## Cycle recommendation

Run instinct-extractor + instinct-evolve as a pair:
1. After every 5–10 sessions (or when observations.jsonl exceeds 200 lines)
2. Before starting a new major feature or plugin
3. At the end of a large multi-week effort to capture learned patterns
