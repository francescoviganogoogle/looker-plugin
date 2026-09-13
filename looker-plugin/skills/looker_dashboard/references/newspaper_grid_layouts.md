# 24-Column Newspaper Grid Layout Patterns

This reference provides layout patterns and coordinate math for Looker's 24-column newspaper grid (`layout: newspaper`).

---

## 1. Grid Sizing Principles

- **Grid Span**: Every row spans **24 horizontal columns** (`col: 0` to `23`).
- **Row Sum Rule**: The widths of all side-by-side elements in a single row band MUST sum to **exactly 24 columns**.
- **Coordinate System**: Specify `row`, `col`, `width`, and `height` for every element.

---

## 2. Common Row Layout Patterns

### A. Full-Width Text Banner / Section Header Row (24 Cols)
```yaml
- title: "Performance Banner"
  name: sec_header_commercial
  type: text
  body_text: |
    <div style="background: linear-gradient(135deg, #1A365D 0%, #2B6CB0 100%); padding: 20px; border-radius: 8px; color: white;">
      <h2 style="margin: 0; font-size: 22px; font-weight: 700;">Commercial Revenue & Order Trajectory</h2>
      <p style="margin: 6px 0 0 0; opacity: 0.9; font-size: 14px;">Real-time analysis comparing current year performance to prior periods.</p>
    </div>
  row: 0
  col: 0
  width: 24
  height: 4
```

### B. 4-KPI Summary Strip Row (4 x 6 Cols = 24)
```yaml
- title: "Total Revenue"
  name: kpi_revenue
  type: single_value
  row: 4
  col: 0
  width: 6
  height: 4

- title: "Total Orders"
  name: kpi_orders
  type: single_value
  row: 4
  col: 6
  width: 6
  height: 4

- title: "Average Order Value"
  name: kpi_aov
  type: single_value
  row: 4
  col: 12
  width: 6
  height: 4

- title: "Conversion Rate"
  name: kpi_conversion
  type: single_value
  row: 4
  col: 18
  width: 6
  height: 4
```

### C. Asymmetric 2-Viz Row: Centerpiece Trend + Categorical Breakdown (16 + 8 Cols = 24)
```yaml
# Primary Trend Centerpiece (16 Cols)
- title: "Monthly Revenue & Growth Trajectory"
  name: viz_revenue_trend
  type: looker_area
  row: 8
  col: 0
  width: 16
  height: 9

# Secondary Breakdown (8 Cols)
- title: "Revenue by Acquisition Channel"
  name: viz_channel_breakdown
  type: looker_pie
  row: 8
  col: 16
  width: 8
  height: 9
```

### D. Full-Width Deep-Dive Data Table Row (24 Cols)
```yaml
- title: "Regional Commercial Performance Matrix"
  name: viz_regional_grid
  type: looker_grid
  row: 17
  col: 0
  width: 24
  height: 11
```
