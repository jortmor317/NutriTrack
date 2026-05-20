-- ============================================================
-- SCRIPT DE DEMO PARA LA PRESENTACIÓN
-- Ejecutar en Snowflake durante la defensa
-- ============================================================

-- ============================================================
-- DEMO 1 — INCREMENTAL
-- ============================================================

-- PASO 0 — Estado ANTES (ejecutar primero para mostrar al tribunal)
SELECT 'FCT_SUBSCRIPTIONS' as tabla, COUNT(*) as total
FROM NUTRITRACK_DEV_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS
UNION ALL
SELECT 'FCT_FOOD_LOGS', COUNT(*)
FROM NUTRITRACK_DEV_GOLD_DB.GOLD.FCT_FOOD_LOGS;

-- PASO 1 — Ejecutar en dbt Cloud IDE:
-- dbt run-operation demo_incremental
-- dbt build --select fct_subscriptions fct_food_logs

-- PASO 2 — Estado DESPUÉS (ejecutar para demostrar que aumentaron las filas)
SELECT 'FCT_SUBSCRIPTIONS' as tabla, COUNT(*) as total
FROM NUTRITRACK_DEV_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS
UNION ALL
SELECT 'FCT_FOOD_LOGS', COUNT(*)
FROM NUTRITRACK_DEV_GOLD_DB.GOLD.FCT_FOOD_LOGS;

-- PASO 3 — Ver el registro nuevo en Gold
SELECT subscription_id, user_id, revenue, created_at
FROM NUTRITRACK_DEV_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS
ORDER BY created_at DESC
LIMIT 3;

-- ============================================================
-- DEMO 2 — SCD2
-- ============================================================

-- PASO 0 — Estado ANTES (una sola versión de Basic a 4.99)
SELECT plan_name, price, dbt_valid_from, dbt_valid_to,
    CASE WHEN dbt_valid_to IS NULL THEN 'VIGENTE' ELSE 'HISTÓRICO' END as estado
FROM NUTRITRACK_DEV_SILVER_DB.SNAPSHOTS.SNAP_SUBSCRIPTION_PLANS
WHERE plan_name = 'Basic'
ORDER BY dbt_valid_from;

-- PASO 1 — Ejecutar en dbt Cloud IDE:
-- dbt run-operation demo_scd2
-- dbt snapshot

-- PASO 2 — Estado DESPUÉS (dos versiones: 4.99 HISTÓRICO + 6.99 VIGENTE)
SELECT plan_name, price, dbt_valid_from, dbt_valid_to,
    CASE WHEN dbt_valid_to IS NULL THEN 'VIGENTE' ELSE 'HISTÓRICO' END as estado
FROM NUTRITRACK_DEV_SILVER_DB.SNAPSHOTS.SNAP_SUBSCRIPTION_PLANS
WHERE plan_name = 'Basic'
ORDER BY dbt_valid_from;

-- PASO 3 — Demostrar que el revenue histórico es correcto con SCD2
-- Las suscripciones contratadas ANTES del cambio usan precio 4.99
-- Las contratadas DESPUÉS usan precio 6.99
SELECT 
    s.subscription_id,
    s.start_date,
    p.price as precio_vigente_en_contratacion,
    p.dbt_valid_from,
    p.dbt_valid_to
FROM NUTRITRACK_DEV_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS s
JOIN NUTRITRACK_DEV_SILVER_DB.SNAPSHOTS.SNAP_SUBSCRIPTION_PLANS p
    ON s.plan_id = p.plan_id
    AND s.start_date BETWEEN p.dbt_valid_from 
    AND COALESCE(p.dbt_valid_to, CURRENT_DATE())
WHERE p.plan_name = 'Basic'
ORDER BY s.start_date DESC
LIMIT 10;

-- ============================================================
-- DEMO 3 — PIPELINE COMPLETO DEV → PRD
-- ============================================================

-- PASO 0 — Estado ANTES en PRD
SELECT 'FCT_SUBSCRIPTIONS' as tabla, COUNT(*) as total
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS
UNION ALL
SELECT 'FCT_FOOD_LOGS', COUNT(*)
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_FOOD_LOGS;

-- PASO 1 — Insertar registro nuevo en Bronze PRD
INSERT INTO NUTRITRACK_PRD_BRONZE_DB.RAW.SUBSCRIPTIONS
(ID, USER_ID, PLAN_ID, PROMO_ID, START_DATE, END_DATE, STATUS, CREATED_AT)
SELECT
    UUID_STRING(),
    (SELECT ID FROM NUTRITRACK_PRD_BRONZE_DB.RAW.USERS ORDER BY RANDOM() LIMIT 1),
    (SELECT ID FROM NUTRITRACK_PRD_BRONZE_DB.RAW.SUBSCRIPTION_PLANS ORDER BY RANDOM() LIMIT 1),
    NULL,
    CURRENT_DATE(),
    NULL,
    'active',
    CURRENT_TIMESTAMP();

-- PASO 2 — Ejecutar en dbt Cloud:
-- Deploy → Jobs → PRD - Ingesta diaria → Run now

-- PASO 3 — Estado DESPUÉS en PRD (debe haber aumentado en 1)
SELECT 'FCT_SUBSCRIPTIONS' as tabla, COUNT(*) as total
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS
UNION ALL
SELECT 'FCT_FOOD_LOGS', COUNT(*)
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_FOOD_LOGS;

-- PASO 4 — Ver el registro nuevo en Gold PRD
SELECT subscription_id, user_id, revenue, created_at
FROM NUTRITRACK_PRD_GOLD_DB.GOLD.FCT_SUBSCRIPTIONS
ORDER BY created_at DESC
LIMIT 3;

-- ============================================================
-- DEMO 4 — SCD2 EN PRD
-- ============================================================

-- PASO 0 — Estado ANTES en PRD
SELECT plan_name, price, dbt_valid_from, dbt_valid_to,
    CASE WHEN dbt_valid_to IS NULL THEN 'VIGENTE' ELSE 'HISTÓRICO' END as estado
FROM NUTRITRACK_PRD_SILVER_DB.SNAPSHOTS.SNAP_SUBSCRIPTION_PLANS
WHERE plan_name = 'Basic'
ORDER BY dbt_valid_from;

-- PASO 1 — Modificar precio en Bronze PRD
UPDATE NUTRITRACK_PRD_BRONZE_DB.RAW.SUBSCRIPTION_PLANS
SET PRICE = '6.99'
WHERE NAME = 'Basic'
AND PRICE = '4.99';

-- PASO 2 — Ejecutar job de PRD con snapshot:
-- Deploy → Jobs → PRD - Ingesta diaria → Run now

-- PASO 3 — Estado DESPUÉS en PRD
SELECT plan_name, price, dbt_valid_from, dbt_valid_to,
    CASE WHEN dbt_valid_to IS NULL THEN 'VIGENTE' ELSE 'HISTÓRICO' END as estado
FROM NUTRITRACK_PRD_SILVER_DB.SNAPSHOTS.SNAP_SUBSCRIPTION_PLANS
WHERE plan_name = 'Basic'
ORDER BY dbt_valid_from;