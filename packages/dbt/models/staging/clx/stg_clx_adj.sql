/*
    Staging: Adjustments
    =====================
    Source: RAW.CLX_ADJ (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
*/

with source as (
    select * from {{ source('raw', 'CLX_ADJ') }}
    where clnt_id = '{{ var("client_id") }}'
),

renamed as (
    select
        -- Primary keys
        adj_id,
        clnt_id,
        mrch_key,
        
        -- Reference (legacy names)
        adj_ref_nr,
        
        -- Dates (legacy names)
        adj_dt,
        eff_dt,
        orig_txn_dt,
        
        -- Amount (legacy names)
        adj_am,
        adj_typ_cd,
        
        -- Codes (legacy names)
        adj_cd,
        adj_desc,
        adj_ctgr,
        
        -- Fee info (legacy names)
        fee_typ_cd,
        fee_desc,
        
        -- Related transaction (legacy names)
        rltd_txn_id,
        rltd_txn_typ,
        
        -- Status (legacy names)
        adj_stat,
        
        -- Platform (legacy name)
        pltf_id,
        
        -- Audit fields
        crt_by,
        crt_ts,
        upd_ts
        
    from source
)

select * from renamed
