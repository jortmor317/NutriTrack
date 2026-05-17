-- Todos los food_id en fct_food_logs
-- deben existir en dim_foods
SELECT
    fl.food_log_item_id,
    fl.food_id
FROM {{ ref('fct_food_logs') }} fl
LEFT JOIN {{ ref('dim_foods') }} f
    ON fl.food_id = f.food_id
WHERE f.food_id IS NULL