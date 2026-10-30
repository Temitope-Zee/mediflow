{#- Use the schema names exactly as written in dbt_project.yml (staging, intermediate, marts) -#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ custom_schema_name if custom_schema_name is not none else target.schema }}
{%- endmacro %}
