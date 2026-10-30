-- One row per outpatient appointment, with status spelt one way only.

select
    appointment_id::int          as appointment_id,
    patient_id::int              as patient_id,
    clinic_code                  as unit_code,
    clinician_id,
    booked_at::timestamp         as booked_at,
    scheduled_at::timestamp      as scheduled_at,
    case upper(trim(status))
        when 'ATTENDED'    then 'Attended'
        when 'DNA'         then 'DNA'
        when 'CANCELLED'   then 'Cancelled'
        when 'RESCHEDULED' then 'Rescheduled'
    end                          as status
from {{ source('raw', 'appointments') }}
