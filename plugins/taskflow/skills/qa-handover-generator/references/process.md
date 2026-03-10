# qa-handover-generator — Process Reference

## 1. Input Collection

### Task file
Read `.ai/tasks/<KEY>.yml` to extract:
- `summary` — what the ticket is about
- `acceptance_criteria` — the measurable requirements
- `contradictions` — any detected conflicts (important for QA awareness)
- `description` — full ticket description for context

### Project profile
Load via project-profile-loader:
- `qa.format` — output format
- `qa.require_screenshots` — whether to include screenshot section
- `qa.checklist_template` — custom QA checklist if defined

### Git diff
Run `git diff main...HEAD --stat` and `git diff main...HEAD` to get:
- List of changed files with line counts
- Actual code changes for functional impact analysis

If no git diff is available (no commits yet), use the task description and
acceptance criteria as the sole source for test scenarios.

---

## 2. Section Generation

### Summary
2-3 sentences covering:
- What was implemented (derived from task summary + git diff)
- Key decisions made during implementation (especially resolved contradictions)
- Scope notes (what was intentionally excluded)

### Changes
For each changed file, describe the functional impact:

```markdown
### Changed files
- `src/components/SearchBar.tsx` — New autocomplete search component with debounced input
- `src/api/users.ts` — Added search endpoint with name, email, and username fields
- `src/hooks/useRecentUsers.ts` — Hook for recently viewed users (empty search state)
- `tests/SearchBar.test.tsx` — Unit tests for search behavior and edge cases
```

Group by feature area when there are many files. Don't list config or lock files
unless they represent meaningful changes.

### Test scenarios
Map each acceptance criterion to a testable scenario:

```markdown
### Test scenarios
1. **Search by name** — Type "Sarah" in search bar → results show users with "Sarah" in first or last name
2. **Case insensitive** — Type "SARAH" → same results as "sarah"
3. **Empty search** — Clear search field → shows 5 recently viewed users (updated from original AC per standup decision)
4. **Autocomplete trigger** — Type 1 character → no dropdown. Type 2 characters → dropdown appears
5. **Result display** — Each result shows avatar, full name, and department
6. **Result click** — Click a result → navigates to /users/{id}
7. **Overflow** — Search returning 15+ results → "View all X results" link at bottom
```

If contradictions were resolved, note the resolution in the relevant scenario.

### Regression risks
Identify areas that could break:

```markdown
### Regression risks
- **Navigation bar layout** — new search component added to nav; verify it doesn't push other elements on narrow screens
- **User API performance** — new search endpoint hits the users table; verify query performance with large datasets
- **Recently viewed storage** — uses localStorage; verify behavior when storage is full or disabled
```

Focus on:
- Components that share state or layout with changed code
- API endpoints that changed signature or behavior
- Database queries that changed
- Shared utilities that were modified

### Screenshots
Only included when `qa.require_screenshots: true` AND changed files include
UI components (`.tsx`, `.jsx`, `.vue`, `.svelte`, `.html`, `.css`).

```markdown
### Screenshots
> Screenshots required per project profile. Attach before submitting.
- [ ] Search bar in default state (empty)
- [ ] Search bar with autocomplete results
- [ ] Empty search showing recently viewed users
- [ ] "View all" overflow link
- [ ] Mobile/responsive view
```

When screenshots are not required or no UI files changed, omit this section entirely.

---

## 3. Output Formats

### jira-comment
Uses Jira wiki markup:

```
{panel:title=QA Handover: PROJ-456}
h3. Summary
Implemented user search with autocomplete in the top navigation bar...

h3. Changes
||File||Impact||
|SearchBar.tsx|New autocomplete component with debounced input|
|users.ts|Search endpoint with name, email, username fields|

h3. Test Scenarios
# Search by name — type "Sarah" → matching results appear
# Case insensitive — type "SARAH" → same results
# Empty search — clear field → shows recently viewed users

h3. Regression Risks
* Navigation bar layout on narrow screens
* User API query performance with large datasets

h3. Resolved Contradictions
* Empty search behavior changed from "no results" to "recently viewed users" per standup
{panel}
```

### github-pr
Uses GitHub-flavored markdown with task lists:

```markdown
## QA Handover: PROJ-456

### Summary
Implemented user search with autocomplete...

### Changes
| File | Impact |
|------|--------|
| SearchBar.tsx | New autocomplete component |

### Test Scenarios
- [ ] Search by name — type "Sarah" → matching results
- [ ] Case insensitive — "SARAH" returns same results
- [ ] Empty search — shows recently viewed users

### Regression Risks
- Navigation bar layout on narrow screens
- User API query performance

### Resolved Contradictions
- Empty search: changed to show recently viewed users (standup decision)
```

### markdown (default)
Plain markdown without platform-specific syntax. Same structure as github-pr
but uses `- ` bullets instead of `- [ ] ` checkboxes for test scenarios.

---

## 4. Custom Checklist Template

When `qa.checklist_template` is defined in the project profile, append it
after the test scenarios section:

```markdown
### QA Checklist
- [ ] Functional testing
- [ ] Edge cases
- [ ] Regression check
- [ ] Accessibility
- [ ] Performance
```

If not defined, omit this section.

---

## 5. Contradiction Awareness

When the task file contains contradictions, add a "Resolved Contradictions"
section to the handover. This alerts QA to requirements that changed during
development:

```markdown
### Resolved Contradictions
| Original | Updated | Resolution |
|----------|---------|------------|
| Empty search shows no results | Show recently viewed users (max 5) | Per standup decision — AC updated |
| Search by name and email only | Also search by username | Extended scope, approved by PM |
```

If `contradictions` array is empty, omit this section.

---

## 6. File Output

Write the formatted handover to `.ai/tasks/<KEY>-handover.md`.

If the file already exists, overwrite it (regeneration is expected when
changes are made after initial handover).

---

## 7. Error Handling

| Error | Action |
|-------|--------|
| Task file not found | Abort with error — cannot generate handover without task context |
| No git diff available | Generate from task description only, note "no code diff available" |
| Profile not found | Use markdown format with default settings |
| No acceptance criteria | Generate test scenarios from description; warn "AC missing" |
| Screenshot required but no UI files changed | Skip screenshot section, note in summary |

---

## 8. Example: Full Handover (GitHub PR format)

Task: `PROJ-456` — Implement user search with autocomplete

```markdown
## QA Handover: PROJ-456

### Summary
Implemented user search with autocomplete in the top navigation bar. Search
supports name, email, and username (added per comment request). Empty search
shows recently viewed users instead of blank state (updated per standup decision).

### Changes
| File | Impact |
|------|--------|
| `src/components/SearchBar.tsx` | New autocomplete component with 300ms debounce |
| `src/components/SearchResult.tsx` | Result item with avatar, name, department |
| `src/api/users.ts` | Search endpoint — name, email, username fields |
| `src/hooks/useRecentUsers.ts` | Recently viewed users hook (localStorage) |
| `src/hooks/useSearch.ts` | Debounced search hook with abort controller |
| `tests/SearchBar.test.tsx` | 12 unit tests covering all AC |

### Test Scenarios
- [ ] Type "Sarah" → results show matching users by name
- [ ] Type "SARAH" → same results as lowercase (case insensitive)
- [ ] Type "sarah@" → matches by email
- [ ] Type "schen" → matches by username
- [ ] Clear search field → shows 5 recently viewed users
- [ ] Type 1 char → no dropdown; type 2 chars → dropdown appears
- [ ] Each result shows avatar, full name, department
- [ ] Click result → navigates to user profile page
- [ ] Search returning 15+ results → "View all X results" link visible
- [ ] Click "View all" → navigates to full search results page

### Regression Risks
- Navigation bar layout may shift on screens < 768px
- Search API response time with 10k+ users in database
- localStorage quota when recently viewed list grows unbounded

### Resolved Contradictions
| Original | Updated | Resolution |
|----------|---------|------------|
| Empty search shows no results | Show recently viewed users (max 5) | Standup decision, AC updated |
| Search by name and email | Also search by username | Scope extension, approved |
```

Output: `QA handover generated: .ai/tasks/PROJ-456-handover.md (github-pr)`
