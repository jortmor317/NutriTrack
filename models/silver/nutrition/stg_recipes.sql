with source as (
    select * from {{ source('nutritrack', 'RECIPES') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                 as recipe_id,
        -- FK a NUTRITIONISTS que tiene ID UUID
        NUTRITIONIST_ID::VARCHAR    as nutritionist_id,
        -- Puede ser nulo (10 registros)
        NAME::VARCHAR               as recipe_name,
        -- Normalizamos categorías de castellano a inglés por inconsistencia de fuente
        CASE CATEGORY
            WHEN 'Desayuno'     THEN 'breakfast'
            WHEN 'Almuerzo'     THEN 'lunch'
            WHEN 'Cena'         THEN 'dinner'
            WHEN 'Snack'        THEN 'snack'
            WHEN 'Pre-entreno'  THEN 'pre_workout'
            WHEN 'Post-entreno' THEN 'post_workout'
            ELSE NULL
        END::VARCHAR                as category,
        -- Puede ser nulo (115 registros)
        PREP_TIME_MIN::INTEGER      as prep_time_min,
        -- Puede ser nulo (53 registros)
        SERVINGS::INTEGER           as servings,
        CREATED_AT::TIMESTAMP       as created_at
    from source
)

select * from renamed