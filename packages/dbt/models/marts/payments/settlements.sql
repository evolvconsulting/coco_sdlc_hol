/*
    Marts: Settlements
    ===================
    Final business-ready table for settlement analytics.
    Referenced by the PAYMENT_ANALYTICS semantic view.
*/

with enriched as (
    select * from {{ ref('int_settlements__enriched') }}
)

select
    -- Surrogate key
    settlement_id,

    -- Dates
    settlement_date,
    batch_date,
    
    -- Card info
    card_brand,
    card_type,
    
    -- Plan info
    interchange_plan_code,
    
    -- Merchant info
    merchant_dba_name as merchant_name,
    corporate_name,
    
    -- Batch reference
    batch_reference_number as batch_number,
    
    -- Counts
    sales_transaction_count as sales_count,
    refund_transaction_count as refund_count,
    net_transaction_count as net_count,
    
    -- Amounts
    net_settlement_amount as net_amount,
    gross_sales_amount as sales_amount,
    refund_amount,
    discount_fee_amount as discount_amount

from enriched
