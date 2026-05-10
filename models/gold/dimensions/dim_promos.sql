with promos as (
    select * from {{ ref('stg_promos') }}
),

enriched as (
    select
        -- Campos base
        promo_id,
        promo_code,
        description,
        discount_pct,
        valid_from,
        valid_to,

        -- Campos enriquecidos derivados
        -- Flag si la promo está vigente a día de hoy
        CASE
            WHEN valid_from <= CURRENT_DATE()
                AND (valid_to IS NULL OR valid_to >= CURRENT_DATE())
                THEN TRUE
            ELSE FALSE
        END                                                     as is_active,

        -- Días de vigencia de la promo
        DATEDIFF('day', valid_from, COALESCE(valid_to, CURRENT_DATE())) as duration_days,

        -- Segmentación por nivel de descuento
        CASE
            WHEN discount_pct < 10                              THEN 'low'
            WHEN discount_pct BETWEEN 10 AND 25                THEN 'medium'
            WHEN discount_pct > 25                             THEN 'high'
            ELSE NULL
        END                                                     as discount_tier

    from promos
)

select * from enriched