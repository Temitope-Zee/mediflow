-- One row per calendar day, 2023 to 2026.

select
    d::date                              as date_day,
    extract(year from d)::int            as year,
    extract(month from d)::int           as month,
    to_char(d, 'Mon YYYY')               as month_label,
    extract(isodow from d)::int          as iso_day_of_week,
    extract(isodow from d) in (6, 7)     as is_weekend
from generate_series('2023-01-01'::date, '2026-12-31'::date, interval '1 day') as d
