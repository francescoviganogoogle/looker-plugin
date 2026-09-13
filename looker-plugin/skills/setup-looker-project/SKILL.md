---
name: setup-looker-project
description: Configures the current project workspace and global Antigravity environment with the Looker Antigravity Suite. Requires Looker Instance Name or URL as a mandatory parameter (no defaults or fallbacks).
---

# Setup Looker Antigravity Suite

This skill provides an automated workflow to equip your environment and workspace with the complete **Looker Antigravity Suite**.

## Trigger & User Prompts

Triggers when a user says:
- *"Configure this project with Looker Antigravity Suite"*
- *"Setup Looker in this project"*
- *"Install Looker plugin for instance <my-instance>"*

---

## Instructions for Antigravity

1. **Mandatory Input - Request Looker Instance Name or URL**:
   The Looker instance name or URL is a required parametric input.
   If the user has **NOT** explicitly provided their Looker instance name or URL in their prompt (e.g. `mycompany`, `mycompany.looker.com`, or `https://looker.mycompany.com`), you **MUST** ask the user to provide it before executing the setup script.
   
   > ⚠️ **CRITICAL**: Do **NOT** assume, default, or fall back to any hardcoded instance URL.

2. **Execute Setup Automation**:
   Run the setup script targeting the project or global environment:
   ```bash
   bash /path/to/looker-antigravity-suite/skills/setup-looker-project/scripts/setup_project.sh \
     --looker-url "<USER_PROVIDED_INSTANCE_NAME_OR_URL>" \
     [--target-dir .] [--global]
   ```

3. **Confirm & Deliver Results**:
   Provide a clean executive summary confirming that the Looker plugin and global MCP server (`~/.gemini/config/mcp_config.json`) have been configured for the specified instance.
