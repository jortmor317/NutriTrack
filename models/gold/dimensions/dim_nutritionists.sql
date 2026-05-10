with nutritionists as (
    select * from {{ ref('stg_nutritionists') }}
),

enriched as (
    select
        -- Campos base
        nutritionist_id,
        nutritionist_name,
        email,
        specialty,
        years_experience,
        created_at,

        -- Segmentación por nivel de experiencia
        CASE
            WHEN years_experience < 3                           THEN 'junior'
            WHEN years_experience BETWEEN 3 AND 10             THEN 'senior'
            WHEN years_experience > 10                         THEN 'expert'
            ELSE NULL
        END                                                     as experience_tier,

        -- Antigüedad en la plataforma en días
        DATEDIFF('day', created_at, CURRENT_DATE())             as days_on_platform

    from nutritionists
)

select * from enriched