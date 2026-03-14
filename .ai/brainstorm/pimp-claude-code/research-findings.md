# Pimp Your Claude Code — Research Findings

## Research Date: 2026-03-14

---

## 1. Status Line

The biggest customization surface. A shell script runs after every Claude response, displaying live info at the bottom of the terminal. Claude pipes JSON session data to stdin.

**Config:**
```json
// ~/.claude/settings.json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 2
  }
}
```

**Alternative:** Type `/statusline` and describe what you want in natural language — Claude generates the script.

**Available JSON fields:**
| Field | What it gives you |
|---|---|
| `model.display_name` | Short model name |
| `model.id` | Full model ID |
| `context_window.total_input_tokens` | Input tokens used |
| `context_window.context_window_size` | Max context |
| `context_window.used_percentage` | % context consumed |
| `cost.total_cost_usd` | Session cost |
| `cost.total_duration_ms` | Total duration |
| `workspace.current_dir` | Working directory |

**Community projects:**
- **gabriel-dehan/claude_monitor_statusline** (GitHub) — Ruby-based. Shows folder, git branch, model, token/message counts remaining, time until rate limit reset. Multiple display modes (minimal, text, background). Colors editable. Supports plan type config (pro, max5, max20).
- **alexop.dev walkthrough** — Bash + jq script showing `[Model] Context: 42%` style output.

**Features:** Supports ANSI colors, multi-line output, clickable OSC 8 links (iTerm2/Kitty/WezTerm), cached operations (e.g., git info refreshed every 5 seconds). Debounced at 300ms. Can be Bash, Python, Ruby, or Node.js.

---

## 2. Spinner Verbs (Custom Loading Messages)

**Config:**
```json
// ~/.claude/settings.json
{
  "spinnerVerbs": {
    "mode": "replace",
    "verbs": [
      "Issuing royal decree",
      "Consulting the court wizard",
      "Polishing the crown",
      "Getting distracted by a shinier bug",
      "Hyperfocusing on the wrong file"
    ]
  }
}
```

**Modes:** `"replace"` overrides defaults completely. Default mode appends to existing list.

---

## 3. Sound Notifications

**Simple — macOS system sounds:**
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "afplay /System/Library/Sounds/Funk.aiff"
      }]
    }],
    "Notification": [{
      "hooks": [{
        "type": "command",
        "command": "afplay /System/Library/Sounds/Purr.aiff"
      }]
    }]
  }
}
```

macOS has 11 built-in sounds in `/System/Library/Sounds/`.

**Ridiculous — claude-sounds by daveschumaker:**
Bash script that plays random AI-generated voice lines (ElevenLabs' Archer persona) on notification hooks. Randomly selects MP3 from a folder. Author's assessment: "Is this necessary? Absolutely not. Is it fun? Yes!" Source: GitHub.

**Linux:** Use `paplay` or `aplay` instead of `afplay`.

---

## 4. Desktop Notifications

**macOS:**
```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\" sound name \"Glass\"'"
      }]
    }]
  }
}
```

**Linux:**
```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "notify-send 'Claude Code' 'Claude Code needs your attention'"
      }]
    }]
  }
}
```

**Windows (PowerShell):**
```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "powershell.exe -Command \"[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Claude Code needs your attention', 'Claude Code')\""
      }]
    }]
  }
}
```

Source: GitButler blog, Anthropic docs.

---

## 5. Themes

6 built-in themes (dark, light, colorblind-friendly, ANSI-only variants). Switch via `/config` → "Output configuration" → select theme. Or env var: `CLAUDE_CODE_THEME=dark`.

**Community demand:** GitHub issue #1302 requests custom theme support — import/export, custom color values, base16/iTerm2 format support. Pain point: Claude Code overrides terminal colors, breaking carefully configured terminal themes (Ghostty, Kitty, etc.).

**Workaround:** Use ANSI-only mode to inherit terminal palette.

**Tmux status bar trick (Angelo Lima):**
```
# ~/.tmux.conf
set -g status-right '#[fg=green]Claude #[fg=white]| #[fg=cyan]%H:%M'
set -g default-terminal "screen-256color"
```

---

## 6. Output Styles

Change Claude's response tone/format. Three built-in styles: Default, Explanatory, Learning.

**Switch:** `/config` → "Output style" or set `"outputStyle": "Explanatory"` in `.claude/settings.local.json`.

**Custom styles:** Create markdown files in `~/.claude/output-styles/` (user) or `.claude/output-styles/` (project).

```markdown
---
name: Technical Writer
description: Adapt Claude Code for documentation and technical writing
keep-coding-instructions: false
---

# Technical Writing Mode

You are a technical writer specializing in software documentation...
```

**Note:** Changes take effect on next session start (system prompt cached during session).

---

## 7. Keybindings

Full customization via `~/.claude/keybindings.json`. Use `/keybindings` to create/open the file. Auto-reloads without restart.

**Customizable contexts:** Global, Chat, History, Autocomplete, Vim mode, Settings, Help, Diff, Tabs, Attachments, Footer.

**Supports:** Modifiers (ctrl, alt/opt, shift, meta/cmd), chords (`ctrl+k ctrl+s`), special keys, unbinding via `null`.

**Reserved (cannot rebind):** Ctrl+C, Ctrl+D.

**Vim mode:** Enable with `/vim`. Mode switching, hjkl navigation, text objects, yank/paste, indentation.

```json
{
  "$schema": "https://www.schemastore.org/claude-code-keybindings.json",
  "bindings": [
    {
      "context": "Chat",
      "bindings": {
        "ctrl+e": "chat:externalEditor",
        "ctrl+u": null
      }
    }
  ]
}
```

---

## 8. Auto-Format Hooks (PostToolUse)

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "prettier --write \"$CLAUDE_FILE_PATHS\""
      }]
    }]
  }
}
```

Source: Builder.io blog, community examples.

---

## 9. Auto-Commit via GitButler

GitButler hooks that auto-commit Claude's work into separate virtual branches per session. Uses Stop hook lifecycle to trigger git operations after Claude finishes.

Source: blog.gitbutler.com

---

## 10. Custom Slash Commands / Skills

Save long prompts as reusable commands in `.claude/skills/<name>/SKILL.md`.

**Dynamic context injection:** Use `!command` syntax in SKILL.md to run shell commands inline before sending to Claude.

**Example:** A `/pr-summary` skill that auto-fetches `gh pr diff`, `gh pr view --comments`, and `gh pr diff --name-only`.

**Argument patterns:** Square brackets as named parameters: `[component_name] [description]`.

---

## 11. Prompt Hooks (LLM as Gatekeeper)

`type: "prompt"` hooks where a Claude model (Haiku by default) makes yes/no decisions about whether to proceed. The LLM evaluates context and returns `{"ok": true/false}`.

**Use case:** Smart guardrails that require judgment — "should this file be modified given the current task scope?"

---

## Sources

- Anthropic Claude Code documentation (docs.anthropic.com)
- GitHub: gabriel-dehan/claude_monitor_statusline
- GitHub: daveschumaker/claude-sounds
- GitHub Issue #1302 — Custom theme support request
- GitButler blog (blog.gitbutler.com) — Hook integrations
- alexop.dev — Status line walkthrough
- Builder.io — PostToolUse formatting hooks
- Angelo Lima — tmux integration
