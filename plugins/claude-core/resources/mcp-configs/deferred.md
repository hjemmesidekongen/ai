# MCP Config Templates — Status Notes

## Confirmed Endpoints
- **Atlassian**: `https://mcp.atlassian.com/v1/sse` — OAuth via browser redirect on first use
- **Figma**: Local MCP plugin at `http://127.0.0.1:3845/sse` — requires Figma desktop app with MCP plugin
- **Playwright**: `@anthropic-ai/mcp-playwright` npm package — stdio transport
- **Storybook**: `http://localhost:6006/mcp` — requires running Storybook dev server with MCP support

## Placeholder Endpoints (TODO — verify before use)
- **Azure DevOps**: No confirmed MCP endpoint. May need community server or direct API integration. PAT-based auth.
- **Slack**: No confirmed official MCP endpoint. Research needed for community alternative. OAuth-based auth.
- **Microsoft 365**: No confirmed MCP endpoint. Official connector may exist for Team/Enterprise plans, or community Graph API MCP for personal use.

## Usage
Copy the relevant JSON snippet into your project's `.mcp.json` file. Replace placeholder values (`<org-name>`, `<personal-access-token>`, `TODO_VERIFY_ENDPOINT`) with actual values.
