with source as (
    select * from {{ source('nutritrack', 'GOALS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                 as goal_id,
        -- FK a USERS que tiene ID INTEGER
        USER_ID::INTEGER            as user_id,
        TARGET_CALORIES::FLOAT      as target_calories,
        TARGET_PROTEIN_G::FLOAT     as target_protein_g,
        TARGET_CARBS_G::FLOAT       as target_carbs_g,
        TARGET_FAT_G::FLOAT         as target_fat_g,
        -- Normalizamos a snake_case minúsculas: Bronze contiene 'Lose Weight', 'lose_weight', 'GAIN_MUSCLE'
        CASE LOWER(REPLACE(GOAL_TYPE, ' ', '_'))
            WHEN 'lose_weight'  THEN 'lose_weight'
            WHEN 'gain_muscle'  THEN 'gain_muscle'
            WHEN 'maintain'     THEN 'maintain'
            ELSE LOWER(REPLACE(GOAL_TYPE, ' ', '_'))
        END::VARCHAR                as goal_type,
        SET_AT::TIMESTAMP           as set_at
    from source
)

select * from renamed