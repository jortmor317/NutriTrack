with users as (
    select * from {{ ref('stg_users') }}
),

enriched as (
    select
        -- Campos base
        user_id,
        user_name,
        email,
        gender,
        phone,
        birth_date,
        created_at,

        -- Campos enriquecidos derivados
        DATEDIFF('year', birth_date, CURRENT_DATE())            as age,

        CASE
            WHEN DATEDIFF('year', birth_date, CURRENT_DATE()) < 18  THEN 'Under 18'
            WHEN DATEDIFF('year', birth_date, CURRENT_DATE()) < 26  THEN '18-25'
            WHEN DATEDIFF('year', birth_date, CURRENT_DATE()) < 36  THEN '26-35'
            WHEN DATEDIFF('year', birth_date, CURRENT_DATE()) < 46  THEN '36-45'
            WHEN DATEDIFF('year', birth_date, CURRENT_DATE()) < 56  THEN '46-55'
            ELSE '55+'
        END                                                     as age_group,

        DATEDIFF('day', created_at, CURRENT_DATE())             as days_since_registration,

        YEAR(created_at)                                        as registration_year,
        MONTH(created_at)                                       as registration_month,

        -- Flag usuario reciente (últimos 90 días)
        CASE
            WHEN DATEDIFF('day', created_at, CURRENT_DATE()) <= 90 THEN TRUE
            ELSE FALSE
        END                                                     as is_recent_user

    from users
)

select * from enriched