with source as (
    select * from {{ source('nutritrack', 'USERS') }}
),

renamed as (
    select
        ID::INTEGER             as user_id,
        NAME::VARCHAR           as user_name,
        EMAIL::VARCHAR          as email,
        -- Detectamos el formato de fecha por el separador usado
        -- YYYY-MM-DD usa guiones, DD/MM/YYYY usa barras
        CASE
            WHEN CONTAINS(BIRTH_DATE, '/')
                THEN TO_DATE(BIRTH_DATE, 'DD/MM/YYYY')
            ELSE TO_DATE(BIRTH_DATE, 'YYYY-MM-DD')
        END                     as birth_date,
        -- Normalizamos gender: Bronze contenía 'M', 'MALE', 'F', 'female' y nulos
        CASE UPPER(TRIM(GENDER))
            WHEN 'M'        THEN 'male'
            WHEN 'MALE'     THEN 'male'
            WHEN 'F'        THEN 'female'
            WHEN 'FEMALE'   THEN 'female'
            ELSE 'unknown'
        END::VARCHAR            as gender,
        PHONE::VARCHAR          as phone,
        CREATED_AT::TIMESTAMP   as created_at
    from source
),

deduped as (
    select *,
        -- Deduplicamos por email quedándonos con el registro más reciente
        -- Bronze puede contener duplicados de la fuente original
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at DESC) as rn
    from renamed
)

select * exclude rn
from deduped
where rn = 1