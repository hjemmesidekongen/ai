# Blog Post Strategy — Pimp Your Claude Code

## Research Date: 2026-03-14

---

## Decision: One Post (revised from initial two-post recommendation)

Split into two posts for optimal reader experience and SEO coverage.

### Post 1: "Make It Yours" — Cosmetic & Personality

**Focus:** Quick wins, visual impact, personality. High shareability, low barrier.

**Topics (in order):**
1. Themes — one command, instant visual change (30 sec)
2. Spinner Verbs — custom loading messages (30 sec)
3. Status Line — context %, cost, git info at bottom of terminal (2 min)
4. Sound Notifications — sounds on task completion (1 min)
5. Desktop Notifications — OS-level alerts (1 min)
6. Output Styles — change Claude's tone/format (2 min)
7. Keybindings & Vim Mode — muscle memory customization (2 min)

### Post 2: "Make It Work For You" — Workflow Automation

**Focus:** Power-user automation. Workflow-changing, not aesthetic.

**Topics:**
1. Custom Slash Commands — reusable prompt templates
2. Auto-Format Hooks — Prettier/ESLint after every edit
3. Auto-Commit with GitButler — Stop hooks + virtual branches
4. Prompt Hooks / LLM as Gatekeeper — Haiku-powered guardrails

---

## Title Candidates (ranked)

1. **"My Claude Code Setup: Status Bars, Custom Sounds, and Auto-Commits"** — personal angle, searches well for "claude code setup"
2. **"Pimp Your Claude Code: 11 Customizations You Didn't Know Existed"** — direct, curiosity gap
3. **"Claude Code Looks Boring Out of the Box. Here's How to Fix That."** — problem-first, provocative
4. **"Stop Using Vanilla Claude Code: A Customization Guide for Power Users"** — imperative, audience qualifier
5. **"The Claude Code Customization Guide Nobody Wrote Yet"** — positions against docs gap

**Split titles:**
- Post 1: "Pimp Your Claude Code: Status Bars, Custom Spinners, and Sounds"
- Post 2: "Pimp Your Claude Code, Part 2: Auto-Format, Auto-Commit, and LLM Gatekeepers"

---

## Section Subtitles

| Section | Subtitle |
|---------|----------|
| Themes | "Six options, zero of them great" |
| Spinner Verbs | "Issuing royal decree..." |
| Status Line | "Know everything without looking away" |
| Sound Notifications | "Your ears are a second monitor" |
| Desktop Notifications | "Because you alt-tabbed 40 minutes ago" |
| Output Styles | "Make Claude talk like you want it to" |
| Keybindings | "Your muscle memory, your rules" |
| Custom Slash Commands | "Your prompts, on speed dial" |
| Auto-Format Hooks | "Prettier runs so you don't have to" |
| Auto-Commit (GitButler) | "Every change, captured automatically" |
| Prompt Hooks | "Let Haiku be your bouncer" |

---

## Content Grouping (UX-driven)

Three groups, explicitly labeled in the post:

1. **Make It Yours** (themes, spinners, status line) — Visual personality. 5 min total.
2. **Stay in Flow** (sounds, notifications, output styles, keybindings) — Productivity and feedback loops.
3. **Automate Everything** (slash commands, auto-format, auto-commit, prompt hooks) — Workflow automation.

---

## Section Structure (consistent for every topic)

```
### [Topic Name]          ← H3
One-line description      ← What it does
[Config location badge]   ← e.g. "~/.claude/settings.json"
[Code block]              ← The config
[Screenshot/GIF/result]   ← Proof it works
[Pro tip or gotcha]       ← Optional callout
```

---

## Hook / Intro (Post 1)

> Claude Code ships with a dark terminal and a blinking cursor. No status bar, no context
> about how much of your window you've used, no sound when a 3-minute task finishes while
> you're making coffee. It works, but it doesn't feel like yours.
>
> I've been running Claude Code as my primary dev tool for months. Somewhere along the way,
> I stopped accepting the defaults and started making it mine — custom status line, sounds
> that tell me when work is done, spinner messages that make me laugh, keybindings that
> match my muscle memory.
>
> Here's everything I changed and how to set it up.

---

## Visual Strategy

| Section | Visual Type |
|---------|-------------|
| Themes | Side-by-side screenshots of 2-3 built-in themes |
| Spinner Verbs | GIF of custom messages cycling (3-5 sec loop) |
| Status Line | Annotated screenshot with arrows to each element |
| Sound Notifications | Code block + link to audio sample |
| Desktop Notifications | Screenshot of macOS notification |
| Output Styles | Before/after of same prompt with different styles |
| Keybindings | Syntax-highlighted JSON |
| Custom Slash Commands | Code block + terminal demo screenshot |
| Auto-Format Hooks | Before/after terminal output |
| Auto-Commit | GitButler screenshot with virtual branches |
| Prompt Hooks | Code block + simple flowchart |

---

## SEO Keywords

**Primary:**
- "claude code customization"
- "claude code setup"
- "claude code settings"

**Secondary:**
- "claude code status line"
- "claude code themes"
- "claude code hooks"
- "claude code keybindings"
- "claude code spinner"
- "claude code notifications"

---

## Unique Angle vs. Anthropic Docs

Anthropic wrote the manual. We write the setup guide.

1. **Curation** — which settings are actually worth it (ranked by impact)
2. **Real daily-driver setup** — how settings combine into a coherent workflow
3. **Community ecosystem** — claude_monitor_statusline, claude-sounds, GitButler (not in docs)
4. **Opinions** — "six themes, zero of them great"
5. **The why** — custom spinners make waits feel shorter (UX psychology)

---

## CTA

**Post 1:** "Try one. Just one. Change your spinner verbs, play a sound on completion, switch the theme. Once your terminal stops feeling generic, you won't go back."

**Post 2:** Share actual config as downloadable gist. "That's my actual config. Steal what works."

---

## Code Block UX Rules

- Trivial configs: inline code span, no fenced block
- 3-5 line configs: normal fenced block
- Complex configs: annotated with comments
- Use diff-style for modifications to existing files
- One combined "starter config" at the end of each post
- Every code block needs a copy button (blog platform feature)
