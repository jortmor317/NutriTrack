{% macro validate_scd2() %}

    {% set silver_db = "NUTRITRACK_" ~ env_var('DBT_ENVIRONMENTS') ~ "_SILVER_DB" %}

    {% set planes = run_query(
        "SELECT plan_name, price, dbt_valid_from, dbt_valid_to,
                CASE WHEN dbt_valid_to IS NULL THEN 'VIGENTE' ELSE 'HISTÓRICO' END as estado
         FROM " ~ silver_db ~ ".SNAPSHOTS.SNAP_SUBSCRIPTION_PLANS
         WHERE plan_name = 'Basic'
         ORDER BY dbt_valid_from"
    ) %}

    {{ log("✅ Historial SCD2 del plan Basic:", info=true) }}
    {% for row in planes %}
        {{ log("  → precio: " ~ row[1] ~ " | válido desde: " ~ row[2] ~ " | válido hasta: " ~ row[3] ~ " | " ~ row[4], info=true) }}
    {% endfor %}

{% endmacro %}