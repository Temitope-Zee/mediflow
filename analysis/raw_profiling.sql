-- Lab 1: profiling the raw layer
-- Each query measures one planted data quality problem.
-- Every column in raw is text, so values are cast where a comparison needs a number or date.

\echo '1. Patient numbers (MRN) registered more than once'
select count(*) as duplicated_mrns
from (
    select mrn
    from raw.patients
    group by mrn
    having count(*) > 1
) d;

\echo '2. Patients with no date of birth'
select count(*) as missing_dob
from raw.patients
where date_of_birth is null or date_of_birth = '';

\echo '3. Patients born in the future'
select count(*) as future_dob
from raw.patients
where nullif(date_of_birth, '')::date > current_date;

\echo '4. Postcodes not in capitals'
select count(*) as lowercase_postcodes
from raw.patients
where postcode <> upper(postcode);

\echo '5. Appointment status: every spelling in the data'
select status, count(*) as appointments
from raw.appointments
group by status
order by status;

\echo '6. Appointments for a patient who is not registered'
select count(*) as orphan_appointments
from raw.appointments a
left join raw.patients p on a.patient_id = p.patient_id
where p.patient_id is null;

\echo '7. Admissions discharged before they were admitted'
select count(*) as discharged_before_admitted
from raw.admissions
where nullif(discharged_at, '')::timestamp < admitted_at::timestamp;

\echo '8. Patients still in hospital (no discharge date, not an error)'
select count(*) as current_inpatients
from raw.admissions
where discharged_at is null or discharged_at = '';

\echo '9. Invoices with a negative amount'
select count(*) as negative_invoices
from raw.invoices
where amount_gbp::numeric < 0;

\echo '10. Invoices paid before they were issued'
select count(*) as paid_before_invoiced
from raw.invoices
where nullif(paid_date, '')::date < invoice_date::date;
