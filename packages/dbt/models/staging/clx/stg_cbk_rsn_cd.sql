/*
    Staging: Chargeback Reason Codes
    =================================
    Source: RAW.CBK_RSN_CD (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
*/

with source as (
    select * from {{ source('raw', 'CBK_RSN_CD') }}
),

renamed as (
    select
        -- Primary key
        cbk_rsn_id,
        
        -- Network (legacy name)
        ntwrk,
        
        -- Code info (legacy names)
        rsn_cd,
        rsn_desc,
        rsn_ctgr,
        
        -- Response (legacy name)
        resp_dys,
        
        -- Guidance (legacy names)
        req_docs,
        dfns_tips
        
    from source
)

select * from renamed
