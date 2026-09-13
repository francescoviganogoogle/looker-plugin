# LookML Dashboard Filters & Tile Listening Parameter Reference

This reference guide provides the complete LookML parameter reference, syntax rules, filter types, `ui_config` options, cascading filter dependencies, and element listening directives for LookML dashboards (`.dashboard.lookml`), based on the official [Google Cloud Looker Documentation](https://docs.cloud.google.com/looker/docs/reference/param-lookml-dashboard#filters).

---

## 1. Dashboard-Level Filter Bar Controls

The following parameters are declared at the root level of the dashboard (`- dashboard: <slug>`):

```yaml
- dashboard: <dashboard_slug>
  title: "<Dashboard_Title>"
  layout: newspaper
  filters_bar_collapsed: false # Default: false. If true, filter bar is collapsed until viewer expands it.
  filters_location_top: true   # Default: true. If false, filter bar appears on the right side of dashboard.
  show_filters_bar: true       # Cosmetic visibility toggle (useful in embedded contexts).
```

---

## 2. Top-Level `filters:` Parameter Reference

All dashboard filters MUST be declared in the top-level `filters:` block. NEVER place `type: date_filter` or `type: field_filter` inside `elements:`.

### Complete Filter Declaration Syntax

```yaml
filters:
  - name: <filter_name>
    title: "<Filter_Display_Title>"
    type: field_filter | number_filter | date_filter | string_filter
    model: <model_name>           # Required when type: field_filter
    explore: <explore_name>       # Required when type: field_filter
    field: <view_name>.<field_name>  # Required when type: field_filter (must be fully qualified)
    default_value: "<filter_expression>" # Optional default (e.g. "90 days", "Complete", "50 to 100")
    allow_multiple_values: true | false  # Default: true. Set false for single-select filters.
    required: true | false               # Default: false. If true, dashboard will not run when empty.
    ui_config:                           # Optional visual control configuration
      type: button_group | button_toggles | radio_buttons | checkboxes | dropdown_menu | tag_list | day_picker | day_range_picker | date_time_range_input | relative_timeframes | range_slider | slider | advanced
      display: inline | popover | overflow
      options:
        - "<option_1>"
        - "<option_2>"
    listens_to_filters:                  # Optional cascading filter dependencies
      - <parent_filter_name>
```

---

## 3. Core Filter Types (`type:`)

| Filter Type | Description | Required Parameters | Suggestions Behavior |
| :--- | :--- | :--- | :--- |
| **`field_filter`** | Binds to an underlying LookML field. Standard choice for dimension or measure filtering. | `model`, `explore`, `field` | Automatically generates filter suggestions for `type: string` fields. |
| **`date_filter`** | Accepts date values, ranges, or relative time expressions (e.g. `"90 days"`, `"last month"`). | `name`, `title` | Does not generate string suggestions; renders date picker or timeframe widget. |
| **`number_filter`** | Accepts numerical integers/floats or range expressions (e.g. `"50 to 100"`, `"> 10"`). | `name`, `title` | Does not generate suggestions; renders numeric input or slider. |
| **`string_filter`** | Accepts freeform text input without requiring field association. | `name`, `title` | Does not generate suggestions; renders text box or button controls. |

---

## 4. Filter Control Styling (`ui_config:`)

The `ui_config:` block controls the visual widget, display position, and selectable option values.

```yaml
ui_config:
  type: <control_type>
  display: inline | popover | overflow
  options:
    - "<value_1>"
    - "<value_2>"
```

### A. `ui_config.type` Options & Data Type Compatibility

| `ui_config.type` | Selection Mode | Description | Compatible Data Types |
| :--- | :--- | :--- | :--- |
| **`button_group`** | Multiple | Row of clickable buttons for each value in `options`. | String (`STR`), Number (`NUM`), Tier (`TIER`), Zipcode (`ZIP`), YesNo (`Y/N`), Distance (`DIST`), Duration (`DUR`) |
| **`checkboxes`** | Multiple | Checkboxes for each value specified in `options`. | `STR`, `NUM`, `TIER`, `ZIP`, `Y/N`, `DIST`, `DUR` |
| **`tag_list`** | Multiple | Multi-select drop-down tag list of `options`. | `STR`, `NUM`, `TIER`, `ZIP`, `DIST`, `DUR` |
| **`range_slider`** | Multiple | Dual-thumb slider for setting numeric ranges (uses `min` and `max` in `options`). | `NUM`, `DIST`, `DUR` |
| **`button_toggles`** | Single | Single-select group of button toggles for `options`. | `STR`, `NUM`, `TIER`, `ZIP`, `Y/N`, `DIST`, `DUR`, Parameter (`PAR`) |
| **`radio_buttons`** | Single | Radio buttons including an explicit "Any value" option. | `STR`, `NUM`, `TIER`, `ZIP`, `Y/N`, `DIST`, `DUR`, `PAR` |
| **`dropdown_menu`** | Single | Drop-down menu listing `options` plus "Any value". | `STR`, `NUM`, `TIER`, `ZIP`, `Y/N`, `DIST`, `DUR`, `PAR` |
| **`slider`** | Single | Single-value slider between `min` and `max` values in `options`. | `NUM`, `DIST`, `DUR` |
| **`day_picker`** | Single Date | Single date picker control. | Date & Time (`D&T`) |
| **`day_range_picker`** | Date Range | Date range picker control selecting start and end dates. | `D&T` |
| **`date_time_range_input`** | Date & Time Range | Picker selecting specific date and time ranges. | `D&T` |
| **`relative_timeframes`** | Timeframe Preset | Range or presets ("Today", "Last 7 Days", "Last 90 Days"). | `D&T` |
| **`advanced`** | Freeform / Expression | Standard Looker filter expression text control. | All supported data types |

### B. `ui_config.display` Placement

- **`inline`**: The filter control is rendered directly in the top dashboard filter bar.
- **`popover`**: A compact summary value is shown in the top bar; clicking opens the full popover widget.
- **`overflow`**: Filter is placed inside the "More" overflow button dropdown.

### C. `ui_config.options` Subparameter

- **Discrete Value List**:
  ```yaml
  ui_config:
    type: button_group
    display: inline
    options:
      - "Option A"
      - "Option B"
      - "Option C"
  ```
- **Slider Numeric Range (`min` / `max`)**:
  ```yaml
  ui_config:
    type: range_slider
    display: inline
    options:
      min: 0
      max: 1000
  ```

---

## 5. Linked Cascading Filters (`listens_to_filters:`)

For `type: field_filter`, you can dynamically narrow the suggested values of a filter based on the user's selection in a parent filter using `listens_to_filters:`:

```yaml
filters:
  - name: country_filter
    title: "Country"
    type: field_filter
    model: <model_name>
    explore: <explore_name>
    field: locations.country

  - name: state_filter
    title: "State / Province"
    type: field_filter
    model: <model_name>
    explore: <explore_name>
    field: locations.state
    listens_to_filters:
      - country_filter
```

---

## 6. Tile Listening Syntax (`listen:`)

Data tiles in `elements:` connect to top-level filters via `listen:`, mapping the local filter name `<filter_name>` to the target Explore field `<view_name>.<field_name>`:

```yaml
elements:
  - name: <element_name>
    title: "<Element_Title>"
    type: single_value | looker_line | looker_column | looker_bar | looker_area | looker_grid
    model: <model_name>
    explore: <explore_name>
    fields: [<view_name>.<field_name_1>, <view_name>.<field_name_2>]
    listen:
      <filter_name_1>: <view_name>.<field_name_1>
      <filter_name_2>: <view_name>.<field_name_2>
    row: 0
    col: 0
    width: 12
    height: 8
```

### Merged Queries Tile Listening
For dashboard elements using `merged_queries`, each source query declares its own `listen:` block independently inside `query_fields`:

```yaml
elements:
  - name: viz_merged_element
    type: looker_column
    merged_queries:
      - model: <model_name_1>
        explore: <explore_name_1>
        fields: [<view_1>.<field_1>]
        listen:
          <filter_name>: <view_1>.<field_1>
      - model: <model_name_2>
        explore: <explore_name_2>
        fields: [<view_2>.<field_2>]
        listen:
          <filter_name>: <view_2>.<field_2>
```
