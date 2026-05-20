with ingredients as (
    select * from {{ ref('stg_recipe_ingredients') }}
),

usda_foods as (
    select * from {{ ref('stg_usda_foods') }}
),

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
        -- PK/FK
        recipe_id,

        -- Métricas totales
        total_ingredients,
        total_calories,
        total_protein_g,
        total_carbs_g,
        total_fat_g,
        total_fiber_g,
        total_calcium_mg,
        total_iron_mg,
        total_vitamin_c_mg,


        -- Perfil macronutricional — atributo derivado de las métricas
        CASE
            WHEN total_protein_g IS NULL
              OR total_carbs_g IS NULL
              OR total_fat_g IS NULL                           THEN NULL
            WHEN total_protein_g >= total_carbs_g
             AND total_protein_g >= total_fat_g                THEN 'protein_rich'
            WHEN total_carbs_g >= total_protein_g
             AND total_carbs_g >= total_fat_g                  THEN 'carb_rich'
            WHEN total_fat_g >= total_protein_g
             AND total_fat_g >= total_carbs_g                  THEN 'fat_rich'
            ELSE                                                    'balanced'
        END                                                     as macronutrient_profile

    from recipe_nutrition
)

select * from enriched