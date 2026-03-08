# Decision Reader — Detailed Process

## Step 1: Scan All Decisions

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

## Step 2: Filter by Relevance (if domains specified)

```
if no domains specified:
  relevant = all_decisions
else:
  # Expand domains using domain map
  domain_map = {
    "dev": ["dev", "security", "strategy"],
    "design": ["design", "brand", "content"],
    "content": ["content", "brand", "design"],
    "brand": ["brand", "design"],
    "devops": ["devops", "dev", "security"]
  }

  expanded_domains = set()
  for d in requested_domains:
    expanded_domains.update(domain_map.get(d, [d]))

  relevant = []
  for d in all_decisions:
    if any(domain in expanded_domains for domain in d.domain):
      relevant.append(d)

Report: "Found {len(relevant)} relevant decisions (out of {len(all_decisions)} total)"
```

## Step 3: Sort

```
# Sort: high confidence first, then by date (most recent first)
relevant.sort(key=lambda d: (
  {"high": 0, "medium": 1, "low": 2}.get(d.confidence, 3),
), reverse=False)

# Stable sort — within same confidence, recent first
relevant.sort(key=lambda d: d.session_date, reverse=True)
relevant.sort(key=lambda d: {"high": 0, "medium": 1, "low": 2}.get(d.confidence, 3))
```

## Step 4: Output

### If output_path is specified — write markdown:

```markdown
## Past Decisions

**Scanned:** {total_count} decisions across {topic_count} topics
**Relevant:** {relevant_count} decisions

### High Confidence

| ID | Decision | Domain | Source Topic | Date |
|----|----------|--------|-------------|------|
| {id} | {decision} | {domain} | {topic} | {date} |

### Medium Confidence

| ID | Decision | Domain | Source Topic | Date |
|----|----------|--------|-------------|------|

### Low Confidence

| ID | Decision | Domain | Source Topic | Date |
|----|----------|--------|-------------|------|
```

### If no output_path — return to caller inline:

Present the decisions as a structured list the calling skill can use directly.
Include id, decision text, domain, confidence, source topic, and date for each.

If no relevant decisions found:
```markdown
## Past Decisions

No relevant decisions found.
Scanned {total_count} decisions across {topic_count} topics.
```

## Step 5: Checkpoint Verification

```
# Check 1: decisions_loaded
assert topic_count >= 1  # at least 1 decisions.yml was scanned
# If .ai/brainstorm/ is empty, warn but pass (no decisions to load is valid)

# Check 2: relevance_filtered
assert filter was applied (or all returned if no domains specified)

# Check 3: output_delivered
if output_path: assert file exists and contains "## Past Decisions"
if inline: assert decisions were returned to caller
```

## Error Handling

| Error | Action |
|-------|--------|
| .ai/brainstorm/ doesn't exist | Warn "No brainstorm data found", return empty |
| decisions.yml parse error | Skip that file, warn, continue |
| output_path parent doesn't exist | Create parent directory |
| No relevant decisions | Return/write "No relevant decisions" (not an error) |
