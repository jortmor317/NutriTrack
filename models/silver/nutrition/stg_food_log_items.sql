with source as (
    select * from {{ source('nutritrack', 'FOOD_LOG_ITEMS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                     as food_log_item_id,
        FOOD_LOG_ID::VARCHAR            as food_log_id,
        -- FK a USDA_FOODS — usamos FDC_ID en lugar de FOOD_ID
        FDC_ID::VARCHAR                 as fdc_id,
        -- Mantenemos FOOD_ID original por trazabilidad con Bronze
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