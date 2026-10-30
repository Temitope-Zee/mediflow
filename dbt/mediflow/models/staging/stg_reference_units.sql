-- One row per clinic or ward. bed_count arrives as text like '28.0', so it is cast through numeric.

select
    unit_code,
    unit_name,
    unit_type,
    specialty,
    nullif(bed_count, '')::numeric::int  as bed_count
from {{ source('raw', 'reference_units') }}
