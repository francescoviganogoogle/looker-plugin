# Data Grids, Geographic Maps, and Donut Multiples Reference

This reference provides syntax and templates for data tables (`looker_grid`), maps (`looker_map`), and pivoted Donut Multiples (`looker_donut_multiples`).

---

## 1. Executive Data Grid (`looker_grid`)

```yaml
- title: "Regional Commercial Performance Matrix"
  name: viz_regional_performance_grid
  type: looker_grid
  model: thelook_ecommerce
  explore: order_items
  fields: [users.state, order_items.count, order_items.total_sale_price, order_items.average_sale_price]
  sorts: [order_items.total_sale_price desc]
  limit: 25
  vis_config:
    type: looker_grid
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
  row: 17
  col: 0
  width: 24
  height: 11
```

---

## 2. Donut Multiples (`looker_donut_multiples`) Mandatory Pivot Rule

`looker_donut_multiples` **REQUIRES at least one pivoted dimension (`pivots: [dimension]`)** or multiple measures. Never use `looker_donut_multiples` with 1 unpivoted dimension + 1 measure!

```yaml
- title: "Customer Status Distribution Across Departments"
  name: viz_dept_status_donut_multiples
  type: looker_donut_multiples
  model: thelook_ecommerce
  explore: order_items
  fields: [products.department, users.status, order_items.count]
  pivots: [products.department]
  sorts: [order_items.count desc 0]
  vis_config:
    type: looker_donut_multiples
    show_legend: true
    series_colors:
      Active: "#34a853"
      Churned: "#ea4335"
  row: 8
  col: 16
  width: 8
  height: 9
```

---

## 3. Geographic Maps (`looker_map`)

Map visualizations **MUST include at least one dimension with `type: location` OR a dimension declaring a LookML `map_layer_name`**:

```yaml
- title: "Geographic Customer Concentration"
  name: viz_customer_map
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
  row: 17
  col: 0
  width: 24
  height: 10
```
