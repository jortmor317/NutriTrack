{{
    config(
        materialized='incremental',
        unique_key='subscription_id',
        on_schema_change='sync_all_columns'
    )
}}

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

{% if is_incremental() %}
max_created_at as (
    select max(created_at) as max_created_at from {{ this }}
),
{% endif %}

joined as (
    select
        -- PKs y FKs
        s.subscription_id,
        s.user_id,
        s.plan_id,
        s.promo_id,
        s.start_date,
        s.end_date,

        -- Degenerate dimension: estado de la suscripción
        s.status,

        -- Métricas de revenue
        -- revenue se calcula en la fact porque depende del precio del plan
        -- en el momento de la contratación y del descuento aplicado
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

        -- Flags métricas
        CASE WHEN s.promo_id IS NOT NULL THEN TRUE
             ELSE FALSE
        END                                                     as had_promo,

        CASE WHEN s.status = 'cancelled' THEN TRUE
             ELSE FALSE
        END                                                     as is_cancelled,

        -- Degenerate dimensions: atributos de la cancelación sin dimensión propia
        c.reason                                                as cancellation_reason,
        c.cancelled_at,

        -- Necesario para el filtro incremental
        s.created_at

    from subscriptions s
    left join plans p
        on s.plan_id = p.plan_id
    left join promos pr
        on s.promo_id = pr.promo_id
    left join cancellations c
        on s.subscription_id = c.subscription_id

    {% if is_incremental() %}
    cross join max_created_at m
    {% endif %}

    where 1=1
    {% if is_incremental() %}
        and s.created_at >= m.max_created_at
    {% endif %}
)

select * from joined