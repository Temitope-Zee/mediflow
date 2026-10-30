-- Fails if an appointment was booked after the date it took place.
select appointment_id, booking_date, appointment_date
from {{ ref('fct_appointments') }}
where booking_date > appointment_date
