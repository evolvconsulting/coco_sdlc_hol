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
        ref_nr,
        
        -- Dates (legacy names)
        adj_dt,
        eff_dt,
        post_dt,
        
        -- Amount (legacy names)
        adj_am,
        adj_typ,
        
        -- Codes (legacy names)
        rsn_cd,
        rsn_desc,
        gl_acct,
        
        -- Fee info (legacy names)
        dept_cd,
        notes_tx,
        
        -- Related transaction (legacy names)
        btch_ref,
        
        -- Status (legacy names)
        adj_stat,
        
        -- Platform (legacy name)
        pltf_id,
        
        -- Audit fields
        aprvd_by,
        crt_ts,
        upd_ts
        
    from source
)

select * from renamed
