/*
    Intermediate: Enriched Settlement Transactions
    ===============================================
    
    COLUMN NAME TRANSFORMATION:
    - rcrd_dt              -> settlement_date
    - btch_dt              -> batch_date
    - prcs_dt              -> processing_date
    - sales_ct             -> sales_transaction_count
    - rfnd_ct              -> refund_transaction_count
    - net_ct               -> net_transaction_count
    - sales_am             -> gross_sales_amount
    - rfnd_am              -> refund_amount
    - prcs_net_am          -> net_settlement_amount
    - dscn_am              -> discount_fee_amount
    - intchg_am            -> interchange_fee_amount
    - card_brnd            -> card_brand
    - card_typ             -> card_type
    - plan_cd              -> interchange_plan_code
    - plan_desc            -> interchange_plan_description
    - btch_ref             -> batch_reference_number
    - ntwrk                -> processing_network
    
    ENRICHMENT:
    - Joins to merchants for location details
    - Joins to processors for platform name
    - Derives average_ticket_amount
*/

with settlements as (
    select * from {{ ref('stg_clx_settle') }}
),

merchants as (
    select * from {{ ref('stg_clx_mrch_mstr') }}
),

processors as (
    select * from {{ ref('stg_pltf_ref') }}
)

select
    -- Primary key
    settlements.settle_id as settlement_id,
    
    -- Dates (RENAMED from legacy)
    settlements.rcrd_dt as settlement_date,
    settlements.btch_dt as batch_date,
    settlements.prcs_dt as processing_date,
    
    -- Counts (RENAMED from legacy)
    settlements.sales_ct as sales_transaction_count,
    settlements.rfnd_ct as refund_transaction_count,
    settlements.net_ct as net_transaction_count,
    0 as rejected_transaction_count,  -- Default value
    
    -- Amounts (RENAMED from legacy)
    settlements.sales_am as gross_sales_amount,
    settlements.rfnd_am as refund_amount,
    settlements.prcs_net_am as net_settlement_amount,
    settlements.dscn_am as discount_fee_amount,
    settlements.intchg_am as interchange_fee_amount,
    
    -- Derived: Average ticket
    case 
        when settlements.net_ct > 0 
        then round(settlements.prcs_net_am / settlements.net_ct, 2)
        else 0 
    end as average_ticket_amount,
    
    -- Card info (RENAMED from legacy)
    settlements.card_brnd as card_brand,
    settlements.card_typ as card_type,
    
    -- Plan info (RENAMED from legacy)
    settlements.plan_cd as interchange_plan_code,
    settlements.plan_desc as interchange_plan_description,
    
    -- Merchant info (ENRICHED from join)
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,
    
    -- Reference (RENAMED from legacy)
    settlements.btch_ref as batch_reference_number,
    
    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name,
    settlements.ntwrk as processing_network

from settlements
left join merchants 
    on settlements.mrch_key = merchants.mrch_key
left join processors 
    on settlements.pltf_id = processors.pltf_id
