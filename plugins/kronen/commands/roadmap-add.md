---
name: roadmap-add
description: Add an item to the project roadmap interactively
user_invocable: true
arguments:
  - name: title
    description: "Title for the roadmap item (optional — will prompt if missing)"
    required: false
---

# /roadmap:add

Add a new item to `.ai/roadmap.yml` with guided input.

## Steps

1. **Read the current roadmap** at `.ai/roadmap.yml`
   - If it doesn't exist, create it with the standard header

2. **Get the item details:**
   - If `$ARGUMENTS` contains a title, use it
   - Otherwise, ask: "What do you want to track?"

3. **Prompt for classification** (offer sensible defaults based on the title):
   - **Priority**: now / next / later / backlog (default: backlog)
   - **Category**: core / toolkit / development / marketing / devops / design / ux / infrastructure
   - **Plugin**: which plugin this belongs to (default: infer from category)
   - **Tags**: suggest 2-3 relevant tags, let user confirm or adjust

4. **Check for duplicates** using keyword matching against existing items
   - If potential duplicate found, ask: "Similar to RL-{N}: '{title}'. Add anyway?"

5. **Generate the item:**
   - `id`: next sequential RL-NNN
   - `title`: from user input
   - `description`: ask for a 1-2 sentence description
   - `source`: "manual"
   - `added`: today's date

6. **Append to roadmap.yml** under the appropriate phase section

7. **Confirm**: "Added RL-{N}: '{title}' to roadmap ({priority})"
