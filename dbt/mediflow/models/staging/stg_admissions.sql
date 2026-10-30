-- One row per inpatient stay. A blank discharge date means the patient is still in hospital.

select
    admission_id::int                     as admission_id,
    patient_id::int                       as patient_id,
    ward_code,
    admission_type,
    admitted_at::timestamp                as admitted_at,
    nullif(discharged_at, '')::timestamp  as discharged_at,
    discharge_destination
from {{ source('raw', 'admissions') }}
