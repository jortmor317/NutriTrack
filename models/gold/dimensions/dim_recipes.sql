with recipes as (
    select * from {{ ref('stg_recipes') }}
),

ingredients as (
    select * from {{ ref('stg_recipe_ingredients') }}
),

usda_foods as (
    select * from {{ ref('stg_usda_foods') }}
),

-- Calculamos macronutrientes por receta sumando los ingredientes
recipe_nutrition as (
    select
        i.recipe_id,
        COUNT(i.recipe_ingredient_id)                           as total_ingredients,
        ROUND(SUM(f.calories_kcal * i.quantity_g / 100), 2)    as total_calories,
        ROUND(SUM(f.protein_g * i.quantity_g / 100), 2)        as total_protein_g,
        ROUND(SUM(f.carbs_g * i.quantity_g / 100), 2)          as total_carbs_g,
        ROUND(SUM(f.fat_g * i.quantity_g / 100), 2)            as total_fat_g,
        ROUND(SUM(f.fiber_g * i.quantity_g / 100), 2)          as total_fiber_g,
        ROUND(SUM(f.calcium_mg * i.quantity_g / 100), 2)       as total_calcium_mg,
        ROUND(SUM(f.iron_mg * i.quantity_g / 100), 2)          as total_iron_mg,
        ROUND(SUM(f.vitamin_c_mg * i.quantity_g / 100), 2)     as total_vitamin_c_mg
    from ingredients i
    left join usda_foods f
        on i.fdc_id = f.fdc_id
    group by i.recipe_id
),

enriched as (
    select
        -- Campos base
        r.recipe_id,
        r.nutritionist_id,
        r.recipe_name,
        r.category,
        r.prep_time_min,
        r.servings,
        r.created_at,

        -- Macronutrientes totales de la receta
        n.total_ingredients,
        n.total_calories,
        n.total_protein_g,
        n.total_carbs_g,
        n.total_fat_g,
        n.total_fiber_g,
        n.total_calcium_mg,
        n.total_iron_mg,
        n.total_vitamin_c_mg,

        -- Macronutrientes por porción (si tiene servings)
        CASE WHEN r.servings IS NOT NULL AND r.servings > 0
            THEN ROUND(n.total_calories / r.servings, 2)
            ELSE NULL
        END                                                     as calories_per_serving,

        CASE WHEN r.servings IS NOT NULL AND r.servings > 0
            THEN ROUND(n.total_protein_g / r.servings, 2)
            ELSE NULL
        END                                                     as protein_per_serving_g,

        -- Perfil macronutricional dominante de la receta
        CASE
            WHEN n.total_protein_g IS NULL
              OR n.total_carbs_g IS NULL
              OR n.total_fat_g IS NULL                         THEN NULL
            WHEN n.total_protein_g >= n.total_carbs_g
             AND n.total_protein_g >= n.total_fat_g            THEN 'protein_rich'
            WHEN n.total_carbs_g >= n.total_protein_g
             AND n.total_carbs_g >= n.total_fat_g              THEN 'carb_rich'
            WHEN n.total_fat_g >= n.total_protein_g
             AND n.total_fat_g >= n.total_carbs_g              THEN 'fat_rich'
            ELSE                                                    'balanced'
        END                                                     as macronutrient_profile

    from recipes r
    left join recipe_nutrition n
        on r.recipe_id = n.recipe_id
)

select * from enriched