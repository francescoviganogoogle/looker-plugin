# Looker Functions & Operators Reference (Looker Expressions / Lexp)

Source: https://docs.cloud.google.com/looker/docs/functions-and-operators

This document is the authoritative reference for functions and operators available inside Looker expressions (Lexp), Table Calculations (`expression:` in `dynamic_fields` or `table_calculations:`), Custom Fields, and Data Tests.

---

## 1. CRITICAL ANTI-HALLUCINATION RULE: DO NOT INVENT FUNCTIONS

Looker Table Calculations execute in Looker's in-memory expression engine (**Lexp**), **NOT** in database SQL. Do NOT invent SQL functions or operators that do not exist in Looker expressions.

### Non-Existent Functions (NEVER USE IN TABLE CALCULATIONS)
| Hallucinated / SQL Function | Why It Fails in Looker Expressions | Valid Looker Expression Equivalent |
| :--- | :--- | :--- |
| `nullif(x, 0)` | Looker throws an unknown function error. | `if(x = 0, null, y / x)` or simply `y / x` (Looker handles division by zero safely). |
| `ifnull(x, y)` / `nvl(x, y)` | Looker throws an unknown function error. | `coalesce(x, y)` |
| `CASE WHEN ... END` | SQL syntax is invalid in Looker expressions. | Nested `if(condition, yes_val, no_val)` |
| `to_char()`, `date_format()` | SQL syntax is invalid in Looker expressions. | Use `value_format_name` parameter on the field or tile definition. |

> **IMPORTANT DISTINCTION**:
> - Inside LookML **Measures** (`type: number`, `sql: ...`), database SQL functions like `NULLIF()` **ARE** valid because `sql:` compiles to SQL sent to BigQuery/database.
> - Inside Looker **Table Calculations** (`expression:` inside `dynamic_fields:`), `nullif()` **DOES NOT EXIST** and must never be used.
> - **CRITICAL YAML KEY RULE**: In `.dashboard.lookml` declarative code, table calculations MUST ALWAYS be declared under **`dynamic_fields:`**. NEVER use `table_calculations:` as a root YAML element key.

---

## 2. Table Calculation-Only Functions (Positional, Aggregation & Window)

These functions are **ONLY** valid inside Table Calculations declared in `dynamic_fields:`. They cannot be used in standard custom dimensions or filters.

### Row & Window Navigation
*   **`offset(field, row_offset)`**
    *   *Description*: Returns the value of `field` from `row_offset` rows away. Negative values look up toward previous rows (`-1` = previous row); positive values look down toward future rows (`1` = next row).
    *   *Example (PoP Change)*: `(${orders.count} - offset(${orders.count}, 1)) / offset(${orders.count}, 1)`
*   **`offset_list(field, row_offset, length)`**
    *   *Description*: Returns a list of values of `field` starting at `row_offset` for `length` rows.
    *   *Example (7-Period Moving Average)*: `mean(offset_list(${orders.revenue}, -6, 7))`
*   **`row()`**
    *   *Description*: Returns the current row number (1-indexed).

### Column & Row Totals / Aggregations Across Rows
*   **`sum(field)`**: Returns the total sum of `field` across all rows in the query result.
    *   *Example (% of Total)*: `${orders.revenue} / sum(${orders.revenue})`
*   **`mean(field)`**: Returns the arithmetic mean (average) of `field` across all rows.
*   **`median(field)`**: Returns the median value of `field` across all rows.
*   **`max(field)`**: Returns the maximum value of `field` across all rows.
    *   *Example (Cohort Retention)*: `${users.count} / max(${users.count})`
*   **`min(field)`**: Returns the minimum value of `field` across all rows.
*   **`percentile(field, percentile)`**: Returns the value of `field` at the specified percentile (between 0 and 1).
*   **`running_total(field)`**: Returns the cumulative running total of `field` from row 1 up to the current row.
    *   *Example (YTD Cumulative Revenue)*: `running_total(${orders.revenue})`

### Pivot Navigation Functions
*   **`pivot_index(field, pivot_column_number)`**: Returns the value of `field` for the 1-indexed pivot column.
    *   *Example*: `pivot_index(${orders.count}, 2) - pivot_index(${orders.count}, 1)`
*   **`pivot_row(field)`**: Returns a list of all pivoted values for `field` in the current row.
    *   *Example (Row Total across Pivots)*: `sum(pivot_row(${orders.count}))`
*   **`pivot_offset(field, column_offset)`**: Returns the value of `field` from a pivot column offset relative to the current pivot column.
*   **`pivot_offset_list(field, column_offset, length)`**: Returns a list of pivoted values starting at `column_offset` for `length` pivot columns.
*   **`pivot_where(field, condition)`**: Returns the value of `field` in the pivot column where `condition` evaluates to true.

---

## 3. Logical Functions, Operators & Constants

*   **Operators**: `=`, `!=`, `>`, `<`, `>=`, `<=`, `AND`, `OR`, `NOT`
*   **Constants**: `yes`, `no`, `null`
*   **`if(condition, value_if_yes, value_if_no)`**:
    *   *Description*: Evaluates `condition` and returns `value_if_yes` if true, otherwise `value_if_no`.
    *   *Example (Safe Division / Zero Guard)*: `if(offset(${orders.count}, 1) = 0, null, (${orders.count} - offset(${orders.count}, 1)) / offset(${orders.count}, 1))`
*   **`coalesce(value_1, value_2, ...)`**:
    *   *Description*: Returns the first non-null argument from the list.
    *   *Example*: `coalesce(${orders.revenue}, 0)`
*   **`is_null(value)`**: Returns `yes` if `value` is null, otherwise `no`.
*   **`not_null(value)`**: Returns `yes` if `value` is not null, otherwise `no`.

---

## 4. Mathematical Functions & Operators

*   **Operators**: `+` (addition), `-` (subtraction), `*` (multiplication), `/` (division), `^` (exponentiation)
*   **`abs(value)`**: Returns the absolute value of a number.
*   **`ceiling(value)`**: Rounds a number up to the nearest integer.
*   **`exp(value)`**: Returns *e* raised to the power of `value`.
*   **`floor(value)`**: Rounds a number down to the nearest integer.
*   **`ln(value)`**: Returns the natural logarithm of `value`.
*   **`log(value, base)`**: Returns the logarithm of `value` to `base`.
*   **`mod(dividend, divisor)`**: Returns the remainder of dividing `dividend` by `divisor`.
*   **`power(base, exponent)`**: Raises `base` to `exponent`.
*   **`rand()`**: Returns a random number between 0 and 1.
*   **`round(value, decimals)`**: Rounds a number to the specified number of decimal places.
*   **`trunc(value, decimals)`**: Truncates a number to the specified number of decimal places.

---

## 5. String Functions & Operators

*   **String Operator**: `concat(text_1, text_2, ...)`
*   **`concat(text_1, text_2, ...)`**: Concatenates multiple text strings together.
*   **`contains(text, search_string)`**: Returns `yes` if `text` contains `search_string`.
*   **`ends_with(text, search_string)`**: Returns `yes` if `text` ends with `search_string`.
*   **`starts_with(text, search_string)`**: Returns `yes` if `text` starts with `search_string`.
*   **`length(text)`**: Returns the number of characters in `text`.
*   **`lower(text)`**: Converts `text` to lowercase.
*   **`upper(text)`**: Converts `text` to uppercase.
*   **`replace(text, old_string, new_string)`**: Replaces all occurrences of `old_string` with `new_string`.
*   **`substring(text, start_position, length)`**: Extracts a substring from `text` starting at 1-indexed `start_position` for `length` characters.
*   **`trim(text)` / `trim_left(text)` / `trim_right(text)`**: Removes whitespace from both sides, left side, or right side.

---

## 6. Date & Time Functions

*   **`now()`**: Returns the current date and time.
*   **`add_days(date, n)` / `add_months(date, n)` / `add_years(date, n)`**: Adds `n` days/months/years to a date.
*   **`diff_days(date_1, date_2)` / `diff_months(date_1, date_2)` / `diff_years(date_1, date_2)`**: Returns the difference between two dates in days/months/years.
*   **`extract_days(date)` / `extract_months(date)` / `extract_years(date)`**: Extracts the day/month/year component from a date.
*   **`trunc_days(date)` / `trunc_months(date)` / `trunc_years(date)`**: Truncates a date to the start of the day/month/year.
