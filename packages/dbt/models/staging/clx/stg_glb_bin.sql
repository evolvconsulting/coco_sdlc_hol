/*
    Staging: Global BIN Reference
    ==============================
    Source: RAW.GLB_BIN (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
*/

with source as (
    select * from {{ source('raw', 'GLB_BIN') }}
),

renamed as (
    select
        -- Primary key
        bin_id,
        
        -- Card info (legacy names)
        card_brnd,
        card_typ,
        card_lvl,
        card_prod,
        
        -- Issuer info (legacy names)
        issr_nm,
        issr_cntry,
        issr_phn,
        
        -- Flags (legacy names)
        cmrcl_flg,
        prepd_flg,
        reg_flg,
        
        -- Network (legacy name)
        ntwrk,
        
        -- Audit fields
        crt_ts,
        upd_ts
        
    from source
)

select * from renamed
