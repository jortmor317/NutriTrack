with source as (
    select * from {{ source('nutritrack', 'RECIPE_INGREDIENTS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                     as recipe_ingredient_id,
        RECIPE_ID::VARCHAR              as recipe_id,
        -- FK a USDA_FOODS — usamos FDC_ID en lugar de FOOD_ID
        FDC_ID::VARCHAR                 as fdc_id,
        -- Mantenemos FOOD_ID original por trazabilidad
        FOOD_ID::VARCHAR                as food_id_original,
        QUANTITY_G::FLOAT               as quantity_g,
        -- Normalizamos unit
        CASE LOWER(COALESCE(UNIT, 'g'))
            WHEN 'g'        THEN 'g'
            WHEN 'gr'       THEN 'g'
            WHEN 'grams'    THEN 'g'
            ELSE 'g'
        END::VARCHAR                    as unit
    from source
)

select * from renamed