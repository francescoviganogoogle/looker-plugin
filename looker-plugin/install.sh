#!/usr/bin/env bash
#
# Global Installer for Looker Antigravity Suite Plugin
# Pure Bash implementation (Zero Python, Zero looker-cli)
# Installs the plugin globally into ~/.gemini/config/plugins/
# and configures the Looker Remote MCP Server globally in ~/.gemini/config/mcp_config.json
#

set -e

# Clear inherited shell function noise from parent environment
unset -f poetry yarn pip pdm uvx npm npx pip3 python3 pipx pnpx pnpm yarnpkg uv python hatch 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_CONFIG_DIR="$HOME/.gemini/config"
GLOBAL_PLUGINS_DIR="$GLOBAL_CONFIG_DIR/plugins/looker-antigravity-suite"
GLOBAL_MCP_FILE="$GLOBAL_CONFIG_DIR/mcp_config.json"

LOOKER_INPUT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --looker-url|-u|--instance|-i|--looker-instance)
      LOOKER_INPUT="$2"
      shift 2
      ;;
    *)
      if [ -z "$LOOKER_INPUT" ] && [[ "$1" != -* ]]; then
        LOOKER_INPUT="$2"
      fi
      shift
      ;;
  esac
done

if [ -z "$LOOKER_INPUT" ]; then
  if [ -t 0 ]; then
    read -p "Enter your Looker Instance Name or URL (e.g. 'mycompany', 'company.looker.com', or 'https://looker.company.com'): " LOOKER_INPUT
  fi
fi

if [ -z "$LOOKER_INPUT" ]; then
  echo "Error: Looker instance name or URL is required. No defaults or fallbacks are provided." >&2
  echo "Usage: $0 --looker-url <INSTANCE_NAME_OR_URL>" >&2
  exit 1
fi

format_mcp_url() {
  local raw="$1"
  raw="$(echo "$raw" | xargs)"
  if [[ "$raw" != http://* && "$raw" != https://* ]]; then
    raw="https://$raw"
  fi
  local proto="${raw%%://*}"
  local rest="${raw#*://}"
  local host="${rest%%/*}"
  if [[ "$host" != *.* ]]; then
    host="${host}.looker.com"
  fi
  echo "${proto}://${host}/mcp"
}

MCP_URL="$(format_mcp_url "$LOOKER_INPUT")"

echo " Installing Looker Antigravity Suite Globally..."
echo " Configured Looker MCP Endpoint: $MCP_URL"

# 1. Install Plugin Files Globally
mkdir -p "$GLOBAL_PLUGINS_DIR"
cp -rf "$SCRIPT_DIR/"* "$GLOBAL_PLUGINS_DIR/" 2>/dev/null || true

# 2. Update plugin's local mcp_config.json
cat <<EOF > "$GLOBAL_PLUGINS_DIR/mcp_config.json"
{
  "mcpServers": {
    "looker-antigravity-2.0": {
      "serverUrl": "$MCP_URL",
      "disabledTools": [
        "add_dashboard_element",
        "add_dashboard_filter",
        "generate_embed_url",
        "health_analyze",
        "health_pulse",
        "health_vacuum",
        "make_dashboard",
        "query_url"
      ],
      "oauth": {
        "clientId": "antigravity"
      }
    }
  }
}
EOF

# 3. Configure Global MCP Server (~/.gemini/config/mcp_config.json)
echo " Setting up global MCP configuration at $GLOBAL_MCP_FILE..."
mkdir -p "$(dirname "$GLOBAL_MCP_FILE")"

cat <<EOF > "$GLOBAL_MCP_FILE"
{
  "mcpServers": {
    "looker-antigravity-2.0": {
      "serverUrl": "$MCP_URL",
      "disabledTools": [
        "add_dashboard_element",
        "add_dashboard_filter",
        "generate_embed_url",
        "health_analyze",
        "health_pulse",
        "health_vacuum",
        "make_dashboard",
        "query_url"
      ],
      "oauth": {
        "clientId": "antigravity"
      }
    }
  }
}
EOF

echo " Global MCP configuration updated successfully."

# 4. Output Summary
cat <<EOF

==================================================
 Looker Antigravity Suite Global Setup Complete
==================================================
Global Plugin Dir : $GLOBAL_PLUGINS_DIR
Global MCP Config : $GLOBAL_MCP_FILE
Configured MCP URL: $MCP_URL
Disabled Tools    : 8 tools disabled
==================================================
EOF
