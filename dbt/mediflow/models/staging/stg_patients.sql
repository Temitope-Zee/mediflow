-- One row per registration. Duplicate MRNs are kept, but every row gets a
-- canonical_patient_id: the earliest registration for that MRN.

with source as (
    select * from {{ source('raw', 'patients') }}
),

typed as (
    select
        patient_id::int                  as patient_id,
        upper(trim(mrn))                 as mrn,
        initcap(trim(first_name))        as first_name,
        initcap(trim(last_name))         as last_name,
        nullif(date_of_birth, '')::date  as date_of_birth,
        upper(trim(sex))                 as sex,
        upper(trim(postcode))            as postcode,
        registered_at::timestamp         as registered_at
    from source
)

select
    patient_id,
    first_value(patient_id) over (
        partition by mrn order by registered_at, patient_id
    )                                    as canonical_patient_id,
    mrn,
    first_name,
    last_name,
    case when date_of_birth > current_date then null
         else date_of_birth end          as date_of_birth,
    sex,
    postcode,
    registered_at
from typed
