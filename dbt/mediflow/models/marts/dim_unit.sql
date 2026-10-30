-- One row per clinic or ward.

select
    unit_code,
    unit_name,
    unit_type,
    specialty,
    bed_count
from {{ ref('stg_reference_units') }}
