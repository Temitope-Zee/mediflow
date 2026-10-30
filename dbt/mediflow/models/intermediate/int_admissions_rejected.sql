-- Quarantine: admissions that cannot be used in length-of-stay or readmission figures.
-- Kept, with a reason, so someone can investigate and correct the source system.

select
    *,
    'discharged_before_admitted'  as rejection_reason,
    current_timestamp             as rejected_at
from {{ ref('stg_admissions') }}
where discharged_at < admitted_at
