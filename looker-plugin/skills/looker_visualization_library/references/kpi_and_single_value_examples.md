# KPI & Single Value Card Configuration Reference (`type: single_value`)

This reference provides canonical, production-ready LookML templates and guidelines for configuring executive KPI tiles (`type: single_value`) with prior-period comparison deltas, growth badges, and conditional formatting.

---

## 1. CRITICAL: Element-Scope Placement vs `vis_config:` Nesting

> [!IMPORTANT]
> **LOOKML COMPILER RULE**: Looker's LookML API compiler (`POST /api/4.0/dashboards/lookml`) parses properties declared at the **element root scope** (as peer keys to `name:`, `title:`, `fields:`, `vis_config:`) into the top level of `result_maker.vis_config`.
> 
> * **Element Root Scope (REQUIRED)**: Declaring `show_comparison: true`, `comparison_type: change`, `show_comparison_label: true`, `comparison_label: "vs Prior Year"`, and `hidden_fields: [...]` at element scope populates top-level `result_maker.vis_config.show_comparison = true`. This is **mandatory** for Looker's `Dashboards-Next` frontend to render the comparison growth badge.
> * **Inner `vis_config:` Scope**: If comparison directives are placed ONLY inside `vis_config:`, Looker nests them in `result_maker.vis_config.vis_config`, leaving top-level `show_comparison` as `None`, which suppresses all comparison badges in the UI.
> * **Best Practice**: Declare comparison keys at BOTH the element root scope AND inside `vis_config:` to guarantee complete UI and API compatibility.

---

## 2. Production KPI Templates for All Comparison Types

### Template A: Percentage Growth / Delta Change (`comparison_type: change`)

Use when displaying percentage growth or delta change relative to the prior period (e.g. YoY or MoM sales growth).

```yaml
- name: kpi_total_revenue
  title: "Total Sales Revenue"
  type: single_value
  model: thelook
  explore: order_items
  fields: [order_items.total_sale_price, order_items.created_year]
  fill_fields: [order_items.created_year]
  filters:
    order_items.created_year: "2 years"
  sorts: [order_items.created_year desc]
  limit: 500
  dynamic_fields:
    - table_calculation: percent_change
      label: "Percent Change"
      expression: "if(offset(${order_items.total_sale_price}, 1) = 0, null, (${order_items.total_sale_price} - offset(${order_items.total_sale_price}, 1)) / offset(${order_items.total_sale_price}, 1))"
      value_format_name: percent_1
  # --- MANDATORY ELEMENT-SCOPE COMPARISON DIRECTIVES ---
  show_comparison: true # Element-level scope: populates top-level result_maker.vis_config.show_comparison
  comparison_type: change # 'change' displays percentage or delta difference
  comparison_reverse_colors: false # False: increase is green (+), decrease is red (-)
  show_comparison_label: true
  comparison_label: "vs Prior Year"
  hidden_fields: [order_items.created_year]
  # --- VIS_CONFIG DIRECTIVES ---
  vis_config:
    type: single_value
    show_single_value_title: true
    single_value_title: "Total Sales Revenue"
    show_comparison: true
    comparison_type: change
    comparison_reverse_colors: false
    show_comparison_label: true
    comparison_label: "vs Prior Year"
    value_format: "$#,##0"
    hidden_fields: [order_items.created_year]
  note_state: expanded
  note_display: below
  note_text: "Compared to prior year performance"
  row: 4
  col: 0
  width: 6
  height: 4
```

---

### Template B: Previous Period Raw Value (`comparison_type: value`)

Use when displaying the exact prior-period raw number directly beneath the current value (e.g. Current Sales vs Prior Year Raw Sales).

```yaml
- name: kpi_gross_margin_raw_value
  title: "Gross Margin with Prior Period Raw Value"
  type: single_value
  model: thelook
  explore: order_items
  fields: [order_items.total_gross_margin, order_items.created_year]
  fill_fields: [order_items.created_year]
  filters:
    order_items.created_year: "2 years"
  sorts: [order_items.created_year desc]
  limit: 500
  dynamic_fields:
    - table_calculation: prior_period_margin
      label: "Prior Period Margin"
      expression: "offset(${order_items.total_gross_margin}, 1)"
      value_format_name: usd_0
  # --- MANDATORY ELEMENT-SCOPE COMPARISON DIRECTIVES ---
  show_comparison: true
  comparison_type: value # 'value' displays the raw calculated prior number
  show_comparison_label: true
  comparison_label: "Prior Year Margin"
  hidden_fields: [order_items.created_year]
  # --- VIS_CONFIG DIRECTIVES ---
  vis_config:
    type: single_value
    show_single_value_title: true
    single_value_title: "Gross Margin"
    show_comparison: true
    comparison_type: value
    show_comparison_label: true
    comparison_label: "Prior Year Margin"
    value_format: "$#,##0"
    hidden_fields: [order_items.created_year]
  row: 4
  col: 6
  width: 6
  height: 4
```

---

### Template C: Target Goal Progress Percentage (`comparison_type: progress_percentage`)

Use when displaying completion progress percentage relative to a target benchmark or goal.

```yaml
- name: kpi_new_users_goal
  title: "New Users Acquired"
  type: single_value
  model: thelook
  explore: users
  fields: [users.count]
  filters:
    users.created_date: 7 days
  limit: 500
  dynamic_fields:
    - table_calculation: goal
      label: "Target Goal"
      expression: "10000"
      value_format_name: decimal_0
  # --- MANDATORY ELEMENT-SCOPE COMPARISON DIRECTIVES ---
  show_comparison: true
  comparison_type: progress_percentage # 'progress_percentage' displays % achieved of target goal
  show_comparison_label: true
  comparison_label: "of 10,000 Goal"
  # --- VIS_CONFIG DIRECTIVES ---
  vis_config:
    type: single_value
    show_single_value_title: true
    single_value_title: "New Users Acquired"
    show_comparison: true
    comparison_type: progress_percentage
    show_comparison_label: true
    comparison_label: "of 10,000 Goal"
    value_format: "#,##0"
  row: 4
  col: 12
  width: 6
  height: 4
```

---

### Template D: Reversed Color Scale for Inverse Metrics (`comparison_reverse_colors: true`)

Use for negative metrics like Order Cancellation Rate, Customer Churn, or Server Response Latency where a decrease is desirable (green) and an increase is undesirable (red).

```yaml
- name: kpi_cancellation_rate
  title: "Order Cancellation Rate"
  type: single_value
  model: thelook
  explore: order_items
  fields: [order_items.cancellation_rate, order_items.created_year]
  fill_fields: [order_items.created_year]
  filters:
    order_items.created_year: "2 years"
  sorts: [order_items.created_year desc]
  limit: 500
  dynamic_fields:
    - table_calculation: rate_change
      label: "Rate Change"
      expression: "if(offset(${order_items.cancellation_rate}, 1) = 0, null, (${order_items.cancellation_rate} - offset(${order_items.cancellation_rate}, 1)) / offset(${order_items.cancellation_rate}, 1))"
      value_format_name: percent_1
  # --- MANDATORY ELEMENT-SCOPE COMPARISON DIRECTIVES ---
  show_comparison: true
  comparison_type: change
  comparison_reverse_colors: true # True: decrease is green (-), increase is red (+)
  show_comparison_label: true
  comparison_label: "vs Prior Year"
  hidden_fields: [order_items.created_year]
  # --- VIS_CONFIG DIRECTIVES ---
  vis_config:
    type: single_value
    show_single_value_title: true
    single_value_title: "Order Cancellation Rate"
    show_comparison: true
    comparison_type: change
    comparison_reverse_colors: true
    show_comparison_label: true
    comparison_label: "vs Prior Year"
    value_format: "0.0%"
    hidden_fields: [order_items.created_year]
  row: 4
  col: 18
  width: 6
  height: 4
```

---

## 3. Key Rules & Error Prevention

1. **Field Order**: Always place primary metric measure FIRST, time/year dimension SECOND in `fields: [view.measure, view.year_dim]`.
2. **Hidden Fields**: Set `hidden_fields: [view.year_dim]` at both element scope and inside `vis_config:` so Looker displays `fields[0]` as the primary single value.
3. **Element Scope Placement**: Always include `show_comparison: true`, `comparison_type: ...`, `show_comparison_label: true`, `comparison_label: ...`, and `hidden_fields: [...]` at element scope (outside `vis_config:`).
4. **Conditional Formatting**: Always enclose `type` in double quotes matching exact Looker UI strings (`type: "greater than"`, `type: "less than"`, `type: "equal to"`).

