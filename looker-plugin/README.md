# 📊 Looker Antigravity Suite Plugin

[![Antigravity 2.0](https://img.shields.io/badge/Google%20Antigravity-2.0-4285F4?logo=google&logoColor=white)](https://cloud.google.com)
[![Looker MCP](https://img.shields.io/badge/Looker-MCP%202.0-0052CC?logo=looker&logoColor=white)](https://looker.com)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

An all-in-one **Antigravity Plugin** for Looker developers and data teams. Bundles custom **Skills**, **Rules**, **Automated UDD Publishing Scripts**, and **Global Remote MCP Server Configuration** into a single deployable unit for Google Antigravity (AGY) and Antigravity 2.0.

---

## 🚀 Key Features

- **🌐 Global Looker MCP Server Integration**: Connects Antigravity directly to your Looker instance via OAuth 2.0 (`looker-antigravity-2.0`).
- **📊 Automated LookML Dashboard Publishing**: Compiles `.dashboard.lookml` files and publishes or updates them as interactive **User-Defined Dashboards (UDDs)** directly in Looker via REST API (v4.1.0 supports in-place updates via `--preferred-slug`).
- **📐 24-Column Newspaper Grid Layout Engine**: Standardized LookML dashboard syntax for multi-tab architectures, header banners, single_value KPI cards, Cartesian charts, and filter mapping.
- **🧮 Table Calculations & Looker Expression Engine**: Null-safe relative percentage growth formulas (`if(offset(x, 1) = 0, null, (x - offset(x, 1)) / offset(x, 1))`), window calculations, and dynamic fields.
- **⚡ Strict Parametric Setup**: Guarantees zero hardcoded URLs or fallback assumptions—requires explicit instance parameterization (`mycompany`, `company.looker.com`, or `https://looker.company.com`).
- **🩺 Comprehensive LookML Diagnostics**: Built-in error catalog and diagnostic skills for resolving LookML validation errors.
- **📐 LookML Modeling Best Practices**: Embedded guidelines for Period-over-Period (PoP) analysis, PDT performance, Liquid templating, and Explore/View architecture.

---

## 📦 Plugin Contents (12 Skills Included)

```
looker-plugin/
├── AGENT.md                                      # Antigravity agent guidelines & communication rules
├── WORKFLOW.md                                   # Detailed setup & onboarding guide
├── install.sh                                    # Parametric global installer script
├── plugin.json                                   # Plugin metadata
├── mcp_config.json                               # Global MCP server template
├── rules/
│   └── looker-development-rules.md               # LookML development & dashboard lifecycle rules
└── skills/
    ├── setup-looker-project/                     # Workspace & global MCP initializer
    ├── get-looker-mcp-token/                     # OAuth token retrieval & auto-refresh
    ├── publish_lookml_dashboard_as_udd/          # Direct LookML -> UDD publishing automation (v4.1.0)
    ├── looker_dashboard/                         # 24-column newspaper grid layout & tab architecture
    ├── looker_visualization_library/             # KPI single_value, Cartesian, and grid chart templates
    ├── looker_mcp_discovery/                     # Model, Explore, dimension & measure discovery via MCP
    ├── lookml_calculations_and_table_calcs/      # Table calculations, Lexp formulas, & YoY % growth
    ├── lookml-diagnostics/                       # LookML error catalog & diagnostic guide
    ├── lookml-modeling-guidelines/               # Architecture, Explores, and View design rules
    ├── lookml-pdt-guidelines/                    # Persistent Derived Table optimization
    ├── lookml-pop-guidelines/                    # Period-over-Period (YoY, MoM, QoQ) patterns
    └── lookml-liquid-guidelines/                 # Liquid templates and dynamic filters
```

---

## ⚡ Quick Start & Installation

> [!IMPORTANT]
> The setup scripts require your **Looker Instance Name or URL** as a mandatory argument. No default instances or fallbacks are assumed.

### 1. Global Installation (Antigravity 2.0)

To install the plugin globally across all Antigravity workspaces and configure the global MCP server in `~/.gemini/config/mcp_config.json`:

```bash
cd looker-plugin/looker-plugin
./install.sh --looker-url <YOUR_INSTANCE_NAME_OR_URL>
```

**Examples:**
```bash
# Using instance name shorthand
./install.sh --looker-url mycompany

# Using full custom URL
./install.sh --looker-url https://looker.mycompany.com
```

### 2. Workspace Initialization

To configure a specific local project directory with the Looker plugin suite and `AGENT.md` rules, just ask Antigravity 2.0 to install the plugin using a prompt like:

```
First install and configure the Looker plugin stored in PLUGIN_FOLDER for instance YOUR_INSTANCE
```

As an alternative:

```bash
bash looker-plugin/skills/setup-looker-project/scripts/setup_project.sh \
  --looker-url <YOUR_INSTANCE_NAME_OR_URL> \
  --target-dir .
```

---

## 🛠️ Usage & Example Prompts

Once installed, restart Antigravity 2.0. You can interact with Looker using natural prompts:

| Goal / Action | Example Prompt | Active Skill / Tool |
| :--- | :--- | :--- |
| **Configure Workspace** | *"Configure this project with the Looker plugin for instance mycompany"* | `setup-looker-project` |
| **Explore Data Models** | *"Show me all available dimensions and measures in the sales Explore"* | `looker_mcp_discovery` / MCP |
| **Design Newspaper Dashboard** | *"Build a 2-tab sales analysis LookML dashboard with 24-column grid layout"* | `looker_dashboard` |
| **KPI & Chart Styling** | *"Configure YoY single_value KPI cards and dual-axis line/bar charts"* | `looker_visualization_library` |
| **Table Calculations** | *"Add null-safe YoY percentage growth table calculations for revenue"* | `lookml_calculations_and_table_calcs` |
| **Diagnose LookML Errors** | *"Fix the LookML validation error in order_items.view.lkml"* | `lookml-diagnostics` |
| **Publish / Update UDD** | *"Publish sales_overview.dashboard.lookml as a UDD in folder 123"* | `publish_lookml_dashboard_as_udd` |
| **In-Place UDD Update** | *"Update dashboard 108 in-place using preferred slug FOnJ8gOG2iXFYsEG2GvMYP"* | `publish_lookml_dashboard_as_udd` |
| **Implement YoY / MoM** | *"Add Period-over-Period analysis for revenue in the orders view"* | `lookml-pop-guidelines` |
| **Optimize PDT** | *"Convert user_facts to a Persistent Derived Table with datagroup caching"* | `lookml-pdt-guidelines` |

---

## 📊 Dashboard Publishing Workflow (UDD)

The plugin provides a direct shell workflow (`publish_dashboard_as_udd.sh`) to turn declarative LookML dashboard definitions into live, interactive Looker UDDs:

```bash
# Initial Publish (Creates new UDD)
bash looker-plugin/skills/publish_lookml_dashboard_as_udd/scripts/publish_dashboard_as_udd.sh \
  --lookml-file ./dashboards/sales_overview.dashboard.lookml \
  --folder-id 123

# In-Place Update (Updates existing UDD in-place using memorized slug)
bash looker-plugin/skills/publish_lookml_dashboard_as_udd/scripts/publish_dashboard_as_udd.sh \
  --lookml-file ./dashboards/sales_overview.dashboard.lookml \
  --folder-id 123 \
  --preferred-slug FOnJ8gOG2iXFYsEG2GvMYP
```

1. **OAuth Authentication**: Automatically syncs or retrieves the active Looker MCP token (`get_mcp_token.sh`).
2. **REST API Direct Import**: Posts the LookML payload to Looker REST API (`/api/4.0/dashboards/lookml`).
3. **Automated Slug In-Place Updates**: Version 4.1.0 auto-injects `--preferred-slug` into the LookML header and JSON body, preventing duplicate dashboard creations during iterative updates.

---

## 🔒 Authentication & Security

- **OAuth 2.0**: Authenticates securely against Looker's remote MCP endpoint using standard PKCE flow.
- **Single Sign-On (SSO)**: Prompts for standard user login in your browser on first tool call.
- **Token Auto-Refresh**: Handled seamlessly by `get-looker-mcp-token` skill without storing cleartext passwords.

Before authenticating with MCP make sure you (or your Looker admin) have configured an OAuth client named `antigravity` as follows:

```json
{
  "redirect_uri": "https://antigravity.google/oauth-callback", 
  "display_name": "antigravity",
  "description": "antigravity",
  "enabled": true
}
```

---

## 📄 License

Distributed under the Apache 2.0 License.
