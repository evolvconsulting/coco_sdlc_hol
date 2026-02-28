/*
    Intermediate: Enriched Chargeback Transactions
    ===============================================
    
    COLUMN NAME TRANSFORMATION:
    - dsput_rcvd_dt        -> dispute_received_date
    - orig_txn_dt          -> original_transaction_date
    - due_dt               -> response_due_date
    - rslvd_dt             -> resolution_date
    - dsput_am             -> dispute_amount
    - txn_am               -> original_transaction_amount
    - repr_am              -> representment_amount
    - cbk_stat             -> chargeback_status
    - cbk_win_loss         -> chargeback_outcome
    - cbk_cycl             -> lifecycle_stage
    - rsn_desc_ovrd        -> reason_description_override
    - rsn_ctgr             -> reason_category
    - card_brnd            -> card_brand
    - card_lst4            -> card_last_four
    - mrch_nm              -> merchant_name_on_dispute
    - resp_sent_flg        -> response_submitted
    - resp_dt              -> response_date
    - docs_sbmtd_flg       -> documents_submitted
    
    ENRICHMENT:
    - Joins to merchants for location details
    - Joins to processors for platform name
    - Joins to chargeback reason codes for full description
    - Derives days_until_due and is_past_due
*/

with chargebacks as (
    select * from {{ ref('stg_clx_cbk') }}
),

merchants as (
    select * from {{ ref('stg_clx_mrch_mstr') }}
),

processors as (
    select * from {{ ref('stg_pltf_ref') }}
),

chargeback_reasons as (
    select * from {{ ref('stg_cbk_rsn_cd') }}
)

select
    -- Primary key
    chargebacks.cbk_id as chargeback_id,
    
    -- Case info
    chargebacks.case_nr as case_number,
    chargebacks.arn as acquirer_reference_number,
    
    -- Dates (RENAMED from legacy)
    chargebacks.dsput_rcvd_dt as dispute_received_date,
    chargebacks.orig_txn_dt as original_transaction_date,
    chargebacks.due_dt as response_due_date,
    chargebacks.rslvd_dt as resolution_date,
    
    -- Derived: Days calculations
    datediff('day', chargebacks.dsput_rcvd_dt, chargebacks.due_dt) as days_to_respond,
    datediff('day', current_date(), chargebacks.due_dt) as days_until_due,
    case 
        when chargebacks.due_dt < current_date() and chargebacks.cbk_stat != 'Closed' 
        then true 
        else false 
    end as is_past_due,
    
    -- Amounts (RENAMED from legacy)
    chargebacks.dsput_am as dispute_amount,
    chargebacks.txn_am as original_transaction_amount,
    chargebacks.repr_am as representment_amount,
    
    -- Status (RENAMED from legacy)
    chargebacks.cbk_stat as chargeback_status,
    chargebacks.cbk_win_loss as chargeback_outcome,
    chargebacks.cbk_cycl as lifecycle_stage,
    
    -- Reason info (RENAMED + ENRICHED from join)
    chargeback_reasons.rsn_cd as reason_code,
    coalesce(chargebacks.rsn_desc_ovrd, chargeback_reasons.rsn_desc) as reason_description,
    coalesce(chargebacks.rsn_ctgr, chargeback_reasons.rsn_ctgr) as reason_category,
    
    -- Card info (RENAMED from legacy)
    chargebacks.card_brnd as card_brand,
    chargebacks.card_lst4 as card_last_four,
    
    -- Merchant info (RENAMED + ENRICHED from join)
    chargebacks.mrch_nm as merchant_name_on_dispute,
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,
    merchants.cty as merchant_city,
    merchants.st_cd as merchant_state,
    merchants.mcc as merchant_category_code,
    
    -- Response info (RENAMED from legacy)
    chargebacks.resp_sent_flg as response_submitted,
    chargebacks.resp_dt as response_date,
    chargebacks.docs_sbmtd_flg as documents_submitted,
    
    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name

from chargebacks
left join merchants 
    on chargebacks.mrch_key = merchants.mrch_key
left join processors 
    on chargebacks.pltf_id = processors.pltf_id
left join chargeback_reasons 
    on chargebacks.cbk_rsn_id = chargeback_reasons.cbk_rsn_id
