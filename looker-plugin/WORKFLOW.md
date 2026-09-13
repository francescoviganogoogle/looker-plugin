# Looker Antigravity Plugin: Setup & Onboarding Workflow

This guide walks you through setting up the **Looker Antigravity Suite Plugin**, verifying all required components, and connecting Antigravity 2.0 to your Looker analytics platform via global MCP server configuration.

---

## ⚡ Strictly Parametric Setup (No Defaults / No Fallbacks)

The plugin requires your **Looker Instance Name or URL** as a **mandatory input parameter**. 
- There are **no hardcoded fallbacks or default URLs**.
- If the Looker instance is not provided in your prompt or CLI arguments, you will be prompted to enter it.
- Flexible input formats are supported and automatically normalized:
  - Shorthand name: `mycompany` ➔ `https://mycompany.looker.com/mcp`
  - Full domain: `company.looker.com` ➔ `https://company.looker.com/mcp`
  - Custom domain: `https://looker.company.com` ➔ `https://looker.company.com/mcp`

---

## 💡 Model Context Protocol (MCP) in Antigravity 2.0

In **Antigravity 2.0**, MCP servers are defined globally in `~/.gemini/config/mcp_config.json`. Global MCP servers connect Google Antigravity directly to your Looker platform across all workspaces, enabling Antigravity to:
- Explore data models and business measures.
- Validate LookML code changes automatically.
- Generate and update interactive business dashboards.
- Run queries and verify data accuracy—all within a secure, authenticated session.

---

## 📋 Prerequisite Checklist

### 1. Platform & Environment Requirements
- [x] **Antigravity 2.0**: Installed and active.
- [x] **Looker Instance Name / URL**: Provided as a required parameter (e.g., `mycompany` or `https://looker.mycompany.com`).

### 2. Terminal Utilities Requirement
The publishing script uses pure shell script (`bash`) and `curl` for HTTP communication:
- [x] **`curl`**: HTTPS REST API communication.
- [x] **`bash`**: Shell execution environment.
- [x] **`grep` / `sed` / `cut` / `awk`**: Auto-discovery of credentials and payload formatting.

---

## 🛠️ Step-by-Step Global Installation Workflow

### Step 1: Run Parametric Global Installer
Run `install.sh` from the plugin directory, passing your mandatory Looker instance name or URL:

```bash
cd looker-antigravity-suite
./install.sh --looker-url <YOUR_INSTANCE_NAME_OR_URL>
```

*Example:*
```bash
./install.sh --looker-url mycompany
```
*or*
```bash
./install.sh --looker-url https://looker.company.com
```

---

### Step 2: Verify Global MCP Configuration
Verify that `~/.gemini/config/mcp_config.json` contains your configured Looker remote MCP server definition:

```json
{
  "mcpServers": {
    "looker-antigravity-2.0": {
      "serverUrl": "https://your-instance.looker.com/mcp",
      "oauth": {
        "clientId": "antigravity"
      }
    }
  }
}
```

---

### Step 3: Connect & Authenticate in Antigravity 2.0
1. Launch or restart **Antigravity 2.0**.
2. Antigravity will automatically load the global MCP server `looker-antigravity-2.0`.
3. When you prompt Antigravity to perform a Looker action (e.g., *"Show available models"* or *"Publish sales dashboard"*), Antigravity will initiate an **OAuth single sign-on prompt**.
4. Log in with your standard Looker account credentials in the popup browser window to authorize access.
