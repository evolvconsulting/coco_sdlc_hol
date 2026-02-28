/*
    Marts: Authorizations
    ======================
    Final business-ready table for authorization analytics.
    Referenced by the PAYMENT_ANALYTICS semantic view.
*/

with enriched as (
    select * from {{ ref('int_authorizations__enriched') }}
)

select
    -- Surrogate key
    authorization_id,

    -- Transaction details
    transaction_date,
    transaction_time,
    
    -- Card brand
    card_brand,
    
    -- Approval status
    approval_status_code,
    approval_status,
    decline_reason_text as decline_reason,
    
    -- Amount
    transaction_amount,
    
    -- Merchant info
    merchant_dba_name as merchant_name,
    corporate_name,
    merchant_category_code,
    
    -- Processor
    processor_id,
    processor_name,
    
    -- Card details
    card_bin,
    card_last_four,
    
    -- Transaction type
    payment_method,
    processing_network,
    
    -- Response codes
    avs_response_code as avs_response,
    cvv_response_code as cvv_response,

    -- Risk
    risk_score

from enriched
