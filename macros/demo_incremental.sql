{% macro demo_incremental() %}

    -- PASO 1 — Nueva suscripción en Bronze
    INSERT INTO {{ source('nutritrack', 'SUBSCRIPTIONS') }}
    (ID, USER_ID, PLAN_ID, PROMO_ID, START_DATE, END_DATE, STATUS, CREATED_AT)
    SELECT
        UUID_STRING(),
        (SELECT ID FROM {{ source('nutritrack', 'USERS') }} ORDER BY RANDOM() LIMIT 1),
        (SELECT ID FROM {{ source('nutritrack', 'SUBSCRIPTION_PLANS') }} ORDER BY RANDOM() LIMIT 1),
        NULL,
        CURRENT_DATE(),
        NULL,
        'active',
        CURRENT_TIMESTAMP();

    -- PASO 2 — Nuevo food log item en Bronze
    INSERT INTO {{ source('nutritrack', 'FOOD_LOG_ITEMS') }}
    (ID, FOOD_LOG_ID, FOOD_ID, QUANTITY_G, UNIT, FDC_ID)
    SELECT
        UUID_STRING(),
        (SELECT ID FROM {{ source('nutritrack', 'FOOD_LOGS') }} ORDER BY RANDOM() LIMIT 1),
        (SELECT FOOD_ID FROM {{ source('nutritrack', 'FOOD_LOG_ITEMS') }} LIMIT 1),
        100,
        'g',
        (SELECT FDC_ID FROM {{ source('nutritrack', 'FOOD_LOG_ITEMS') }} WHERE FDC_ID IS NOT NULL LIMIT 1);

    {{ log("✅ Registros insertados en Bronze DEV.", info=true) }}
    {{ log("Ahora ejecuta: dbt build --select fct_subscriptions fct_food_logs", info=true) }}

{% endmacro %}