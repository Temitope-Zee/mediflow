-- One row per real person: only the canonical registration for each MRN.

select
    patient_id,
    mrn,
    first_name,
    last_name,
    date_of_birth,
    date_part('year', age(current_date, date_of_birth))::int  as age_years,
    case
        when date_of_birth is null then 'Unknown'
        when age(current_date, date_of_birth) < interval '18 years' then '0-17'
        when age(current_date, date_of_birth) < interval '40 years' then '18-39'
        when age(current_date, date_of_birth) < interval '65 years' then '40-64'
        when age(current_date, date_of_birth) < interval '80 years' then '65-79'
        else '80+'
    end                                                       as age_band,
    sex,
    postcode,
    registered_at
from {{ ref('stg_patients') }}
where patient_id = canonical_patient_id
