/*
    Intermediate: Enriched Adjustments
    ===================================
    
    COLUMN NAME TRANSFORMATION:
    - adj_dt               -> adjustment_date
    - eff_dt               -> effective_date
    - orig_txn_dt          -> original_transaction_date
    - adj_am               -> adjustment_amount
    - adj_typ_cd           -> adjustment_type_code
    - adj_cd               -> adjustment_code
    - adj_desc             -> adjustment_description
    - adj_ctgr             -> adjustment_category
    - fee_typ_cd           -> fee_type_code
    - fee_desc             -> fee_description
    - rltd_txn_id          -> related_transaction_id
    - rltd_txn_typ         -> related_transaction_type
    - adj_stat             -> adjustment_status
    
    ENRICHMENT:
    - Joins to merchants for location details
    - Joins to processors for platform name
    - Derives adjustment_type from adjustment_type_code
*/

with adjustments as (
    select * from {{ ref('stg_clx_adj') }}
),

merchants as (
    select * from {{ ref('stg_clx_mrch_mstr') }}
),

processors as (
    select * from {{ ref('stg_pltf_ref') }}
)

select
    -- Primary key
    adjustments.adj_id as adjustment_id,
    
    -- Reference
    adjustments.adj_ref_nr as adjustment_reference_number,
    
    -- Dates (RENAMED from legacy)
    adjustments.adj_dt as adjustment_date,
    adjustments.eff_dt as effective_date,
    adjustments.orig_txn_dt as original_transaction_date,
    
    -- Amount (RENAMED from legacy)
    adjustments.adj_am as adjustment_amount,
    
    -- Type (RENAMED + DERIVED from legacy)
    adjustments.adj_typ_cd as adjustment_type_code,
    case 
        when adjustments.adj_typ_cd = 'C' then 'Credit'
        when adjustments.adj_typ_cd = 'D' then 'Debit'
        else 'Unknown'
    end as adjustment_type,
    
    -- Codes (RENAMED from legacy)
    adjustments.adj_cd as adjustment_code,
    adjustments.adj_desc as adjustment_description,
    adjustments.adj_ctgr as adjustment_category,
    
    -- Fee info (RENAMED from legacy)
    adjustments.fee_typ_cd as fee_type_code,
    adjustments.fee_desc as fee_description,
    
    -- Related transaction (RENAMED from legacy)
    adjustments.rltd_txn_id as related_transaction_id,
    adjustments.rltd_txn_typ as related_transaction_type,
    
    -- Status (RENAMED from legacy)
    adjustments.adj_stat as adjustment_status,
    
    -- Merchant info (ENRICHED from join)
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,
    
    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name,
    
    -- Audit
    adjustments.crt_by as created_by

from adjustments
left join merchants 
    on adjustments.mrch_key = merchants.mrch_key
left join processors 
    on adjustments.pltf_id = processors.pltf_id
