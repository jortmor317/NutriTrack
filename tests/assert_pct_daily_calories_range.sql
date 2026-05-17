-- El porcentaje de objetivo calórico no debe ser negativo
-- No ponemos límite superior porque un usuario puede consumir
-- más del 1000% de su objetivo en un día (datos reales USDA)
SELECT
    food_log_item_id,
    pct_daily_calories
FROM {{ ref('fct_food_logs') }}
WHERE pct_daily_calories < 0