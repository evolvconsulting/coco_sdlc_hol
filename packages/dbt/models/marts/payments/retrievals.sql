/*
    Marts: Retrievals
    ==================
    Final business-ready table for retrieval request analytics.
    Referenced by the PAYMENT_ANALYTICS semantic view.
*/

with enriched as (
    select * from {{ ref('int_retrievals__enriched') }}
)

select
    -- Dates
    original_sale_date,
    response_due_date,
    fulfillment_date,
    
    -- Status
    retrieval_status,
    
    -- Reason
    reason_code,
    
    -- Reference
    acquirer_reference_number as reference_number,
    
    -- Merchant info
    merchant_dba_name as merchant_name,
    
    -- Card info
    card_brand,
    
    -- Amount
    retrieval_amount

from enriched
