-- El revenue nunca debe ser negativo o nulo
-- Si devuelve filas, el test falla
SELECT
    subscription_id,
    revenue
FROM {{ ref('fct_subscriptions') }}
WHERE revenue < 0
   OR revenue IS NULL