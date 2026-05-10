with source as (
    select * from {{ source('nutritrack', 'PROMOS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                     as promo_id,
        CODE::VARCHAR                   as promo_code,
        DISCOUNT_PCT::FLOAT             as discount_pct,
        VALID_FROM::DATE                as valid_from,
        VALID_TO::DATE                  as valid_to,
        DESCRIPTION::VARCHAR            as description
    from source
)

select * from renamed