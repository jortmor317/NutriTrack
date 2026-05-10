with foods as (
    select * from {{ ref('stg_foods') }}
),

enriched as (
    select
        -- Campos base
        food_id,
        food_name,
        calories_per_100g,
        protein_g,
        carbs_g,
        fat_g,
        fiber_g,
        category,
        source,

        -- Segmentación por calorías basada en percentiles 33 y 66
        CASE
            WHEN calories_per_100g IS NULL              THEN NULL
            WHEN calories_per_100g < 76                 THEN 'low'
            WHEN calories_per_100g BETWEEN 76 AND 250   THEN 'medium'
            ELSE                                             'high'
        END                                             as calorie_tier,

        -- Flag alto contenido proteico (por encima de la media: 9.36g)
        CASE
            WHEN protein_g IS NULL                      THEN NULL
            WHEN protein_g > 9.36                       THEN TRUE
            ELSE                                             FALSE
        END                                             as is_high_protein,

        -- Perfil macronutricional dominante
        CASE
            WHEN protein_g IS NULL
              OR carbs_g IS NULL
              OR fat_g IS NULL                          THEN NULL
            WHEN protein_g >= carbs_g
             AND protein_g >= fat_g                     THEN 'protein_rich'
            WHEN carbs_g >= protein_g
             AND carbs_g >= fat_g                       THEN 'carb_rich'
            WHEN fat_g >= protein_g
             AND fat_g >= carbs_g                       THEN 'fat_rich'
            ELSE                                             'balanced'
        END                                             as macronutrient_profile

    from foods
)

select * from enriched