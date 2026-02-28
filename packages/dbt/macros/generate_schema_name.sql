{#
    This macro overrides the default schema naming behavior.
    By default, dbt creates schemas like: target_schema_model_schema
    This macro uses the model's schema directly for cleaner naming.
#}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
