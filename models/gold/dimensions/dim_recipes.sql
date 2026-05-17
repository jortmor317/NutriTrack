with recipes as (
    select * from {{ ref('stg_recipes') }}
)

select
    recipe_id,
    nutritionist_id,
    recipe_name,
    category,
    prep_time_min,
    servings,
    created_at

from recipes