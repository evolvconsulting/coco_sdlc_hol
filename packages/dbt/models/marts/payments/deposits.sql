/*
    Marts: Deposits
    ================
    Final business-ready table for deposit/funding analytics.
    Referenced by the PAYMENT_ANALYTICS semantic view.
*/

with enriched as (
    select * from {{ ref('int_deposits__enriched') }}
)

select
    -- Surrogate key
    deposit_id,

    -- Dates
    deposit_date,
    settlement_date,
    
    -- Status
    payment_status,
    
    -- Merchant info
    merchant_dba_name as merchant_name,
    corporate_name,
    
    -- Bank info
    bank_account_last_four,
    
    -- Categories
    transaction_category,
    major_category_code,
    minor_category_code,
    
    -- Amounts
    total_deposit_amount as deposit_amount,
    net_sales_amount,
    total_fees_amount,
    chargeback_deduction_amount as chargeback_amount,
    adjustment_amount,
    interchange_charges_amount as interchange_charges,
    service_charges_amount as service_charges,
    
    -- Counts
    item_count

from enriched
