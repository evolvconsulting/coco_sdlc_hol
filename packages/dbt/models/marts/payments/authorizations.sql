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
    authorization_id as authorization_key,

    -- Transaction details
    transaction_date,
    transaction_time,

    -- Merchant
    merchant_id,

    -- Card brand
    card_brand,
    card_type,
    case when is_commercial_card then 'Commercial' else 'Consumer' end as card_category,

    -- Entry mode
    entry_mode,

    -- Approval status
    approval_status_code,
    approval_status,
    decline_reason_text as decline_reason,

    -- Amount
    transaction_amount,
    1 as transactions_count,

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

    -- Retry metrics
    is_retry,
    case when is_retry then 1 else 0 end as retry_count,
    case when is_retry_successful then 1 else 0 end as retry_success_count

from enriched
