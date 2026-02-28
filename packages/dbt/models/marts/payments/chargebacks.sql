/*
    Marts: Chargebacks
    ===================
    Final business-ready table for chargeback analytics.
    Referenced by the PAYMENT_ANALYTICS semantic view.
*/

with enriched as (
    select * from {{ ref('int_chargebacks__enriched') }}
)

select
    -- Surrogate key
    chargeback_id,

    -- Dates
    dispute_received_date,
    original_transaction_date,
    response_due_date,
    
    -- Reason info
    reason_code,
    reason_description,
    
    -- Status
    chargeback_status,
    chargeback_outcome as outcome,
    lifecycle_stage,
    
    -- Merchant info
    merchant_dba_name as merchant_name,
    merchant_city,
    merchant_state,
    merchant_category_code,
    
    -- Card info
    card_brand,
    
    -- Amounts
    dispute_amount,
    original_transaction_amount as transaction_amount

from enriched
