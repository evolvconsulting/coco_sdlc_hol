/*
    Marts: Adjustments
    ===================
    Final business-ready table for adjustment analytics.
    Referenced by the PAYMENT_ANALYTICS semantic view.
*/

with enriched as (
    select * from {{ ref('int_adjustments__enriched') }}
)

select
    -- Surrogate key
    adjustment_id,

    -- Dates
    adjustment_date,
    effective_date,
    
    -- Codes
    adjustment_code,
    adjustment_description,
    adjustment_category,
    adjustment_type,
    
    -- Fee info
    fee_description,
    
    -- Merchant info
    merchant_dba_name as merchant_name,
    corporate_name,
    
    -- Amount
    adjustment_amount

from enriched
