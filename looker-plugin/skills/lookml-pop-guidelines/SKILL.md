---
name: lookml-pop-guidelines
description: >-
  Guidelines for implementing Period-over-Period (PoP) analysis in LookML
  for e.g. YoY, MoM, QoQ etc.
---

# Period-over-Period (PoP) Guidelines

This guide provides best practices and patterns for implementing
Period-over-Period (PoP) analysis in LookML.

--------------------------------------------------------------------------------

## 1. Native PoP Measures: Syntax & Parameters

Looker provides a built-in measure `type: period_over_period` that automatically
computes comparisons like Month-over-Month (MoM), Quarter-over-Quarter (QoQ), or
Year-over-Year (YoY) entirely within LookML, eliminating the need for complex
derived tables.

A native PoP measure requires specific subparameters to function correctly:

*   **`based_on`:** The LookML reference to the base metric you are comparing
    (e.g., `${total_sales}`). This **must** be an aggregate measure (like `type:
    sum` or `type: count`); you cannot base PoP on non-aggregate measures.
*   **`based_on_time`:** The date/time dimension used to align the periods
    across the data (e.g., `${created_date}`).
*   **`period`:** The interval for the comparison (e.g., `year`, `quarter`,
    `month`, `week`).
*   **`kind`:** Defines the output calculation type.
    *   `previous`: Returns the raw value of the metric from the previous period
        (default).
    *   `difference`: Calculates the absolute change (current period value minus
        previous period value).
    *   `relative_change`: Calculates the percentage change/growth (absolute
        change divided by previous period value).
*   **`value_to_date`:** When set to `yes`, Looker restricts the previous
    period's calculation to the exact elapsed fraction of the current period.
    This is essential for accurate Year-to-Date (YTD) or Month-to-Date (MTD)
    comparisons (e.g., comparing Jan 1–June 6 of this year strictly to Jan
    1–June 6 of last year).

--------------------------------------------------------------------------------

## 2. Rules, Limitations, & Explore Requirements

To prevent query failures, an agent writing native PoP measures must adhere to
these technical constraints:

*   **Timeframe Granularity:** The timeframe selected in the user's Explore
    query **must be equal to or smaller than** the `period` defined in the
    LookML. For instance, if the measure uses `period: month`, the user must
    query by `date` or `week`.
*   **Timestamp Requirement:** The queried timeframe must inherently contain
    timestamp data. Abstract timeframes like `day_of_week` or `month_name` lack
    specific historical context and will break PoP measures unless accompanied
    by a strict date dimension (like `created_date`) in the query.
*   **No Arbitrary Intervals:** Native PoP strictly compares a standardized
    period to the *immediately preceding* period of the same type. It does not
    natively support arbitrary intervals (e.g., comparing the last 14 days to
    the previous 14 days) or offset gaps (e.g., comparing May of this year to
    December of last year).
*   **Feature Incompatibilities:** Native PoP measures cannot be used with
    Aggregate Awareness, Subtotals, Cohort Analysis, or Rolling Calculations.
    Furthermore, you cannot use Liquid parameters inside the PoP measure
    definition itself.
*   **No Filtering on PoP Measures:** You cannot apply filters directly to a
    `period_over_period` measure (e.g., in the Explore UI or inside LookML). To
    filter the results of a PoP comparison, you must filter the underlying base
    measure, or use custom SQL/derived table calculations if dynamic filtering
    is required.

--------------------------------------------------------------------------------

## 3. Handling Weeks and Custom/Fiscal Calendars

For highly accurate week-based comparisons or fiscal calendars, Looker
recommends defining a custom calendar table in your data warehouse.

*   To enable PoP analysis on custom calendars, your `calendar_definition`
    LookML block must explicitly include the `previous_ordinal_mapping`
    parameter to map custom timeframes to their previous equivalents in the
    database.
*   Instead of `period`, you must use `custom_calendar_period` (e.g.,
    `custom_calendar_period: custom_year`) in your measure definition.

### Defining a Custom Calendar View

Your database custom calendar table must be modeled in LookML with a
`calendar_definition` block. All mandatory timeframe mapping dimensions must be
defined in the view.

```lookml
view: fiscal_calendar_table {
  sql_table_name: `my_project.my_dataset.fiscal_calendar_table` ;;

  calendar_definition: {
    reference_date: reference_date

    # Maps timeframe fields to database columns
    timeframe_mapping: {
      custom_date: reference_date
      custom_week: fiscal_week_of_year
      custom_period: fiscal_period_of_year
      custom_quarter: fiscal_quarter_of_year
      custom_year: fiscal_year
      custom_season: fiscal_season
    }

    # Maps timeframes to numeric ordinals for offset calculations
    timeframe_ordinal_mapping: {
      custom_date: reference_date_num
      custom_week: fiscal_week_of_year_num
      custom_period: fiscal_period_of_year_num
      custom_quarter: fiscal_quarter_of_year_num
      custom_year: fiscal_year_num
      custom_season: fiscal_season_num
    }

    # REQUIRED for Period-over-Period custom calendar measures
    previous_ordinal_mapping: {
      custom_date: prev_day_num
      custom_week: prev_week_num
    }
  }

  # Mandatory mappings as underlying dimensions
  dimension: reference_date {
    type: date
    primary_key: yes
    sql: ${TABLE}.reference_date ;;
  }

  dimension: reference_date_num {
    type: number
    sql: ${TABLE}.reference_date_num ;;
  }

  dimension: fiscal_week_of_year {
    type: string
    sql: ${TABLE}.fiscal_week_of_year ;;
  }

  dimension: fiscal_week_of_year_num {
    type: number
    sql: ${TABLE}.fiscal_week_of_year_num ;;
  }

  dimension: prev_day_num {
    type: number
    sql: ${TABLE}.prev_day_num ;;
  }

  dimension: prev_week_num {
    type: number
    sql: ${TABLE}.prev_week_num ;;
  }

  # ... Include other dimensions for period, quarter, season, year ...
}
```

### Linking to a Custom Calendar Dimension Group

Once the calendar view is defined, you link it to a standard date column in
another view via a `dimension_group` of `type: custom_calendar`:

```lookml
view: employees {
  # ... Other fields ...

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  # Base timestamp field (hidden, cast to date)
  dimension: hire_raw {
    type: date
    hidden: yes
    sql: CAST(${TABLE}.hire_date AS DATE) ;;
  }

  # Link the custom calendar using based_on_calendar
  dimension_group: hire {
    type: custom_calendar
    sql: ${hire_raw} ;;
    based_on_calendar: fiscal_calendar_table
  }
}
```

### Joining Custom Calendar in the Explore

To resolve the custom timeframe mapping, you must join the custom calendar view
to your base explore:

```lookml
explore: employee_hub {
  from: employees

  join: fiscal_calendar_table {
    relationship: many_to_one
    sql_on: ${employee_hub.hire_raw}
            = ${fiscal_calendar_table.reference_date} ;;
  }
}
```

### Defining Native PoP Measures on Custom Calendars

Now you can write PoP measures comparing the custom timeframes using the
`custom_calendar_period` parameter:

```lookml
measure: total_hires {
  type: count
}

# Returns hires from the previous custom fiscal year
measure: hires_previous_fiscal_year {
  type: period_over_period
  based_on: total_hires
  based_on_time: employee_hub.hire_custom_year
  custom_calendar_period: custom_year
  kind: previous
}

# Returns percentage growth compared to the previous custom fiscal year
measure: hires_yoy_fiscal_growth {
  type: period_over_period
  based_on: total_hires
  based_on_time: employee_hub.hire_custom_year
  custom_calendar_period: custom_year
  kind: relative_change
  value_format_name: percent_2
}
```

--------------------------------------------------------------------------------

## 4. Alternative Pattern: Arbitrary Period Comparisons

Because native PoP cannot evaluate dynamic user-selected ranges (like 12 days
vs. previous 12 days), you must build an alternative LookML structure using
templated filters and filtered measures:

1.  **Filter Entry:** Create a `type: date` filter for the user to select the
    range.
2.  **Date Math:** Use Liquid (`{% date_start %}` and `{% date_end %}`) to
    capture the boundaries and calculate the exact interval (e.g., 12 days).
3.  **Boundary Logic:** Subtract the interval from the start date to define the
    exact boundaries of the "Previous Period."
4.  **Boolean Flags:** Create `type: yesno` dimensions that evaluate if a raw
    timestamp falls into the "Selected Period" or the "Previous Period."
5.  **Filtered Measures:** Apply those `yesno` dimensions as hardcoded filters
    on standard measures.

--------------------------------------------------------------------------------

## 5. Canonical LookML Examples

### Example A: Native YTD Year-Over-Year Measure

*The optimal pattern for standard PoP comparisons up to the current day.*

```lookml
measure: total_sales {
  type: sum
  sql: ${sale_price} ;;
}

measure: total_sales_previous_year {
  type: period_over_period
  based_on: total_sales
  based_on_time: created_date
  period: year
  kind: previous
  value_to_date: yes
  description: "Matches the exact YTD elapsed time for the previous year"
}
```

### Example B: Arbitrary/Dynamic Period Comparison Pattern

*The workaround pattern for dynamic intervals not supported by native PoP.*

```lookml
# 1. User Input Filter
filter: dynamic_date_filter {
  type: date
  description: "Select a range. The measure will compare to the
    immediately preceding period of the exact same length."
}

# 2. Boolean flags to separate current and past periods
dimension: is_current_period {
  type: yesno
  hidden: yes
  sql: {% condition dynamic_date_filter %} ${created_raw} {% endcondition %} ;;
}

# Example using BigQuery / Standard SQL dialect date math:
dimension: is_previous_period {
  type: yesno
  hidden: yes
  sql:
    ${created_raw} >= TIMESTAMP_SUB(
      {% date_start dynamic_date_filter %},
      INTERVAL TIMESTAMP_DIFF(
        {% date_end dynamic_date_filter %},
        {% date_start dynamic_date_filter %},
        DAY
      ) DAY
    )
    AND ${created_raw} < {% date_start dynamic_date_filter %} ;;
}

# 3. Filtered Measures
measure: current_period_sales {
  type: sum
  sql: ${sale_price} ;;
  filters: [is_current_period: "yes"]
}

measure: previous_period_sales {
  type: sum
  sql: ${sale_price} ;;
  filters: [is_previous_period: "yes"]
}
```

### Example C: Native Growth and Percentage Change Measures

*The optimal pattern for calculating absolute differences and percentage growth
YoY.*

```lookml
measure: total_sales {
  type: sum
  sql: ${sale_price} ;;
}

measure: total_sales_previous_year {
  type: period_over_period
  based_on: total_sales
  based_on_time: created_date
  period: year
  kind: previous
}

measure: total_sales_yoy_difference {
  type: period_over_period
  based_on: total_sales
  based_on_time: created_date
  period: year
  kind: difference
  description: "The absolute change in sales compared to last year"
}

measure: total_sales_yoy_growth {
  type: period_over_period
  based_on: total_sales
  based_on_time: created_date
  period: year
  kind: relative_change
  value_format_name: percent_2
  description: "The percentage growth in sales compared to last year"
}
```
