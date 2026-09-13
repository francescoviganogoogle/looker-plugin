# Cartesian & Multi-Scale Dual Vertical Axis Chart Reference

This reference provides syntax, query verification examples, and full production templates for Cartesian line, column, area, and bar charts (`looker_line`, `looker_column`, `looker_area`, `looker_bar`).

---

## 1. Empirical Query Verification Protocol

Before synthesizing `.dashboard.lookml` for multi-measure Cartesian charts, verify scale ranges by executing a lightweight analytical check query:

```python
# Tool Call: execute_analytical_query
execute_analytical_query(
    model="thelook_ecommerce",
    explore="order_items",
    dimensions=["order_items.created_month"],
    measures=["order_items.total_sale_price", "order_items.order_count"],
    limit=5
)
```

**Returned Data Inspection**:
- `order_items.total_sale_price`: Max = $450,000
- `order_items.order_count`: Max = 1,150
- Scale Ratio: $450,000 / 1,150 = 391:1$ (Exceeds 5:1 threshold)
- **Conclusion**: Configure Dual Y-Axes with all 6 mandatory parameters (`y_axis_combined: false` + `show_y_axis_labels: true` + `show_y_axis_ticks: true` + `orientation: left/right` + `axisId` + `series_types` + `series_colors`).

---

## 2. Scale-Aware Dual Vertical Axis Production Template

Use dual vertical Y-axes whenever plotting $\ge 2$ measures with different numerical scales or unit types (e.g., Total Revenue $ vs Order Count #, or Revenue $ vs Conversion Rate %):

```yaml
# ✅ CORRECT: Full element context with single-level vis_config
elements:
  - name: viz_revenue_orders_trajectory
    title: "Monthly Revenue & Order Volume Trajectory"
    type: looker_area
    model: thelook_ecommerce
    explore: order_items
    fields: [order_items.created_month, order_items.total_sale_price, order_items.order_count]
    sorts: [order_items.created_month asc]
    y_axis_combined: false       # ⚡ Direct element properties (NEVER wrap in vis_config:)
    show_y_axis_labels: true
    show_y_axis_ticks: true
    show_x_axis_label: true
    x_axis_gridlines: false
    y_axis_gridlines: true
    show_legend: true
    legend_position: bottom
    interpolation: monotone
    show_null_points: false       # ⚡ Suppresses zero-drops for null points
    y_axes:
      - label: "Total Revenue ($)"
        orientation: left
        showLabels: true
        showValues: true
        valueFormat: "$#,##0"
        series:
          - id: order_items.total_sale_price
            name: "Total Sale Price"
            axisId: order_items.total_sale_price # ⚡ MANDATORY double-lock
      - label: "Order Count (#)"
        orientation: right
        showLabels: true
        showValues: true
        valueFormat: "#,##0"
        series:
          - id: order_items.order_count
            name: "Order Count"
            axisId: order_items.order_count      # ⚡ MANDATORY double-lock
    series_types:
      order_items.total_sale_price: area
      order_items.order_count: line
    series_colors:
      order_items.total_sale_price: "#1a73e8"
      order_items.order_count: "#fbbc05"
    row: 8
    col: 0
    width: 16
    height: 9
```

---

## 3. Horizontal Bar Chart Dual Axes (`looker_bar`)

For horizontal bar charts, use `orientation: bottom` (or `left`) for Primary Scale and `orientation: top` (or `right`) for Secondary Scale:

```yaml
elements:
  - name: viz_category_sales_and_margin
    title: "Category Sales and Margin Breakdown"
    type: looker_bar
    model: thelook_ecommerce
    explore: order_items
    fields: [products.category, order_items.total_sale_price, order_items.margin_pct]
    vis_config:
      type: looker_bar
      y_axis_combined: false       # ⚡ Single-level vis_config (NEVER double-nest vis_config:)
      show_y_axis_labels: true
      show_y_axis_ticks: true
      y_axes:
        - label: "Total Sales ($)"
          orientation: bottom
          showLabels: true
          showValues: true
          valueFormat: "$#,##0"
          series:
            - id: order_items.total_sale_price
              name: "Total Sales"
              axisId: order_items.total_sale_price
        - label: "Margin (%)"
          orientation: top
          showLabels: true
          showValues: true
          valueFormat: "0.0%"
          series:
            - id: order_items.margin_pct
              name: "Margin %"
              axisId: order_items.margin_pct
      series_types:
        order_items.total_sale_price: bar
        order_items.margin_pct: line
      series_colors:
        order_items.total_sale_price: "#1a73e8"
        order_items.margin_pct: "#34a853"
```
