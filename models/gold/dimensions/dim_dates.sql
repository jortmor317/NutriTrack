with date_spine as (
    {{
        dbt_utils.date_spine(
            datepart="day",
            start_date="cast('2020-01-01' as date)",
            end_date="cast('2030-12-31' as date)"
        )
    }}
),

enriched as (
    select
        DATE_DAY                                                as date_id,
        DATE_DAY                                                as full_date,
        DAY(DATE_DAY)                                           as day_of_month,
        DAYOFWEEK(DATE_DAY)                                     as day_of_week,
        DAYNAME(DATE_DAY)                                       as day_name,
        WEEKOFYEAR(DATE_DAY)                                    as week_of_year,
        MONTH(DATE_DAY)                                         as month_number,
        MONTHNAME(DATE_DAY)                                     as month_name,
        QUARTER(DATE_DAY)                                       as quarter_number,
        CONCAT('Q', QUARTER(DATE_DAY))                          as quarter_name,
        YEAR(DATE_DAY)                                          as year_number,
        CONCAT(YEAR(DATE_DAY), '-Q', QUARTER(DATE_DAY))         as year_quarter,
        CONCAT(YEAR(DATE_DAY), '-', LPAD(MONTH(DATE_DAY), 2, '0')) as year_month,

        -- Flags útiles
        CASE WHEN DAYOFWEEK(DATE_DAY) IN (1, 7) THEN TRUE
             ELSE FALSE
        END                                                     as is_weekend,

        CASE WHEN DATE_DAY = DATE_TRUNC('month', DATE_DAY) THEN TRUE
             ELSE FALSE
        END                                                     as is_first_day_of_month,

        CASE WHEN DATE_DAY = LAST_DAY(DATE_DAY) THEN TRUE
             ELSE FALSE
        END                                                     as is_last_day_of_month

    from date_spine
)

select * from enriched