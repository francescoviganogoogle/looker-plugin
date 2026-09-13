---
name: lookml_calculations_and_table_calcs
description: Triggers whenever defining calculated dimensions, ratio measures, filtered measures, custom fields, or on-the-fly table calculations (Looker Expressions / Lexp) in LookML models or UDD dashboards.
version: 1.0.0
tags: [runtime_looker_builder, runtime_looker_dashboard, looker_dashboard, lookml, calculations, table-calculations, lexp, formulas]
---

# Skill: LookML Calculations, Looker Expressions & Table Calculations

## Purpose
This skill provides definitive patterns for defining **Calculated Dimensions**, **Calculated Measures**, and **Table Calculations** in LookML models (`.lkml`), User Defined Dashboards (`.lookml`), and Looker Explore queries. It enforces best practices derived from Looker Functions & Operators (`https://docs.cloud.google.com/looker/docs/functions-and-operators`) and real-world analytical use cases.

For a complete catalog of all valid Looker expression functions, refer to [Looker Functions & Operators Reference](references/looker_functions_and_operators.md).

---

## 1. Scope & Execution Engine Distinction

| Capability | Execution Engine | Where It Is Used | Key Syntax / Functions |
| :--- | :--- | :--- | :--- |
| **LookML Calculated Dimensions** | Underlying Database SQL | LookML view (`.view.lkml`) | Database SQL (`CASE WHEN`, `CONCAT`, `EXTRACT`, `${view_name.field_name}`) |
| **LookML Calculated Measures** | Underlying Database SQL | LookML view (`.view.lkml`) | `type: number`, `sql: ${view_name.measure_a} / NULLIF(${view_name.measure_b}, 0) ;;`, `filters: []` |
| **Table Calculations** | Looker Expression Engine (**Lexp**) | Looker Explores, LookML Dashboards (`table_calculations:`), Data Tests | Looker expression functions (`offset()`, `running_total()`, `mean()`, `pivot_index()`, `if()`) |

> [!IMPORTANT]
> **Positional & Aggregation Scope Rule**: Looker functions that refer to other rows (`offset()`, `pivot_index()`) or aggregate across rows (`running_total()`, `mean()`) are **ONLY** valid inside **Table Calculations**. They cannot be used inside LookML dimension or measure `sql:` parameters.

---

## 2. CRITICAL ANTI-HALLUCINATION RULE: DO NOT INVENT FUNCTIONS IN TABLE CALCULATIONS

Looker Table Calculations execute in Looker's in-memory expression engine (**Lexp**), **NOT** in database SQL. You **MUST ONLY** use functions and operators documented in `https://docs.cloud.google.com/looker/docs/functions-and-operators`.

### Non-Existent Functions (NEVER USE IN TABLE CALCULATIONS)
| Hallucinated / SQL Function | Why It Fails in Looker Expressions | Valid Looker Expression Equivalent |
| :--- | :--- | :--- |
| **`nullif(x, 0)`** | Looker throws an unknown function error (`Unknown function nullif`). | Use direct division `y / x` (Looker handles division by zero safely) or explicit conditional: `if(x = 0, null, y / x)`. |
| **`ifnull(x, y)` / `nvl(x, y)`** | Looker throws an unknown function error. | `coalesce(x, y)` |
| **`CASE WHEN ... END`** | SQL syntax is invalid in Looker expressions. | Nested `if(condition, yes_val, no_val)` |

> [!WARNING]
> While `NULLIF()` is valid inside LookML Measure `sql:` blocks (since those run as database SQL), it **DOES NOT EXIST** inside Looker Table Calculations (`expression:` or `table_calculation:`).

---

## 3. Extracted List of Looker Expression Functions & Operators

### 3.1 Mathematical Functions & Operators
*   **Operators**: `+` (add), `-` (subtract), `*` (multiply), `/` (divide), `^` (exponent)
*   **Functions**: `abs(value)`, `ceiling(value)`, `exp(value)`, `floor(value)`, `ln(value)`, `log(value, base)`, `mod(dividend, divisor)`, `power(base, exponent)`, `rand()`, `round(value, decimals)`, `trunc(value, decimals)`

### 3.2 String Functions
*   **Functions**: `concat(text_1, text_2, ...)`, `contains(text, search)`, `ends_with(text, search)`, `starts_with(text, search)`, `length(text)`, `lower(text)`, `upper(text)`, `replace(text, old, new)`, `substring(text, start, length)`, `trim(text)`

### 3.3 Date & Time Functions
*   **Functions**: `now()`, `add_days(date, n)`, `add_months(date, n)`, `add_years(date, n)`, `diff_days(date_1, date_2)`, `diff_months(date_1, date_2)`, `diff_years(date_1, date_2)`, `extract_days(date)`, `extract_months(date)`, `extract_years(date)`, `trunc_days(date)`, `trunc_months(date)`, `trunc_years(date)`

### 3.4 Logical Functions, Operators & Constants
*   **Operators**: `=`, `!=`, `>`, `<`, `>=`, `<=`, `AND`, `OR`, `NOT`
*   **Constants**: `yes`, `no`, `null`
*   **`if(condition, value_if_yes, value_if_no)`**: Evaluates condition and returns yes value or no value.
*   **`coalesce(value_1, value_2, ...)`**: Returns first non-null argument.
*   **`is_null(value)`** / **`not_null(value)`**: Checks for null values.

### 3.5 Table Calculation-Only Functions (Positional, Window & Aggregation)
*   **Row Navigation**: `offset(field, row_offset)`, `offset_list(field, row_offset, length)`, `row()`
*   **Aggregations Across Rows**: `sum(field)`, `mean(field)`, `median(field)`, `max(field)`, `min(field)`, `percentile(field, p)`, `running_total(field)`
*   **Pivot Navigation**: `pivot_index(field, col_number)`, `pivot_row(field)`, `pivot_offset(field, col_offset)`, `pivot_offset_list(...)`, `pivot_where(field, cond)`

---

## 4. Defining Calculated Dimensions (LookML & Custom Fields)

### 4.1 Conditional / Tiered Grouping (`CASE WHEN` & `type: case`)
```lookml
dimension: order_size_tier {
  type: case
  case: {
    when: {
      sql: ${order_items.sale_price} >= 500 ;;
      label: "Enterprise ($500+)"
    }
    when: {
      sql: ${order_items.sale_price} >= 100 ;;
      label: "Mid-Market ($100-$499)"
    }
    else: "Small Business (<$100)"
  }
}
```

### 4.2 On-the-Fly Custom Dimensions in `dynamic_fields:` (Preferred in Dashboards)
When building a dashboard tile or inline query where a custom grouping or boolean comparison is needed without altering LookML view files, define an on-the-fly Custom Dimension inside `dynamic_fields:` using `if(...)`:
```lookml
dynamic_fields:
  - dimension: device_type
    label: Device Type
    expression: 'if(${events.os}="Macintosh", "iOS", if(${events.os}="Windows","Desktop","Android"))'
    _kind_hint: dimension
    _type_hint: string
```

---

## 5. Defining Calculated Measures (Ratios, Averages & Filtered Metrics)

### 5.1 Ratio Measures (`type: number` in `.view.lkml`)
> [!CAUTION]
> **NEVER aggregate a ratio directly!** Always divide aggregated numerators by aggregated denominators. Note that `NULLIF()` is valid here because `sql:` compiles to database SQL.

```lookml
measure: average_order_value {
  type: number
  sql: ${order_items.total_revenue} / NULLIF(${order_items.total_orders}, 0) ;;
  value_format_name: usd
}
```

### 5.2 On-the-Fly Custom Measures in `dynamic_fields:` (Preferred in Dashboards)
When creating a dashboard tile or query requiring a new average or aggregate measure from an existing unaggregated field, define it on-the-fly inside `dynamic_fields:`:
```lookml
dynamic_fields:
  - measure: average_basket_size
    based_on: order_facts.order_amount
    type: average
    label: Average Basket Size
    value_format_name: usd
    _kind_hint: measure
    _type_hint: number
```

---

## 6. On-the-Fly Table Calculations (Looker Expressions / Lexp)

Table calculations execute in Looker memory *after* SQL results return.

### 6.1 Period-over-Period Growth (`offset()`)
Compares the current row against the previous row (`offset(field, 1)`):
```lookml
# Period-over-Period Absolute Change
expression: "${order_items.count} - offset(${order_items.count}, 1)"

# Period-over-Period Percent Change (NOTE: do not use nullif in table calculations)
expression: "if(offset(${order_items.count}, 1) = 0, null, (${order_items.count} - offset(${order_items.count}, 1)) / offset(${order_items.count}, 1))"
```

### 6.2 Share of Total & Cohort Retention (`sum()`, `max()`)
```lookml
# Percent of Total Column
expression: "${orders.total_revenue} / sum(${orders.total_revenue})"

# Cohort Retention (Current Row vs Peak/Max Value)
expression: "${users.count} / max(${users.count})"
```

### 6.3 Window Calculations & Moving Averages (`offset_list()`, `running_total()`)
```lookml
# Cumulative Running Total
expression: "running_total(${orders.total_revenue})"

# 7-Period Trailing Moving Average (averages current row and previous 6 rows)
expression: "mean(offset_list(${orders.total_revenue}, -6, 7))"
```

### 6.4 Pivoted Table Calculations (`pivot_index()`, `pivot_row()`)
```lookml
# Difference between 2nd Pivot Column and 1st Pivot Column
expression: "pivot_index(${orders.count}, 2) - pivot_index(${orders.count}, 1)"

# Row Total across all Pivoted Columns
expression: "sum(pivot_row(${orders.count}))"

# Percent of Row Total across Pivots
expression: "${orders.count} / sum(pivot_row(${orders.count}))"
```

### 6.5 Conditional Logic & Threshold Bucketing (`if()`, `coalesce()`, `is_null()`)
```lookml
# Target Achievement Bucketing
expression: 'if(${orders.total_revenue} >= 10000, "Goal Met", "Below Goal")'

# Null Safe Value Coalescing
expression: "coalesce(${orders.total_revenue}, 0)"
```

---

## 7. Complete LookML Dashboard Tile Templates (Comparative KPIs & Running Calculations)

> [!CRITICAL]
> **COMPARATIVE VISUAL INDEPENDENT TIME FILTER & GLOBAL LISTENER EXCLUSION RULE**:
> Whenever a visual tile involves time comparison (YoY, MoM, PoP, single_value comparison, or pivoted multi-year timelines):
> 1. **Independent Time Frame Filter**: The element MUST include an explicit local filter covering the full comparison window (e.g. `filters: { order_items.created_year: "2 years" }`).
> 2. **Exclusion from Global Date Filter Listeners**: Comparative tiles MUST NOT listen to global date filters (`listen:`) on the date dimension used for comparison. Listening to a global date filter (e.g., `select_date: order_items.created_date`) forces the tile's query to execute on a single date range, truncating the comparison period and preventing Looker from computing the delta.

```lookml
  - title: Total Order Count
    name: Total Order Count
    model: thelook
    explore: order_items
    type: single_value
    fields: [order_items.count, order_items.created_year]
    fill_fields: [order_items.created_year]
    filters:
      order_items.created_year: "2 years"
    sorts: [order_items.created_year desc]
    limit: 500
    dynamic_fields:
      - table_calculation: percent_change
        label: Percent Change
        expression: "${order_items.count}/offset(${order_items.count},1) - 1"
        value_format_name: percent_0
    vis_config:
      type: single_value
      show_single_value_title: true
      single_value_title: Orders This Year
      show_comparison: true
      comparison_type: change
      show_comparison_label: true
      comparison_label: vs Same Period Last Year
      hidden_fields: [order_items.created_year]
```
```

### 7.2 Cumulative Running Total Trend Line Chart (`running_total()`)
```lookml
  - title: Cumulative Revenue Growth
    name: Cumulative Revenue Growth
    model: thelook
    explore: order_items
    type: looker_line
    fields: [order_items.created_date, order_items.total_sale_price]
    sorts: [order_items.created_date]
    limit: 500
    dynamic_fields:
      - table_calculation: cumulative_revenue
        label: Cumulative Revenue
        expression: "running_total(${order_items.total_sale_price})"
        value_format_name: usd_0
        _kind_hint: measure
        _type_hint: number
    hidden_fields: [order_items.total_sale_price]
```

---

## 8. Summary Use Case Matrix for AI Agents (When to Use What)

### Architectural Rule: When to Use `dynamic_fields:` vs `.view.lkml`
1. **DEFAULT / PREFERRED (`dynamic_fields:` in `.dashboard.lookml`)**:
   Whenever you are creating or editing a LookML Dashboard (`import_lookml_dashboard`) where the requested metric or grouping does not exist in the LookML model, **ALWAYS** define it on-the-fly inside `dynamic_fields:`. This works universally for all users without requiring Git write access or risking shared repository pollution.
2. **RESTRICTED (`.view.lkml` Modification)**:
   Only modify a LookML view file (`.view.lkml`) when the user explicitly requests permanent LookML model development AND the user has verified Looker developer permissions (`can.develop` / `can.update`).

### Analytical Pattern Decision Matrix
| Analytical Request | Recommended Solution | Implementation Layer |
| :--- | :--- | :--- |
| *"Show me Average Order Value (AOV)"* | Ratio Measure (`${order_items.total_revenue} / NULLIF(${order_items.total_orders}, 0)`) | LookML Measure (`type: number` in view) OR Custom Measure in `dynamic_fields:` |
| *"Group users into spend brackets or device OS categories"* | Tiered/Conditional Dimension (`if(...)`) | On-the-fly Custom Dimension (`dimension: ... expression: 'if(...)'`) in `dynamic_fields:` |
| *"Create an average measure from an unaggregated amount field"* | Custom Average Measure (`type: average`) | On-the-fly Custom Measure (`measure: ... based_on: ... type: average`) in `dynamic_fields:` |
| *"Add a KPI card comparing this year's orders vs last year"* | KPI Card (`show_comparison: true`, `comparison_type: change`) | LookML Dashboard (`type: single_value`) |
| *"Compare this month's sales to last month (% change)"* | Table Calc (`if(offset(${order_items.total_sales}, 1) = 0, null, (${order_items.total_sales} - offset(${order_items.total_sales}, 1)) / offset(${order_items.total_sales}, 1))`) | LookML Dashboard (`dynamic_fields:`) / Explore |
| *"Calculate cohort retention vs peak signups"* | Table Calc (`${users.count} / max(${users.count})`) + `hidden_fields` | LookML Dashboard (`dynamic_fields:`) / Explore |
| *"Show cumulative YTD signups or revenue line"* | Table Calc (`running_total(${users.total_signups})`) | LookML Dashboard (`dynamic_fields:`) / Explore |
