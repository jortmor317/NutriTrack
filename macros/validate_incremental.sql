{% macro validate_incremental() %}

    {% set gold_db = "NUTRITRACK_" ~ env_var('DBT_ENVIRONMENTS') ~ "_GOLD_DB" %}

    -- Verificar nueva suscripción en Gold
    {% set suscripciones = run_query(
        "SELECT subscription_id, user_id, start_date, status, revenue, created_at
         FROM " ~ gold_db ~ ".GOLD.FCT_SUBSCRIPTIONS
         ORDER BY created_at DESC
         LIMIT 5"
    ) %}

    {{ log("✅ Últimas suscripciones en Gold:", info=true) }}
    {% for row in suscripciones %}
        {{ log("  → " ~ row[0] ~ " | user: " ~ row[1] ~ " | revenue: " ~ row[4] ~ " | created: " ~ row[5], info=true) }}
    {% endfor %}

    -- Verificar nuevo food log en Gold
    {% set food_logs = run_query(
        "SELECT food_log_item_id, user_id, log_date, meal_type, calories_consumed, created_at
         FROM " ~ gold_db ~ ".GOLD.FCT_FOOD_LOGS
         ORDER BY created_at DESC
         LIMIT 5"
    ) %}

    {{ log("✅ Últimos food logs en Gold:", info=true) }}
    {% for row in food_logs %}
        {{ log("  → " ~ row[0] ~ " | user: " ~ row[1] ~ " | meal: " ~ row[3] ~ " | calories: " ~ row[4], info=true) }}
    {% endfor %}

{% endmacro %}