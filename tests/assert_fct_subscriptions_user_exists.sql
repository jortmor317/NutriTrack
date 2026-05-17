{{ config(severity='warn') }}

-- Suscripciones con user_id que no existe en dim_users
-- WARN (no error): consecuencia conocida de la deduplicación en stg_users
-- Los usuarios duplicados por email fueron eliminados en Silver
-- pero sus suscripciones se preservan en fct_subscriptions
SELECT
    s.subscription_id,
    s.user_id
FROM {{ ref('fct_subscriptions') }} s
LEFT JOIN {{ ref('dim_users') }} u
    ON s.user_id = u.user_id
WHERE u.user_id IS NULL