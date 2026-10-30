-- Quarantine: invoices that would distort debt and payment-time figures.

select
    *,
    case
        when amount_gbp < 0 then 'negative_amount'
        when paid_date < invoice_date then 'paid_before_invoiced'
    end                  as rejection_reason,
    current_timestamp    as rejected_at
from {{ ref('stg_invoices') }}
where amount_gbp < 0
   or paid_date < invoice_date
