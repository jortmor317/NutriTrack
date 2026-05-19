# NutriTrack — Data Engineering Project

Arquitectura de datos completa para la plataforma de nutrición NutriTrack, construida con Snowflake, dbt Cloud, GitHub y Power BI siguiendo el patrón Medallion y el modelo dimensional Kimball.

## Stack tecnológico

| Herramienta | Rol |
|---|---|
| **Snowflake** | Cloud Data Warehouse |
| **dbt Cloud** | Transformación y orquestación |
| **GitHub** | Control de versiones |
| **Power BI** | Visualización y análisis |

## Arquitectura Medallion

```
BRONZE                    SILVER                    GOLD
──────────────────        ──────────────────        ──────────────────
Raw data sin modificar    Limpieza y castings        Modelo dimensional
Fuente de verdad          Reglas de negocio          Kimball (estrella)
17 tablas                 16 vistas                  10 modelos
NUTRITRACK_*_BRONZE_DB    NUTRITRACK_*_SILVER_DB     NUTRITRACK_*_GOLD_DB
```

## Entornos

| Entorno | Base de datos | Rama | Job |
|---|---|---|---|
| DEV | NUTRITRACK_DEV_* | dev | Manual |
| PRD | NUTRITRACK_PRD_* | main | Diario 6:00 UTC |

El routing dinámico entre entornos se gestiona mediante la variable de entorno `DBT_ENVIRONMENTS`:
```
NUTRITRACK_{{ env_var('DBT_ENVIRONMENTS') }}_BRONZE_DB
```

## Fuentes de datos (Bronze)

| Tabla | Registros | Descripción |
|---|---|---|
| USERS | 3.030 | Usuarios del sistema |
| SUBSCRIPTIONS | 3.030 | Suscripciones a planes |
| SUBSCRIPTION_PLANS | 5 | Planes disponibles |
| SUBSCRIPTION_CANCELLATIONS | 600 | Cancelaciones |
| PROMOS | 30 | Promociones y descuentos |
| FOODS | 476 | Catálogo sintético (sustituido por USDA) |
| FOOD_LOGS | 8.960 | Registros de comidas |
| FOOD_LOG_ITEMS | 22.464 | Items de cada registro |
| GOALS | 7.560 | Objetivos nutricionales |
| BODY_METRICS | 13.624 | Métricas corporales |
| MEAL_PLANS | 1.800 | Planes de comida |
| NUTRITIONISTS | 50 | Nutricionistas |
| USER_NUTRITIONIST_ASSIGNMENTS | 2.500 | Asignaciones usuario-nutricionista |
| RECIPES | 510 | Recetas |
| RECIPE_INGREDIENTS | 2.869 | Ingredientes de recetas |
| RECIPES_RAW | Variable | Recetas en formato semiestructurado |
| USDA_FOODS | 7.792 | Alimentos oficiales USDA SR Legacy (VARIANT) |

## Modelo dimensional Gold (Kimball)

### Dimensiones

| Dimensión | PK | Registros | Descripción |
|---|---|---|---|
| dim_users | user_id (INT) | 2.997 | Usuarios con age_group, gender normalizado |
| dim_subscription_plans | plan_id (UUID) | 5 | Planes con price_tier, monthly_price |
| dim_promos | promo_id (UUID) | 30 | Promos con discount_tier, is_active |
| dim_nutritionists | nutritionist_id (UUID) | 50 | Nutricionistas con experience_tier |
| dim_foods | food_id = fdc_id (VARCHAR) | 7.792 | Alimentos USDA con macronutrient_profile |
| dim_recipes | recipe_id (UUID) | 510 | Recetas — solo atributos descriptivos |
| dim_dates | date_id (DATE) | 4.017 | Calendario 2020-2030 |

### Facts

| Fact | Granularidad | Registros | Materialización |
|---|---|---|---|
| fct_subscriptions | 1 fila / suscripción | 3.030 | Incremental MERGE |
| fct_food_logs | 1 fila / item de comida | 22.464 | Incremental MERGE |
| fct_recipe_nutrition | 1 fila / receta | 510 | Table |

### Decisiones de diseño

- **Degenerate dimensions**: `meal_type`, `status`, `cancellation_reason` — atributos de la transacción sin dimensión propia (Kimball)
- **Outrigger dimension**: `dim_nutritionists` → `dim_recipes` — relación real de negocio con atributos propios relevantes
- **Métricas de contexto**: `target_calories`, `target_protein_g` en `fct_food_logs` — objetivo del usuario en el momento del registro, no el actual
- **Natural keys**: PKs del sistema origen. Surrogate keys identificadas como mejora futura

## SCD2 — Snapshots

| Snapshot | Columnas monitorizadas | Justificación |
|---|---|---|
| snap_subscription_plans | price, billing_period, plan_name | Revenue histórico correcto cuando el precio cambia |
| snap_nutritionists | specialty, years_experience | Correlaciones históricas correctas por especialidad |

Estrategia `check` — Bronze no tiene `updated_at` fiable.

## Pipeline de ingesta USDA

```
API FoodData Central
      ↓
Python (lotes de 20 IDs — 40x más eficiente)
      ↓
JSON local
      ↓
PUT @STG_NUTRITRACK (Snowflake Stage)
      ↓
COPY INTO USDA_FOODS (FORCE=FALSE — idempotente)
```

USDA_FOODS almacena `RAW_JSON` como VARIANT. `stg_usda_foods` aplana el array `foodNutrients` con LATERAL FLATTEN.

## Estructura del proyecto

```
nutritrack/
├── models/
│   ├── bronze/
│   │   └── sources.yml
│   ├── silver/
│   │   ├── users/
│   │   ├── subscriptions/
│   │   ├── promos/
│   │   ├── nutrition/
│   │   ├── health/
│   │   ├── nutritionist/
│   │   └── plans/
│   └── gold/
│       ├── dimensions/
│       └── facts/
├── snapshots/
│   ├── snap_subscription_plans.sql
│   └── snap_nutritionists.sql
├── macros/
│   ├── generate_schema_name.sql
│   ├── generate_database_name.sql
│   ├── demo_incremental.sql
│   └── validate_incremental.sql
├── tests/
│   ├── assert_revenue_positive.sql
│   ├── assert_pct_daily_calories_range.sql
│   ├── assert_fct_subscriptions_user_exists.sql
│   ├── assert_fct_food_logs_food_exists.sql
│   └── assert_duration_days_positive.sql
└── analyses/
    └── casos_de_uso.sql
```

## Comandos principales

```bash
# Build completo
dbt build

# Build incremental solo de facts
dbt build --select fct_subscriptions fct_food_logs

# Full refresh de un modelo
dbt build --select dim_users --full-refresh

# Solo tests
dbt test

# Solo tests singulares
dbt test --select test_type:singular

# Generar documentación
dbt docs generate
```

## Demo incremental

Simula una ingesta real de datos en Bronze DEV y demuestra el funcionamiento de los modelos incrementales:

```bash
# Paso 1 — Insertar registros nuevos en Bronze
dbt run-operation demo_incremental

# Paso 2 — Ejecutar solo los modelos incrementales
dbt build --select fct_subscriptions fct_food_logs

# Paso 3 — Validar que los registros llegaron a Gold
dbt run-operation validate_incremental
```

## RBAC — Roles de Snowflake

| Rol | Bronze | Silver | Gold | Para quién |
|---|---|---|---|---|
| NUTRITRACK_RAW_ROLE | Escritura | Sin acceso | Sin acceso | Pipelines de ingesta |
| NUTRITRACK_TRANSFORM_ROLE | Lectura | Escritura | Escritura | dbt Cloud |
| NUTRITRACK_BI_ROLE | Sin acceso | Sin acceso | Lectura | Power BI |

## Decisiones de limpieza Silver

| Modelo | Campo | Problema | Solución |
|---|---|---|---|
| stg_users | email | Duplicados | ROW_NUMBER() PARTITION BY email ORDER BY created_at DESC |
| stg_users | birth_date | Dos formatos (DD/MM/YYYY y YYYY-MM-DD) | CASE CONTAINS('/') |
| stg_users | gender | M/MALE/F/female + nulos | CASE UPPER() → male/female/unknown |
| stg_subscriptions | status | Active/ACTIVE/active | LOWER() |
| stg_foods | calories_per_100g | 9999 y negativos | CASE WHEN < 0 OR = 9999 THEN NULL |
| stg_food_logs | meal_type | Breakfast/LUNCH/dinner | LOWER() |
| stg_food_log_items | quantity_g | Valores negativos | CASE WHEN < 0 THEN NULL |
| stg_food_log_items | unit | g/gr/G/grams + nulos | CASE LOWER(COALESCE()) → 'g' |
| stg_goals | goal_type | Inconsistencias + 1.207 nulos | LOWER(REPLACE()) snake_case |
| stg_recipes | category | Castellano (Desayuno→breakfast) | CASE mapeo |
| stg_nutritionists | specialty | Castellano/inglés mezclado | Pendiente — próxima iteración |

## Puntos de mejora identificados

1. Normalizar `specialty` en `stg_nutritionists` (castellano/inglés)
2. Migrar capa semántica a sintaxis dbt Fusion
3. Surrogate keys en dimensiones con `dbt_utils.generate_surrogate_key()`
4. `dim_meal_plans` en Gold — FK huérfana en `fct_food_logs`
5. Role-playing dimensions para `dim_dates` (evitar relación inactiva)
6. Pipeline de ingesta real (Fivetran/Airbyte) para Bronze PRD
7. Modelos intermedios `int_user_subscription_history` e `int_user_health_evolution`

## Casos de uso respondibles

- Revenue y churn por plan, promoción y perfil demográfico
- Impacto de promociones en retención (churn 11.69% con promo vs 13.42% sin promo)
- Adherencia a objetivos calóricos con datos USDA oficiales (61.39% medio)
- Top alimentos más consumidos por perfil de usuario
- Perfil macronutricional de recetas por especialidad de nutricionista
- Revenue histórico correcto mediante SCD2 en snap_subscription_plans
