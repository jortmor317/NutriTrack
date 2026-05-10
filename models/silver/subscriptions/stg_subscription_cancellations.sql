with source as (
    select * from {{ source('nutritrack', 'SUBSCRIPTION_CANCELLATIONS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                     as cancellation_id,
        -- FK a SUBSCRIPTIONS que tiene ID UUID
        SUBSCRIPTION_ID::VARCHAR        as subscription_id,
        -- Normalizamos a snake_case minúsculas: Bronze contiene 'NOT_USING', 'not_using', 'Too Expensive'
        CASE LOWER(REPLACE(REASON, ' ', '_'))
            WHEN 'not_using'            THEN 'not_using'
            WHEN 'too_expensive'        THEN 'too_expensive'
            WHEN 'other'                THEN 'other'
            WHEN 'found_alternative'    THEN 'found_alternative'
            WHEN 'technical_issues'     THEN 'technical_issues'
            ELSE NULL
        END::VARCHAR                    as reason,
        -- Puede ser nulo (231 registros)
        FEEDBACK::VARCHAR               as feedback,
        CANCELLED_AT::TIMESTAMP         as cancelled_at
    from source
)

select * from renamed