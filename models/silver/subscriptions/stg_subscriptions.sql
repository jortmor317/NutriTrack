with source as (
    select * from {{ source('nutritrack', 'SUBSCRIPTIONS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR             as subscription_id,
        -- FKs a tablas con UUID
        USER_ID::INTEGER        as user_id,
        PLAN_ID::VARCHAR        as plan_id,
        PROMO_ID::VARCHAR       as promo_id,
        START_DATE::DATE        as start_date,
        END_DATE::DATE          as end_date,
        -- Normalizamos a minúsculas: Bronze contiene 'Active', 'ACTIVE', 'active'
        LOWER(STATUS)::VARCHAR  as status,
        CREATED_AT::TIMESTAMP   as created_at
    from source
)

select * from renamed