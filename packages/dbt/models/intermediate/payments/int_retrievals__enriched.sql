/*
    Intermediate: Enriched Retrieval Requests
    ==========================================
    
    COLUMN NAME TRANSFORMATION:
    - rtrvl_rcvd_dt        -> retrieval_received_date
    - sale_dt              -> original_sale_date
    - due_dt               -> response_due_date
    - fulfmt_dt            -> fulfillment_date
    - rtrvl_am             -> retrieval_amount
    - rtrvl_stat           -> retrieval_status
    - fulfmt_stat          -> fulfillment_status
    - rsn_cd               -> reason_code
    - rsn_desc             -> reason_description
    - card_brnd            -> card_brand
    - card_lst4            -> card_last_four
    - docs_reqd            -> documents_requested
    - docs_sbmtd_flg       -> documents_submitted
    - sbmsn_mthd           -> submission_method
    
    ENRICHMENT:
    - Joins to merchants for location details
    - Joins to processors for platform name
    - Derives days_until_due and is_overdue
*/

with retrievals as (
    select * from {{ ref('stg_clx_rtrvl') }}
),

merchants as (
    select * from {{ ref('stg_clx_mrch_mstr') }}
),

processors as (
    select * from {{ ref('stg_pltf_ref') }}
)

select
    -- Primary key
    retrievals.rtrvl_id as retrieval_id,
    
    -- Reference
    retrievals.arn as acquirer_reference_number,
    
    -- Dates (RENAMED from legacy)
    retrievals.rtrvl_rcvd_dt as retrieval_received_date,
    retrievals.sale_dt as original_sale_date,
    retrievals.due_dt as response_due_date,
    retrievals.fulfmt_dt as fulfillment_date,
    
    -- Derived: Days calculations
    datediff('day', current_date(), retrievals.due_dt) as days_until_due,
    case 
        when retrievals.due_dt < current_date() 
             and retrievals.rtrvl_stat not in ('Closed', 'Fulfilled') 
        then true 
        else false 
    end as is_overdue,
    
    -- Amount (RENAMED from legacy)
    retrievals.rtrvl_am as retrieval_amount,
    
    -- Status (RENAMED from legacy)
    retrievals.rtrvl_stat as retrieval_status,
    retrievals.fulfmt_stat as fulfillment_status,
    
    -- Reason info (RENAMED from legacy)
    retrievals.rsn_cd as reason_code,
    retrievals.rsn_desc as reason_description,
    
    -- Card info (RENAMED from legacy)
    retrievals.card_brnd as card_brand,
    retrievals.card_lst4 as card_last_four,
    
    -- Merchant info (ENRICHED from join)
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,
    
    -- Documentation (RENAMED from legacy)
    retrievals.docs_reqd as documents_requested,
    retrievals.docs_sbmtd_flg as documents_submitted,
    retrievals.sbmsn_mthd as submission_method,
    
    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name

from retrievals
left join merchants 
    on retrievals.mrch_key = merchants.mrch_key
left join processors 
    on retrievals.pltf_id = processors.pltf_id
