/*
    Staging: Settlement Transactions
    =================================
    Source: RAW.CLX_SETTLE (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
*/

with source as (
    select * from {{ source('raw', 'CLX_SETTLE') }}
    where clnt_id = '{{ var("client_id") }}'
),

renamed as (
    select
        -- Primary keys
        settle_id,
        clnt_id,
        mrch_key,
        
        -- Dates (legacy names)
        rcrd_dt,
        btch_dt,
        prcs_dt,
        
        -- Counts (legacy names)
        sales_ct,
        rfnd_ct,
        net_ct,
        
        -- Amounts (legacy names)
        sales_am,
        rfnd_am,
        prcs_net_am,
        dscn_am,
        intchg_am,
        
        -- Card info (legacy names)
        card_brnd,
        card_typ,
        
        -- Plan info (legacy names)
        plan_cd,
        plan_desc,
        
        -- Reference (legacy names)
        btch_ref,
        
        -- Platform (legacy name)
        pltf_id,
        ntwrk,
        
        -- Audit fields
        crt_ts,
        upd_ts
        
    from source
)

select * from renamed
