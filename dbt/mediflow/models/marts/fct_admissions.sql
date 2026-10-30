-- One row per inpatient stay.

select
    admission_id,
    patient_id,
    unit_code,
    admitted_at::date      as admission_date,
    discharged_at::date    as discharge_date,
    admission_type,
    discharge_destination,
    length_of_stay_days,
    is_current_inpatient,
    readmitted_within_30d
from {{ ref('int_admissions_enriched') }}
