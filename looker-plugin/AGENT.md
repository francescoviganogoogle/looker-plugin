# Antigravity Agent Guidelines & Workflow Rules

## 1. Business-First & Non-Technical Communication Rule

### Overview
The user is a business stakeholder and non-technical decision-maker. All communications, summaries, and responses must prioritize business value, clarity, and executive-level summaries, while eliminating technical jargon and low-level implementation details.

### Communication Directives
1. **Focus on Business Value & Outcomes**:
   - Frame all responses around direct business answers, key metrics, insights, and high-level results.
   - Summarize actions in clear, plain language (e.g., "Updated the Sales Performance Dashboard" instead of "Executed POST /api/4.0/dashboards/lookml with Bearer token").

2. **Zero Technical Jargon**:
   - Do **NOT** mention API endpoints, HTTP status codes, JSON payload fields, authentication tokens, SDK methods, bash scripts, or internal file paths unless explicitly requested by the user.
   - Avoid developer terms like "cURL", "SDK", "payload", "endpoints", "tokens", "JSON", "subagent", or "regex".

3. **No Code or Config Dumps**:
   - Never output raw JSON configurations, raw code snippets, API response payloads, or shell commands in user-facing responses.
   - Present data using clean, professional Markdown elements: executive bullet points, summary tables, and high-level charts.

4. **Clickable & Clean Deliverables**:
   - When providing access to dashboards, reports, or artifacts, provide user-friendly clickable links (e.g., `[View Sales Performance Dashboard](https://<instance>/dashboards/<id>)`) without exposing underlying configuration paths or technical query strings.

---

## 2. Mandatory Dashboard Lifecycle & Publishing Prerequisite

When creating or modifying any dashboard in this workspace, the agent **MUST** execute the complete two-stage lifecycle. Creating or saving a `.dashboard.lookml` file alone is **INCOMPLETE** and strictly prohibited as a final deliverable.

### Required Two-Stage Dashboard Workflow:

1. **Stage 1: Declarative Local LookML Creation & Validation**:
   - Construct the dashboard definition locally as a `.dashboard.lookml` file using `layout: newspaper` (24-column grid).
   - Validate the project/LookML definition using `validate_project` or `lookml-diagnostics` to ensure zero syntax or reference errors.

2. **Stage 2: MANDATORY UDD Publishing (REQUIRED)**:
   - **Prerequisite Execution**: Before running `publish_lookml_dashboard_as_udd`, the agent **MUST ensure at least one Looker MCP tool call** (such as `get_models`, `get_explores`, or `validate_project`) has been executed during the session. This guarantees that Antigravity's OAuth session is active and `mcp_oauth_tokens.json` is synced on disk.
   - **Invoke Skill**: Immediately invoke `publish_lookml_dashboard_as_udd` to import/compile the LookML definition into Looker as an interactive, editable User-Defined Dashboard (UDD).
   - *Never stop after Stage 1.* You must execute Stage 2 in the same turn before responding to the user.

3. **In-Place Updates**:
   - Always memorize the `dashboard_id` returned during initial creation and pass `--existing-dashboard-id <id>` on subsequent updates to overwrite the UDD in-place without creating duplicate dashboards.

4. **Deliverable Requirement**:
   - Always provide the user with a clickable link to the published UDD: `[View Interactive Dashboard](https://<instance>/dashboards/<dashboard_id>)`.

---

## 3. Looker Remote MCP Server & Skill Usage Directives

1. **Remote MCP Tool Integration**:
   - Use Looker MCP tools (`get_models`, `get_explores`, `get_dimensions`, `get_measures`, `query_sql`, etc.) to explore data models and verify data accuracy.
   - On initial connection, Antigravity will handle OAuth single sign-on authentication seamlessly.

2. **Parametric Instance Requirement**:
   - Ensure the Looker instance URL/name is provided. If not provided, ask the user before attempting Looker operations.
