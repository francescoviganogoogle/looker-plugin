#!/usr/bin/env bash
#
# Configurator for Looker Antigravity Suite Plugin
# Pure Bash implementation (Zero Python, Zero looker-cli)
# Creates AGENT.md in project root and configures disabledTools.
#

set -e

# Clear inherited shell function noise from parent environment
unset -f poetry yarn pip pdm uvx npm npx pip3 python3 pipx pnpx pnpm yarnpkg uv python hatch 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

TARGET_DIR="."
LOOKER_INPUT=""
IS_GLOBAL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --target-dir|-t)
      TARGET_DIR="$2"
      shift 2
      ;;
    --looker-url|-u|--instance|-i|--looker-instance)
      LOOKER_INPUT="$2"
      shift 2
      ;;
    --global|-g)
      IS_GLOBAL=true
      shift
      ;;
    *)
      if [ -z "$LOOKER_INPUT" ] && [[ "$1" != -* ]]; then
        LOOKER_INPUT="$1"
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
  echo "Usage: $0 --looker-url <INSTANCE_NAME_OR_URL> [--target-dir <DIR>] [--global]" >&2
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

if [ "$IS_GLOBAL" = true ]; then
  exec "$PACKAGE_ROOT/install.sh" --looker-url "$MCP_URL"
fi

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"
PLUGINS_DIR="$TARGET_DIR/.agents/plugins/looker-antigravity-suite"

mkdir -p "$PLUGINS_DIR"
cp -rf "$PACKAGE_ROOT/"* "$PLUGINS_DIR/" 2>/dev/null || true

# Remove redundant AGENT.md inside plugin subfolder if present
rm -f "$PLUGINS_DIR/AGENT.md" "$PLUGINS_DIR/agents.md"

# Update plugin local mcp_config.json with pure bash
cat <<EOF > "$PLUGINS_DIR/mcp_config.json"
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

# Configure global MCP as required by Antigravity 2.0
if [ -f "$PACKAGE_ROOT/install.sh" ]; then
  "$PACKAGE_ROOT/install.sh" --looker-url "$MCP_URL" >/dev/null 2>&1 || true
fi

# Create single clean AGENT.md in project root
cat <<'EOF' > "$TARGET_DIR/AGENT.md"
# Antigravity Agent Guidelines & Workflow Rules

## 1. Business-First & Non-Technical Communication Rule

### Overview
The user is a business stakeholder and non-technical decision-maker. All communications, summaries, and responses must prioritize business value, clarity, and executive-level summaries, while eliminating technical jargon and low-level implementation details.

### Communication Directives
1. **Focus on Business Value & Outcomes**:
   - Frame all responses around direct business answers, key metrics, insights, and high-level results.
   - Summarize actions in clear, plain language.

2. **Zero Technical Jargon**:
   - Do **NOT** mention API endpoints, HTTP status codes, JSON payload fields, authentication tokens, SDK methods, bash scripts, or internal file paths unless explicitly requested by the user.

3. **No Code or Config Dumps**:
   - Never output raw JSON configurations, raw code snippets, API response payloads, or shell commands in user-facing responses.

4. **Clickable & Clean Deliverables**:
   - When providing access to dashboards, reports, or artifacts, provide user-friendly clickable links (e.g., `[View Sales Performance Dashboard](https://<instance>/dashboards/<id>)`).

---

## 2. Mandatory Dashboard Lifecycle, Publishing, & Project Cleanup Rules

When creating or modifying any dashboard in this workspace, the agent **MUST** execute the complete lifecycle:

### Required Dashboard Workflow:

1. **Stage 1: Declarative Local LookML Creation & Validation**:
   - Construct the dashboard definition locally as a `.dashboard.lookml` file using `layout: newspaper` (24-column grid).
   - Validate the project/LookML definition using `validate_project` or `lookml-diagnostics` to ensure zero syntax or reference errors.

2. **Stage 2: MANDATORY UDD Publishing**:
   - **Prerequisite Execution**: Before running `publish_lookml_dashboard_as_udd`, the agent **MUST ensure at least one Looker MCP tool call** (such as `get_models`, `get_explores`, or `validate_project`) has been executed during the session.
   - **Invoke Skill**: Immediately invoke `publish_lookml_dashboard_as_udd` (`publish_dashboard_as_udd.sh`) to import/compile the LookML definition into Looker as an interactive, editable User-Defined Dashboard (UDD).

3. **In-Place Updates**:
   - Always memorize the `dashboard_id` returned during initial creation and pass `--existing-dashboard-id <id>` on subsequent updates to overwrite the UDD in-place without creating duplicate dashboards.

4. **Project Cleanliness Option**:
   - If UDD-only mode is requested, pass `--delete-project-file --project-id <project_id>` to delete the `.dashboard.lookml` file from the LookML project repository after import.

5. **STRICT PROHIBITION ON WORKAROUND CODE & SCRIPT MODIFICATIONS**:
   - **DO NOT WRITE WORKAROUND CODE**: If `publish_dashboard_as_udd.sh` or any skill command fails, the agent **MUST NOT** attempt to write ad-hoc Python (`publish.py`), Node (`publish.js`), JavaScript, or cURL workaround scripts in the workspace.
   - **DO NOT MODIFY SKILL SCRIPTS**: The agent **MUST NOT** edit, modify, or rewrite `publish_dashboard_as_udd.sh` or `get_mcp_token.sh`.
   - **STOP EXECUTION IMMEDIATELY ON FAILURE**: If a skill command fails, stop execution immediately, report the exact error to the user, and ask for instructions.

6. **Deliverable Requirement**:
   - Always provide the user with a clickable link to the published UDD: `[View Interactive Dashboard](https://<instance>/dashboards/<dashboard_id>)`.
EOF

cat <<EOF
{
  "status": "success",
  "message": "Project workspace configured with single AGENT.md in project root and global Looker MCP with 8 disabledTools.",
  "target_directory": "$TARGET_DIR",
  "plugin_location": "$PLUGINS_DIR",
  "configured_mcp_url": "$MCP_URL"
}
EOF
