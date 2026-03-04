# Decision Reader — Detailed Process

## Step 1: Determine Context

```
project_name = read agency.yml → active
state = read_yaml(.ai/projects/{project_name}/state.yml)

current_module = state.current_module   # e.g., "dev", "design"
current_skill = state.current_skill     # e.g., "scaffold", "design-tokens"

# Build domain filter from current context
relevant_domains = [current_module]

# Add related domains based on module
domain_map = {
  "dev": ["dev", "security", "strategy"],
  "design": ["design", "brand", "content"],
  "content": ["content", "brand", "design"],
  "brand": ["brand", "design"],
  "devops": ["devops", "dev", "security"]
}
relevant_domains = domain_map.get(current_module, [current_module])

Report: "Context: module={current_module}, skill={current_skill}"
Report: "Filtering domains: {relevant_domains}"
```

## Step 2: Scan All Decisions

```
brainstorm_dir = .ai/brainstorm/
all_decisions = []

for topic_dir in brainstorm_dir/*/
  decisions_file = topic_dir/decisions.yml
  if not exists(decisions_file):
    continue

  decisions = read_yaml(decisions_file)
  if decisions is None or not isinstance(decisions, list):
    WARN: "Skipping malformed {decisions_file}"
    continue

  for d in decisions:
    d._source_topic = basename(topic_dir)
    all_decisions.append(d)

Report: "Scanned {len(all_decisions)} total decisions across {topic_count} topics"
```

## Step 3: Filter by Relevance

```
relevant = []
for d in all_decisions:
  # Domain match: any overlap between decision domains and relevant domains
  if any(domain in relevant_domains for domain in d.domain):
    d._relevance = "domain_match"
    relevant.append(d)

# Sort: high confidence first, then by date (most recent first)
relevant.sort(key=lambda d: (
  {"high": 0, "medium": 1, "low": 2}.get(d.confidence, 3),
  d.session_date  # reversed — recent first
), reverse=False)

# For date sort, reverse the secondary key
relevant.sort(key=lambda d: d.session_date, reverse=True)
relevant.sort(key=lambda d: {"high": 0, "medium": 1, "low": 2}.get(d.confidence, 3))

Report: "Found {len(relevant)} relevant decisions (out of {len(all_decisions)} total)"
```

## Step 4: Write Summary to Findings

Write to `.ai/projects/{project_name}/dev/findings.md`:

```markdown
## Past Decisions

**Context:** {current_module}/{current_skill}
**Scanned:** {total_count} decisions across {topic_count} topics
**Relevant:** {relevant_count} decisions matching domains: {relevant_domains}

### High Confidence

| ID | Decision | Domain | Source Topic | Date |
|----|----------|--------|-------------|------|
| {id} | {decision} | {domain} | {topic} | {date} |

### Medium Confidence

| ID | Decision | Domain | Source Topic | Date |
|----|----------|--------|-------------|------|
| {id} | {decision} | {domain} | {topic} | {date} |

### Low Confidence

| ID | Decision | Domain | Source Topic | Date |
|----|----------|--------|-------------|------|
| {id} | {decision} | {domain} | {topic} | {date} |

---
*Loaded by decision-reader at {timestamp}*
```

If no relevant decisions found, write:

```markdown
## Past Decisions

No relevant decisions found for {current_module}/{current_skill}.
Scanned {total_count} decisions across {topic_count} topics — none matched domains: {relevant_domains}.
```

## Step 5: Checkpoint Verification

```
# Check 1: decisions_loaded
assert topic_count >= 1  # at least 1 decisions.yml was scanned
# If .ai/brainstorm/ is empty, warn but pass (no decisions to load is valid)

# Check 2: relevance_filtered
assert filter was applied using relevant_domains
# 0 relevant decisions is a valid outcome — the filter ran

# Check 3: summary_written
findings = read(.ai/projects/{project_name}/dev/findings.md)
assert "## Past Decisions" in findings
```

## Error Handling

| Error | Action |
|-------|--------|
| .ai/brainstorm/ doesn't exist | Warn "No brainstorm data found", write empty section |
| state.yml missing current_module | Use all domains (no filter) |
| decisions.yml parse error | Skip that file, warn, continue |
| findings.md doesn't exist | Create it with just the decisions section |
| No relevant decisions | Write "No relevant decisions" message (not an error) |

Log all errors to `state.yml` errors array. Before retrying, check errors array for previous attempts — never repeat a failed approach.

---

## Trace Protocol

If `state.yml` has `trace.enabled: true`, follow the
[trace protocol](../../../../resources/trace-protocol.md) to write a structured
trace file to `.ai/projects/[name]/traces/`.
