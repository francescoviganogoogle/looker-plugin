# Looker Development Best Practices & Workflow Rules

When working on LookML models, dashboards, and queries in this workspace:

1. **Declarative Dashboard First**: Always construct visual dashboard layouts using LookML dashboard files (`.dashboard.lookml`) with `layout: newspaper` (24-column grid).
2. **Validation First**: Always run `validate_project` or consult `lookml-diagnostics` before publishing or committing LookML code.
3. **MANDATORY Publishing as UDD**: Creating a `.dashboard.lookml` file alone is incomplete. Agents **MUST** execute the `publish_lookml_dashboard_as_udd` skill (`publish_dashboard_as_udd.sh`) to import the LookML dashboard into Looker as an interactive, editable User Defined Dashboard (UDD).
4. **Publishing Prerequisite**: Before calling `publish_lookml_dashboard_as_udd`, the agent **MUST** ensure at least one Looker MCP tool call (e.g., `get_models`, `get_explores`, or `validate_project`) has been executed during the session to guarantee active OAuth session token sync.
5. **In-Place Overwrites**: Always memorize the `dashboard_id` returned during creation and pass `--existing-dashboard-id <id>` on subsequent updates to overwrite in-place.
6. **Project Cleanliness Option**: If the user asks for UDD-only mode, pass `--delete-project-file --project-id <project_id>` to delete the LookML dashboard file from the LookML project repository after import.
7. **STRICT PROHIBITION ON WORKAROUND CODE**: If `publish_dashboard_as_udd.sh` or any skill command fails, the agent **MUST NOT** attempt to write custom Python (`publish.py`), Node (`publish.js`), JavaScript, or cURL workaround scripts in the workspace, nor attempt to edit plugin bash scripts.
8. **STOP EXECUTION ON FAILURE**: If a skill command fails, stop execution immediately, report the exact error to the user, and ask for instructions.
9. **Interactive Deliverable**: Always provide the user with the final clickable UDD link (`https://<instance>/dashboards/<id>`).
