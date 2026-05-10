with food_logs as (
    select * from {{ ref('stg_food_logs') }}
),

food_log_items as (
    select * from {{ ref('stg_food_log_items') }}
),

foods as (
    select * from {{ ref('stg_foods') }}
),

goals as (
    select * from {{ ref('stg_goals') }}
),

-- Objetivo calórico más reciente por usuario
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
        fl.meal_type,
        fli.food_id,

        -- Atributos del alimento
        f.food_name,
        f.category                                              as food_category,
        fli.quantity_g,

        -- Métricas nutricionales consumidas según cantidad
        -- Todos los valores nutricionales son por 100g
        ROUND(f.calories_per_100g * fli.quantity_g / 100, 2)   as calories_consumed,
        ROUND(f.protein_g * fli.quantity_g / 100, 2)           as protein_consumed_g,
        ROUND(f.carbs_g * fli.quantity_g / 100, 2)             as carbs_consumed_g,
        ROUND(f.fat_g * fli.quantity_g / 100, 2)               as fat_consumed_g,
        ROUND(f.fiber_g * fli.quantity_g / 100, 2)             as fiber_consumed_g,

        -- Objetivos calóricos del usuario
        g.target_calories,
        g.target_protein_g,
        g.target_carbs_g,
        g.target_fat_g,

        -- % del objetivo calórico diario cubierto por este item
        CASE
            WHEN g.target_calories IS NOT NULL
             AND g.target_calories > 0
             AND f.calories_per_100g IS NOT NULL
                THEN ROUND(
                    (f.calories_per_100g * fli.quantity_g / 100) / g.target_calories * 100
                , 2)
            ELSE NULL
        END                                                     as pct_daily_calories,

        -- Notas del log
        fl.notes

    from food_log_items fli
    left join food_logs fl
        on fli.food_log_id = fl.food_log_id
    left join foods f
        on fli.food_id = f.food_id
    left join latest_goals g
        on fl.user_id = g.user_id
        and g.rn = 1
)

select * from joined