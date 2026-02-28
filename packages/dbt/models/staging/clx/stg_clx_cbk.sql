/*
    Staging: Chargeback Transactions
    =================================
    Source: RAW.CLX_CBK (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
*/

with source as (
    select * from {{ source('raw', 'CLX_CBK') }}
    where clnt_id = '{{ var("client_id") }}'
),

renamed as (
    select
        -- Primary keys
        cbk_id,
        clnt_id,
        mrch_key,
        
        -- Case info (legacy names)
        case_nr,
        arn,
        
        -- Dates (legacy names)
        dsput_rcvd_dt,
        orig_txn_dt,
        due_dt,
        rslvd_dt,
        
        -- Amounts (legacy names)
        dsput_am,
        txn_am,
        repr_am,
        
        -- Status (legacy names)
        cbk_stat,
        cbk_win_loss,
        cbk_cycl,
        
        -- Reason (legacy names)
        cbk_rsn_id,
        rsn_desc_ovrd,
        rsn_ctgr,
        
        -- Card info (legacy names)
        card_brnd,
        card_lst4,
        
        -- Merchant (legacy names)
        mrch_nm,
        
        -- Response (legacy names)
        resp_sent_flg,
        resp_dt,
        docs_sbmtd_flg,
        
        -- Platform (legacy name)
        pltf_id,
        
        -- Audit fields
        crt_ts,
        upd_ts
        
    from source
)

select * from renamed
