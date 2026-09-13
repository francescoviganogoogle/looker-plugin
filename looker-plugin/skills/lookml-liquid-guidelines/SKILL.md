---
name: lookml-liquid-guidelines
description: >-
  Guidelines for writing better Liquid templates in LookML, including
  templated filters, parameters, dynamic dimensions/measures, and
  conditional logic.
---

# Liquid Guidelines

This guide provides best practices, syntax, and architectural rules for using
Liquid templating in LookML to create dynamic and interactive models.

--------------------------------------------------------------------------------

## 1. Core Concepts: Templated Filters vs. Liquid Parameters

While both allow user input, they behave fundamentally differently in how Looker
processes them.

*   **Templated Filters (`{% condition %}`):**
    *   **Behavior:** Users enter values just like a standard filter (e.g., "is
        equal to X", "contains Y", "greater than Z"). Looker translates this
        input into a complete, logical SQL expression (e.g., `table.column =
        'X'`).
    *   **Best For:** Passing complex, multi-value user inputs directly into the
        `WHERE` or `HAVING` clause of a derived table.
    *   **Setup:** Requires a `filter` field in LookML to capture the input.
*   **Liquid Parameters (`{% parameter %}`):**
    *   **Behavior:** Users select a *single* value from a predefined list (or
        type a single string). Looker inserts this exact, literal value into the
        SQL query or uses it to evaluate Liquid `{% if %}` logic.
    *   **Best For:** Toggling dimensions/measures (e.g., choosing to view
        "Revenue" vs. "Profit"), changing aggregation levels, or altering which
        database table is queried.
    *   **Setup:** Requires a `parameter` field in LookML to capture the input.

> [!WARNING]
>
> Persistence (PDTs) is **not supported** for derived tables that use templated
> filters or Liquid parameters. They must remain ephemeral because they require
> real-time user context to execute.

--------------------------------------------------------------------------------

## 2. Templated Filters: Best Practices & Syntax

Templated filters inject a logical statement into your SQL based on the user's
filter selections.

### Syntax

```sql
{% condition filter_name %} sql_or_lookml_reference {% endcondition %}
```

*   `filter_name`: The name of the `filter` field (or `dimension`) the user
    interacts with.
*   `sql_or_lookml_reference`: The database column or LookML field you are
    applying the condition against.

### Example: Dynamic Derived Table

Creating a derived table that only queries data for a specific, user-selected
region.

```lookml
# Step 1: Create the filter field for the user
filter: region_selector {
  type: string
  suggest_explore: order
  suggest_dimension: order.region
}

# Step 2: Use the filter in the derived table's SQL
view: region_sales_stats {
  derived_table: {
    sql:
      SELECT
        customer_id,
        SUM(spend) as lifetime_spend
      FROM orders
      WHERE {% condition region_selector %} orders.region {% endcondition %}
      GROUP BY 1
    ;;
  }
}
```

### Date specific logic (`date_start` / `date_end`)

When users apply date filters, you can extract the bounding dates using `{%
date_start filter_name %}` and `{% date_end filter_name %}`.

*   **Best Practice:** Always wrap these in `COALESCE` or `IFNULL` to prevent
    SQL errors if the user selects an open-ended date range (e.g., "before
    2026-01-01").

```lookml
filter: order_date_filter {
  type: date
}

# In your SQL block:
# COALESCE({% date_start order_date_filter %},
# DATE_ADD(CURRENT_TIMESTAMP(),-2,'MONTH'))
```

--------------------------------------------------------------------------------

## 3. Liquid Parameters: Best Practices & Syntax

Liquid parameters let users change the literal behavior of a query or toggle
LookML elements.

### Example A: Dynamic Measure (Metric Toggling)

Allow a user to select which metric they want to see in a single column.

```lookml
# Step 1: Create the parameter to capture user choice
parameter: metric_selector {
  type: unquoted # Unquoted type is safe for column names
  allowed_value: { label: "Total Revenue" value: "revenue" }
  allowed_value: { label: "Total Profit" value: "profit" }
  allowed_value: { label: "Order Count" value: "orders" }
}

# Step 2: Inject the parameter directly into the SQL
measure: dynamic_metric {
  type: sum
  sql: ${TABLE}.{% parameter metric_selector %} ;;
  label_from_parameter: metric_selector # Dynamically updates the column header
}
```

### Example B: Conditional Logic with `_parameter_value`

Use `parameter_name._parameter_value` inside standard Liquid `{% if %}` / `{%
else %}` blocks to build complex conditional logic.

```lookml
parameter: date_granularity {
  type: string
  allowed_value: { value: "Day" }
  allowed_value: { value: "Month" }
}

dimension: dynamic_date {
  sql:
    {% if date_granularity._parameter_value == "'Day'" %}
      ${created_date}
    {% elsif date_granularity._parameter_value == "'Month'" %}
      ${created_month}
    {% else %}
      ${created_year}
    {% endif %} ;;
}
```

*Note: When the parameter `type` is `string`, Looker surrounds the value in
single quotes. Your Liquid logic must evaluate it with single quotes inside
double quotes (e.g., `"'Day'"`).*

--------------------------------------------------------------------------------

## 4. Advanced Liquid Variables

Looker provides extensive contextual Liquid variables beyond basic parameters.

*   **`_in_query`, `_is_selected`, `_is_filtered`**: Used to inspect query
    context. For example, `_in_query` can be used inside a dimension's `sql`
    parameter to change calculation logic based on whether another field is
    included in the query.
*   **`{{ value }}`**: Inputs the actual cell value directly. Highly utilized
    inside the `html` or `link` parameters to build dynamic URLs (e.g., linking
    out to a CRM using `url: "https://crm.example.com/user/{{ value }}"`).
*   **`_filters['view_name.field_name']`**: Captures the exact text a user
    entered into a filter. Used extensively in the `link` parameter to pass a
    user's filter context from a dashboard directly into a drilled-down Explore.
