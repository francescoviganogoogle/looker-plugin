#!/usr/bin/env bash
#
# Get Looker MCP OAuth Access Token & Synchronize Across Antigravity Directories
# Pure Bash + cURL implementation (Zero Python, Zero looker-cli)
#
# Usage:
#   bash get_mcp_token.sh               # Outputs raw access token
#   bash get_mcp_token.sh --export-env  # Outputs shell export commands
#   bash get_mcp_token.sh --json        # Outputs JSON object with token and base URL
#

set -e

# Suppress parent environment function import warnings
unset -f poetry yarn pip pdm uvx npm npx pip3 python3 pipx pnpx pnpm yarnpkg uv python hatch 2>/dev/null || true

MODE="raw"

while [[ $# -gt 0 ]]; do
  case $1 in
    --export-env|-e)
      MODE="export"
      shift
      ;;
    --json|-j)
      MODE="json"
      shift
      ;;
    --raw|-r)
      MODE="raw"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Candidate paths for mcp_oauth_tokens.json
CANDIDATE_PATHS=(
  "$HOME/.gemini/antigravity/mcp_oauth_tokens.json"
  "$HOME/.gemini/antigravity-cli/mcp_oauth_tokens.json"
  "$HOME/.gemini/mcp_oauth_tokens.json"
  "$HOME/.gemini/config/mcp_oauth_tokens.json"
  "$HOME/.config/Antigravity/mcp_oauth_tokens.json"
  "/tmp/mcp_oauth_tokens.json"
)

# Candidate paths for mcp_config.json
MCP_CONFIG_PATHS=(
  "$HOME/.gemini/config/mcp_config.json"
  "$HOME/.gemini/antigravity/mcp_config.json"
  "$HOME/.gemini/antigravity-cli/mcp_config.json"
  "$HOME/.gemini/mcp_config.json"
)

BASE_URL=""

# 1. Discover Base URL from LOOKER_BASE_URL, mcp_config.json, or mcp_oauth_tokens.json
if [ -n "$LOOKER_BASE_URL" ] && [[ "$LOOKER_BASE_URL" != *"<your-"* ]] && [[ "$LOOKER_BASE_URL" != *"example.com"* ]]; then
  BASE_URL="${LOOKER_BASE_URL%/}"
fi

# Try discovering from mcp_config.json candidate paths
if [ -z "$BASE_URL" ]; then
  for p in "${MCP_CONFIG_PATHS[@]}"; do
    if [ -f "$p" ]; then
      URL_FOUND=$(grep -o '"serverUrl": *"[^"]*"' "$p" 2>/dev/null | head -n 1 | sed -E 's/.*"serverUrl": *"([^"]*)".*/\1/' || true)
      if [ -n "$URL_FOUND" ] && [[ "$URL_FOUND" != *"<your-"* ]] && [[ "$URL_FOUND" != *"example.com"* ]]; then
        BASE_URL=$(echo "$URL_FOUND" | sed 's#/mcp$##' | sed 's#/$##')
        break
      fi
    fi
  done
fi

# Try discovering from mcp_oauth_tokens.json candidate paths (token_url or serverUrl key)
if [ -z "$BASE_URL" ]; then
  for p in "${CANDIDATE_PATHS[@]}"; do
    if [ -f "$p" ]; then
      TOKEN_URL=$(grep -o '"token_url": *"[^"]*"' "$p" 2>/dev/null | head -n 1 | sed -E 's/.*"token_url": *"([^"]*)".*/\1/' || true)
      if [ -n "$TOKEN_URL" ] && [[ "$TOKEN_URL" != *"<your-"* ]] && [[ "$TOKEN_URL" != *"example.com"* ]]; then
        BASE_URL=$(echo "$TOKEN_URL" | sed 's#/api/token$##' | sed 's#/$##')
        break
      fi
      KEY_URL=$(grep -oE '"https?://[^"/]+/mcp"' "$p" 2>/dev/null | head -n 1 | tr -d '"' || true)
      if [ -n "$KEY_URL" ] && [[ "$KEY_URL" != *"<your-"* ]] && [[ "$KEY_URL" != *"example.com"* ]]; then
        BASE_URL=$(echo "$KEY_URL" | sed 's#/mcp$##' | sed 's#/$##')
        break
      fi
    fi
  done
fi

if [ -z "$BASE_URL" ]; then
  if [ "$MODE" = "json" ]; then
    echo '{"status":"error","error":"Looker Base URL could not be discovered. Please set LOOKER_BASE_URL or configure your Looker MCP server."}'
  else
    echo "Error: Looker Base URL could not be discovered. Please set LOOKER_BASE_URL or configure your Looker MCP server." >&2
  fi
  exit 1
fi

HOST=$(echo "$BASE_URL" | sed -E 's#https?://##' | cut -d'/' -f1 | cut -d':' -f1)

FOUND_TOKEN=""
REFRESH_TOKEN=""
FOUND_PATH=""

# 2. Discover Access Token & Refresh Token from candidate paths
for p in "${CANDIDATE_PATHS[@]}"; do
  if [ -f "$p" ]; then
    ACC=$(grep -o '"access_token": *"[^"]*"' "$p" 2>/dev/null | head -n 1 | sed -E 's/.*"access_token": *"([^"]*)".*/\1/' || true)
    REF=$(grep -o '"refresh_token": *"[^"]*"' "$p" 2>/dev/null | head -n 1 | sed -E 's/.*"refresh_token": *"([^"]*)".*/\1/' || true)
    if [ -n "$ACC" ] || [ -n "$REF" ]; then
      FOUND_TOKEN="$ACC"
      REFRESH_TOKEN="$REF"
      FOUND_PATH="$p"
      break
    fi
  fi
done

if [ -z "$FOUND_TOKEN" ]; then
  FOUND_TOKEN="${LOOKER_OAUTH_TOKEN:-${LOOKER_ACCESS_TOKEN:-$BEARER_TOKEN}}"
fi

# 3. Validate Token via cURL
IS_VALID=false
if [ -n "$FOUND_TOKEN" ]; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $FOUND_TOKEN" "$BASE_URL/api/4.0/user" 2>/dev/null || true)
  if [ "$HTTP_CODE" = "200" ]; then
    IS_VALID=true
  fi
fi

# 4. Refresh token if invalid and refresh_token is present
if [ "$IS_VALID" = false ] && [ -n "$REFRESH_TOKEN" ]; then
  REFRESH_RESP=$(curl -s -X POST "$BASE_URL/api/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=refresh_token&refresh_token=$REFRESH_TOKEN&client_id=antigravity" 2>/dev/null || true)
  
  NEW_ACC=$(echo "$REFRESH_RESP" | grep -o '"access_token": *"[^"]*"' | head -n 1 | sed -E 's/.*"access_token": *"([^"]*)".*/\1/' || true)
  if [ -n "$NEW_ACC" ]; then
    FOUND_TOKEN="$NEW_ACC"
    IS_VALID=true
  fi
fi

if [ -z "$FOUND_TOKEN" ]; then
  if [ "$MODE" = "json" ]; then
    echo '{"status":"error","error":"OAuth access token not found in MCP configuration. Please run a Looker MCP tool call first."}'
  else
    echo "Error: OAuth access token not found in MCP configuration." >&2
  fi
  exit 1
fi

# 5. Synchronize Token across all candidate paths
if [ -n "$FOUND_PATH" ] && [ -f "$FOUND_PATH" ]; then
  for target_p in "${CANDIDATE_PATHS[@]}"; do
    if [[ "$target_p" != /tmp/* ]] && [ "$target_p" != "$FOUND_PATH" ]; then
      mkdir -p "$(dirname "$target_p")" 2>/dev/null || true
      cp "$FOUND_PATH" "$target_p" 2>/dev/null || true
    fi
  done
fi

# 6. Output according to requested mode
if [ "$MODE" = "export" ]; then
  echo "export LOOKER_OAUTH_TOKEN=\"$FOUND_TOKEN\""
  echo "export LOOKER_BASE_URL=\"$BASE_URL\""
  echo "export LOOKER_HOST=\"$HOST\""
elif [ "$MODE" = "json" ]; then
  cat <<EOF
{
  "status": "success",
  "access_token": "$FOUND_TOKEN",
  "base_url": "$BASE_URL",
  "host": "$HOST",
  "synced_from": "$FOUND_PATH"
}
EOF
else
  echo "$FOUND_TOKEN"
fi
