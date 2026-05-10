{% snapshot snap_nutritionists %}

    {{
        config(
            unique_key='nutritionist_id',
            strategy='check',
            check_cols=['specialty', 'years_experience'],
            invalidate_hard_deletes=True
        )
    }}

    select * from {{ ref('stg_nutritionists') }}

{% endsnapshot %}