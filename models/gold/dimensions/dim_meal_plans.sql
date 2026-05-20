with meal_plans as (
    select * from {{ ref('stg_meal_plans') }}
)

select
    meal_plan_id,
    user_id,
    nutritionist_id,
    meal_plan_name,
    daily_calories,
    daily_protein_g,
    daily_carbs_g,
    daily_fat_g,
    start_date,
    end_date,
    is_active
from meal_plans