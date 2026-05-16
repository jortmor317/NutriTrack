with source as (
    select * from {{ source('nutritrack', 'USDA_FOODS') }}
),

-- Aplanamos el array de nutrientes
flattened as (
    select
        RAW_JSON:fdcId::VARCHAR             as fdc_id,
        RAW_JSON:description::VARCHAR       as description,
        RAW_JSON:dataType::VARCHAR          as data_type,
        RAW_JSON:publicationDate::VARCHAR   as publication_date,
        f.value:nutrient:name::VARCHAR      as nutrient_name,
        f.value:amount::FLOAT               as amount,
        f.value:nutrient:unitName::VARCHAR  as unit,
        LOADED_AT                           as loaded_at
    from source,
        LATERAL FLATTEN(input => RAW_JSON:foodNutrients) f
),

-- Pivotamos los nutrientes relevantes a columnas
pivoted as (
    select
        fdc_id,
        description,
        data_type,
        publication_date,
        loaded_at,

        -- Calorías en kcal
        MAX(CASE WHEN nutrient_name = 'Energy' 
                  AND unit = 'kcal' 
                  THEN amount END)          as calories_kcal,

        -- Macronutrientes
        MAX(CASE WHEN nutrient_name = 'Protein' 
                  THEN amount END)          as protein_g,

        MAX(CASE WHEN nutrient_name = 'Carbohydrate, by difference' 
                  THEN amount END)          as carbs_g,

        MAX(CASE WHEN nutrient_name = 'Total lipid (fat)' 
                  THEN amount END)          as fat_g,

        MAX(CASE WHEN nutrient_name = 'Fiber, total dietary' 
                  THEN amount END)          as fiber_g,

        MAX(CASE WHEN nutrient_name = 'Total Sugars' 
                  THEN amount END)          as sugars_g,

        -- Minerales
        MAX(CASE WHEN nutrient_name = 'Calcium, Ca' 
                  THEN amount END)          as calcium_mg,

        MAX(CASE WHEN nutrient_name = 'Iron, Fe' 
                  THEN amount END)          as iron_mg,

        MAX(CASE WHEN nutrient_name = 'Sodium, Na' 
                  THEN amount END)          as sodium_mg,

        MAX(CASE WHEN nutrient_name = 'Potassium, K' 
                  THEN amount END)          as potassium_mg,

        -- Vitaminas
        MAX(CASE WHEN nutrient_name = 'Vitamin C, total ascorbic acid' 
                  THEN amount END)          as vitamin_c_mg,

        MAX(CASE WHEN nutrient_name = 'Vitamin A, IU' 
                  THEN amount END)          as vitamin_a_iu

    from flattened
    group by fdc_id, description, data_type, publication_date, loaded_at
)

select * from pivoted