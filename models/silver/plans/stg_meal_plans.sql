with source as (
    select * from {{ source('nutritrack', 'MEAL_PLANS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                 as meal_plan_id,
        -- FK a USERS que tiene ID INTEGER
        USER_ID::INTEGER            as user_id,
        -- FK a NUTRITIONISTS que tiene ID UUID
        NUTRITIONIST_ID::VARCHAR    as nutritionist_id,
        NAME::VARCHAR               as meal_plan_name,
        DAILY_CALORIES::FLOAT       as daily_calories,
        -- Campos con nulos, pendiente de estrategia de imputación con negocio
        DAILY_PROTEIN_G::FLOAT      as daily_protein_g,
        DAILY_CARBS_G::FLOAT        as daily_carbs_g,
        DAILY_FAT_G::FLOAT          as daily_fat_g,
        START_DATE::DATE            as start_date,
        -- Puede ser nulo si el plan está activo
        END_DATE::DATE              as end_date,
        IS_ACTIVE::BOOLEAN          as is_active
    from source
)

select * from renamed