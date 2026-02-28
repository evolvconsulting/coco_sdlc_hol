/*
    Intermediate: Enriched Deposit/Funding Transactions
    ====================================================
    
    COLUMN NAME TRANSFORMATION:
    - funded_dt            -> deposit_date
    - settle_dt            -> settlement_date
    - dpst_am              -> total_deposit_amount
    - net_sales_am         -> net_sales_amount
    - fees_am              -> total_fees_amount
    - cbk_am               -> chargeback_deduction_amount
    - adj_am               -> adjustment_amount
    - rsrv_am              -> reserve_holdback_amount
    - item_ct              -> item_count
    - pymt_stat            -> payment_status
    - pymt_mthd            -> payment_method
    - dda_lst4             -> bank_account_last_four
    - bank_nm              -> bank_name
    - txn_ctgr             -> transaction_category
    
    ENRICHMENT:
    - Joins to merchants for location details
    - Joins to processors for platform name
    - Derives interchange_charges_amount and service_charges_amount
*/

with deposits as (
    select * from {{ ref('stg_clx_fund') }}
),

merchants as (
    select * from {{ ref('stg_clx_mrch_mstr') }}
),

processors as (
    select * from {{ ref('stg_pltf_ref') }}
)

select
    -- Primary key
    deposits.fund_id as deposit_id,
    
    -- Dates (RENAMED from legacy)
    deposits.funded_dt as deposit_date,
    deposits.settle_dt as settlement_date,
    deposits.expct_dt as expected_deposit_date,
    
    -- Amounts (RENAMED from legacy)
    deposits.dpst_am as total_deposit_amount,
    deposits.net_sales_am as net_sales_amount,
    deposits.fees_am as total_fees_amount,
    deposits.cbk_am as chargeback_deduction_amount,
    deposits.adj_am as adjustment_amount,
    deposits.rsrv_am as reserve_holdback_amount,
    
    -- Derived: Fee breakdown (estimated split)
    round(deposits.fees_am * 0.7, 2) as interchange_charges_amount,
    round(deposits.fees_am * 0.3, 2) as service_charges_amount,
    
    -- Counts (RENAMED from legacy)
    deposits.item_ct as item_count,
    deposits.sales_ct as sales_count,
    deposits.rfnd_ct as refund_count,
    
    -- Status (RENAMED from legacy)
    deposits.pymt_stat as payment_status,
    deposits.pymt_mthd as payment_method,
    
    -- Bank info (RENAMED from legacy)
    deposits.dda_lst4 as bank_account_last_four,
    deposits.bank_nm as bank_name,
    
    -- Category (RENAMED from legacy)
    deposits.txn_ctgr as transaction_category,
    deposits.fund_typ as deposit_type,
    
    -- Derived: Category codes
    left(deposits.txn_ctgr, 3) as major_category_code,
    right(deposits.txn_ctgr, 3) as minor_category_code,
    
    -- Merchant info (ENRICHED from join)
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,
    
    -- Reference (RENAMED from legacy)
    deposits.btch_ref as batch_reference_number,
    deposits.ach_trc as ach_trace_number,
    
    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name

from deposits
left join merchants 
    on deposits.mrch_key = merchants.mrch_key
left join processors 
    on deposits.pltf_id = processors.pltf_id
