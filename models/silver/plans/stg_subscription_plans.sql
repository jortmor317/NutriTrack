with source as (
    select * from {{ source('nutritrack', 'SUBSCRIPTION_PLANS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR             as plan_id,
        NAME::VARCHAR           as plan_name,
        PRICE::FLOAT            as price,
        BILLING_PERIOD::VARCHAR as billing_period
    from source
)

select * from renamed