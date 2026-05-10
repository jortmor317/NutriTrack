with source as (
    select * from {{ source('nutritrack', 'RECIPE_INGREDIENTS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                     as recipe_ingredient_id,
        -- FKs a tablas con ID UUID
        RECIPE_ID::VARCHAR              as recipe_id,
        FOOD_ID::VARCHAR                as food_id,
        -- Puede ser nulo (27 registros)
        QUANTITY_G::FLOAT               as quantity_g,
        -- Normalizamos todas las variantes de gramos a 'g', asumimos 'g' cuando es nulo
        CASE LOWER(COALESCE(UNIT, 'g'))
            WHEN 'g'        THEN 'g'
            WHEN 'gr'       THEN 'g'
            WHEN 'grams'    THEN 'g'
            ELSE 'g'
        END::VARCHAR                    as unit
    from source
)

select * from renamed