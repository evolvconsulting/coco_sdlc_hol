/*
    Staging: Decline Reason Codes
    ==============================
    Source: RAW.DCLN_RSN_CD (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
*/

with source as (
    select * from {{ source('raw', 'DCLN_RSN_CD') }}
),

renamed as (
    select
        -- Primary key
        dcln_rsn_id,
        
        -- Code info (legacy names)
        dcln_rsn_cd,
        dcln_rsn_desc,
        dcln_ctgr,
        
        -- Guidance (legacy names)
        mrch_actn,
        cust_msg,
        
        -- Flags (legacy names)
        sft_dcln_flg,
        frd_flg
        
    from source
)

select * from renamed
