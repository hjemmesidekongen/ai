---
name: slack-basics
description: >
  Slack channel reading, message search, and posting via Slack MCP. Use when
  reading channel history, searching for past messages, posting updates to a channel,
  replying to threads, listing channels, or looking up users by name or email.
user_invocable: false
interactive: false
triggers:
  - "slack"
  - "send message"
  - "check channel"
  - "slack message"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "mcp_server_available"
      verify: "MCP server 'slack' responds to a list-channels or auth check"
      fail_action: "Emit fallback: MCP server 'slack' not configured — this skill requires it"
    - name: "channel_resolved"
      verify: "Target channel ID resolved before posting or reading"
      fail_action: "List channels and match by name before proceeding"
    - name: "post_confirmed"
      verify: "Post/reply tool call returned success with a timestamp"
      fail_action: "Retry once; if still failing, report error with tool response"
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "D-030 decisions"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New MCP interaction skill for Slack"
---

# Slack Basics

Read channels, search messages, and post to Slack via the Slack MCP server.

## MCP requirement

Requires MCP server `slack` to be configured. If not available:

> MCP server 'slack' not configured — this skill requires it

Check with `/mcp` in Claude Code. The server name in tool calls will be `mcp__<plugin>_slack__<tool>`.

## Operations

| Goal | Tool | Key params |
|------|------|-----------|
| List channels | `slack_list_channels` | `limit`, `cursor` |
| Read channel history | `slack_get_channel_history` | `channel_id`, `limit` |
| Search messages | `slack_search_messages` | `query`, `count` |
| Post to channel | `slack_post_message` | `channel_id`, `text` |
| Reply to thread | `slack_reply_to_thread` | `channel_id`, `thread_ts`, `text` |
| Get thread replies | `slack_get_thread_replies` | `channel_id`, `thread_ts` |
| Look up user | `slack_get_user_profile` | `user_id` |

## Execution sequence

1. Resolve channel: if given a name, list channels and match — never assume the ID
2. Read or search as needed; keep `limit` ≤ 20 for history reads
3. If posting, confirm channel ID before calling the post tool
4. Report success with channel name and message timestamp, or surface the error

## Fallback

If the `slack` MCP server is not connected, stop and state the requirement clearly. Do not attempt workarounds via web browsing or other tools.

Full operation details and error patterns: `references/process.md`.
