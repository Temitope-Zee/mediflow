-- Fails if any invoice has a negative amount (possibly a credit note: finance must confirm).
select invoice_id, amount_gbp
from {{ ref('fct_invoices') }}
where amount_gbp < 0
