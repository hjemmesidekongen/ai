# MCP Server Evaluation Guide

## Purpose

Evaluations test whether an LLM can effectively use your MCP server to answer realistic,
complex questions using only the tools your server provides. The measure of an MCP server's
quality is not how comprehensively it implements tools, but how well those tools — their
schemas, descriptions, and return values — enable an LLM with no other context to solve
real tasks.

Run evals after the server builds, tests pass, and tool schemas are stable.

---

## Question requirements

Create 10 questions. Each must satisfy all six criteria:

### 1. Independent
Each question stands alone. It must not depend on the answer to any other question,
and must not assume prior write operations.

### 2. Read-only
Questions must be answerable using only non-destructive, idempotent tool calls.
Never require the LLM to modify state to arrive at an answer.

### 3. Complex
Each question should require multiple tool calls — potentially dozens. Consider:
- Multi-hop questions: find X, then use X to find Y
- Aggregation: group results, calculate rates, compare across entities
- Pagination: answers may require scanning many pages of results
- Historical depth: querying data 1–2 years old to find niche information

Questions solvable with a single keyword search are too easy.

### 4. Realistic
Questions should reflect actual human use cases — the kinds of retrieval tasks
a person assisted by an LLM would genuinely care about.

Do not include the exact keywords from the target content. Use synonyms, related
concepts, or paraphrasing to prevent trivial keyword matches.

### 5. Verifiable
Each question has exactly one correct answer, known in advance, checkable by direct
string comparison. Specify the required format in the question when ambiguity exists:
- "Use YYYY/MM/DD format."
- "Respond True or False."
- "Answer A, B, C, or D only."

### 6. Stable
Base questions on historical or closed data — completed projects, merged PRs,
archived records. Do not ask about current counts (open issues, active members,
current reactions) because those change.

---

## Answer requirements

### Single value
One value only. Never a list, a complex object, or natural language text (unless
the answer is a verbatim string that can be reproduced exactly and compared directly).

### Human-readable preferred
Prefer names, dates, counts, and boolean values over opaque IDs. IDs are acceptable
when the question specifically asks for them.

### Diverse types
Across 10 questions, vary the answer types: usernames, dates, counts, booleans,
short strings, IDs. Do not make all 10 questions return the same type.

### String-comparable
The LLM must be able to reproduce the answer in the exact format you record.
If format ambiguity exists, specify it in the question.

---

## XML format

```xml
<evaluation>
  <qa_pair>
    <question>Find the project created in Q2 2024 with the highest number of completed
    tasks. What is the project name?</question>
    <answer>Website Redesign</answer>
  </qa_pair>
  <qa_pair>
    <question>Among bugs reported in January 2024 marked as critical priority, which
    assignee resolved the highest percentage within 48 hours? Provide their username.</question>
    <answer>alex_eng</answer>
  </qa_pair>
</evaluation>
```

Each `<qa_pair>` contains exactly one `<question>` and one `<answer>`.

---

## Creation process

### Step 1: Documentation inspection
Read API and server documentation to understand available endpoints, data types,
and relationships. Fetch additional information from the web if documentation is sparse.
Do not read the MCP server's implementation code at this stage.

### Step 2: Tool inspection
List all tools available on the server. For each tool, examine:
- Name and description
- Input schema (required vs. optional parameters)
- Expected output structure

Do not call tools yet — just inspect schemas.

### Step 3: Develop understanding
Iterate steps 1 and 2 until you understand what the server can retrieve and how.
Think about what kinds of questions would require multiple tools in sequence.

### Step 4: Read-only content exploration
Use the MCP server tools to inspect actual content. Constraints:
- Read-only, non-destructive calls only
- Use `limit` parameters — keep results small (< 10 per call)
- Paginate rather than fetching bulk data
- Goal: identify specific entities (users, projects, issues, channels) that can
  anchor realistic, stable questions

### Step 5: Draft and verify questions
Draft 10 questions following all requirements above. Then solve each question
yourself using the MCP server tools. Record the correct answer. Remove any question
that requires a write operation to answer, or whose answer you cannot verify.

---

## Verification

After drafting:

1. Parse the XML file — confirm structure is valid
2. For each `<qa_pair>`, attempt to answer the question yourself using only the tools
3. Replace any incorrect answers with the verified answers
4. Remove any pair that requires destructive operations
5. Remove any pair whose answer is ambiguous or unstable

Parallelize verification across questions where possible to manage context length.

---

## Good question examples

**Multi-hop with aggregation:**
```xml
<qa_pair>
  <question>Find the repository that was archived in Q3 2023 and had previously been
  the most forked project in the organization. What was the primary programming language
  used in that repository?</question>
  <answer>Python</answer>
</qa_pair>
```
Good because: requires finding archived repos, identifying the most-forked among them,
then inspecting the language — three distinct tool calls minimum, based on stable data.

**Context synthesis without keyword matching:**
```xml
<qa_pair>
  <question>Locate the initiative focused on improving customer onboarding that was
  completed in late 2023. The project lead created a retrospective after completion.
  What was the lead's role title at that time?</question>
  <answer>Product Manager</answer>
</qa_pair>
```
Good because: avoids exact project name, requires finding a completed project by
description, locating its lead, and looking up their role — stable historical data.

---

## Anti-patterns

| Pattern | Why it fails | Fix |
|---------|-------------|-----|
| "How many open issues are assigned to engineering?" | Answer changes constantly | Ask about a fixed time window: "How many issues were opened in January 2024?" |
| "Find the PR titled 'Add auth feature' and tell me who created it." | Trivial keyword search | Describe the PR by its effects, not its title |
| "List all repos using Python." | Answer is a list; order is ambiguous | Ask for a specific superlative: "Which Python repo has the most stars?" |
| Answer requires complex return structure | Cannot verify by string comparison | Redesign to return a single scalar value |
| Question about "current" state | Answer will drift over time | Anchor to a specific date range or closed event |

---

## Running evaluations

Use `scripts/evaluation.py` (in this skill's scripts directory). Requires:
- Python 3.10+
- `pip install anthropic mcp`
- `ANTHROPIC_API_KEY` set in environment

```bash
# stdio transport — script launches the server automatically
python scripts/evaluation.py \
  -t stdio -c python -a my_server.py \
  -e API_KEY=abc123 \
  evaluation.xml

# SSE transport — start server before running
python scripts/evaluation.py \
  -t sse -u https://example.com/mcp \
  -H "Authorization: Bearer token" \
  evaluation.xml

# Save report to file
python scripts/evaluation.py \
  -t stdio -c python -a my_server.py \
  -o report.md \
  evaluation.xml
```

### Report output

The script produces a markdown report with:
- Overall accuracy (correct / total)
- Average task duration and tool calls per task
- Per-task: question, expected answer, actual answer, pass/fail, tool call details
- Agent's summary of its approach for each task
- Agent's feedback on tool descriptions and schemas

Use the feedback section to identify which tool descriptions are unclear,
which parameter docs are missing, and where the server returns too much data.
