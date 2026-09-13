#!/usr/bin/env bash
#
# Publish LookML Dashboard as User-Defined Dashboard (UDD) via direct Looker REST API
# Bare-bones cURL wrapper (Zero Python, Zero looker-cli, Zero sed/awk/grep)
# Outputs direct Looker REST API JSON response to standard output.
#

set -e

# Suppress parent environment function import warnings
unset -f poetry yarn pip pdm uvx npm npx pip3 python3 pipx pnpx pnpm yarnpkg uv python hatch 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GET_TOKEN_SCRIPT="$SCRIPT_DIR/../../get-looker-mcp-token/scripts/get_mcp_token.sh"

LOOKML_FILE=""
FOLDER_ID="1"
PAYLOAD_FILE=""
PREFERRED_SLUG=""
DELETE_PROJECT_FILE=false
PROJECT_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --lookml-file|-f)
      LOOKML_FILE="$2"
      shift 2
      ;;
    --payload-file|-p)
      PAYLOAD_FILE="$2"
      shift 2
      ;;
    --folder-id)
      FOLDER_ID="$2"
      shift 2
      ;;
    --preferred-slug|--slug)
      PREFERRED_SLUG="$2"
      shift 2
      ;;
    --delete-project-file)
      DELETE_PROJECT_FILE=true
      shift
      ;;
    --project-id)
      PROJECT_ID="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# 1. Retrieve OAuth Token and Base URL using get_mcp_token.sh
if [ -f "$GET_TOKEN_SCRIPT" ]; then
  eval $(bash "$GET_TOKEN_SCRIPT" --export-env 2>/dev/null || true)
fi

TOKEN="${LOOKER_OAUTH_TOKEN:-${LOOKER_ACCESS_TOKEN:-$BEARER_TOKEN}}"
BASE_URL="${LOOKER_BASE_URL%/}"

if [ -z "$BASE_URL" ] || [[ "$BASE_URL" == *"<your-"* ]] || [[ "$BASE_URL" == *"example.com"* ]]; then
  echo '{"status":"error","error":"Looker Base URL not configured. Please set LOOKER_BASE_URL or configure your Looker MCP server."}'
  exit 1
fi

if [ -z "$TOKEN" ]; then
  echo '{"status":"error","error":"OAuth access token not found. Please run a Looker MCP tool call prior to running this script."}'
  exit 1
fi

TEMP_PAYLOAD=""

# 2. Prepare JSON payload
if [ -n "$PAYLOAD_FILE" ] && [ -f "$PAYLOAD_FILE" ]; then
  TARGET_PAYLOAD="$PAYLOAD_FILE"
elif [ -n "$LOOKML_FILE" ] && [ -f "$LOOKML_FILE" ]; then
  TEMP_PAYLOAD=$(mktemp)
  LOOKML_CONTENT=$(< "$LOOKML_FILE")

  # If preferred_slug was provided via CLI, ensure it exists in the LookML string
  if [ -n "$PREFERRED_SLUG" ]; then
    if [[ "$LOOKML_CONTENT" != *"preferred_slug:"* ]]; then
      LOOKML_CONTENT=$(echo "$LOOKML_CONTENT" | sed "/^[[:space:]]*- dashboard:/a\\  preferred_slug: \"$PREFERRED_SLUG\"")
    fi
  fi

  # Escape newlines and double quotes in lookml for valid JSON payload via bash parameter expansion
  LOOKML_ESCAPED="${LOOKML_CONTENT//\\/\\\\}"
  LOOKML_ESCAPED="${LOOKML_ESCAPED//\"/\\\"}"
  LOOKML_ESCAPED="${LOOKML_ESCAPED//$'\n'/\\n}"
  LOOKML_ESCAPED="${LOOKML_ESCAPED//$'\r'/}"
  
  if [ -n "$PREFERRED_SLUG" ]; then
    printf '{"folder_id":"%s","lookml":"%s","preferred_slug":"%s"}' "$FOLDER_ID" "$LOOKML_ESCAPED" "$PREFERRED_SLUG" > "$TEMP_PAYLOAD"
  else
    printf '{"folder_id":"%s","lookml":"%s"}' "$FOLDER_ID" "$LOOKML_ESCAPED" > "$TEMP_PAYLOAD"
  fi
  TARGET_PAYLOAD="$TEMP_PAYLOAD"
else
  echo '{"status":"error","error":"Either --lookml-file or --payload-file parameter is required"}'
  exit 1
fi

# 3. Send LookML import request to Looker REST API via cURL
RESP=$(curl -s -X POST "$BASE_URL/api/4.0/dashboards/lookml" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary @"$TARGET_PAYLOAD" 2>/dev/null || true)

if [ -n "$TEMP_PAYLOAD" ] && [ -f "$TEMP_PAYLOAD" ]; then
  rm -f "$TEMP_PAYLOAD"
fi

# 4. Cleanup project file if requested
if [ "$DELETE_PROJECT_FILE" = true ] && [ -n "$PROJECT_ID" ] && [ -n "$LOOKML_FILE" ]; then
  REL_PATH="${LOOKML_FILE#*/dashboards/}"
  ENCODED_PATH="${REL_PATH//\//%2F}"
  
  curl -s -X DELETE "$BASE_URL/api/4.0/projects/$PROJECT_ID/files/$ENCODED_PATH" \
    -H "Authorization: Bearer $TOKEN" > /dev/null 2>&1 || true
  
  rm -f "$LOOKML_FILE" 2>/dev/null || true
fi

# 5. Output direct raw Looker REST API JSON response
echo "$RESP"
