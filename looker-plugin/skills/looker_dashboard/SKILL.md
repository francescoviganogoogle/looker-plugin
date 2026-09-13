---
name: looker_dashboard
description: Core architecture and layout specification for LookML dashboards (.dashboard.lookml). Enforces 24-column newspaper grid layout, root declarations, top-level tabs, filters syntax, element grid positioning, and tile listening.
version: 2.2.0
tags: [runtime_looker_builder, runtime_looker_dashboard, looker_dashboard, lookml, dashboard, newspaper-grid, layout, visual-hierarchy, filters]
references:
  - references/newspaper_grid_layouts.md
  - references/lookml_dashboard_filters_reference.md
  - references/lookml_dashboard_examples.md
---

# Skill: LookML Dashboard Architecture & Layout Rules

This skill establishes mandatory top-level dashboard declarations, 24-column newspaper grid rules, tabs architecture, top-level filter declarations, and tile listening parameters for generating valid LookML dashboards (`.dashboard.lookml`).

---

## 1. Core Root Parameters Syntax

Every LookML dashboard MUST declare layout and viewer options at the root level using generic schema parameters:

```yaml
- dashboard: <dashboard_slug_identifier>
  title: "<Human_Readable_Dashboard_Title>"
  description: "<Executive_summary_of_dashboard_objectives>"
  preferred_viewer: dashboards-next
  layout: newspaper
  crossfilter_enabled: false   # Set true ONLY if all tiles query the exact same Explore
  filters_bar_collapsed: false # Optional: default false
  filters_location_top: true   # Optional: default true
```

### Core Directives:
1. **`layout: newspaper`**: Mandatory 24-column grid (`col: 0` to `23`). Every element MUST specify `row`, `col`, `width`, and `height` coordinates.
2. **`crossfilter_enabled: false`**: Set `crossfilter_enabled: true` ONLY if ALL tiles query the exact same Explore. If tiles span multiple Explores, set `crossfilter_enabled: false` to prevent cross-filter errors.
3. **Element Slugs & Titles**: Every element MUST declare a unique identifier `- name: <element_slug_id>` AND a human-readable display `title: "<Visual_Display_Title>"`.

---

## 2. 24-Column Newspaper Grid Layout

Design dashboards with structured visual hierarchy across the 24-column grid:

| Tile Type | Width (`width:`) | Height (`height:`) | Grid Positioning & Rules |
| :--- | :--- | :--- | :--- |
| **Section Header Card** (`type: text`) | `24` | `4` or `5` | Full width banner at row start (`col: 0`). Use `height: 4` or `5` for clean text rendering. |
| **KPI Summary Card** (`type: single_value`) | `6` or `8` | `4` | Horizontal KPI strip, spanning full row width (e.g. 4x6=24 or 3x8=24). |
| **Trend Chart** (`type: looker_line` / `looker_area`) | `16` or `24` | `8` or `9` | Centerpiece visual. Place alongside secondary breakdown charts. |
| **Breakdown** (`type: looker_column` / `looker_bar`) | `8` or `12` | `8` | Categorical breakdown next to primary trend. |
| **Deep-Dive Data Table** (`type: looker_grid`) | `24` | `10` or `12` | Full width deep-dive table at bottom of section. |

---

## 3. Tabs Architecture (`tabs:`)

Define tabs at the root level of multi-tab dashboards. Both `name:` and `label:` MUST match the exact human-readable tab title:

```yaml
tabs:
  - name: "<Tab_1_Title>"
    label: "<Tab_1_Title>"
  - name: "<Tab_2_Title>"
    label: "<Tab_2_Title>"
```

- **Element Binding**: Every element inside a multi-tab dashboard MUST declare its target tab via `tab_name: "<Tab_1_Title>"`.

---

## 4. Top-Level Filters (`filters:`) & Tile Listening (`listen:`) Syntax

Filters are top-level entities defined in the `filters:` block at the dashboard root level. NEVER place `type: date_filter` or `type: field_filter` inside `elements:`.

### A. Dashboard Filter Parameter Reference (`filters:`)

```yaml
filters:
  - name: <filter_name>
    title: "<Filter_Display_Title>"
    type: field_filter | number_filter | date_filter | string_filter
    model: <model_name>           # Required when type: field_filter
    explore: <explore_name>       # Required when type: field_filter
    field: <view_name>.<field_name>  # Required when type: field_filter
    default_value: "<default_filter_expression>" # Optional, e.g. "90 days", "Complete"
    allow_multiple_values: true | false          # Default: true
    required: true | false                       # Default: false
    ui_config:                                   # Optional control styling
      type: button_group | button_toggles | radio_buttons | checkboxes | dropdown_menu | day_picker | day_range_picker | date_time_picker | relative_timeframes | time_range | range_slider | slider | advanced
      display: inline | popover | overflow
      options:
        - "<option_1>"
        - "<option_2>"
    listens_to_filters:                          # Optional cascading filter dependency
      - <parent_filter_name>
```

### B. Filter Types Overview

1. **`field_filter`**: Default choice when associated with an underlying field (`model`, `explore`, and `field` required). Automatically pulls filter suggestions from string fields.
2. **`date_filter`**: Accepts date ranges or relative timeframe expressions (e.g. `"90 days"`, `"last month"`).
3. **`number_filter`**: Accepts numerical values or ranges (e.g. `"50 to 100"`, `"> 10"`).
4. **`string_filter`**: Accepts freeform string text inputs.

### C. Tile Listening Syntax (`listen:`)

Data tiles in `elements:` connect to top-level filters via the `listen:` block, mapping the local filter name `<filter_name>` to the target view field `<view_name>.<field_name>`:

```yaml
elements:
  - name: <element_name>
    title: "<Element_Display_Title>"
    type: single_value | looker_line | looker_column | looker_bar | looker_area | looker_grid
    model: <model_name>
    explore: <explore_name>
    fields: [<view_name>.<field_name_1>, <view_name>.<field_name_2>]
    listen:
      <filter_name_1>: <view_name>.<field_name_1>
      <filter_name_2>: <view_name>.<field_name_2>
    row: 0
    col: 0
    width: 12
    height: 8
```

---

## 5. Visualization Directives Delegation & Examples

For visualization configuration directives (`vis_config`, scale-aware dual Y-axes, `series_colors`, series types, Donut Multiples pivot constraints), refer exclusively to:
- **`looker_visualization_library` skill** (the canonical visualization reference).

For exhaustive documentation and reference examples, use `view_file` on:
- **`references/lookml_dashboard_filters_reference.md`**: Complete parameter reference guide for dashboard filters, all `ui_config` control types (`button_group`, `checkboxes`, `tag_list`, `range_slider`, `dropdown_menu`, `relative_timeframes`, etc.), placement modes (`inline`, `popover`, `overflow`), cascading filter dependencies (`listens_to_filters`), and merged query tile listening.
- **`references/newspaper_grid_layouts.md`**: Grid coordinate patterns, column math, and section sizing.
- **`references/lookml_dashboard_examples.md`**: Multi-tab LookML dashboard templates.

