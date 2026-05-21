{% macro demo_scd2() %}

    {% set bronze_db = "NUTRITRACK_" ~ env_var('DBT_ENVIRONMENTS') ~ "_BRONZE_DB" %}

    {% set update_price %}
        UPDATE {{ bronze_db }}.RAW.SUBSCRIPTION_PLANS
        SET PRICE = (PRICE::FLOAT + 1)::VARCHAR
        WHERE NAME = 'Basic';
    {% endset %}
    {% do run_query(update_price) %}

    {{ log("✅ Precio de Basic incrementado en 1€ en Bronze.", info=true) }}
    {{ log("Ahora ejecuta: dbt snapshot", info=true) }}
    {{ log("Luego ejecuta: dbt run-operation validate_scd2", info=true) }}

{% endmacro %}