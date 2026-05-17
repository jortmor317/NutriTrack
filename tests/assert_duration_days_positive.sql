-- La duración de una suscripción nunca debe ser negativa
SELECT
    subscription_id,
    duration_days,
    start_date,
    end_date
FROM {{ ref('fct_subscriptions') }}
WHERE duration_days < 0