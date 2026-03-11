/*
    Intermediate: Enriched Adjustments
    ===================================
    
    COLUMN NAME TRANSFORMATION:
    - adj_dt               -> adjustment_date
    - eff_dt               -> effective_date
    - post_dt              -> original_transaction_date
    - adj_am               -> adjustment_amount
    - adj_typ              -> adjustment_type_code
    - rsn_cd               -> adjustment_code
    - rsn_desc             -> adjustment_description
    - gl_acct              -> adjustment_category
    - dept_cd              -> fee_type_code
    - notes_tx             -> fee_description
    - btch_ref             -> related_transaction_id
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
    adjustments.ref_nr as adjustment_reference_number,
    
    -- Dates (RENAMED from legacy)
    adjustments.adj_dt as adjustment_date,
    adjustments.eff_dt as effective_date,
    adjustments.post_dt as original_transaction_date,
    
    -- Amount (RENAMED from legacy)
    adjustments.adj_am as adjustment_amount,
    
    -- Type (RENAMED + DERIVED from legacy)
    adjustments.adj_typ as adjustment_type_code,
    case 
        when adjustments.adj_typ = 'C' then 'Credit'
        when adjustments.adj_typ = 'D' then 'Debit'
        else 'Unknown'
    end as adjustment_type,
    
    -- Codes (RENAMED from legacy)
    adjustments.rsn_cd as adjustment_code,
    adjustments.rsn_desc as adjustment_description,
    adjustments.gl_acct as adjustment_category,
    
    -- Fee info (RENAMED from legacy)
    adjustments.dept_cd as fee_type_code,
    adjustments.notes_tx as fee_description,
    
    -- Related transaction (RENAMED from legacy)
    adjustments.btch_ref as related_transaction_id,
    
    -- Status (RENAMED from legacy)
    adjustments.adj_stat as adjustment_status,
    
    -- Merchant info (ENRICHED from join)
    merchants.mrch_id as merchant_id,
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,
    
    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name,
    
    -- Audit
    adjustments.aprvd_by as created_by

from adjustments
left join merchants 
    on adjustments.mrch_key = merchants.mrch_key
left join processors 
    on adjustments.pltf_id = processors.pltf_id
