{% macro validate_incremental() %}

    {% set gold_db = "NUTRITRACK_" ~ env_var('DBT_ENVIRONMENTS') ~ "_GOLD_DB" %}

    -- Verificar nueva suscripción en Gold
    {% set suscripciones = run_query(
        "SELECT subscription_id, user_id, start_date, status, revenue, created_at
         FROM " ~ gold_db ~ ".GOLD.FCT_SUBSCRIPTIONS
         WHERE created_at >= CURRENT_DATE()
         ORDER BY created_at DESC
         LIMIT 5"
    ) %}

    {{ log("✅ Nuevas suscripciones en Gold hoy:", info=true) }}
    {% for row in suscripciones %}
        {{ log("  → " ~ row[0] ~ " | user: " ~ row[1] ~ " | revenue: " ~ row[4], info=true) }}
    {% endfor %}

    -- Verificar nuevo food log en Gold
    {% set food_logs = run_query(
        "SELECT food_log_item_id, user_id, log_date, meal_type, calories_consumed, created_at
         FROM " ~ gold_db ~ ".GOLD.FCT_FOOD_LOGS
         WHERE created_at >= CURRENT_DATE()
         ORDER BY created_at DESC
         LIMIT 5"
    ) %}

    {{ log("✅ Nuevos food logs en Gold hoy:", info=true) }}
    {% for row in food_logs %}
        {{ log("  → " ~ row[0] ~ " | user: " ~ row[1] ~ " | meal: " ~ row[3], info=true) }}
    {% endfor %}

{% endmacro %}