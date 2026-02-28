/*
    Staging: Platform Reference
    ============================
    Source: RAW.PLTF_REF (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
*/

with source as (
    select * from {{ source('raw', 'PLTF_REF') }}
),

renamed as (
    select
        -- Primary key
        pltf_id,
        
        -- Platform info (legacy names)
        pltf_nm,
        pltf_cd,
        
        -- Status (legacy name)
        actv_flg,
        
        -- Audit field
        crt_ts
        
    from source
)

select * from renamed
