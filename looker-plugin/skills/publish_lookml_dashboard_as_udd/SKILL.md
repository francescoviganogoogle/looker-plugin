---
name: publish_lookml_dashboard_as_udd
description: Triggers whenever publishing, importing, or updating a LookML dashboard definition (.dashboard.lookml) as an interactive User Defined Dashboard (UDD) in Looker using direct Looker REST API endpoints authenticated via the get-looker-mcp-token skill.
version: 4.1.0
tags: [developer-workflow, looker, lookml, dashboard, udd, publish, import, oauth, rest-api, preferred-slug, cURL]
---

# Publish LookML Dashboard as User-Defined Dashboard (UDD)

This skill provides instructions for **Antigravity 2.0** to publish or update a LookML dashboard (`.dashboard.lookml`) as an interactive User Defined Dashboard (UDD) in Looker using **pure Bash cURL requests** (`POST /api/4.0/dashboards/lookml`) authenticated via OAuth Bearer token.

**Zero Python, Zero looker-cli, Zero sed/awk/grep**: Implementation is a minimal, pure Bash + cURL wrapper.

The script returns the **direct raw JSON response from the Looker REST API**, enabling Antigravity 2.0 (the agent) to receive and parse all dashboard metadata (`id`, `slug`, `title`, `url`, `updated_at`, etc.) directly.

---

## 1. Agent Conversation Guidelines & Mandatory Rules

> [!CAUTION]
> **STRICT PROHIBITION ON WORKAROUND CODE & SCRIPT MODIFICATION**:
> - **DO NOT WRITE CUSTOM WORKAROUND CODE**: If `publish_dashboard_as_udd.sh` fails or returns an error, the agent **MUST NOT** attempt to write ad-hoc Python (`publish.py`), Node (`publish.js`), JavaScript, or cURL workaround scripts in the workspace.
> - **DO NOT EDIT SKILL SCRIPTS**: The agent **MUST NOT** edit, modify, or rewrite `publish_dashboard_as_udd.sh` or `get_mcp_token.sh`.
> - **STOP EXECUTION IMMEDIATELY ON FAILURE**: If the script execution fails, the agent **MUST STOP IMMEDIATELY**, report the exact error message clearly to the user, and request user guidance rather than attempting unauthorized code generation or script alterations.

> [!IMPORTANT]
> **MCP Tool Call Prerequisite**:
> - **Execute MCP Tool First**: Before invoking `publish_lookml_dashboard_as_udd` or running `publish_dashboard_as_udd.sh`, the agent **MUST ensure at least one Looker MCP tool call** (such as `get_models`, `get_explores`, or `validate_project`) has been executed during the conversation. This guarantees that Antigravity's internal OAuth session is active and `mcp_oauth_tokens.json` is refreshed on disk.
>
> **Direct Looker API Response Parsing & In-Place Updates**:
> - **Extract & Memorize Returned Slug**: When creating a new UDD during a conversation, Antigravity 2.0 **MUST** parse the raw JSON response payload and memorize the exact `"slug":"..."` string (e.g. `FOnJ8gOG2iXFYsEG2GvMYP`).
> - ⚠️ **NEVER GUESS THE SLUG**: Do **NOT** construct or derive slugs from file names or dashboard titles (e.g. `sales_analysis___antigravity...` is INVALID). Always use the exact `slug` string returned by Looker in the API response.
> - **In-Place Updates via `--preferred-slug`**: When updating an existing dashboard, Antigravity 2.0 **MUST** pass `--preferred-slug <memorized_slug>` when invoking `publish_dashboard_as_udd.sh` (or write `preferred_slug: "<memorized_slug>"` directly inside `.dashboard.lookml` under `- dashboard:`). Looker matches `preferred_slug` and overwrites the existing UDD in-place instead of creating duplicate dashboards.
> - **Provide Clickable Link**: After every create or update operation, Antigravity 2.0 **MUST** output clear, clickable Markdown links to the dashboard (`https://<instance>/dashboards/<id>`).

---

## 2. Technical Architecture & Looker REST APIs

### Automatic Credential Auto-Discovery via `get-looker-mcp-token`
Antigravity 2.0 automatically delegates OAuth token discovery to the `get-looker-mcp-token` skill:
- **Token Skill Invocation**: Runs `bash .agents/plugins/looker-antigravity-suite/skills/get-looker-mcp-token/scripts/get_mcp_token.sh --export-env`.
- **Token Discovery & Auto-Sync**: Searches `mcp_oauth_tokens.json` across `~/.gemini/antigravity/`, `~/.gemini/antigravity-cli/`, and `~/.gemini/config/` and synchronizes the active OAuth session across all paths.

---

## 3. LookML Dashboard Syntax Guidelines

### 24-Column Newspaper Layout Rules
- All LookML dashboard definitions **MUST** use `layout: newspaper` (24-column grid).
- Header banners (`type: text`) must declare `width: 24` and `height: 4` or `5` to prevent vertical scrollbars in Looker.
- Vary tile dimensions dynamically (e.g. KPI cards `6x4`, line trends `16x9`, bar breakdowns `8x9`).
- Filters must be defined in top-level `filters:` block and connected to tiles via `listen:`. Never place `type: date_filter` or `type: field_filter` inside `elements:`.

### LookML Dashboard Syntax with `preferred_slug` (For In-Place Updates)
When updating an existing dashboard, pass `--preferred-slug <memorized_slug>` to the script or place `preferred_slug` under `- dashboard:`:
```yaml
- dashboard: sales_overview
  title: "Sales Overview"
  preferred_slug: "FOnJ8gOG2iXFYsEG2GvMYP"    # Include exact memorized slug for in-place updates
  layout: newspaper
  elements:
    - name: total_revenue
      type: single_value
      ...
```

---

## 4. Execution Instructions for Antigravity 2.0

When triggered to publish or update a UDD, Antigravity 2.0 **MUST** execute `scripts/publish_dashboard_as_udd.sh`:

```bash
# Mode 1: Creating New Dashboard
bash .agents/skills/publish_lookml_dashboard_as_udd/scripts/publish_dashboard_as_udd.sh \
  --lookml-file <path_to_dashboard.lookml> \
  --folder-id <target_folder_id>

# Mode 2: Updating Existing Dashboard In-Place (Pass memorized slug)
bash .agents/skills/publish_lookml_dashboard_as_udd/scripts/publish_dashboard_as_udd.sh \
  --lookml-file <path_to_dashboard.lookml> \
  --folder-id <target_folder_id> \
  --preferred-slug <memorized_slug>

# Mode 3: Clean Project Mode (UDD Only - Deletes LookML file from project after import)
bash .agents/skills/publish_lookml_dashboard_as_udd/scripts/publish_dashboard_as_udd.sh \
  --lookml-file <path_to_dashboard.lookml> \
  --folder-id <target_folder_id> \
  --preferred-slug <memorized_slug> \
  --delete-project-file \
  --project-id <project_id>
```

The command outputs the direct raw Looker REST API response JSON payload. Antigravity 2.0 MUST read `id`, `slug`, `title`, and `url` directly from this output.
If this command fails, **STOP IMMEDIATELY**. Do not write Python or Node scripts. Report the output to the user.
