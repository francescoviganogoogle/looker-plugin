- dashboard: sales_performance_overview
  title: "Sales Performance Overview"
  layout: newspaper
  preferred_viewer: dashboards-next
  crossfilter_enabled: true

  tabs:
    - name: overview
      label: "Executive Overview"

  filters:
    - name: date_range
      title: "Date Range"
      type: date_filter
      default_value: "last 90 days"
      ui_config:
        type: relative_timeframes
        display: inline

  elements:
    - name: header_tile
      type: text
      tab_name: overview
      body_text: |
        <div style='padding: 16px; background: linear-gradient(135deg, #ffffff 0%, #f4f8fe 100%); border: 1px solid #d2e3fc; border-radius: 12px;'>
          <h2 style='color: #1a73e8; margin: 0;'>Sales Performance Overview</h2>
          <p style='color: #5f6368; margin: 4px 0 0 0;'>Executive dashboard detailing revenue, order counts, and geographic distributions.</p>
        </div>
      row: 0
      col: 0
      width: 24
      height: 4

    - title: "Total Revenue"
      name: total_revenue_kpi
      model: ecommerce
      explore: orders
      type: single_value
      fields: [orders.total_revenue]
      listen:
        date_range: orders.created_date
      tab_name: overview
      row: 4
      col: 0
      width: 6
      height: 4

    - title: "Total Orders"
      name: total_orders_kpi
      model: ecommerce
      explore: orders
      type: single_value
      fields: [orders.count]
      listen:
        date_range: orders.created_date
      tab_name: overview
      row: 4
      col: 6
      width: 6
      height: 4

    - title: "Revenue Trend"
      name: revenue_trend_line
      model: ecommerce
      explore: orders
      type: looker_line
      fields: [orders.created_date, orders.total_revenue]
      sorts: [orders.created_date]
      listen:
        date_range: orders.created_date
      tab_name: overview
      row: 8
      col: 0
      width: 16
      height: 9

    - title: "Top Countries Breakdown"
      name: top_countries_bar
      model: ecommerce
      explore: orders
      type: looker_bar
      fields: [users.country, orders.total_revenue]
      sorts: [orders.total_revenue desc]
      limit: 10
      listen:
        date_range: orders.created_date
      tab_name: overview
      row: 8
      col: 16
      width: 8
      height: 9
