---
name: lookml-modeling-guidelines
description: Guidelines for LookML modeling and effective Looker MCP tool use.
---

# LookML Modeling Guidelines

This guide provides instructions on how to effectively use the Looker MCP tools
to assist with LookML modeling tasks. It synthesizes best practices for LookML
development with effective tool usage.

## LookML File Types

Understand the purpose of different file types in a LookML project:

*   **Project Manifest (`manifest.lkml`)**: Global configuration for the
    project, including imports and constants.
*   **Model Files (`.model.lkml`)**: Defines database connections and Explores
    (how views are joined).
*   **View Files (`.view.lkml`)**: Blueprints for data, defining dimensions,
    measures, and derived tables.
*   **Dashboard Files (`.dashboard.lookml`)**: LookML-defined dashboards
    (layout, visualizations, filters, tabs).
*   **Specialized Files**: Refinement files (for overriding/patching), Data Test
    files (automated logic checks), and Document files (`.md`).

## 1. Analyzing Requirements

Before writing any LookML code or making modifications, analyze the user's
request to determine the necessary LookML elements.

*   **Understand the Request**: Identify the core business question or technical
    requirement.
*   **Identify Existing Resources**:
    *   Use the Discovery tools (see section 2) to search the existing LookML
        project.
    *   Identify which existing columns (dimensions) and measures are best
        suited to answer the user prompt.
    *   *Do not recreate existing logic.* Reuse existing elements whenever
        possible.
*   **Determine Necessary Additions**:
    *   Identify if any *new* LookML elements are required to fulfill the
        prompt:
        *   **New Views**: Are we introducing new tables or derived tables?
            (Note: If creating a derived table or PDT, you MUST consult the
            `lookml-pdt-guidelines` skill).
        *   **New Dimensions**: Do we need to expose new columns or define new
            logic from existing columns?
        *   **New Measures**: Are we adding new aggregations (e.g., `count`,
            `sum`, `average`) or calculated metrics?
        *   **Other Elements**: Do we need new joins in an Explore, or other
            LookML elements?

## 2. Discovery & Exploration

*   **Project Mapping**: Use `get_projects`, `get_models`, and `get_explores` to
    understand the project structure.
*   **Field Discovery**: Use `get_dimensions` and `get_measures` to see what is
    exposed in an explore. Prefer this over reading all view files.
*   **Schema Discovery**: Use `get_connections`, `get_connection_databases`,
    `get_connection_schemas`, `get_connection_tables`, and
    `get_connection_table_columns` to inspect the connected database and to
    retrieve table names, column names, and data types. Table names, column
    names, and data types are case sensitive.
*   **Data Discovery**: Use `query` to query an explore. Note that the fields
    passed to this tool are the fully qualified names as exposed by Looker,
    which may differ from the raw field name in the view file. Always use the
    Field Discovery tools to understand the available fields before running a
    query.

## 3. Verification & Testing

Always verify that your LookML is valid and generates the expected SQL or
results.

*   **Syntactic Correctness:** All code must be syntactically perfect, with
    balanced braces and correct parameters. `sql` parameters must match the
    specific database dialect (e.g., BigQuery, Snowflake). Always ensure strict
    adherence to LookML syntax, especially when defining blocks and using
    correct indentation.
*   **Running Queries**: Use `query` to verify results.
*   **Type Safety**: Make sure that the data types used in LookML fields are
    compatible with the underlying database and SQL dialect defined by the
    Looker connection.
*   **SQL Verification**: Use `query_sql` to inspect the SQL Looker generates
    but without executing the query against the database. Do not use this tool
    to generate SQL to manually execute, prefer `query` to do that.
*   **Validation**: Use `validate_project` frequently during development.
*   **Testing**: Use `get_lookml_tests` and `run_lookml_tests` to execute tests.

## 4. Creating New Views

Use `create_view_from_table` to generate boilerplate LookML views directly from
the database schema. Always use this tool to generate views from tables and then
edit the generated view file.

### Naming & Uniqueness Requirements

*   **Model:** Instance-wide uniqueness required (prevents URL collisions and
    instance errors).
*   **View:** Project-wide uniqueness required (acts as namespace for fields).
*   **Explore:** Model-wide uniqueness required (query starting point).
*   **Field:** View-wide uniqueness required (dimension/measure names must be
    unique within the view).

## 5. Dashboard LookML Syntax & Tabs

When writing LookML dashboard files (`.dashboard.lookml`):

*   **24-Column Newspaper Layout**: Always specify `layout: newspaper`.
*   **Tabs Block Syntax (CRITICAL)**:
    *   Under `tabs:`, use `label:` for display names. Do **NOT** use `title:`.
    ```yaml
    tabs:
      - name: tab_1_id
        label: "Tab 1 Display Label"
    ```
    *   Under each element in `elements:`, use `tab_name:` to assign the tile to a tab. Do **NOT** use `tab:`.
    ```yaml
    elements:
      - name: tile_name
        tab_name: tab_1_id
    ```

## 6. Feedback Loop (Validation)

After making any changes to LookML files:

1.  Run `validate_project` to check for syntax and reference errors.
2.  If errors are found, fix them and repeat step 1.
3.  If data tests are defined, run `run_lookml_tests` to ensure they still pass.
4.  **DO NOT** consider the task complete until `validate_project` returns no
    errors (and `run_lookml_tests` if applicable).

--------------------------------------------------------------------------------

## 7. Best Practices

### A. Models

*   **Includes**: Use specific, granular `include` paths instead of broad
    wildcards to prevent performance bloat, avoid namespace collisions, and
    improve compilation speed.
    *   **Do**: `include: "/views/users.view.lkml"`
    *   **Don't**: `include: "/views/*.view.lkml"`

### B. Explores

*   **Joins**: Always specify the `relationship` parameter explicitly (e.g.,
    `many_to_one`). This is critical for Looker to generate correct SQL and
    avoid fanouts.
*   **Granular Explores**: Prefer small, focused Explores over monolithic ones
    to simplify the user interface and ease troubleshooting.

### C. Views

*   **Primary Key**: Every view representing a table should have a primary key
    defined. It must be the first dimension and have `primary_key: yes`. This is
    essential for symmetric aggregates.
*   **Field References**: Measures should reference dimensions (e.g.,
    `${dimension_name}`), not table columns directly (e.g.,
    `${TABLE}.column_name`). This ensures a single source of truth.
*   **Field Descriptions**: Always add a human-readable `description` parameter
    to any new dimension or measure. This helps end-users understand the field
    in the field picker.

### D. General

*   **DRY Principles & Modularity:** Utilize `extends`, `refinements` (for
    modular, scalable code), and `sets` to eliminate code duplication.
*   **Refinements vs. Extensions**: Use **Refinements** (`+` syntax) to layer
    changes onto existing objects without renaming (e.g., customizing Blocks).
    Use **Extensions** (`extends`) to create new, specialized variants while
    keeping the original object intact.

### Constraints & Guardrails

*   **Mandatory Primary Keys:** You must always define a dimension with
    `primary_key: yes` when creating any view, derived table, or PDT. Every
    table must have an explicit primary key.
*   **Application Scope:** All guidelines and best practices in this file apply
    ONLY to new code added to fulfill the user prompt. Do not refactor or modify
    existing code to comply with these guidelines unless explicitly requested or
    necessary for the new code to function. Keep existing code as is.
*   **Zero-Error Policy:** Strictly forbidden from submitting code that fails
    the LookML Validator.
*   **Data Minimization:** Access only the data and schema necessary for the
    current task.
*   **Validation**: Keep the scope of validation to your changes only. Do not
    fix existing validation errors.
