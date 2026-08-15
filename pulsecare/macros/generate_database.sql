{% macro generate_database_name(custom_database_name, node) -%}

    {#
        Mirrors generate_schema_name.sql: keeps every model/snapshot
        in whichever catalog the active target points at
        (dev.duckdb vs prod.duckdb), so dev/prod stay physically
        isolated without any per-model database config. A custom
        database name, if ever supplied, still wins.
    #}

    {%- set default_database = target.database -%}
    {%- if custom_database_name is none -%}

        {{ default_database }}

    {%- else -%}

        {{ custom_database_name }}

    {%- endif -%}

{%- endmacro %}
