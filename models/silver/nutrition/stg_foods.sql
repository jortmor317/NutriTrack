with source as (
    select * from {{ source('nutritrack', 'FOODS') }}
),

renamed as (
    select
        ID::VARCHAR                     as food_id,
        NAME::VARCHAR                   as food_name,
        -- Nullificamos valores anómalos: 9999 (placeholder) y negativos (errores)
        CASE
            WHEN CALORIES_PER_100G::FLOAT < 0
              OR CALORIES_PER_100G::FLOAT = 9999   THEN NULL
            ELSE CALORIES_PER_100G::FLOAT
        END                             as calories_per_100g,
        PROTEIN_G::FLOAT                as protein_g,
        CARBS_G::FLOAT                  as carbs_g,
        FAT_G::FLOAT                    as fat_g,
        FIBER_G::FLOAT                  as fiber_g,
        CASE INITCAP(CATEGORY)
            WHEN 'Seeds And Nuts' THEN 'Nuts & Seeds'
            ELSE INITCAP(CATEGORY)
        END::VARCHAR                    as category,
        LOWER(SOURCE)::VARCHAR          as source
    from source
)

select * from renamed