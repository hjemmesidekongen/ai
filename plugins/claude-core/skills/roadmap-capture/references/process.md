# roadmap-capture — Process

## Capture workflow

1. **Detect the idea** — recognize when a conversation surfaces something out-of-scope
2. **Check for duplicates** — read `.ai/roadmap.yml`, search for similar items by title keywords
3. **If duplicate found** — mention it to the user ("Already tracked as RL-042") and skip
4. **Generate the item:**
   - `id`: next sequential RL-NNN (scan existing items for highest number)
   - `title`: concise, action-oriented (e.g. "Add dark mode support")
   - `description`: 1-2 sentences explaining what and why
   - `category`: infer from context (core, toolkit, development, marketing, devops, design, ux, infrastructure)
   - `plugin`: which plugin this belongs to (claude-core, claude-toolkit, development, etc.)
   - `priority`: default to `backlog` unless user specifies urgency
   - `source`: where the idea came from (e.g. "conversation", "brainstorm/{topic}", "plan/{name}")
   - `added`: today's date (YYYY-MM-DD)
   - `tags`: relevant keywords for filtering (2-5 tags)
5. **Confirm with user** — briefly state what's being captured: "Capturing 'Add dark mode support' → roadmap (backlog)"
6. **Append to roadmap.yml** — add the item under the appropriate phase section

## Priority levels

| Priority | Meaning |
|----------|---------|
| now | Actively being built |
| next | Queued for after current work |
| later | Planned but not urgent |
| backlog | Good idea, no timeline |

## Category guidance

- `core` — foundation functionality (tracing, memory, planning, brainstorm)
- `toolkit` — builder tools (skill/plugin/command creation, testing)
- `development` — dev workflow (code gen, review, CI/CD)
- `marketing` — brand, SEO, content, analytics
- `devops` — deployment, monitoring, infrastructure
- `design` — UI/UX, design systems, component libraries
- `ux` — user experience improvements to Claude Code itself
- `infrastructure` — cross-cutting technical improvements

## Duplicate detection

Simple keyword matching:
1. Extract significant words from the new title (drop articles, prepositions)
2. For each existing item, count matching significant words in title + description
3. If match score >= 60% of new title words → flag as potential duplicate
4. Present to user: "This looks similar to RL-042: '{title}'. Add anyway or skip?"

## Edge cases

- **Empty roadmap**: create the file with the standard header from the roadmap template
- **User says "track this"**: explicit request — always capture, don't second-guess
- **Vague idea**: if the user hasn't landed on something concrete, ask "Want me to capture this to the roadmap, or is this still in the thinking stage?"
