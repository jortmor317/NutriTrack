with source as (
    select * from {{ source('nutritrack', 'FOOD_LOGS') }}
),

renamed as (
    select
        -- ID es UUID
        ID::VARCHAR                 as food_log_id,
        -- FK a USERS que tiene ID INTEGER
        USER_ID::INTEGER            as user_id,
        -- FK a MEAL_PLANS que tiene ID UUID
        MEAL_PLAN_ID::VARCHAR       as meal_plan_id,
        -- Detectamos el formato de fecha por el separador usado
        -- YYYY-MM-DD usa guiones, DD/MM/YYYY usa barras
        CASE
            WHEN CONTAINS(LOG_DATE, '/')
                THEN TO_DATE(LOG_DATE, 'DD/MM/YYYY')
            ELSE TO_DATE(LOG_DATE, 'YYYY-MM-DD')
        END                         as log_date,
        -- Normalizamos a minúsculas: Bronze contiene 'Breakfast', 'LUNCH', 'dinner', etc.
        LOWER(MEAL_TYPE)::VARCHAR   as meal_type,
        NOTES::VARCHAR              as notes,
        CREATED_AT::TIMESTAMP       as created_at
    from source
)

select * from renamed