/*
    Intermediate: Enriched Authorization Transactions
    ==================================================
    
    COLUMN NAME TRANSFORMATION:
    - Legacy (RAW/STG)     -> Intermediate (clarified)
    - txn_dt               -> transaction_date
    - txn_tm               -> transaction_time
    - txn_ts               -> transaction_timestamp
    - txn_am               -> transaction_amount
    - aprvl_cd             -> approval_status_code
    - dcln_rsn_tx          -> decline_reason_text
    - bin_id               -> card_bin
    - card_lst4            -> card_last_four
    - pymt_mthd            -> payment_method
    - ntwrk                -> processing_network
    - entry_md             -> entry_mode
    - pltf_id              -> processor_id
    - avs_rslt             -> avs_response_code
    - cvv_rslt             -> cvv_response_code
    
    ENRICHMENT:
    - Joins to merchants for location details
    - Joins to BIN table for card details
    - Joins to processors for platform name
    - Joins to decline reasons for full description
    - Derives approval_status from approval_status_code
    
    RETRY DETECTION:
    - A retry is when the same card (BIN + last 4) attempts the same amount
      at the same merchant within 24 hours of a prior decline
    - is_retry_attempt: TRUE on the subsequent attempt after a decline
    - is_retried_decline: TRUE on the declined row that was later retried successfully
*/

with auth as (
    select * from {{ ref('stg_clx_auth') }}
),

merchants as (
    select * from {{ ref('stg_clx_mrch_mstr') }}
),

bins as (
    select * from {{ ref('stg_glb_bin') }}
),

processors as (
    select * from {{ ref('stg_pltf_ref') }}
),

decline_reasons as (
    select * from {{ ref('stg_dcln_rsn_cd') }}
),

enriched as (
    select
        auth.auth_id as authorization_id,
        auth.txn_dt as transaction_date,
        auth.txn_tm as transaction_time,
        auth.txn_ts as transaction_timestamp,
        auth.txn_am as transaction_amount,
        auth.aprvl_cd as approval_status_code,
        case 
            when auth.aprvl_cd = 1 then 'Approved'
            when auth.aprvl_cd = 2 then 'Declined'
            else 'Unknown'
        end as approval_status,
        decline_reasons.dcln_rsn_cd as decline_reason_code,
        coalesce(auth.dcln_rsn_tx, decline_reasons.dcln_rsn_desc) as decline_reason_text,
        decline_reasons.dcln_ctgr as decline_category,
        decline_reasons.sft_dcln_flg as is_soft_decline,
        bins.card_brnd as card_brand,
        bins.card_typ as card_type,
        bins.card_lvl as card_level,
        bins.issr_nm as issuing_bank_name,
        bins.reg_flg as is_durbin_regulated,
        bins.cmrcl_flg as is_commercial_card,
        auth.bin_id as card_bin,
        auth.card_lst4 as card_last_four,
        merchants.mrch_id as merchant_id,
        merchants.lctn_dba_nm as merchant_dba_name,
        merchants.corp_dba_nm as corporate_name,
        merchants.mcc as merchant_category_code,
        merchants.mcc_desc as merchant_category_description,
        merchants.cty as merchant_city,
        merchants.st_cd as merchant_state,
        merchants.zip_cd as merchant_zip,
        auth.pymt_mthd as payment_method,
        auth.ntwrk as processing_network,
        auth.entry_md as entry_mode,
        processors.pltf_id as processor_id,
        processors.pltf_nm as processor_name,
        auth.avs_rslt as avs_response_code,
        auth.cvv_rslt as cvv_response_code

    from auth
    left join merchants 
        on auth.mrch_key = merchants.mrch_key
    left join bins 
        on auth.bin_id = bins.bin_id
    left join processors 
        on auth.pltf_id = processors.pltf_id
    left join decline_reasons 
        on auth.dcln_rsn_id = decline_reasons.dcln_rsn_id
),

retry_detection as (
    select
        *,
        lag(approval_status_code) over (
            partition by card_bin, card_last_four, merchant_id, transaction_amount
            order by transaction_timestamp
        ) as _prev_approval_code,
        lag(transaction_timestamp) over (
            partition by card_bin, card_last_four, merchant_id, transaction_amount
            order by transaction_timestamp
        ) as _prev_timestamp,
        lead(approval_status_code) over (
            partition by card_bin, card_last_four, merchant_id, transaction_amount
            order by transaction_timestamp
        ) as _next_approval_code,
        lead(transaction_timestamp) over (
            partition by card_bin, card_last_four, merchant_id, transaction_amount
            order by transaction_timestamp
        ) as _next_timestamp
    from enriched
)

select
    authorization_id,
    transaction_date,
    transaction_time,
    transaction_timestamp,
    transaction_amount,
    approval_status_code,
    approval_status,
    decline_reason_code,
    decline_reason_text,
    decline_category,
    is_soft_decline,
    card_brand,
    card_type,
    card_level,
    issuing_bank_name,
    is_durbin_regulated,
    is_commercial_card,
    card_bin,
    card_last_four,
    merchant_id,
    merchant_dba_name,
    corporate_name,
    merchant_category_code,
    merchant_category_description,
    merchant_city,
    merchant_state,
    merchant_zip,
    payment_method,
    processing_network,
    entry_mode,
    processor_id,
    processor_name,
    avs_response_code,
    cvv_response_code,

    case
        when _prev_approval_code = 2
            and datediff('hour', _prev_timestamp, transaction_timestamp) <= 24
        then true
        else false
    end as is_retry_attempt,

    case
        when approval_status_code = 2
            and _next_approval_code = 1
            and datediff('hour', transaction_timestamp, _next_timestamp) <= 24
        then true
        else false
    end as is_retried_decline

from retry_detection
