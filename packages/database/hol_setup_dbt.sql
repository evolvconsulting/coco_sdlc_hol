-- ============================================================
-- SECTION 6: Staging Views
-- ============================================================
USE SCHEMA COCO_SDLC_HOL.STAGING;

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_pltf_ref AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.PLTF_REF
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
);

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_glb_bin AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.GLB_BIN
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
);

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_dcln_rsn_cd AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.DCLN_RSN_CD
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
);

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_cbk_rsn_cd AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.CBK_RSN_CD
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
);

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_clx_mrch_mstr AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.CLX_MRCH_MSTR
    where clnt_id = 'dmcl'
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
);

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_clx_auth AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.CLX_AUTH
    where clnt_id = 'dmcl'
),

renamed as (
    select
        -- Primary keys
        auth_id,
        clnt_id,
        mrch_key,

        -- Transaction timing (legacy names preserved)
        txn_dt,
        txn_tm,
        txn_ts,

        -- Amount (legacy name)
        txn_am,

        -- Approval info (legacy names)
        aprvl_cd,
        dcln_rsn_id,
        dcln_rsn_tx,

        -- Card info (legacy names)
        bin_id,
        card_lst4,

        -- Transaction type (legacy names)
        pymt_mthd,
        ntwrk,
        entry_md,

        -- Platform (legacy name)
        pltf_id,
        trmnl_id,

        -- Response codes (legacy names)
        avs_rslt,
        cvv_rslt,

        -- Audit fields
        crt_ts,
        upd_ts

    from source
)

select * from renamed
);

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_clx_settle AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.CLX_SETTLE
    where clnt_id = 'dmcl'
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
);

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_clx_fund AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.CLX_FUND
    where clnt_id = 'dmcl'
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
);

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_clx_cbk AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.CLX_CBK
    where clnt_id = 'dmcl'
),

renamed as (
    select
        -- Primary keys
        cbk_id,
        clnt_id,
        mrch_key,

        -- Case info (legacy names)
        case_nr,
        arn,

        -- Dates (legacy names)
        dsput_rcvd_dt,
        orig_txn_dt,
        due_dt,
        rslvd_dt,

        -- Amounts (legacy names)
        dsput_am,
        txn_am,
        repr_am,

        -- Status (legacy names)
        cbk_stat,
        cbk_win_loss,
        cbk_cycl,

        -- Reason (legacy names)
        cbk_rsn_id,
        rsn_desc_ovrd,
        rsn_ctgr,

        -- Card info (legacy names)
        card_brnd,
        card_lst4,

        -- Merchant (legacy names)
        mrch_nm,

        -- Response (legacy names)
        resp_sent_flg,
        resp_dt,
        docs_sbmtd_flg,

        -- Platform (legacy name)
        pltf_id,

        -- Audit fields
        crt_ts,
        upd_ts

    from source
)

select * from renamed
);

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_clx_rtrvl AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.CLX_RTRVL
    where clnt_id = 'dmcl'
),

renamed as (
    select
        -- Primary keys
        rtrvl_id,
        clnt_id,
        mrch_key,

        -- Reference (legacy names)
        arn,

        -- Dates (legacy names)
        rtrvl_rcvd_dt,
        sale_dt,
        due_dt,
        fulfmt_dt,

        -- Amount (legacy names)
        rtrvl_am,

        -- Status (legacy names)
        rtrvl_stat,
        fulfmt_stat,

        -- Reason (legacy names)
        rsn_cd,
        rsn_desc,

        -- Card info (legacy names)
        card_brnd,
        card_lst4,

        -- Documentation (legacy names)
        docs_reqd,
        docs_sbmtd_flg,
        sbmsn_mthd,

        -- Platform (legacy name)
        pltf_id,

        -- Audit fields
        crt_ts,
        upd_ts

    from source
)

select * from renamed
);

CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_clx_adj AS (
with source as (
    select * from COCO_SDLC_HOL.RAW.CLX_ADJ
    where clnt_id = 'dmcl'
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
);
