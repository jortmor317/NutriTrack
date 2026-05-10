with source as (
    select * from {{ source('nutritrack', 'FOODS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                 as food_id,
        NAME::VARCHAR               as food_name,
        CALORIES_PER_100G::FLOAT    as calories_per_100g,
        PROTEIN_G::FLOAT            as protein_g,
        CARBS_G::FLOAT              as carbs_g,
        FAT_G::FLOAT                as fat_g,
        FIBER_G::FLOAT              as fiber_g,
        -- Normalizamos a INITCAP y unificamos categorías inconsistentes de la fuente
        CASE INITCAP(CATEGORY)
            WHEN 'Seeds And Nuts' THEN 'Nuts & Seeds'
            ELSE INITCAP(CATEGORY)
        END::VARCHAR                as category,
        -- Normalizamos source a minúsculas
        LOWER(SOURCE)::VARCHAR      as source
    from source
)

select * from renamed