/*
    Staging: Retrieval Requests
    ============================
    Source: RAW.CLX_RTRVL (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
*/

with source as (
    select * from {{ source('raw', 'CLX_RTRVL') }}
    where clnt_id = '{{ var("client_id") }}'
),

renamed as (
    select
        -- Primary keys
        rtrvl_id,
        clnt_id,
        mrch_key,
        
        -- Reference (legacy names)
        arn,
        
        -- Dates (legacy names)
        rtrvl_rcvd_dt,
        sale_dt,
        due_dt,
        fulfmt_dt,
        
        -- Amount (legacy names)
        rtrvl_am,
        
        -- Status (legacy names)
        rtrvl_stat,
        fulfmt_stat,
        
        -- Reason (legacy names)
        rsn_cd,
        rsn_desc,
        
        -- Card info (legacy names)
        card_brnd,
        card_lst4,
        
        -- Documentation (legacy names)
        docs_reqd,
        docs_sbmtd_flg,
        sbmsn_mthd,
        
        -- Platform (legacy name)
        pltf_id,
        
        -- Audit fields
        crt_ts,
        upd_ts
        
    from source
)

select * from renamed
