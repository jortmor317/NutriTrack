with source as (
    select * from {{ source('nutritrack', 'USER_NUTRITIONIST_ASSIGNMENTS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                 as assignment_id,
        -- FK a USERS que tiene ID INTEGER
        USER_ID::INTEGER            as user_id,
        -- FK a NUTRITIONISTS que tiene ID UUID
        NUTRITIONIST_ID::VARCHAR    as nutritionist_id,
        START_DATE::DATE            as start_date,
        END_DATE::DATE              as end_date,
        IS_ACTIVE::BOOLEAN          as is_active
    from source
)

select * from renamed