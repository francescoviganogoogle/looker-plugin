# LookML Dashboard Reference Examples & Vis Config Guide

This reference document provides production LookML dashboard YAML templates, visualization configuration choices, highcharts overrides, and multi-tab examples.

---

## 1. Production Multi-Tab LookML Dashboard Example

```yaml
- dashboard: executive_sales_and_digital_performance
  title: "Executive Sales and Digital Performance"
  description: "Executive briefing analyzing commercial revenue performance and web session traffic."
  preferred_viewer: dashboards-next
  layout: newspaper
  crossfilter_enabled: false

  tabs:
    - name: "Executive Sales Overview"
      label: "Executive Sales Overview"
    - name: "Web Traffic & Conversion"
      label: "Web Traffic & Conversion"

  filters:
    - name: date_range
      title: "Date Range"
      type: date_filter
      default_value: "90 days"
      ui_config:
        type: relative_timeframes
        display: inline

    - name: brand
      title: "Brand Name"
      type: field_filter
      model: advanced_ecomm
      explore: order_items
      field: products.brand
      allow_multiple_values: true
      ui_config:
        type: tag_list
        display: popover

  elements:
    # =========================================================================
    # TAB 1: Executive Sales Overview
    # =========================================================================
    - title: "Top-Line Sales Overview Section Header"
      name: header_sales_overview
      type: text
      tab_name: "Executive Sales Overview"
      body_text: |
        <div style='padding: 16px 24px; background: linear-gradient(135deg, #ffffff 0%, #f4f8fe 100%); border-left: 6px solid #1a73e8; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(26,115,232,0.08);'>
          <h2 style='color: #0f172a; margin: 0 0 4px 0; font-size: 20px; font-weight: 700;'>Top-Line Sales Overview</h2>
          <p style='color: #475569; margin: 0; font-size: 13px;'>Track key revenue metrics, order velocity, and overall margin performance.</p>
        </div>
      row: 0
      col: 0
      width: 24
      height: 4

    - title: "Total Revenue ($)"
      name: viz_total_revenue_kpi
      type: single_value
      tab_name: "Executive Sales Overview"
      model: advanced_ecomm
      explore: order_items
      fields: [order_items.total_sale_price]
      listen:
        date_range: order_items.created_date
        brand: products.brand
      row: 4
      col: 0
      width: 8
      height: 4
      vis_config:
        type: single_value
        value_format: "$#,##0"

    - title: "Total Orders"
      name: viz_total_orders_kpi
      type: single_value
      tab_name: "Executive Sales Overview"
      model: advanced_ecomm
      explore: order_items
      fields: [order_items.order_count]
      listen:
        date_range: order_items.created_date
        brand: products.brand
      row: 4
      col: 8
      width: 8
      height: 4

    - title: "Average Order Value ($)"
      name: viz_aov_kpi
      type: single_value
      tab_name: "Executive Sales Overview"
      model: advanced_ecomm
      explore: order_items
      fields: [order_items.average_order_value]
      listen:
        date_range: order_items.created_date
        brand: products.brand
      row: 4
      col: 16
      width: 8
      height: 4

    - title: "Monthly Revenue Trend ($)"
      name: viz_monthly_revenue_trend
      type: looker_line
      tab_name: "Executive Sales Overview"
      model: advanced_ecomm
      explore: order_items
      fields: [order_items.created_month, order_items.total_sale_price]
      sorts: [order_items.created_month asc]
      listen:
        date_range: order_items.created_date
        brand: products.brand
      row: 8
      col: 0
      width: 16
      height: 8

    - title: "Revenue & Order Volume by Product Category"
      name: viz_revenue_and_orders_by_category
      type: looker_column
      tab_name: "Executive Sales Overview"
      model: advanced_ecomm
      explore: order_items
      fields: [products.category, order_items.total_sale_price, order_items.order_count]
      sorts: [order_items.total_sale_price desc]
      limit: 10
      listen:
        date_range: order_items.created_date
        brand: products.brand
      row: 8
      col: 0
      width: 24
      height: 8
      vis_config:
        type: looker_column
        y_axis_combined: false
        show_y_axis_labels: true
        show_x_axis_label: true
        y_axes:
          - label: "Total Revenue ($)"
            orientation: left
            series:
              - id: order_items.total_sale_price
                name: Total Revenue
                axisId: order_items.total_sale_price
          - label: "Order Volume (Count)"
            orientation: right
            series:
              - id: order_items.order_count
                name: Order Volume
                axisId: order_items.order_count
        series_colors:
          order_items.total_sale_price: "#1a73e8"
          order_items.order_count: "#12b5cb"

    # =========================================================================
    # TAB 2: Web Traffic & Conversion
    # =========================================================================
    - title: "Traffic & User Engagement Section Header"
      name: header_traffic_overview
      type: text
      tab_name: "Web Traffic & Conversion"
      body_text: |
        <div style='padding: 16px 24px; background: linear-gradient(135deg, #ffffff 0%, #f4f8fe 100%); border-left: 6px solid #1a73e8; border-radius: 12px;'>
          <h2 style='color: #0f172a; margin: 0 0 4px 0; font-size: 20px; font-weight: 700;'>Traffic &amp; Conversion Performance</h2>
          <p style='color: #475569; margin: 0; font-size: 13px;'>Analyze web visitor volume, conversion rates, and channel acquisition.</p>
        </div>
      row: 0
      col: 0
      width: 24
      height: 4

    - title: "Total Web Sessions"
      name: viz_total_sessions_kpi
      type: single_value
      tab_name: "Web Traffic & Conversion"
      model: thelook
      explore: sessions
      fields: [sessions.count]
      listen:
        date_range: sessions.created_date
      row: 4
      col: 0
      width: 12
      height: 4

    - title: "Session Conversion Rate (%)"
      name: viz_conversion_rate_kpi
      type: single_value
      tab_name: "Web Traffic & Conversion"
      model: thelook
      explore: sessions
      fields: [sessions.conversion_rate]
      listen:
        date_range: sessions.created_date
      row: 4
      col: 12
      width: 12
      height: 4
```

---

## 2. Visualization Configuration Options (`vis_config`)

| Chart Type | `type:` Parameter | Mandatory Field Requirements | Key `vis_config` Parameters |
| :--- | :--- | :--- | :--- |
| **KPI Summary** | `single_value` | 1 Measure | `single_value_title`, `value_format` |
| **Line Trend** | `looker_line` | 1 Date/Time Dimension + $\ge 1$ Measure | `x_axis_gridlines: false`, `show_y_axis_labels: true` |
| **Column / Bar** | `looker_column` / `looker_bar` | 1 Categorical Dimension + $\ge 1$ Measure | `stacking: ""` or `"normal"`, `series_colors: {}` |
| **Area Chart** | `looker_area` | 1 Date/Time Dimension + $\ge 1$ Measure | `stacking: "normal"` |
| **Pie Chart** | `looker_pie` | 1 Unpivoted Dimension + 1 Measure | `value_labels: legend`, `colors: [...]` |
| **Donut Multiples** | `looker_donut_multiples` | 1 Dimension + 1 Pivoted Dimension + 1 Measure (requires `pivots: [dimension]`) or Multiple Measures | `pivots: [dimension]`, `series_colors: {}` (See `dashboards/business_pulse.lookml#L644-L646`) |
| **Data Grid** | `looker_grid` / `table` | $\ge 1$ Dimensions + $\ge 1$ Measures | `show_view_names: false`, `show_row_numbers: true` |

---

## 3. Top-Level Filter Types & UI Configs

```yaml
filters:
  - name: relative_date
    title: "Timeframe"
    type: date_filter
    default_value: "90 days"
    ui_config:
      type: relative_timeframes
      display: inline

  - name: category_picker
    title: "Product Category"
    type: field_filter
    model: advanced_ecomm
    explore: order_items
    field: products.category
    allow_multiple_values: true
    ui_config:
      type: checkboxes
      display: popover
```

---

## 4. Dual-Axis Cartesian Chart Examples (Vertical & Horizontal)

### A. Vertical Dual-Axis Column Chart (`type: looker_column`)
Plots Revenue ($) on Left Axis and Order Count on Right Axis.

```yaml
- title: "Revenue & Orders by Product Category"
  name: viz_revenue_and_orders_by_category
  type: looker_column
  model: thelook
  explore: order_items
  fields: [products.category, order_items.total_sale_price, order_items.order_count]
  sorts: [order_items.total_sale_price desc]
  vis_config:
    type: looker_column
    y_axis_combined: false
    y_axes:
      - label: "Total Revenue ($)"
        orientation: left
        series:
          - id: order_items.total_sale_price
            axisId: order_items.total_sale_price
      - label: "Order Count"
        orientation: right
        series:
          - id: order_items.order_count
            axisId: order_items.order_count
```

### B. Vertical Dual-Axis Line Chart (`type: looker_line`)
Plots Revenue ($) on Left Axis and Gross Margin % on Right Axis.

```yaml
- title: "Monthly Revenue & Gross Margin % Trend"
  name: viz_monthly_revenue_margin_trend
  type: looker_line
  model: thelook
  explore: order_items
  fields: [order_items.created_month, order_items.total_sale_price, order_items.total_gross_margin_percentage]
  sorts: [order_items.created_month asc]
  vis_config:
    type: looker_line
    y_axis_combined: false
    interpolation: monotone
    y_axes:
      - label: "Total Revenue ($)"
        orientation: left
        valueFormat: "$#,##0"
        series:
          - id: order_items.total_sale_price
            axisId: order_items.total_sale_price
      - label: "Gross Margin (%)"
        orientation: right
        valueFormat: "0.0%"
        series:
          - id: order_items.total_gross_margin_percentage
            axisId: order_items.total_gross_margin_percentage
```

### C. Horizontal Dual-Axis Bar Chart (`type: looker_bar`)
Plots Revenue ($) on Bottom Axis and Order Count on Top Axis.

```yaml
- title: "Revenue & Orders by Traffic Source (Horizontal)"
  name: viz_traffic_source_revenue_orders_bar
  type: looker_bar
  model: thelook
  explore: order_items
  fields: [users.traffic_source, order_items.total_sale_price, order_items.order_count]
  sorts: [order_items.total_sale_price desc]
  vis_config:
    type: looker_bar
    y_axis_combined: false
    y_axes:
      - label: "Total Revenue ($)"
        orientation: bottom
        valueFormat: "$#,##0"
        series:
          - id: order_items.total_sale_price
            axisId: order_items.total_sale_price
      - label: "Order Volume (Count)"
        orientation: top
        valueFormat: "#,##0"
        series:
          - id: order_items.order_count
            axisId: order_items.order_count
```

```
