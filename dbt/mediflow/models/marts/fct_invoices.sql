-- One row per valid invoice, with payment status and timing.
-- Rows in int_invoices_rejected are left out.

select
    i.invoice_id,
    coalesce(p.canonical_patient_id, i.patient_id)  as patient_id,
    i.admission_id,
    i.payer_type,
    i.amount_gbp,
    i.invoice_date,
    i.due_date,
    i.paid_date,
    i.paid_date is not null                          as is_paid,
    i.paid_date - i.invoice_date                     as days_to_pay,
    case when i.paid_date is null and current_date > i.due_date
         then current_date - i.due_date end          as days_overdue
from {{ ref('stg_invoices') }} i
left join {{ ref('stg_patients') }} p
    on i.patient_id = p.patient_id
where i.invoice_id not in (
    select invoice_id from {{ ref('int_invoices_rejected') }}
)
