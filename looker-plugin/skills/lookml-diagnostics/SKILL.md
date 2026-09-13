---
name: lookml-diagnostics
description: Guide for diagnosing and resolving LookML validation failures.
---

# LookML Diagnostics

This skill provides a tactical framework for diagnosing and resolving LookML
validation errors.

## Core Concepts

*   **Validation**: The process of checking LookML for errors (commonly referred
    to as the Looker Validator).
*   **Projects**: The top-level container for all LookML files.
*   **Models**: Define database connections and specify which Explores to
    include.
*   **Explores**: Critically define joins and queryable field sets for users.
*   **Views**: Map to physical database tables or derived tables (SQL-based or
    Native) and encapsulates fields.
*   **Fields**: Dimensions, measures, filters, and parameters.

## Lexical Aliasing and Namespace Overrides

Developers use aliasing parameters to override default bindings, which
frequently drives compilation failures.

*   **`view_name`**: Applied at the Explore level to change the base view
    (renaming the base view in the UI).
*   **`from`**: Applied at the Join level to change the base view utilized for a
    specific join (essential for self-joins).
*   **`extends`**: Introduces object-oriented inheritance at both View and
    Explore levels, creating deep dependency graphs.
*   **`view_label`**: Alters UI presentation ONLY; does not affect generated SQL
    or namespace resolution.
*   **Refinements**: Use `view: +view_name {}` to add to or override existing
    view definitions without modifying the original file.

## Troubleshooting Validation Errors

Refer to the [Looker Error Catalog](error_catalog.md) for a comprehensive
collection of LookML validation errors, structured by problem, possible causes,
and remedies. Use this catalog as the primary reference when troubleshooting.

## Troubleshooting Protocol

1.  **Identify the Error**: Extract the exact error message from the LookML
    validator or logs.
2.  **Consult the Catalog**: Search [error_catalog.md](error_catalog.md) for the
    corresponding problem description.
3.  **Analyze Causes**: Review the possible causes to identify which one applies
    to the current project state.
4.  **Apply Remedies**: Follow the tactical steps to resolve the issue.
5.  **Verify**: Re-run the validator to ensure the error is resolved.
6.  **Iterate**: You may have to repeat the above steps a few times to resolve
    all the issues.

## Best Practices

*   **Explicit Includes**: Use granular `include` paths instead of broad
    wildcards to improve performance and avoid name collisions.
*   **Granular Explores**: Prefer small, focused Explores over monolithic ones
    to simplify the user interface and troubleshooting.
*   **Linting Consistency**: Always insert a blank line before a list to ensure
    proper markdown rendering and avoid lint findings.
