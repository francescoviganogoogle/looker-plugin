---
name: looker_mcp_discovery
description: Google ADK skill for discovering Looker Models, Explores, dimensions, measures, and executing analytical queries via Looker MCP.
version: 1.1.0
tags: [runtime_looker_analyst, runtime_looker_dashboard, looker_dashboard, looker, mcp, analytics, query, discovery, adk, schema]
---

# Looker MCP Analytical Discovery & Query Skill (ADK Standard)

When a user asks data analytical questions or requests data exploration, you MUST use the Looker Model Context Protocol (MCP) tools to discover schema metadata and execute queries under the user's OAuth viewer token.

## 1. Schema Discovery Workflow
* **Step 1: Model & Explore Discovery**: If the target model or explore is not explicitly provided, call `get_models` and `get_explores` to discover accessible Looker analytical models and their underlying explores.
* **Step 2: Field Metadata Lookup**: Once a target model and explore are identified, call `get_dimensions` and `get_measures` (or `get_explore_metadata`) to inspect valid fully-qualified field names (e.g., `order_items.status`, `order_items.total_sale_price`).
* **Geographic & Map Layer Inspection**: When inspecting output from `get_dimensions`, check if a dimension has `"map_layer_name": "countries"`, `"map_layer_name": "us_states"`, `"type": "location"`, or represents a geographic entity (e.g., fields named `country`, `state`, `zip`, `city`). When any of these are present, actively select `type: looker_map` for geographic visualization tiles!
* **NEVER guess field names**: Always verify field names against metadata before running analytical queries or designing dashboard tiles.

## 2. Analytical Explanations & Transparency
* When returning query results or designing dashboard tiles, clearly explain to the user the exact dimensions, measures, and filter criteria selected from the Data Dictionary.
* Highlight any interesting trends or anomalies discovered in the data during schema exploration.

## 3. Query Execution & Verification
* **Step 3: Run Analytical Query**: Call `query` with the validated model, explore, fields list, sorts, and optional filters.
* **Row-Level Security Enforcement**: All MCP tool executions must pass the authenticated user's Looker OAuth viewer token (`X-Looker-OAuth-Token`) to guarantee that row-level data permissions are strictly enforced by the Looker backend.
* **No Mocking**: Looker is NEVER mocked up. If tool execution fails due to connection or token errors, halt and instruct the user to authenticate their Looker viewer credentials via OAuth.

## 4. Navigating Hierarchies & Validating Linked Filters (`listens_to_filters`) via Looker MCP
Before configuring Linked / Faceted Filters (`listens_to_filters:`) in a LookML dashboard (`.dashboard.lookml`), you MUST use your Looker MCP discovery tools (`get_dimensions`, `run_inline_query`) to inspect metadata and verify directional validity:
* **Step 1: Check Dimension `type` & `suggestions` via `get_dimensions`**:
  Inspect the dimension metadata returned by `get_dimensions(model, explore)` for the prospective child filter field (`child_field`).
  - **Fatal Exclusions (`type: tier` or static `suggestions: [...]`)**: If the child dimension has `type == "tier"` OR contains explicit static LookML `"suggestions": [...]`, **DO NOT link it as a child in `listens_to_filters:`**. Looker populates tier/static suggestions at compile-time without executing a SQL `SELECT DISTINCT` query, making them un-filterable (`Looker UI disables 'Filters to update when this filter changes' on static/tier fields`).
* **Step 2: Verify `Parent -> Child` Topological Hierarchy (`1:N` Cardinality)**:
  Inspect the entity view grains (`view_name.field_name`) to establish 1-to-Many (`1:N`) directional hierarchy:
  - Parent (`1`-Side / Lookup Entities): Higher-order customer/product dimensions (`users.country`, `users.state`, `users.clv_tier`, `products.department`).
  - Child (`N`-Side / Transaction Entities): Lower-order granular dimensions (`events.traffic_source`, `order_items.status`, `products.brand`, `users.city`).
  - `listens_to_filters:` MUST strictly flow from `Parent -> Child` (`Customer CLV Tier -> Traffic Source`, `Department -> Brand`). NEVER link `Child -> Parent` (`traffic_source_filter` ruling `clv_tier_filter`).
* **Step 3: Empirical Suggestion Verification via `run_inline_query`**:
  If uncertain whether a Parent-to-Child filter relationship works, empirically test it via `run_inline_query`:
  `SELECT DISTINCT child_field FROM explore WHERE parent_field = 'sample_value' LIMIT 5`
  (e.g. `fields: ["users.traffic_source"]`, `filters: {"users.clv_tier": "VIP"}`). If Looker returns narrowed distinct results, the hierarchy is empirically verified!
