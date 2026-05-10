with source as (
    select * from {{ source('nutritrack', 'USERS') }}
),

renamed as (
    select
        ID::INTEGER             as user_id,
        NAME::VARCHAR           as user_name,
        EMAIL::VARCHAR          as email,
        BIRTH_DATE::DATE        as birth_date,
        GENDER::VARCHAR         as gender,
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