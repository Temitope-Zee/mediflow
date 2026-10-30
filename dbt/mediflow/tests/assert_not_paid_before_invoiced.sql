-- Fails if an invoice was paid before it was issued, which makes days_to_pay negative.
select invoice_id, invoice_date, paid_date
from {{ ref('fct_invoices') }}
where paid_date < invoice_date
