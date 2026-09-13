# Looker Error Catalog

This catalog provides a collection of common Looker error messages, their
underlying causes, and tactical remedies.

## 1. Liquid and Variable Errors

### Problem: `Variable not found (?)`

* **Possible Causes**:
    * Liquid `{{ }}` syntax is nested within Liquid logic `{% %}`.
    * A templated filter references a table that is not joined into the
      current Explore or derived table.
    * A field is referenced in Liquid without being fully scoped (e.g.,
      `field_name` instead of `view_name.field_name`).
    * A parameter value is incompatible with its defined `type`.
    * A dimension group is referenced without a timeframe (e.g.,
      `creation_date` instead of `creation_date_year`).

* **Remedies**:
    * Un-nest Liquid tags: use `{{ }}` for output and `{% %}` for logic
      separately.

    * Ensure all referenced views are joined in the Explore definition.
    * Use fully qualified names: `${view_name.field_name}` for LookML
      substitution (in `sql` parameters) or `view_name.field_name._value` in
      Liquid (e.g., `{{ view_name.field_name._value }}`).

    * Verify parameter types (e.g., `string` vs `unquoted`).
    * Append a timeframe to all dimension group references.

## 2. View and Explore Resolution Errors

### Problem: `Inaccessible view (?). (?) is not accessible in explore (?).`

* **Possible Causes**:
    * The referenced view does not exist or is not included in the model.
    * A required `join` is missing from the Explore definition.
    * The view has been aliased using the `from` parameter, and the original
      name is being used.

* **Remedies**:
    * Verify the view exists and add `include: "/path/to/view_file.view.lkml"`
      to the model.

    * Add the missing `join: view_name {}` to the Explore.
    * Use the alias name if `from` is used, or correct the reference.

### Problem: `Unknown view (?)`

* **Possible Causes**:
    * The view file is not included in the model file.
    * The Explore extends a base Explore that is missing a `view_name`
      parameter.

    * The Explore name is based on a misspelled or nonexistent view.
* **Remedies**:
    * Add the appropriate `include` statement.
    * Ensure `view_name` is specified if the Explore name differs from the base
      view.

    * Correct typos in Explore or View definitions.

## 3. Field Resolution Errors

### Problem: `Unknown or inaccessible field (?)`

* **Possible Causes**:
    * Typo in the field name or in the reference to the field.
    * The field is explicitly excluded from the Explore using the `fields`
      parameter.

    * The reference is to a `dimension_group` without a timeframe.
    * The view containing the field is not joined to the Explore.
* **Remedies**:
    * Check for typos in the LookML definition and references.
    * Adjust the `fields` list in the Explore or Join to include the field.
    * Append the correct timeframe (e.g., `_date`, `_month`) to the field name.

## 4. Structural and Logical Errors

### Problem: `Circular dependency detected`

* **Possible Causes**:
    * Two or more LookML objects (Views or Explores) attempt to `extend` each
      other in a loop.

* **Remedies**:
    * Trace the inheritance chain and break the loop by refactoring shared logic
      into a base object.

### Problem: `View 'X' is already defined`

* **Possible Causes**:
    * Multiple files define the same view name, or the same file is included
      multiple times under different paths.

* **Remedies**:
    * Ensure each view name is unique across the project.
    * Consolidate duplicate definitions or use `include` wildcards more
      carefully.

### Problem: `Multiple fields declared as primary_key: yes`

* **Possible Causes**:
    * More than one dimension in a single view has `primary_key: yes` set.
* **Remedies**:
    * Ensure only one dimension (or a concatenated dimension) is marked as the
      primary key.

## 5. SQL and Database Errors

### Problem: `SQL Error: Column not found`

* **Possible Causes**:
    * A LookML field references a database column that does not exist in the
      underlying table or derived table SQL.

* **Remedies**:
    * Verify the database schema and update the `${TABLE}.column_name`
      reference.

### Problem: `looker is having trouble connecting to your database`

* **Possible Causes**:
    * The connection pool is exhausted (too many concurrent queries).
    * The database concurrency limit has been reached.

* **Remedies**:
    * Identify and optimize long-running queries that may be hogging the pool.
    * Increase the database's "Max Connections" setting if appropriate.
    * Increase "Connection Pool Timeout" in Looker Connection settings to
      allow queries to wait longer.
    * Optimize queries or reduce dashboard tile count to lower overall
      concurrency.
