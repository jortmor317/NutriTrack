with source as (
    select * from {{ source('nutritrack', 'NUTRITIONISTS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                     as nutritionist_id,
        NAME::VARCHAR                   as nutritionist_name,
        EMAIL::VARCHAR                  as email,
        SPECIALTY::VARCHAR              as specialty,
        YEARS_EXPERIENCE::INTEGER       as years_experience,
        CREATED_AT::TIMESTAMP           as created_at
    from source
)

select * from renamed