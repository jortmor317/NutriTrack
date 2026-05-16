with usda_foods as (
    select * from {{ ref('stg_usda_foods') }}
),

enriched as (
    select
        -- PK — usamos fdc_id como identificador
        fdc_id                                                  as food_id,
        description                                             as food_name,
        data_type,
        publication_date,

        -- Macronutrientes oficiales USDA
        calories_kcal                                           as calories_per_100g,
        protein_g,
        carbs_g,
        fat_g,
        fiber_g,
        sugars_g,

        -- Minerales
        calcium_mg,
        iron_mg,
        sodium_mg,
        potassium_mg,

        -- Vitaminas
        vitamin_c_mg,
        vitamin_a_iu,

        -- Campos enriquecidos derivados
        CASE
            WHEN calories_kcal IS NULL              THEN NULL
            WHEN calories_kcal < 76                 THEN 'low'
            WHEN calories_kcal BETWEEN 76 AND 250   THEN 'medium'
            ELSE                                         'high'
        END                                                     as calorie_tier,

        CASE
            WHEN protein_g IS NULL                  THEN NULL
            WHEN protein_g > 9.36                   THEN TRUE
            ELSE                                         FALSE
        END                                                     as is_high_protein,

        CASE
            WHEN protein_g IS NULL
              OR carbs_g IS NULL
              OR fat_g IS NULL                      THEN NULL
            WHEN protein_g >= carbs_g
             AND protein_g >= fat_g                 THEN 'protein_rich'
            WHEN carbs_g >= protein_g
             AND carbs_g >= fat_g                   THEN 'carb_rich'
            WHEN fat_g >= protein_g
             AND fat_g >= carbs_g                   THEN 'fat_rich'
            ELSE                                         'balanced'
        END                                                     as macronutrient_profile

    from usda_foods
)

select * from enriched