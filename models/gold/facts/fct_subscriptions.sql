with subscriptions as (
    select * from {{ ref('stg_subscriptions') }}
),

plans as (
    select * from {{ ref('stg_subscription_plans') }}
),

promos as (
    select * from {{ ref('stg_promos') }}
),

cancellations as (
    select * from {{ ref('stg_subscription_cancellations') }}
),

joined as (
    select
        -- PKs y FKs
        s.subscription_id,
        s.user_id,
        s.plan_id,
        s.promo_id,
        s.start_date,
        s.end_date,
        s.status,

        -- Atributos del plan
        p.price                                                 as plan_price,
        p.billing_period,

        -- Métricas de revenue
        -- Revenue real según periodo de facturación y descuento aplicado
        CASE
            WHEN s.promo_id IS NOT NULL AND pr.discount_pct IS NOT NULL
                THEN ROUND(p.price * (1 - pr.discount_pct / 100), 2)
            ELSE p.price
        END                                                     as revenue,

        -- Descuento aplicado en valor absoluto
        CASE
            WHEN s.promo_id IS NOT NULL AND pr.discount_pct IS NOT NULL
                THEN ROUND(p.price * (pr.discount_pct / 100), 2)
            ELSE 0
        END                                                     as discount_amount,

        -- Duración de la suscripción en días
        DATEDIFF('day', s.start_date,
            COALESCE(s.end_date, CURRENT_DATE()))               as duration_days,

        -- Flags
        CASE WHEN s.promo_id IS NOT NULL THEN TRUE
             ELSE FALSE
        END                                                     as had_promo,

        CASE WHEN s.status = 'cancelled' THEN TRUE
             ELSE FALSE
        END                                                     as is_cancelled,

        -- Motivo de cancelación si existe
        c.reason                                                as cancellation_reason,
        c.cancelled_at

    from subscriptions s
    left join plans p
        on s.plan_id = p.plan_id
    left join promos pr
        on s.promo_id = pr.promo_id
    left join cancellations c
        on s.subscription_id = c.subscription_id
)

select * from joined