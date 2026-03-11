# MCP Server Types — Deep Dive

## stdio (Standard Input/Output)

### How it works

Claude Code spawns the server as a child process and communicates via JSON-RPC
over stdin/stdout. The process runs for the entire session and terminates when
Claude Code exits.

### Configuration

**Basic (NPM package):**
```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "${CLAUDE_PROJECT_DIR}"]
  }
}
```

**Custom server (bundled with plugin):**
```json
{
  "custom": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/my-server.js",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "API_KEY": "${MY_API_KEY}",
      "LOG_LEVEL": "info",
      "DATABASE_URL": "${DB_URL}"
    }
  }
}
```

**Python server:**
```json
{
  "python-server": {
    "command": "python",
    "args": ["-m", "my_mcp_server"],
    "env": {
      "PYTHONUNBUFFERED": "1"
    }
  }
}
```

### Process lifecycle

1. **Startup** — Claude Code spawns process with `command` + `args`
2. **Communication** — JSON-RPC messages via stdin/stdout
3. **Session** — process runs for entire Claude Code session
4. **Shutdown** — process terminated when Claude Code exits

### Use cases

- File system access tools
- Local database connections
- Custom MCP servers bundled with a plugin
- NPM-packaged MCP servers (`npx -y <package>`)

### Critical rules

- Log to stderr, never stdout — stdout is the MCP protocol channel
- Set `PYTHONUNBUFFERED=1` for Python servers (buffered stdout breaks the protocol)
- Use `${CLAUDE_PLUGIN_ROOT}` for bundled server paths
- Pass configuration via `args` or `env`, not stdin

### Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Server won't start | Command not found or not executable | Check path, permissions, `which <command>` |
| Communication fails | Stray stdout output (print, console.log) | Redirect all logging to stderr |
| Server crashes silently | Unhandled error in server code | Check `claude --debug`, add error handling |
| Environment vars empty | Not set in user's shell | Document required vars, check `echo $VAR` |

## SSE (Server-Sent Events)

### How it works

Claude Code establishes an HTTP connection to the server URL. The server streams
events to the client via SSE. Tool calls are sent as HTTP POST requests.
Reconnection is automatic on disconnect.

### Configuration

**Basic (OAuth — no headers needed):**
```json
{
  "asana": {
    "type": "sse",
    "url": "https://mcp.asana.com/sse"
  }
}
```

**With custom headers:**
```json
{
  "service": {
    "type": "sse",
    "url": "https://mcp.example.com/sse",
    "headers": {
      "X-API-Version": "v1",
      "X-Client-ID": "${CLIENT_ID}"
    }
  }
}
```

### Connection lifecycle

1. **Initialization** — HTTP connection established to URL
2. **Handshake** — MCP protocol negotiation
3. **Streaming** — server sends events via SSE
4. **Requests** — client sends HTTP POST for tool calls
5. **Reconnection** — automatic reconnection on disconnect

### Authentication

OAuth is handled automatically by Claude Code:
1. First tool use triggers authentication
2. Browser opens for OAuth consent
3. Tokens stored and refreshed automatically

No additional configuration required for OAuth-enabled servers.

### Use cases

- Official hosted MCP servers (Asana, GitHub)
- Cloud services with MCP endpoints
- Services requiring OAuth authentication
- Scenarios where no local installation is needed

### Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Connection refused | Wrong URL or server down | Verify URL, check network |
| OAuth loop | Stale tokens or misconfigured redirect | Clear cached tokens, re-auth |
| Events stop arriving | Connection dropped without reconnect | Restart Claude Code, check `--debug` |
| 403 after auth | Insufficient OAuth scopes | Re-authorize with correct scopes |

## HTTP (REST API)

### How it works

Claude Code sends HTTP requests (GET for discovery, POST for tool calls) to the
server URL. Each request is independent and stateless. Headers are sent with
every request.

### Configuration

**Basic:**
```json
{
  "api": {
    "type": "http",
    "url": "https://api.example.com/mcp"
  }
}
```

**With authentication:**
```json
{
  "api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}",
      "Content-Type": "application/json",
      "X-API-Version": "2024-01-01"
    }
  }
}
```

### Request/response flow

1. **Discovery** — GET request to discover available tools
2. **Invocation** — POST with tool name and parameters
3. **Response** — JSON response with results or errors
4. **Stateless** — each request is independent

### Authentication

Token-based via headers:

```json
{
  "headers": {
    "Authorization": "Bearer ${API_TOKEN}"
  }
}
```

API key alternative:
```json
{
  "headers": {
    "X-API-Key": "${API_KEY}"
  }
}
```

OAuth is also supported (same automatic flow as SSE).

### Use cases

- REST API-based MCP servers
- Internal microservices
- Serverless function backends
- Token-based authentication scenarios

### Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| 401 Unauthorized | Bad or expired token | Check `${API_TOKEN}` is set, refresh token |
| 403 Forbidden | Token lacks permissions | Check scopes, request correct permissions |
| 429 Too Many Requests | Rate limited | Reduce call frequency, add backoff |
| 500 Server Error | Backend issue | Check server logs, contact service provider |

## WebSocket

### How it works

Claude Code establishes a persistent WebSocket connection for real-time
bidirectional communication. Messages use JSON-RPC format over the WebSocket
channel. Automatic reconnection on disconnect.

### Configuration

**Basic:**
```json
{
  "realtime": {
    "type": "ws",
    "url": "wss://mcp.example.com/ws"
  }
}
```

**With authentication:**
```json
{
  "realtime": {
    "type": "ws",
    "url": "wss://mcp.example.com/ws",
    "headers": {
      "Authorization": "Bearer ${TOKEN}",
      "X-Client-ID": "${CLIENT_ID}"
    }
  }
}
```

### Connection lifecycle

1. **Handshake** — WebSocket upgrade request
2. **Connection** — persistent bidirectional channel
3. **Messages** — JSON-RPC over WebSocket
4. **Heartbeat** — keep-alive messages maintain connection
5. **Reconnection** — automatic on disconnect

### Use cases

- Real-time data streaming
- Live updates and notifications
- Collaborative editing tools
- Low-latency tool calls
- Push notifications from server

### Critical rules

- Always use `wss://` (secure WebSocket), never `ws://`
- Expect automatic reconnection — design tools to handle reconnect gracefully
- Connection maintained for the session duration

### Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Connection drops | Network instability | Reconnection is automatic, check network |
| Handshake fails | Wrong URL or firewall | Verify URL, check WebSocket support |
| Messages not delivered | Connection in reconnecting state | Wait for reconnection, retry |
| High latency | Network or server load | Check server performance, reduce payload |

## Comparison matrix

| Feature | stdio | SSE | HTTP | WebSocket |
|---------|-------|-----|------|-----------|
| **Transport** | Process stdin/stdout | HTTP + SSE stream | HTTP request/response | WebSocket |
| **Direction** | Bidirectional | Server-push + POST | Request/response | Bidirectional |
| **State** | Stateful (process) | Stateful (connection) | Stateless | Stateful (connection) |
| **Auth** | Env vars | OAuth (auto) / Headers | Headers | Headers |
| **Latency** | Lowest | Medium | Medium | Low |
| **Setup complexity** | Easy | Medium | Easy | Medium |
| **Reconnection** | Process respawn | Automatic | N/A (stateless) | Automatic |
| **Best for** | Local tools | Cloud services | REST APIs | Real-time |

## Choosing the right type

**Use stdio when:**
- Running local tools or custom servers bundled with the plugin
- Need lowest latency (no network overhead)
- Working with file systems or local databases
- Distributing server code with the plugin

**Use SSE when:**
- Connecting to hosted cloud services
- Service supports OAuth authentication
- Using official MCP servers (Asana, GitHub)
- Want automatic reconnection without local setup

**Use HTTP when:**
- Integrating with REST APIs or microservices
- Need stateless interactions (no session state)
- Using token-based authentication
- Simple request/response pattern is sufficient

**Use WebSocket when:**
- Need real-time bidirectional updates
- Building collaborative or streaming features
- Low-latency is critical
- Server needs to push data without polling
