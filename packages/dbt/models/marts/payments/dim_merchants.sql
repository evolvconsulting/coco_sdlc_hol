/*
    Marts: Merchants Dimension
    ===========================
    Merchant/Store reference table for semantic view relationships.
    Enables joins between transaction tables and merchant attributes.
*/

with merchants as (
    select * from {{ ref('stg_clx_mrch_mstr') }}
)

select
    -- Primary key
    mrch_id as merchant_id,
    
    -- Identifiers
    mrch_key,
    lctn_id as location_id,
    
    -- Names
    lctn_dba_nm as merchant_name,
    corp_dba_nm as corporate_name,
    lgl_nm as legal_name,
    
    -- Address
    addr_ln1 as address_line1,
    cty as city,
    st_cd as state,
    zip_cd as zip_code,
    cntry_cd as country,
    
    -- Contact
    phn_nr as phone,
    email_addr as email,
    
    -- Business classification
    mcc as mcc_code,
    mcc_desc as mcc_description,
    bsns_typ as business_type,
    
    -- Platform/Processor
    pltf_id as processor_id,
    trmnl_ct as terminal_count,
    
    -- Status
    stat_cd as status,
    onbrd_dt as onboarding_date

from merchants
