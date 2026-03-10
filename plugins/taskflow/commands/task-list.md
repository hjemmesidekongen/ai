---
name: task-list
description: "List locally stored tasks with status and contradiction count"
argument-hint: "[--status STATUS]"
---

# Task List

Displays all locally stored tasks in a table with status and contradiction counts.

## Steps

1. **Read task files** — glob all `.ai/tasks/*.yml` files, excluding `active.yml`.

2. **Extract fields** from each task file:
   - `key` — Jira ticket key
   - `summary` — one-line description
   - `status` — current local status (pending, in_progress, done, blocked)
   - `contradictions` — count of entries in `contradictions:` array (0 if none)

3. **Apply filter** — if `--status STATUS` is provided, only include tasks matching that status.

4. **Print table**:

```
KEY        | Summary                          | Status      | Contradictions
-----------+----------------------------------+-------------+---------------
PROJ-101   | Implement login flow             | in_progress | 2
PROJ-102   | Add password reset               | pending     | 0
PROJ-108   | Update API rate limits           | blocked     | 1
```

5. **Print totals** — `N tasks (X pending, Y in_progress, Z done, W blocked)`
