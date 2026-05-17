{{
    config(
        materialized='incremental',
        unique_key='food_log_item_id',
        on_schema_change='sync_all_columns'
    )
}}

with food_logs as (
    select * from {{ ref('stg_food_logs') }}
),

food_log_items as (
    select * from {{ ref('stg_food_log_items') }}
),

foods as (
    select * from {{ ref('stg_usda_foods') }}
),

goals as (
    select * from {{ ref('stg_goals') }}
),

{% if is_incremental() %}
max_created_at as (
    select max(created_at) as max_created_at from {{ this }}
),
{% endif %}

latest_goals as (
    select
        user_id,
        target_calories,
        target_protein_g,
        target_carbs_g,
        target_fat_g,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY set_at DESC) as rn
    from goals
    where target_calories is not null
),

joined as (
    select
        -- PKs y FKs
        fli.food_log_item_id,
        fl.food_log_id,
        fl.user_id,
        fl.meal_plan_id,
        fl.log_date,
        -- Degenerate dimension: atributo de la transacción sin dimensión propia
        fl.meal_type,
        -- FK a dim_foods
        fli.fdc_id                                              as food_id,

        -- Métricas
        fli.quantity_g,
        ROUND(f.calories_kcal * fli.quantity_g / 100, 2)       as calories_consumed,
        ROUND(f.protein_g * fli.quantity_g / 100, 2)           as protein_consumed_g,
        ROUND(f.carbs_g * fli.quantity_g / 100, 2)             as carbs_consumed_g,
        ROUND(f.fat_g * fli.quantity_g / 100, 2)               as fat_consumed_g,
        ROUND(f.fiber_g * fli.quantity_g / 100, 2)             as fiber_consumed_g,
        ROUND(f.calcium_mg * fli.quantity_g / 100, 2)          as calcium_consumed_mg,
        ROUND(f.iron_mg * fli.quantity_g / 100, 2)             as iron_consumed_mg,
        ROUND(f.sodium_mg * fli.quantity_g / 100, 2)           as sodium_consumed_mg,
        ROUND(f.potassium_mg * fli.quantity_g / 100, 2)        as potassium_consumed_mg,
        ROUND(f.vitamin_c_mg * fli.quantity_g / 100, 2)        as vitamin_c_consumed_mg,
        ROUND(f.vitamin_a_iu * fli.quantity_g / 100, 2)        as vitamin_a_consumed_iu,

        -- Métricas de contexto del usuario en el momento del registro
        g.target_calories,
        g.target_protein_g,
        g.target_carbs_g,
        g.target_fat_g,

        -- KPI calculado
        CASE
            WHEN g.target_calories IS NOT NULL
             AND g.target_calories > 0
             AND f.calories_kcal IS NOT NULL
                THEN ROUND(
                    (f.calories_kcal * fli.quantity_g / 100) / g.target_calories * 100
                , 2)
            ELSE NULL
        END                                                     as pct_daily_calories,

        -- Degenerate dimension
        fl.notes,
        fl.created_at

    from food_log_items fli
    left join food_logs fl
        on fli.food_log_id = fl.food_log_id
    left join foods f
        on fli.fdc_id = f.fdc_id
    left join latest_goals g
        on fl.user_id = g.user_id
        and g.rn = 1

    {% if is_incremental() %}
    cross join max_created_at m
    {% endif %}

    where 1=1
    {% if is_incremental() %}
        and fl.created_at > m.max_created_at
    {% endif %}
)

select * from joined