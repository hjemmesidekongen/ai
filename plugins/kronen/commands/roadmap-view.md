---
name: roadmap-view
description: Display the project roadmap with optional filters
user_invocable: true
arguments:
  - name: filter
    description: "Filter by priority (now/next/later/backlog), category, plugin, or tag"
    required: false
---

# /roadmap:view

Display items from `.ai/roadmap.yml` in a readable format.

## Steps

1. **Read** `.ai/roadmap.yml`
   - If missing: "No roadmap found. Use `/roadmap:add` to start one."

2. **Parse filters** from `$ARGUMENTS`:
   - `--priority now` or just `now` → filter by priority
   - `--category core` → filter by category
   - `--plugin kronen` → filter by plugin
   - `--tag phase-2` → filter by tag
   - No filter → show summary of all items grouped by priority

3. **Display:**

   **Summary mode** (no filter):
   ```
   Roadmap — {total} items

   now ({count})
     RL-001: Architecture doc — kronen contract [core]
     RL-002: Plugin scaffold — kronen [core]

   next ({count})
     RL-010: Roadmap auto-capture system [core]

   later ({count})
     ...

   backlog ({count})
     ...
   ```

   **Filtered mode:**
   Show matching items with id, title, category, plugin, and tags.

4. **Stats footer:**
   ```
   {now} active | {next} queued | {later} planned | {backlog} backlog
   ```
