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

-- ============================================================
-- SECTION 7: Intermediate Dynamic Tables
-- ============================================================
USE SCHEMA COCO_SDLC_HOL.INTERMEDIATE;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.int_authorizations__enriched
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with auth as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_auth
),

merchants as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_mrch_mstr
),

bins as (
    select * from COCO_SDLC_HOL.STAGING.stg_glb_bin
),

processors as (
    select * from COCO_SDLC_HOL.STAGING.stg_pltf_ref
),

decline_reasons as (
    select * from COCO_SDLC_HOL.STAGING.stg_dcln_rsn_cd
)

select
    -- Primary key
    auth.auth_id as authorization_id,

    -- Transaction timing (RENAMED from legacy)
    auth.txn_dt as transaction_date,
    auth.txn_tm as transaction_time,
    auth.txn_ts as transaction_timestamp,

    -- Amount (RENAMED from legacy)
    auth.txn_am as transaction_amount,

    -- Approval status (RENAMED + DERIVED)
    auth.aprvl_cd as approval_status_code,
    case
        when auth.aprvl_cd = 1 then 'Approved'
        when auth.aprvl_cd = 2 then 'Declined'
        else 'Unknown'
    end as approval_status,

    -- Decline info (RENAMED + ENRICHED from join)
    decline_reasons.dcln_rsn_cd as decline_reason_code,
    coalesce(auth.dcln_rsn_tx, decline_reasons.dcln_rsn_desc) as decline_reason_text,
    decline_reasons.dcln_ctgr as decline_category,
    decline_reasons.sft_dcln_flg as is_soft_decline,

    -- Card info (RENAMED + ENRICHED from join)
    bins.card_brnd as card_brand,
    bins.card_typ as card_type,
    bins.card_lvl as card_level,
    bins.issr_nm as issuing_bank_name,
    bins.reg_flg as is_durbin_regulated,
    bins.cmrcl_flg as is_commercial_card,
    auth.bin_id as card_bin,
    auth.card_lst4 as card_last_four,

    -- Merchant info (RENAMED + ENRICHED from join)
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,
    merchants.mcc as merchant_category_code,
    merchants.mcc_desc as merchant_category_description,
    merchants.cty as merchant_city,
    merchants.st_cd as merchant_state,
    merchants.zip_cd as merchant_zip,

    -- Transaction type (RENAMED from legacy)
    auth.pymt_mthd as payment_method,
    auth.ntwrk as processing_network,
    auth.entry_md as entry_mode,

    -- Processor info (RENAMED + ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name,

    -- Response codes (RENAMED from legacy)
    auth.avs_rslt as avs_response_code,
    auth.cvv_rslt as cvv_response_code

from auth
left join merchants
    on auth.mrch_key = merchants.mrch_key
left join bins
    on auth.bin_id = bins.bin_id
left join processors
    on auth.pltf_id = processors.pltf_id
left join decline_reasons
    on auth.dcln_rsn_id = decline_reasons.dcln_rsn_id
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.int_settlements__enriched
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with settlements as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_settle
),

merchants as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_mrch_mstr
),

processors as (
    select * from COCO_SDLC_HOL.STAGING.stg_pltf_ref
)

select
    -- Primary key
    settlements.settle_id as settlement_id,

    -- Dates (RENAMED from legacy)
    settlements.rcrd_dt as settlement_date,
    settlements.btch_dt as batch_date,
    settlements.prcs_dt as processing_date,

    -- Counts (RENAMED from legacy)
    settlements.sales_ct as sales_transaction_count,
    settlements.rfnd_ct as refund_transaction_count,
    settlements.net_ct as net_transaction_count,
    0 as rejected_transaction_count,

    -- Amounts (RENAMED from legacy)
    settlements.sales_am as gross_sales_amount,
    settlements.rfnd_am as refund_amount,
    settlements.prcs_net_am as net_settlement_amount,
    settlements.dscn_am as discount_fee_amount,
    settlements.intchg_am as interchange_fee_amount,

    -- Derived: Average ticket
    case
        when settlements.net_ct > 0
        then round(settlements.prcs_net_am / settlements.net_ct, 2)
        else 0
    end as average_ticket_amount,

    -- Card info (RENAMED from legacy)
    settlements.card_brnd as card_brand,
    settlements.card_typ as card_type,

    -- Plan info (RENAMED from legacy)
    settlements.plan_cd as interchange_plan_code,
    settlements.plan_desc as interchange_plan_description,

    -- Merchant info (ENRICHED from join)
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,

    -- Reference (RENAMED from legacy)
    settlements.btch_ref as batch_reference_number,

    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name,
    settlements.ntwrk as processing_network

from settlements
left join merchants
    on settlements.mrch_key = merchants.mrch_key
left join processors
    on settlements.pltf_id = processors.pltf_id
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.int_deposits__enriched
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with deposits as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_fund
),

merchants as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_mrch_mstr
),

processors as (
    select * from COCO_SDLC_HOL.STAGING.stg_pltf_ref
)

select
    -- Primary key
    deposits.fund_id as deposit_id,

    -- Dates (RENAMED from legacy)
    deposits.funded_dt as deposit_date,
    deposits.settle_dt as settlement_date,
    deposits.expct_dt as expected_deposit_date,

    -- Amounts (RENAMED from legacy)
    deposits.dpst_am as total_deposit_amount,
    deposits.net_sales_am as net_sales_amount,
    deposits.fees_am as total_fees_amount,
    deposits.cbk_am as chargeback_deduction_amount,
    deposits.adj_am as adjustment_amount,
    deposits.rsrv_am as reserve_holdback_amount,

    -- Derived: Fee breakdown (estimated split)
    round(deposits.fees_am * 0.7, 2) as interchange_charges_amount,
    round(deposits.fees_am * 0.3, 2) as service_charges_amount,

    -- Counts (RENAMED from legacy)
    deposits.item_ct as item_count,
    deposits.sales_ct as sales_count,
    deposits.rfnd_ct as refund_count,

    -- Status (RENAMED from legacy)
    deposits.pymt_stat as payment_status,
    deposits.pymt_mthd as payment_method,

    -- Bank info (RENAMED from legacy)
    deposits.dda_lst4 as bank_account_last_four,
    deposits.bank_nm as bank_name,

    -- Category (RENAMED from legacy)
    deposits.txn_ctgr as transaction_category,
    deposits.fund_typ as deposit_type,

    -- Derived: Category codes
    left(deposits.txn_ctgr, 3) as major_category_code,
    right(deposits.txn_ctgr, 3) as minor_category_code,

    -- Merchant info (ENRICHED from join)
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,

    -- Reference (RENAMED from legacy)
    deposits.btch_ref as batch_reference_number,
    deposits.ach_trc as ach_trace_number,

    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name

from deposits
left join merchants
    on deposits.mrch_key = merchants.mrch_key
left join processors
    on deposits.pltf_id = processors.pltf_id
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.int_chargebacks__enriched
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with chargebacks as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_cbk
),

merchants as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_mrch_mstr
),

processors as (
    select * from COCO_SDLC_HOL.STAGING.stg_pltf_ref
),

chargeback_reasons as (
    select * from COCO_SDLC_HOL.STAGING.stg_cbk_rsn_cd
)

select
    -- Primary key
    chargebacks.cbk_id as chargeback_id,

    -- Case info
    chargebacks.case_nr as case_number,
    chargebacks.arn as acquirer_reference_number,

    -- Dates (RENAMED from legacy)
    chargebacks.dsput_rcvd_dt as dispute_received_date,
    chargebacks.orig_txn_dt as original_transaction_date,
    chargebacks.due_dt as response_due_date,
    chargebacks.rslvd_dt as resolution_date,

    -- Derived: Days calculations
    datediff('day', chargebacks.dsput_rcvd_dt, chargebacks.due_dt) as days_to_respond,
    datediff('day', current_date(), chargebacks.due_dt) as days_until_due,
    case
        when chargebacks.due_dt < current_date() and chargebacks.cbk_stat != 'Closed'
        then true
        else false
    end as is_past_due,

    -- Amounts (RENAMED from legacy)
    chargebacks.dsput_am as dispute_amount,
    chargebacks.txn_am as original_transaction_amount,
    chargebacks.repr_am as representment_amount,

    -- Status (RENAMED from legacy)
    chargebacks.cbk_stat as chargeback_status,
    chargebacks.cbk_win_loss as chargeback_outcome,
    chargebacks.cbk_cycl as lifecycle_stage,

    -- Reason info (RENAMED + ENRICHED from join)
    chargeback_reasons.rsn_cd as reason_code,
    coalesce(chargebacks.rsn_desc_ovrd, chargeback_reasons.rsn_desc) as reason_description,
    coalesce(chargebacks.rsn_ctgr, chargeback_reasons.rsn_ctgr) as reason_category,

    -- Card info (RENAMED from legacy)
    chargebacks.card_brnd as card_brand,
    chargebacks.card_lst4 as card_last_four,

    -- Merchant info (RENAMED + ENRICHED from join)
    chargebacks.mrch_nm as merchant_name_on_dispute,
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,
    merchants.cty as merchant_city,
    merchants.st_cd as merchant_state,
    merchants.mcc as merchant_category_code,

    -- Response info (RENAMED from legacy)
    chargebacks.resp_sent_flg as response_submitted,
    chargebacks.resp_dt as response_date,
    chargebacks.docs_sbmtd_flg as documents_submitted,

    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name

from chargebacks
left join merchants
    on chargebacks.mrch_key = merchants.mrch_key
left join processors
    on chargebacks.pltf_id = processors.pltf_id
left join chargeback_reasons
    on chargebacks.cbk_rsn_id = chargeback_reasons.cbk_rsn_id
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.int_retrievals__enriched
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with retrievals as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_rtrvl
),

merchants as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_mrch_mstr
),

processors as (
    select * from COCO_SDLC_HOL.STAGING.stg_pltf_ref
)

select
    -- Primary key
    retrievals.rtrvl_id as retrieval_id,

    -- Reference
    retrievals.arn as acquirer_reference_number,

    -- Dates (RENAMED from legacy)
    retrievals.rtrvl_rcvd_dt as retrieval_received_date,
    retrievals.sale_dt as original_sale_date,
    retrievals.due_dt as response_due_date,
    retrievals.fulfmt_dt as fulfillment_date,

    -- Derived: Days calculations
    datediff('day', current_date(), retrievals.due_dt) as days_until_due,
    case
        when retrievals.due_dt < current_date()
             and retrievals.rtrvl_stat not in ('Closed', 'Fulfilled')
        then true
        else false
    end as is_overdue,

    -- Amount (RENAMED from legacy)
    retrievals.rtrvl_am as retrieval_amount,

    -- Status (RENAMED from legacy)
    retrievals.rtrvl_stat as retrieval_status,
    retrievals.fulfmt_stat as fulfillment_status,

    -- Reason info (RENAMED from legacy)
    retrievals.rsn_cd as reason_code,
    retrievals.rsn_desc as reason_description,

    -- Card info (RENAMED from legacy)
    retrievals.card_brnd as card_brand,
    retrievals.card_lst4 as card_last_four,

    -- Merchant info (ENRICHED from join)
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,

    -- Documentation (RENAMED from legacy)
    retrievals.docs_reqd as documents_requested,
    retrievals.docs_sbmtd_flg as documents_submitted,
    retrievals.sbmsn_mthd as submission_method,

    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name

from retrievals
left join merchants
    on retrievals.mrch_key = merchants.mrch_key
left join processors
    on retrievals.pltf_id = processors.pltf_id
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.int_adjustments__enriched
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with adjustments as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_adj
),

merchants as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_mrch_mstr
),

processors as (
    select * from COCO_SDLC_HOL.STAGING.stg_pltf_ref
)

select
    -- Primary key
    adjustments.adj_id as adjustment_id,

    -- Reference
    adjustments.adj_ref_nr as adjustment_reference_number,

    -- Dates (RENAMED from legacy)
    adjustments.adj_dt as adjustment_date,
    adjustments.eff_dt as effective_date,
    adjustments.orig_txn_dt as original_transaction_date,

    -- Amount (RENAMED from legacy)
    adjustments.adj_am as adjustment_amount,

    -- Type (RENAMED + DERIVED from legacy)
    adjustments.adj_typ_cd as adjustment_type_code,
    case
        when adjustments.adj_typ_cd = 'C' then 'Credit'
        when adjustments.adj_typ_cd = 'D' then 'Debit'
        else 'Unknown'
    end as adjustment_type,

    -- Codes (RENAMED from legacy)
    adjustments.adj_cd as adjustment_code,
    adjustments.adj_desc as adjustment_description,
    adjustments.adj_ctgr as adjustment_category,

    -- Fee info (RENAMED from legacy)
    adjustments.fee_typ_cd as fee_type_code,
    adjustments.fee_desc as fee_description,

    -- Related transaction (RENAMED from legacy)
    adjustments.rltd_txn_id as related_transaction_id,
    adjustments.rltd_txn_typ as related_transaction_type,

    -- Status (RENAMED from legacy)
    adjustments.adj_stat as adjustment_status,

    -- Merchant info (ENRICHED from join)
    merchants.lctn_dba_nm as merchant_dba_name,
    merchants.corp_dba_nm as corporate_name,

    -- Processor info (ENRICHED from join)
    processors.pltf_id as processor_id,
    processors.pltf_nm as processor_name,

    -- Audit
    adjustments.crt_by as created_by

from adjustments
left join merchants
    on adjustments.mrch_key = merchants.mrch_key
left join processors
    on adjustments.pltf_id = processors.pltf_id
;

-- ============================================================
-- SECTION 8: Marts Dynamic Tables
-- ============================================================
USE SCHEMA COCO_SDLC_HOL.MARTS;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.MARTS.dim_merchants
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with merchants as (
    select * from COCO_SDLC_HOL.STAGING.stg_clx_mrch_mstr
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
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.MARTS.authorizations
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with enriched as (
    select * from COCO_SDLC_HOL.INTERMEDIATE.int_authorizations__enriched
)

select
    -- Transaction details
    transaction_date,
    transaction_time,

    -- Card brand
    card_brand,

    -- Approval status
    approval_status_code,
    approval_status,
    decline_reason_text as decline_reason,

    -- Amount
    transaction_amount,

    -- Merchant info
    merchant_dba_name as merchant_name,
    corporate_name,
    merchant_category_code,

    -- Processor
    processor_id,
    processor_name,

    -- Card details
    card_bin,
    card_last_four,

    -- Transaction type
    payment_method,
    processing_network,

    -- Response codes
    avs_response_code as avs_response,
    cvv_response_code as cvv_response

from enriched
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.MARTS.settlements
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with enriched as (
    select * from COCO_SDLC_HOL.INTERMEDIATE.int_settlements__enriched
)

select
    -- Dates
    settlement_date,
    batch_date,

    -- Card info
    card_brand,
    card_type,

    -- Plan info
    interchange_plan_code,

    -- Merchant info
    merchant_dba_name as merchant_name,
    corporate_name,

    -- Batch reference
    batch_reference_number as batch_number,

    -- Counts
    sales_transaction_count as sales_count,
    refund_transaction_count as refund_count,
    net_transaction_count as net_count,

    -- Amounts
    net_settlement_amount as net_amount,
    gross_sales_amount as sales_amount,
    refund_amount,
    discount_fee_amount as discount_amount

from enriched
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.MARTS.deposits
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with enriched as (
    select * from COCO_SDLC_HOL.INTERMEDIATE.int_deposits__enriched
)

select
    -- Dates
    deposit_date,
    settlement_date,

    -- Status
    payment_status,

    -- Merchant info
    merchant_dba_name as merchant_name,
    corporate_name,

    -- Bank info
    bank_account_last_four,

    -- Categories
    transaction_category,
    major_category_code,
    minor_category_code,

    -- Amounts
    total_deposit_amount as deposit_amount,
    net_sales_amount,
    total_fees_amount,
    chargeback_deduction_amount as chargeback_amount,
    adjustment_amount,
    interchange_charges_amount as interchange_charges,
    service_charges_amount as service_charges,

    -- Counts
    item_count

from enriched
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.MARTS.chargebacks
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with enriched as (
    select * from COCO_SDLC_HOL.INTERMEDIATE.int_chargebacks__enriched
)

select
    -- Dates
    dispute_received_date,
    original_transaction_date,
    response_due_date,

    -- Reason info
    reason_code,
    reason_description,

    -- Status
    chargeback_status,
    chargeback_outcome as outcome,
    lifecycle_stage,

    -- Merchant info
    merchant_dba_name as merchant_name,
    merchant_city,
    merchant_state,
    merchant_category_code,

    -- Card info
    card_brand,

    -- Amounts
    dispute_amount,
    original_transaction_amount as transaction_amount

from enriched
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.MARTS.retrievals
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with enriched as (
    select * from COCO_SDLC_HOL.INTERMEDIATE.int_retrievals__enriched
)

select
    -- Dates
    original_sale_date,
    response_due_date,
    fulfillment_date,

    -- Status
    retrieval_status,

    -- Reason
    reason_code,

    -- Reference
    acquirer_reference_number as reference_number,

    -- Merchant info
    merchant_dba_name as merchant_name,

    -- Card info
    card_brand,

    -- Amount
    retrieval_amount

from enriched
;

CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.MARTS.adjustments
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
with enriched as (
    select * from COCO_SDLC_HOL.INTERMEDIATE.int_adjustments__enriched
)

select
    -- Dates
    adjustment_date,
    effective_date,

    -- Codes
    adjustment_code,
    adjustment_description,
    adjustment_category,
    adjustment_type,

    -- Fee info
    fee_description,

    -- Merchant info
    merchant_dba_name as merchant_name,
    corporate_name,

    -- Amount
    adjustment_amount

from enriched
;
