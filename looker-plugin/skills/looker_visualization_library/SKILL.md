---
name: looker_visualization_library
description: Comprehensive LookML visualization configuration directives, element-scope placement rules, field ordering, and KPI comparison templates for single_value, Cartesian, and grid elements. YOU MUST load this skill via load_skill('looker_visualization_library') whenever building single_value KPIs or dashboard elements.
version: 2.0.0
tags: [runtime_looker_builder, runtime_looker_dashboard, looker_dashboard, looker, visualization, vis_config, lookml, charts, highcharts, dashboard-tiles]
references:
  - references/kpi_and_single_value_examples.md
  - references/cartesian_and_multi_axis_examples.md
  - references/grid_map_and_donut_examples.md
  - references/visualization_examples_and_parameters.md
---

# Looker Visualization Configuration Library (`vis_config` Directives)

This skill provides mandatory visualization directives and `vis_config` parameter guidelines for individual Looker dashboard elements (`.dashboard.lookml` or UDD imports).

---

## 1. Visualization Taxonomy

Select the appropriate visual category based on the analytical question and schema metadata:

| Category | LookML `type:` | Required Fields | Key Design & Configuration Directives |
| :--- | :--- | :--- | :--- |
| **KPI / Single Value** | `single_value` | 1 Measure (+ 1 Year/Date Dimension) | Format `value_format` explicitly (`"$#,##0"`, `"0.0%"`). Place prior-period comparison metrics in `dynamic_fields:` (`offset()`). Place single_value comparison parameters (`show_comparison: true`, `comparison_type: change`, `comparison_label: "vs Prior Year"`, `show_comparison_label: true`) AT ELEMENT LEVEL SCOPE (peer to name:, type:, fields:). |
| **Time Series & Cartesian** | `looker_line`, `looker_area`, `looker_column`, `looker_bar` | 1 Dimension + 1..N Measures | Use `looker_line` / `looker_area` for chronological time-series (sorted asc). Use `looker_column` / `looker_bar` for categorical breakdowns. Always set `show_null_points: false` by default for line/area charts. |
| **Distribution & Proportions** | `looker_pie`, `looker_donut_multiples` | 1 Dimension + 1 Measure (Pie) or Pivot + Measure (Donut Multiples) | Limit slices (`limit: 8`). **Donut Multiples require a pivoted dimension (`pivots:`)** or multiple measures. |
| **Data Grids & Tables** | `looker_grid` | 1..N Dimensions + 1..N Measures | Enable `show_totals: true` and `row_total: right` for executive data tables. |
| **Geographic Maps** | `looker_map`, `looker_google_map` | 1 Location Dimension OR `map_layer_name` | **Mandatory**: Requires a dimension with `type: location` or a view dimension declaring a map layer (e.g. `us_states`). |
| **Section & Context Banners** | `text` | N/A (`body_text` HTML) | Full width banner at `row: 0, width: 24, height: 4` (or `height: 5` for multi-line subtitles). Use clean, responsive HTML containers. Never use `height: 2` or `3` for rich HTML banners. |

---

## 2. Scale-Aware & Empirical Dual Vertical Axes (`y_axes`)

Whenever any Cartesian chart (`looker_line`, `looker_column`, `looker_area`, `looker_bar`) visualizes $\ge 2$ measures (`fields:` contains $\ge 2$ measures), evaluate whether dual vertical Y-axes are required:

1. **Scale Evaluation Protocol**:
   - **Static Unit Disparity**: If measure unit types differ ($ vs # vs %, e.g., `total_sale_price` and `order_count`, or `revenue` and `margin_rate`), use dual vertical Y-axes.
   - **Empirical Scale Inspection**: If measures share similar units (e.g., `$500,000` Gross Sales vs `$250` Average Item Price), execute `execute_analytical_query(model, explore, dimensions, measures, limit=10)` to check magnitude ranges. If the scale ratio ($\text{Max A} / \text{Max B}$) exceeds 5:1, use dual Y-axes.
2. **Canonical Dual-Axis LookML Directives**:
   - Set `y_axis_combined: false` to split series onto separate Y-axes.
   - Set `show_y_axis_labels: true` and `show_y_axis_ticks: true`.
   - Provide `y_axes:` array with left (`orientation: left`) and right (`orientation: right`) axis objects, mapping each metric via `series: [{id: "field_name", name: "Label", axisId: "field_name"}]`.
   - Specify `series_types:` (e.g. `column` for primary, `line` for secondary) and distinct `series_colors:`.

```yaml
# ✅ CORRECT: Canonical Dual Y-Axis Element Structure (Declarative LookML)
elements:
  - name: viz_orders_and_revenue_by_product_category
    title: "Orders and Revenue by Product Category"
    type: looker_column
    model: thelook
    explore: order_items
    fields: [products.category, order_items.order_count, order_items.total_sale_price]
    sorts: [order_items.order_count desc 0]
    y_axis_combined: false # Split secondary metric onto right Y-axis
    show_y_axis_labels: true
    show_y_axis_ticks: true
    y_axes:
      - label: "Total Revenue ($)"
        orientation: left
        showLabels: true
        showValues: true
        valueFormat: "$#,##0"
        series:
          - id: order_items.total_sale_price
            name: "Total Revenue ($)"
            axisId: order_items.total_sale_price
      - label: "Total Orders (#)"
        orientation: right
        showLabels: true
        showValues: true
        valueFormat: "#,##0"
        series:
          - id: order_items.order_count
            name: "Total Orders (#)"
            axisId: order_items.order_count
    series_types:
      order_items.total_sale_price: column
      order_items.order_count: line
    series_colors:
      order_items.total_sale_price: "#3b82f6"
      order_items.order_count: "#f59e0b"
```

---

## 3. Chart Series Coloring (No HTML Font Tags in Views)

**CRITICAL RULE**: To color chart lines, bars, columns, or pie slices, **NEVER add LookML `html: <font color="red">` tags inside view dimension definitions**. HTML tags in view files only format tabular data cells and are completely ignored by chart visualization engines.

Apply series colors inside `vis_config:`:

1. **`series_colors` (Key-to-Hex Mapping)**:
   - Measures: `order_items.total_sale_price: "#1a73e8"`
   - Pivots: `"Female - order_items.count": "#e91e63"`
   - Pie Slices: `"Chrome": "#4285f4"`
2. **`colors` (Sequential Palette Array)**:
   - Provide a harmonious palette array: `colors: ["#1a73e8", "#34a853", "#fbbc05", "#ea4335"]`
3. **WCAG Compliance**: Ensure text banners and chart elements maintain high contrast against their background. Avoid overly rigid, forced hex codes—prefer cohesive, curated color schemes.

---

## 4. Parameter Quick Reference (`param-lookml-dashboard-element`)

### 4.1 Cartesian Chart Parameters (`looker_line`, `looker_area`, `looker_column`, `looker_bar`)

| Parameter | Type / Valid Values | Behavioral Description |
| :--- | :--- | :--- |
| **`stacking`** | `""` (unstacked), `"normal"`, `"percent"` | Controls whether multi-series bars/areas stack vertically, stack 100% proportionally, or cluster side-by-side. |
| **`show_value_labels`** | `true`, `false` | Renders numerical labels directly above/inside chart data points or bars. |
| **`label_density`** | Integer (`1` to `100`, default `25`) | Controls density of labels displayed when data points overlap on dense charts. |
| **`legend_position`** | `"bottom"`, `"top"`, `"left"`, `"right"` | Determines where the chart legend is placed relative to the plot area. |
| **`interpolation`** | `"linear"`, `"monotone"`, `"step"` | Line/area smoothing curve algorithm (`monotone` provides polished curved lines). |
| **`show_null_points`** | `true`, `false` | When set to `false`, prevents plotting gaps or zero-drops for missing (`NULL`) time-series entries. |
| **`x_axis_scale`** | `"auto"`, `"ordinal"`, `"time"` | Controls horizontal axis scaling behavior (categorical sequence vs continuous time progression). |
| **`y_axis_combined`** | `true`, `false` | Set to `false` for multi-scale metric charts to split onto independent `left` and `right` axes. |
| **`y_axes`** | Array of Axis objects (`orientation`, `label`, `valueFormat`, `series`) | Explicitly configures left/right scales and locks individual series using `axisId: <field_name>`. |

### 4.2 Grid & Table Parameters (`looker_grid`, `table`)

| Parameter | Type / Valid Values | Behavioral Description |
| :--- | :--- | :--- |
| **`show_row_numbers`** | `true`, `false` | Displays 1-indexed line numbers on the left edge of the grid. |
| **`show_totals`** / `row_total` | `true` / `"right"` | Renders summary column totals at bottom and horizontal row totals on the right. |
| **`enable_conditional_formatting`** | `true`, `false` | Activates Looker conditional formatting rules for highlight bands. |
| **`conditional_formatting`** | Array of Rules (`type`, `value`, `background_color`, `font_color`) | Enclose `type` in double quotes matching Looker UI strings (`type: "greater than"`, `type: "along a scale..."`). |

### 4.3 Single Value & KPI Comparison Parameters (`single_value`)

| Parameter | Scope / Location | Valid Values | Behavioral Description |
| :--- | :--- | :--- | :--- |
| **`show_comparison`** | **Element Root Scope** & `vis_config:` | `true`, `false` | **Mandatory at Element Root Scope**: Populates top-level `result_maker.vis_config.show_comparison = true` required by Looker UI to render growth badges. |
| **`comparison_type`** | **Element Root Scope** & `vis_config:` | `"change"`, `"value"`, `"progress_percentage"` | Specifies delta calculation type (`change` = % or abs delta; `value` = previous value; `progress_percentage` = goal %). |
| **`show_comparison_label`** | **Element Root Scope** & `vis_config:` | `true`, `false` | Enables/disables display of the comparison label text underneath the single value. |
| **`comparison_label`** | **Element Root Scope** & `vis_config:` | String (e.g. `"vs Prior Year"`) | Custom subtitle text displayed alongside the comparison percentage/delta. |
| **`comparison_reverse_colors`** | **Element Root Scope** & `vis_config:` | `true`, `false` | Optional: Reverses color scale (green for decrease, red for increase) for inverse metrics like churn or latency. |
| **`hidden_fields`** | **Element Root Scope** & `vis_config:` | Array of field names (`[order_items.created_year]`) | Hides secondary date dimensions or reference measures from primary tile display. |

---

## 5. Extended Reference Documentation

For full copy-pasteable YAML templates, single_value KPI templates, Highcharts JSON overrides (`highcharts_config`), see the reference documents:
- **`references/kpi_and_single_value_examples.md`**: Complete examples for percentage growth, previous period raw value, progress against target, and reversed color metrics.
- **`references/cartesian_and_multi_axis_examples.md`**: Multi-axis Cartesian chart templates.
- **`references/grid_map_and_donut_examples.md`**: Data grids, map layers, and pivoted donut multiples.
- **`references/visualization_examples_and_parameters.md`**: Advanced visualization parameters reference.


