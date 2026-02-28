/*
    Staging: Funding/Deposit Transactions
    ======================================
    Source: RAW.CLX_FUND (legacy OLTP table)
    
    Column naming: Preserves legacy abbreviated names in snake_case
*/

with source as (
    select * from {{ source('raw', 'CLX_FUND') }}
    where clnt_id = '{{ var("client_id") }}'
),

renamed as (
    select
        -- Primary keys
        fund_id,
        clnt_id,
        mrch_key,
        
        -- Dates (legacy names)
        funded_dt,
        settle_dt,
        expct_dt,
        
        -- Amounts (legacy names)
        dpst_am,
        net_sales_am,
        fees_am,
        cbk_am,
        adj_am,
        rsrv_am,
        
        -- Counts (legacy names)
        item_ct,
        sales_ct,
        rfnd_ct,
        
        -- Status (legacy names)
        pymt_stat,
        pymt_mthd,
        
        -- Bank info (legacy names)
        dda_lst4,
        bank_nm,
        
        -- Category (legacy names)
        txn_ctgr,
        fund_typ,
        
        -- Reference (legacy names)
        btch_ref,
        ach_trc,
        
        -- Platform (legacy name)
        pltf_id,
        
        -- Audit fields
        crt_ts,
        upd_ts
        
    from source
)

select * from renamed
