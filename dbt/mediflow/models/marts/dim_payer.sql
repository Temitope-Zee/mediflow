-- One row per payer type.

select distinct
    payer_type,
    payer_type = 'Self-pay'  as is_self_pay
from {{ ref('stg_invoices') }}
