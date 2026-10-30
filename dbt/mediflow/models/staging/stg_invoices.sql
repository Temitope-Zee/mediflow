-- One row per invoice, with money as numeric and dates as dates.

select
    invoice_id,
    patient_id::int                  as patient_id,
    admission_id::int                as admission_id,
    payer_type,
    amount_gbp::numeric(12, 2)       as amount_gbp,
    invoice_date::date               as invoice_date,
    due_date::date                   as due_date,
    nullif(paid_date, '')::date      as paid_date
from {{ source('raw', 'invoices') }}
