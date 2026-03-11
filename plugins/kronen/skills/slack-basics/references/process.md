# Slack Basics — Full Reference

## Channel operations

### List channels

Call `slack_list_channels` to get available channels. Returns channel IDs and names.
Always resolve a channel name to its ID before any read or write operation.

```
slack_list_channels(limit=100)
→ { channels: [{ id: "C123", name: "general" }, ...] }
```

Paginate with `cursor` if the workspace has more channels than the `limit`.

### Read channel history

```
slack_get_channel_history(channel_id="C123", limit=20)
→ { messages: [{ ts: "1710000000.000001", user: "U456", text: "..." }, ...] }
```

- Default to `limit=20`. Increase only when the user explicitly wants more history.
- Messages are returned newest-first. Reverse order for chronological reading.
- `ts` (timestamp) is the message identifier — save it when you need to reply.

## Message search

```
slack_search_messages(query="deploy failed", count=10)
→ { messages: { matches: [{ channel: {...}, ts: "...", text: "..." }] } }
```

Effective query patterns:

| Goal | Query |
|------|-------|
| Keyword in any channel | `deploy failed` |
| In a specific channel | `in:#ops deploy failed` |
| From a user | `from:@alice standup` |
| Date range | `after:2024-01-01 before:2024-02-01 incident` |
| Exact phrase | `"production outage"` |
| File mentions | `has:file design` |

Search is workspace-wide unless scoped with `in:` or `from:`.

## Posting messages

### Post to channel

```
slack_post_message(channel_id="C123", text="Deployment complete.")
→ { ok: true, ts: "1710000000.000200", channel: "C123" }
```

Confirm `ok: true` in the response before reporting success. Surface the `ts` — it identifies the message if a thread reply is needed later.

### Reply to a thread

```
slack_reply_to_thread(channel_id="C123", thread_ts="1710000000.000001", text="Fixed.")
→ { ok: true, ts: "1710000000.000300" }
```

`thread_ts` must be the timestamp of the **parent** message, not a reply within the thread.

### Get thread replies

```
slack_get_thread_replies(channel_id="C123", thread_ts="1710000000.000001")
→ { messages: [...] }
```

The first message in the response is the parent; subsequent messages are the replies.

## Rich message formatting

Slack uses mrkdwn (not standard Markdown):

| Element | Syntax |
|---------|--------|
| Bold | `*bold text*` |
| Italic | `_italic text_` |
| Code (inline) | `` `code` `` |
| Code block | ` ```multiline``` ` |
| Link | `<https://example.com\|Label>` |
| User mention | `<@U123456>` |
| Channel mention | `<#C123456>` |

For structured messages (cards with sections, buttons), pass a `blocks` array using Block Kit. Keep text fallback in `text` for notifications.

## User lookup

```
slack_get_user_profile(user_id="U456")
→ { profile: { real_name: "Alice", display_name: "alice", email: "alice@example.com" } }
```

To find a user by email or display name, search messages from that person or list workspace members if the tool supports it.

## Error handling

| Error | Cause | Fix |
|-------|-------|-----|
| `channel_not_found` | Wrong channel ID or private channel not joined | Re-resolve channel name; confirm bot is a member |
| `not_in_channel` | Bot not added to the channel | Ask user to `/invite @bot` to the channel |
| `ratelimited` | Too many requests | Back off 1 second; do not retry in a tight loop |
| `invalid_auth` | Token expired or wrong scope | Re-authenticate; check MCP server config |
| `msg_too_long` | Text exceeds 40,000 characters | Split into multiple posts |
| Tool not found | MCP server not connected | Emit fallback message; stop |

## Anti-patterns

- **Never assume a channel ID** — always resolve name→ID first via `slack_list_channels`.
- **Don't read unlimited history** — `limit` > 100 without a specific reason wastes tokens and may hit rate limits.
- **Don't broadcast broadly** — if you're posting a message, confirm the right channel with the user before sending.
- **Don't retry on `ratelimited` immediately** — back off briefly rather than hammering the API.
- **Don't parse `ts` as a float** — treat it as an opaque string; floating-point precision will corrupt the value.
- **Don't use Markdown syntax in Slack messages** — use mrkdwn (`*bold*`, not `**bold**`).
