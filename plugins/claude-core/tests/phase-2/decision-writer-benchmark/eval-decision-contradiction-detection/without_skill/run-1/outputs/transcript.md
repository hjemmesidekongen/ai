# Execution Transcript

## Prompt

An existing decisions.yml contains:
  D-001: 'Use PostgreSQL for all persistent storage' (confidence: high, domain: [technical])

A new brainstorm transcript concludes with:
  User: 'For the event log, we should use MongoDB since it's better for append-heavy workloads.'

How would you handle this when extracting decisions?...

## Response

Flag the conflict before writing anything.

D-001 says **"all persistent storage"** — that's an explicit universal scope. The new conclusion carves out an exception. These contradict each other, and silently writing both creates a decisions file that argues with itself.

**What I'd do in the /brainstorm:decide flow:**

1. **Surface the conflict to you** — "D-001 mandates PostgreSQL for *all* persistent storage. This new conclusion wants MongoDB for the event log. That's a scope conflict — which do you want?"

2. **Let you pick one of three resolutions:**
   - **Narrow D-001**: Change it to "Use PostgreSQL for all persistent storage *except event logging*" and add a new D-024 for MongoDB on the event log with the append-heavy rationale.
   - **Override D-001 entirely**: If the thinking has evolved, replace D-001 with a more nuanced storage policy.
   - **Reject the new conclusion**: Keep D-001 as-is if on reflection the MongoDB idea doesn't hold up (maybe PostgreSQL with partitioned append-only tables is good enough).

3. **After you decide**, I'd write both the new/updated decision *and* amend D-001 in the same pass, with cross-references. Something like:

```yaml
D-001:
  decision: "Use PostgreSQL for all persistent storage except event logging"
  confidence: high
  domain: [technical]
  amended_by: D-024
  context: "Original scope was universal; narrowed after event log analysis"

D-024:
  decision: "Use MongoDB for the event log (append-heavy workload)"
  confidence: high
  domain: [technical]
  supersedes_partial: D-001
  context: "Event log is append-heavy with no relational joins — MongoDB fits the access pattern better"
```

**The principle**: decisions.yml is a source of truth. Contradictions in it are worse than having fewer decisions. I'd never quietly write a decision that conflicts with an existing one — that just defers the confusion to whoever reads it next.

## Stderr

None
