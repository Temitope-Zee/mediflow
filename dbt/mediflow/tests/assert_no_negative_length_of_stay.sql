-- Fails if any stay ends before it starts. Returns the offending rows.
select admission_id, admission_date, discharge_date, length_of_stay_days
from {{ ref('fct_admissions') }}
where length_of_stay_days < 0
