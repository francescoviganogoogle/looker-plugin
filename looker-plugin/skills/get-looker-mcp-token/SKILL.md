---
name: get-looker-mcp-token
description: Synchronizes and retrieves the active Looker MCP OAuth access token across all local Antigravity configuration directories with automatic refresh token renewal.
version: 1.1.0
tags: [looker, mcp, oauth, token, credentials, auto-refresh]
---

# Get Looker MCP Token Skill

This skill retrieves the active OAuth access token for the Looker MCP server, automatically refreshes expired tokens via Looker's OAuth token endpoint, and synchronizes the active credentials across all local Antigravity directories (`~/.gemini/antigravity/`, `~/.gemini/antigravity-cli/`, `~/.gemini/config/`).

## Usage

To export token variables into the current shell environment:
```bash
eval $(bash .agents/plugins/looker-antigravity-suite/skills/get-looker-mcp-token/scripts/get_mcp_token.sh --export-env)
```

To output raw JSON containing token status and base URL:
```bash
bash .agents/plugins/looker-antigravity-suite/skills/get-looker-mcp-token/scripts/get_mcp_token.sh --json
```
