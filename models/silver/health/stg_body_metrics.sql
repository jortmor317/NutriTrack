with source as (
    select * from {{ source('nutritrack', 'BODY_METRICS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                 as body_metric_id,
        -- FK a USERS que tiene ID INTEGER
        USER_ID::INTEGER            as user_id,
        WEIGHT_KG::FLOAT            as weight_kg,
        HEIGHT_CM::FLOAT            as height_cm,
        BODY_FAT_PCT::FLOAT         as body_fat_pct,
        BMI::FLOAT                  as bmi,
        RECORDED_DATE::DATE         as recorded_date
    from source
)

select * from renamed