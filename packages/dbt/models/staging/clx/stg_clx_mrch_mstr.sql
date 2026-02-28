/*
    Staging: Merchant Master
    =========================
    Source: RAW.CLX_MRCH_MSTR (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
*/

with source as (
    select * from {{ source('raw', 'CLX_MRCH_MSTR') }}
    where clnt_id = '{{ var("client_id") }}'
),

renamed as (
    select
        -- Primary keys
        mrch_key,
        clnt_id,
        
        -- Identifiers (legacy names)
        mrch_id,
        lctn_id,
        
        -- Names (legacy names)
        lctn_dba_nm,
        corp_dba_nm,
        lgl_nm,
        
        -- Address (legacy names)
        addr_ln1,
        cty,
        st_cd,
        zip_cd,
        cntry_cd,
        
        -- Contact (legacy names)
        phn_nr,
        email_addr,
        
        -- Business info (legacy names)
        mcc,
        mcc_desc,
        bsns_typ,
        
        -- Platform (legacy name)
        pltf_id,
        trmnl_ct,
        
        -- Status (legacy names)
        stat_cd,
        onbrd_dt,
        
        -- Audit fields
        crt_ts,
        upd_ts
        
    from source
)

select * from renamed
