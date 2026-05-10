{% snapshot snap_subscription_plans %}

    {{
        config(
            unique_key='plan_id',
            strategy='check',
            check_cols=['price', 'billing_period', 'plan_name'],
            invalidate_hard_deletes=True
        )
    }}

    select * from {{ ref('stg_subscription_plans') }}

{% endsnapshot %}