/*
    Staging: Authorization Transactions
    ===================================
    Source: RAW.CLX_AUTH (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
    Transformation: Filters by client_id, casts types where needed
*/

with source as (
    select * from {{ source('raw', 'CLX_AUTH') }}
    where clnt_id = '{{ var("client_id") }}'
),

renamed as (
    select
        -- Primary keys
        auth_id,
        clnt_id,
        mrch_key,
        
        -- Transaction timing (legacy names preserved)
        txn_dt,
        txn_tm,
        txn_ts,
        
        -- Amount (legacy name)
        txn_am,
        
        -- Approval info (legacy names)
        aprvl_cd,
        dcln_rsn_id,
        dcln_rsn_tx,
        
        -- Card info (legacy names)
        bin_id,
        card_lst4,
        
        -- Transaction type (legacy names)
        pymt_mthd,
        ntwrk,
        entry_md,
        
        -- Platform (legacy name)
        pltf_id,
        trmnl_id,
        
        -- Response codes (legacy names)
        avs_rslt,
        cvv_rslt,

        -- Risk (legacy name)
        risk_score,

        -- Audit fields
        crt_ts,
        upd_ts
        
    from source
)

select * from renamed
