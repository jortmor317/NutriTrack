-- ============================================================
-- CASOS DE USO NUTRITRACK
-- Queries demostrables en Snowflake durante la presentación
-- Base de datos: NUTRITRACK_PRD_GOLD_DB
-- ============================================================

-- ------------------------------------------------------------
-- CASO 1 — Revenue y distribución por plan
-- ¿Qué planes generan más revenue?
-- ------------------------------------------------------------
SELECT
    p.plan_name,
    COUNT(s.subscription_id)                                    as total_suscripciones,
    ROUND(SUM(s.revenue), 2)                                    as revenue_total,
    ROUND(SUM(s.revenue) / SUM(SUM(s.revenue)) OVER () * 100, 2) as pct_revenue
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS s
JOIN NUTRITRACK_PRD_GOLD_DB.GOLD.DIM_SUBSCRIPTION_PLANS p
    ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY revenue_total DESC;

-- ------------------------------------------------------------
-- CASO 2 — Tasa de churn por perfil demográfico
-- ¿Qué perfil de usuario cancela más?
-- ------------------------------------------------------------
SELECT
    u.age_group,
    u.gender,
    COUNT(s.subscription_id)                                    as total_suscripciones,
    SUM(CASE WHEN s.is_cancelled THEN 1 ELSE 0 END)            as canceladas,
    ROUND(SUM(CASE WHEN s.is_cancelled THEN 1 ELSE 0 END) /
          COUNT(s.subscription_id) * 100, 2)                   as tasa_churn_pct
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS s
JOIN NUTRITRACK_PRD_GOLD_DB.GOLD.DIM_USERS u
    ON s.user_id = u.user_id
WHERE u.age_group IS NOT NULL
  AND u.gender IS NOT NULL
GROUP BY u.age_group, u.gender
ORDER BY tasa_churn_pct DESC;

-- ------------------------------------------------------------
-- CASO 3 — Impacto de promociones en churn y fidelización
-- ¿Las promos reducen el churn?
-- ------------------------------------------------------------
SELECT
    s.had_promo,
    COUNT(s.subscription_id)                                    as total_suscripciones,
    ROUND(SUM(s.revenue), 2)                                    as revenue_total,
    ROUND(SUM(s.discount_amount), 2)                           as descuento_total,
    SUM(CASE WHEN s.is_cancelled THEN 1 ELSE 0 END)            as canceladas,
    ROUND(SUM(CASE WHEN s.is_cancelled THEN 1 ELSE 0 END) /
          COUNT(s.subscription_id) * 100, 2)                   as tasa_churn_pct,
    ROUND(AVG(s.duration_days), 0)                             as duracion_media_dias
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS s
GROUP BY s.had_promo
ORDER BY s.had_promo;

-- ------------------------------------------------------------
-- CASO 4 — Motivos de cancelación
-- ¿Por qué cancelan los usuarios?
-- ------------------------------------------------------------
SELECT
    s.cancellation_reason,
    COUNT(s.subscription_id)                                    as total_cancelaciones,
    ROUND(COUNT(s.subscription_id) /
          SUM(COUNT(s.subscription_id)) OVER () * 100, 2)      as pct_total
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS s
WHERE s.is_cancelled = TRUE
  AND s.cancellation_reason IS NOT NULL
GROUP BY s.cancellation_reason
ORDER BY total_cancelaciones DESC;

-- ------------------------------------------------------------
-- CASO 5 — Top 10 alimentos más consumidos (datos USDA)
-- ¿Qué alimentos consumen más los usuarios?
-- ------------------------------------------------------------
SELECT
    f.food_name,
    f.calorie_tier,
    f.macronutrient_profile,
    ROUND(SUM(fl.calories_consumed), 0)                        as total_calorias_consumidas,
    ROUND(SUM(fl.protein_consumed_g), 0)                       as total_proteinas_g,
    COUNT(fl.food_log_item_id)                                 as veces_consumido
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_FOOD_LOGS fl
JOIN NUTRITRACK_PRD_GOLD_DB.GOLD.DIM_FOODS f
    ON fl.food_id = f.food_id
GROUP BY f.food_name, f.calorie_tier, f.macronutrient_profile
ORDER BY total_calorias_consumidas DESC
LIMIT 10;

-- ------------------------------------------------------------
-- CASO 6 — Adherencia a objetivos calóricos por perfil
-- ¿Qué perfil de usuario cumple mejor sus objetivos?
-- ------------------------------------------------------------
SELECT
    u.age_group,
    u.gender,
    ROUND(AVG(fl.pct_daily_calories), 2)                       as pct_objetivo_calorico_medio,
    COUNT(DISTINCT fl.user_id)                                 as usuarios
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_FOOD_LOGS fl
JOIN NUTRITRACK_PRD_GOLD_DB.GOLD.DIM_USERS u
    ON fl.user_id = u.user_id
WHERE fl.pct_daily_calories IS NOT NULL
  AND u.age_group IS NOT NULL
GROUP BY u.age_group, u.gender
ORDER BY pct_objetivo_calorico_medio DESC;

-- ------------------------------------------------------------
-- CASO 7 — Recetas con mejor perfil nutricional
-- ¿Qué recetas tienen mejor balance de macronutrientes?
-- ------------------------------------------------------------
SELECT
    r.recipe_name,
    r.category,
    n.specialty                                                as nutritionist_specialty,
    rn.total_calories,
    rn.total_protein_g,
    rn.total_carbs_g,
    rn.total_fat_g,
    rn.macronutrient_profile,
    rn.total_ingredients
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_RECIPE_NUTRITION rn
JOIN NUTRITRACK_PRD_GOLD_DB.GOLD.DIM_RECIPES r
    ON rn.recipe_id = r.recipe_id
JOIN NUTRITRACK_PRD_GOLD_DB.GOLD.DIM_NUTRITIONISTS n
    ON r.nutritionist_id = n.nutritionist_id
WHERE rn.macronutrient_profile = 'protein_rich'
  AND rn.total_calories IS NOT NULL
ORDER BY rn.total_protein_g DESC
LIMIT 10;

-- ------------------------------------------------------------
-- CASO 8 — SCD2 en acción
-- ¿Cómo ver el historial de cambios en snap_subscription_plans?
-- ------------------------------------------------------------
SELECT
    plan_id,
    plan_name,
    price,
    billing_period,
    dbt_valid_from,
    dbt_valid_to,
    CASE WHEN dbt_valid_to IS NULL THEN 'VIGENTE' ELSE 'HISTÓRICO' END as estado
FROM NUTRITRACK_PRD_SILVER_DB.SNAPSHOTS.SNAP_SUBSCRIPTION_PLANS
ORDER BY plan_name, dbt_valid_from;

-- ------------------------------------------------------------
-- CASO 9 — Demostración incremental
-- Registros procesados hoy por los modelos incrementales
-- ------------------------------------------------------------
SELECT 'FCT_SUBSCRIPTIONS' as modelo, COUNT(*) as registros_hoy
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS
WHERE created_at >= CURRENT_DATE()
UNION ALL
SELECT 'FCT_FOOD_LOGS', COUNT(*)
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_FOOD_LOGS
WHERE log_date >= CURRENT_DATE();