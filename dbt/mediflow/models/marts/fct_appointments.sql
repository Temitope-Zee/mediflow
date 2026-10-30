-- One row per appointment. Patients are mapped to their canonical ID.
-- Orphan appointments keep their original patient_id so Lab 3 tests can flag them.

select
    a.appointment_id,
    coalesce(p.canonical_patient_id, a.patient_id)  as patient_id,
    a.unit_code,
    a.clinician_id,
    a.booked_at::date                               as booking_date,
    a.scheduled_at::date                            as appointment_date,
    a.status,
    a.status = 'DNA'                                as is_dna,
    a.scheduled_at::date - a.booked_at::date        as booking_lead_days
from {{ ref('stg_appointments') }} a
left join {{ ref('stg_patients') }} p
    on a.patient_id = p.patient_id
