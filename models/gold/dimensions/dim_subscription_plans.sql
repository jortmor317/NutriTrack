with plans as (
    select * from {{ ref('stg_subscription_plans') }}
),

enriched as (
    select
        -- Campos base
        plan_id,
        plan_name,
        price,
        billing_period,

        -- Precio normalizado a mensual para comparar planes entre sí
        CASE billing_period
            WHEN 'annual'   THEN ROUND(price / 12, 2)
            WHEN 'monthly'  THEN price
        END                                                     as monthly_price,

        -- Segmentación por precio mensual
        CASE
            WHEN CASE billing_period
                    WHEN 'annual'  THEN ROUND(price / 12, 2)
                    WHEN 'monthly' THEN price
                 END < 10                                       THEN 'budget'
            WHEN CASE billing_period
                    WHEN 'annual'  THEN ROUND(price / 12, 2)
                    WHEN 'monthly' THEN price
                 END BETWEEN 10 AND 30                         THEN 'standard'
            ELSE                                                    'premium'
        END                                                     as price_tier,

        -- Flag para filtrar planes anuales fácilmente
        CASE billing_period
            WHEN 'annual'   THEN TRUE
            ELSE                 FALSE
        END                                                     as is_annual

    from plans
)

select * from enriched