-- Admissions mapped to the canonical patient, with length of stay and
-- a flag for patients admitted again within 30 days of discharge.
-- Rows in int_admissions_rejected are left out.

with admissions as (
    select
        a.*,
        p.canonical_patient_id
    from {{ ref('stg_admissions') }} a
    left join {{ ref('stg_patients') }} p
        on a.patient_id = p.patient_id
    where a.admission_id not in (
        select admission_id from {{ ref('int_admissions_rejected') }}
    )
),

ordered as (
    select
        *,
        lead(admitted_at) over (
            partition by canonical_patient_id order by admitted_at
        ) as next_admitted_at
    from admissions
)

select
    admission_id,
    canonical_patient_id                       as patient_id,
    ward_code                                  as unit_code,
    admission_type,
    admitted_at,
    discharged_at,
    discharge_destination,
    case when discharged_at is not null then
        round(extract(epoch from discharged_at - admitted_at) / 86400.0, 1)
    end                                        as length_of_stay_days,
    discharged_at is null                      as is_current_inpatient,
    coalesce(
        next_admitted_at <= discharged_at + interval '30 days', false
    )                                          as readmitted_within_30d
from ordered
