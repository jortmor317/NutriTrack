{% macro demo_scd2() %}

    -- ============================================================
    -- DEMO SCD2 NUTRITRACK
    -- Simula un cambio de precio en un plan para demostrar
    -- el funcionamiento de los snapshots SCD2.
    --
    -- Uso:
    -- Paso 1: dbt run-operation demo_scd2
    -- Paso 2: dbt snapshot
    -- Paso 3: dbt run-operation validate_scd2
    -- ============================================================

    {% set bronze_db = "NUTRITRACK_" ~ env_var('DBT_ENVIRONMENTS') ~ "_BRONZE_DB" %}

    -- Subimos el precio de Basic de 4.99 a 6.99
    {% set update_query %}
        UPDATE {{ bronze_db }}.RAW.SUBSCRIPTION_PLANS
        SET PRICE = '6.99'
        WHERE NAME = 'Basic'
        AND PRICE = '4.99';
    {% endset %}
    {% do run_query(update_query) %}

    {{ log("✅ Precio de Basic actualizado de 4.99 a 6.99 en Bronze.", info=true) }}
    {{ log("Ahora ejecuta: dbt snapshot", info=true) }}
    {{ log("Luego ejecuta: dbt run-operation validate_scd2", info=true) }}

{% endmacro %}