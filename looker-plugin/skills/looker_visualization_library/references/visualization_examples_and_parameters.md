# Looker Visualization Examples & Parameter Reference

This reference document contains extended YAML templates, Highcharts overrides, and parameter tables for Looker dashboard visualizations.

---

## 1. Production Visualization Templates

### 1.1 KPI & Single Value Card (`type: single_value`)
```yaml
- title: "Total Revenue (YTD)"
  name: total_revenue_kpi
  type: single_value
  model: thelook_ecommerce
  explore: order_items
  fields: [order_items.total_sale_price, order_items.prior_period_revenue]
  vis_config:
    type: single_value
    show_comparison: true
    comparison_type: change
    comparison_reverse_colors: false
    enable_conditional_formatting: true
    conditional_formatting_include_totals: false
    conditional_formatting_include_nulls: false
  row: 3
  col: 0
  width: 6
  height: 4
```

### 1.2 Multi-Scale Dual-Axis Cartesian Chart (`looker_line` / `looker_column` / `looker_area`)
```yaml
- title: "Monthly Revenue & Order Trajectory"
  name: revenue_orders_trend
  type: looker_area
  model: thelook_ecommerce
  explore: order_items
  fields: [order_items.created_month, order_items.total_sale_price, order_items.order_count]
  sorts: [order_items.created_month asc]
  y_axis_combined: false
  show_y_axis_labels: true
  show_x_axis_label: true
  x_axis_gridlines: false
  y_axis_gridlines: true
  show_legend: true
  legend_position: bottom
  interpolation: linear
  y_axes:
    - label: "Total Revenue ($)"
      orientation: left
      showLabels: true
      showValues: true
      valueFormat: "$#,##0"
      series:
        - id: order_items.total_sale_price
          name: Total Sale Price
          axisId: order_items.total_sale_price
    - label: "Order Count (#)"
      orientation: right
      showLabels: true
      showValues: true
      valueFormat: "#,##0"
      series:
        - id: order_items.order_count
          name: Order Count
          axisId: order_items.order_count
  series_types:
    order_items.total_sale_price: area
    order_items.order_count: line
  row: 7
  col: 0
  width: 16
  height: 9
```

### 1.3 Pie & Donut Multiples (`looker_pie` / `looker_donut_multiples`)
```yaml
- title: "Revenue Breakdown by Acquisition Channel"
  name: channel_revenue_pie
  type: looker_pie
  model: thelook_ecommerce
  explore: order_items
  fields: [users.traffic_source, order_items.total_sale_price]
  sorts: [order_items.total_sale_price desc]
  limit: 8
  inner_radius: 55
  show_legend: true
  legend_position: bottom
  row: 7
  col: 16
  width: 8
  height: 9
```

### 1.4 Executive Data Grid (`looker_grid`)
```yaml
- title: "Regional Commercial Performance Matrix"
  name: regional_performance_grid
  type: looker_grid
  model: thelook_ecommerce
  explore: order_items
  fields: [users.state, order_items.count, order_items.total_sale_price, order_items.average_sale_price]
  sorts: [order_items.total_sale_price desc]
  limit: 25
  vis_config:
    show_view_names: false
    show_row_numbers: true
    show_totals: true
    row_total: right
    series_cell_visualizations:
      order_items.total_sale_price:
        is_active: true
        palette:
          palette_id: default
          collection_id: default
  row: 16
  col: 0
  width: 24
  height: 12
```

### 1.5 Geographic Map (`looker_map`)
```yaml
- title: "Geographic Customer Concentration"
  name: customer_map
  type: looker_map
  model: thelook_ecommerce
  explore: order_items
  fields: [users.location, order_items.total_sale_price]
  vis_config:
    type: looker_map
    map_plot_mode: points
    heatmap_gridlines: false
    heatmap_opacity: 0.5
    point_radius: 5
  row: 16
  col: 0
  width: 24
  height: 10
```

---

## 2. Advanced Chart Config Overrides (`highcharts_config`)

To add plot lines or benchmark thresholds via Highcharts:

```yaml
vis_config:
  type: looker_line
  highcharts_config:
    yAxis:
      plotLines:
        - value: 100000
          color: "#e53e3e"
          width: 2
          dashStyle: "Dash"
          label:
            text: "Target Benchmark ($100k)"
            align: "right"
```


