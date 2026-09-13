---
name: lookml-pdt-guidelines
description: >-
  Guidelines for writing, creating, or modifying Persistent Derived Tables
  (PDTs) and performance aspects of derived tables in LookML.
---

# Persistent Derived Tables (PDT) Guidelines

This guide provides best practices and architectural laws for creating and
optimizing Persistent Derived Tables (PDTs) in LookML.

--------------------------------------------------------------------------------

### Constraints & Guardrails

*   **Mandatory Primary Keys:** You are strictly forbidden from creating any
    view, derived table, or PDT without defining a dimension with `primary_key:
    yes`. Every table must have an explicit primary key.
*   **Access Filters & Performance Cost:** Be extremely cautious when creating
    PDTs based on Explores that utilize `access_filters` or `sql_always_where`
    (referencing user attributes). Looker will generate a completely separate
    physical table in the database scratch schema for every unique combination
    of user attribute values, which can lead to massive database storage
    overhead and high rebuild costs.

--------------------------------------------------------------------------------

## 1. PDT Fundamentals & Selection

*   **Ephemeral vs. Persistent:** Standard derived tables execute ad-hoc,
    regenerating per query. Promote to a PDT only when queries involve
    multi-table joins, complex window functions, massive aggregations, or when
    repetitive dashboard loading drives up compute costs.
*   **Native vs. SQL-Based:**
    *   **Native Derived Tables (NDTs):** Defined using the `explore_source`
        parameter. They inherit existing LookML logic, automatically adapt to
        database dialect changes, and update dynamically if underlying
        dimensions change. **Always prefer NDTs over SQL-based tables.**
    *   **SQL-Based:** Defined using the `sql` parameter with a raw SQL string.
        Use only when leveraging advanced dialect-specific SQL functions that
        LookML cannot easily represent.

--------------------------------------------------------------------------------

## 2. Persistence Strategies

To materialize a table, you must assign it a persistence strategy:

*   **`datagroup_trigger` (Recommended):** Refreshes the PDT based on a
    centralized datagroup (e.g., tied to your ETL pipeline completion). Keeps
    the PDT perfectly synchronized with your cache.
*   **Prefer Datagroups over Hardcoded Intervals:** Avoid using `persist_for:
    "24 hours"` in production. Align PDT refreshes with your upstream ETL load
    schedule using `datagroup_trigger` to eliminate stale caching.
*   **`sql_trigger_value`:** Triggers a rebuild when a provided SQL query
    returns a different result (e.g., `SELECT MAX(id) FROM table`).
*   **`materialized_view: yes`:** For supported database dialects (e.g.,
    BigQuery, Snowflake, Databricks), leverages database-native materialized
    views to automatically cache and refresh query results, serving as an
    alternative to Looker-managed scratch table persistence.
*   **`interval_trigger`:** Rebuilds on a strict time interval (e.g., `"24
    hours"`).
*   **`persist_for`:** Retains the table for a set duration *after* a user first
    queries it. **Note:** Cannot be used with Incremental PDTs.

--------------------------------------------------------------------------------

## 3. Incremental PDTs

Instead of dropping and rebuilding massive tables entirely, Incremental PDTs
append fresh data.

*   **`increment_key`:** Specifies a LookML time dimension (e.g.,
    `created_date`) that defines the time increment for querying fresh data.
*   **`increment_offset`:** (Optional) An integer defining how many previous
    time periods to rebuild. Crucial for catching late-arriving data.
*   **Indexed Increment Keys:** The date or timestamp field used as the
    `increment_key` should be indexed or partitioned in the underlying source
    table. Unindexed fields cause massive full-table scans and database lockups.
*   **Incremental Strategy for Scale:** For multi-million row tables, use
    incremental strategies to force Looker to append new records rather than
    dropping and reconstructing massive historical datasets.
*   **Requirement for SQL-Based Incremental PDTs:** You must include the `{%
    incrementcondition %}` Liquid filter in the `WHERE` clause to bind your
    LookML increment key to the database timestamp column.

--------------------------------------------------------------------------------

## 4. Database-Level Optimization

You can apply native database optimization techniques directly within the
`derived_table` block:

*   **`indexes` (MySQL/Postgres):** Array of high-cardinality columns (e.g.,
    `indexes: ["customer_id"]`).
*   **`partition_keys` (BigQuery/Presto):** Divides large tables by date (e.g.,
    `partition_keys: ["date_column"]`), drastically reducing the amount of data
    scanned.
*   **`cluster_keys` (BigQuery/Snowflake):** Groups co-accessed data on disk
    (e.g., `cluster_keys: ["id_column"]`).
*   **`distribution` / `sortkeys` (Redshift):** Optimizes node distribution and
    sorting across the cluster.
*   **`distribution_style` (Redshift/Aster):** Defines how database rows are
    distributed across compute nodes (options: `all`, `even`, or a specific
    column).

--------------------------------------------------------------------------------

## 5. Architectural Laws

*   **Primary Keys:** Every PDT must have a unique primary key. Define a
    dimension with `primary_key: yes` when creating a PDT.
*   **Dedicated Scratch Schema:** Always configure a dedicated database schema
    (e.g., `looker_scratch`). The Looker database service account must have full
    DDL/DML permissions (CREATE, DROP, INSERT). Without this, Looker cannot
    write physical tables and defaults to slow temporary tables.
*   **Unique Scratch Schemas:** When managing multiple Looker instances (e.g.,
    QA, Staging, Prod) connected to the same database, each instance must use a
    distinct scratch schema to avoid cache conflicts and crashes.
*   **No User-Driven Liquid Filters:** Do not use `{% condition %}` or `{%
    parameter %}` in tables you intend to persist. Because PDTs build in the
    background on a schedule, they have no access to user dashboard context.
*   **Dynamic References:** Use `${view_name.SQL_TABLE_NAME}` instead of
    hardcoded table paths. This ensures Looker correctly isolates your table to
    the scratch schema when you test in Development Mode.
*   **Multi-Line Strings:** Standard LookML multi-line strings simply span
    multiple lines and are terminated with `;;`. Do NOT use YAML block scalars
    like `|` or `|-`.

--------------------------------------------------------------------------------

## 6. SQL Layer Optimization & Development Mode Speedups

*   **Pre-Filter and Aggregate Early:** Use the `WHERE` clause in the SQL
    wrapper to filter out unused dimensions or historical data boundaries. This
    minimizes payload transfers to user-facing Explores.
*   **Safe Mathematical Code:** Always use zero-safe math syntax (e.g.,
    `SAFE_DIVIDE(numerator, denominator)` in BigQuery) instead of a bare `/` to
    prevent division-by-zero errors that can break scheduled builds.
*   **Development Mode Caching & Speedups:** To prevent slow builds and query
    timeouts during development and validation:
    *   **NDT Development Filters (`dev_filters`):** Use the `dev_filters` block
        inside `explore_source` to restrict the dataset size ONLY while
        developing in Development Mode (e.g., limit to the last 24 hours or
        10,000 rows).
    *   **Conditional SQL Queries:** For SQL-based derived tables, use Liquid
        conditional blocks (e.g., `{% if _explore._developer_mode %}`) to
        restrict the table rows compiled during Development Mode, ensuring rapid
        validator and test runs.

--------------------------------------------------------------------------------

## 7. Maintainability & Clean LookML Design

*   **Build Cascading Views Modularly:** Break complex, long queries into small,
    layered steps using Looker's view dependency framework. Reference an earlier
    PDT inside a new PDT using `${view_name.SQL_TABLE_NAME}`.
*   **Clean Object Naming & Hiding:** Keep all base LookML field definitions
    lowercase and separate multi-word items with underscores. Hide raw foreign
    key matching strings using `hidden: yes` to avoid confusing users.
*   **Decouple Raw Logic via Refinement Files:** Use LookML Refinements
    (`+view_name`) to extend PDT structures safely. Separating operational
    attributes from core structural SQL keeps definitions concise and prevents
    git merge conflicts.

--------------------------------------------------------------------------------

## 8. Canonical LookML Examples

### Example A: Native Derived Table (NDT) with Datagroup

*The optimal pattern. Inherits LookML logic and uses database indexing.*

```lookml
view: customer_order_facts {
  derived_table: {
    datagroup_trigger: order_etl_datagroup
    indexes: ["customer_id"]
    explore_source: order {
      column: customer_id { field: order.customer_id }
      column: lifetime_orders { field: order.count }
      column: lifetime_spend { field: order.total_spend }
      # Add columns that don't exist in the base Explore using derived_column
      derived_column: average_order_value {
        sql: lifetime_spend / NULLIF(lifetime_orders, 0) ;;
      }
    }
  }

  dimension: customer_id {
    primary_key: yes
    description: "Unique ID of the customer."
    type: number
    sql: ${TABLE}.customer_id ;;
  }
}
```

### Example B: Incremental Native Derived Table (NDT)

*Appends data daily and looks back 3 days to capture late-arriving records.*

```lookml
view: daily_order_stats {
  derived_table: {
    datagroup_trigger: order_etl_datagroup
    increment_key: "created_date"
    increment_offset: 3
    explore_source: order {
      column: created_date { field: order.created_date }
      column: order_count { field: order.count }
    }
  }

  dimension: created_date {
    primary_key: yes
    description: "The date the orders were created."
    type: date
    sql: ${TABLE}.created_date ;;
  }
}
```

### Example C: Incremental SQL-Based PDT

*Uses raw SQL. Notice the mandatory `{% incrementcondition %}` Liquid block.*

```lookml
view: daily_flight_stats {
  derived_table: {
    datagroup_trigger: flight_etl_datagroup
    increment_key: "departure_date"
    increment_offset: 3
    sql:
      SELECT
        leaving_time AS departure,
        COUNT(flight_id) AS flight_count
      FROM flights
      WHERE {% incrementcondition %} leaving_time {% endincrementcondition %}
      GROUP BY 1
    ;;
  }

  dimension: departure_key {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.departure ;;
  }

  dimension_group: departure {
    type: time
    timeframes: [raw, date, month]
    sql: ${TABLE}.departure ;;
  }
}
```
