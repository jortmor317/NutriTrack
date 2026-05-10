with source as (
    select * from {{ source('nutritrack', 'FOOD_LOG_ITEMS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                 as food_log_item_id,
        -- FKs a tablas con ID UUID
        FOOD_LOG_ID::VARCHAR        as food_log_id,
        FOOD_ID::VARCHAR            as food_id,
        QUANTITY_G::FLOAT           as quantity_g,
        -- Normalizamos todas las variantes de gramos a 'g' y asumimos 'g' cuando es nulo
        CASE LOWER(COALESCE(UNIT, 'g'))
            WHEN 'g'        THEN 'g'
            WHEN 'gr'       THEN 'g'
            WHEN 'grams'    THEN 'g'
            ELSE 'g'
        END::VARCHAR                as unit
    from source
)

select * from renamed