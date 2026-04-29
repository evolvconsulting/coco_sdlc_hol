#!/usr/bin/env python3
"""
fix_retry_columns.py

Rebuilds INT_AUTHORIZATIONS__ENRICHED (INTERMEDIATE) and AUTHORIZATIONS (MARTS)
dynamic tables across all HOL databases to remove the stale retry detection columns
(IS_RETRY_ATTEMPT, IS_RETRIED_DECLINE, RETRY_RECOVERED_COUNT).

Root cause: the template DB (COCO_SDLC_HOL_99) was last built from an older version
of the dbt project that included retry detection logic. The dbt source models were
cleaned in the Apr-28 merge, but Snowflake objects were never rebuilt. Since
PROVISION_HOL_USER uses GET_DDL to clone objects from the template, all provisioned
attendee databases inherited the stale retry columns.

Run from repo root:
    uv run python3 scripts/fix_retry_columns.py
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from hol_util import connect, run_sql

# Template + all attendee databases
DATABASES = [
    'COCO_SDLC_HOL_99',  # template — no ownership regrant
    'COCO_SDLC_HOL_01',
    'COCO_SDLC_HOL_02',
    'COCO_SDLC_HOL_03',
    'COCO_SDLC_HOL_05',
    'COCO_SDLC_HOL_06',
    'COCO_SDLC_HOL_07',
]

# Attendee databases that need ownership regranted after CREATE OR REPLACE
ATTENDEE_DATABASES = [db for db in DATABASES if db != 'COCO_SDLC_HOL_99']


def int_authorizations_ddl(db: str) -> str:
    return f"""
create or replace dynamic table {db}.INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED(
    AUTHORIZATION_ID,
    TRANSACTION_DATE,
    TRANSACTION_TIME,
    TRANSACTION_TIMESTAMP,
    TRANSACTION_AMOUNT,
    APPROVAL_STATUS_CODE,
    APPROVAL_STATUS,
    DECLINE_REASON_CODE,
    DECLINE_REASON_TEXT,
    DECLINE_CATEGORY,
    IS_SOFT_DECLINE,
    CARD_BRAND,
    CARD_TYPE,
    CARD_LEVEL,
    ISSUING_BANK_NAME,
    IS_DURBIN_REGULATED,
    IS_COMMERCIAL_CARD,
    CARD_BIN,
    CARD_LAST_FOUR,
    MERCHANT_ID,
    MERCHANT_DBA_NAME,
    CORPORATE_NAME,
    MERCHANT_CATEGORY_CODE,
    MERCHANT_CATEGORY_DESCRIPTION,
    MERCHANT_CITY,
    MERCHANT_STATE,
    MERCHANT_ZIP,
    PAYMENT_METHOD,
    PROCESSING_NETWORK,
    ENTRY_MODE,
    PROCESSOR_ID,
    PROCESSOR_NAME,
    AVS_RESPONSE_CODE,
    CVV_RESPONSE_CODE
) target_lag = '1 hour' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_WH
 as (
    /*
        Intermediate: Enriched Authorization Transactions
        ==================================================

        COLUMN NAME TRANSFORMATION:
        - Legacy (RAW/STG)     -> Intermediate (clarified)
        - txn_dt               -> transaction_date
        - txn_tm               -> transaction_time
        - txn_ts               -> transaction_timestamp
        - txn_am               -> transaction_amount
        - aprvl_cd             -> approval_status_code
        - dcln_rsn_tx          -> decline_reason_text
        - bin_id               -> card_bin
        - card_lst4            -> card_last_four
        - pymt_mthd            -> payment_method
        - ntwrk                -> processing_network
        - entry_md             -> entry_mode
        - pltf_id              -> processor_id
        - avs_rslt             -> avs_response_code
        - cvv_rslt             -> cvv_response_code

        ENRICHMENT:
        - Joins to merchants for location details
        - Joins to BIN table for card details
        - Joins to processors for platform name
        - Joins to decline reasons for full description
        - Derives approval_status from approval_status_code
    */

    with auth as (
        select * from {db}.staging.stg_clx_auth
    ),

    merchants as (
        select * from {db}.staging.stg_clx_mrch_mstr
    ),

    bins as (
        select * from {db}.staging.stg_glb_bin
    ),

    processors as (
        select * from {db}.staging.stg_pltf_ref
    ),

    decline_reasons as (
        select * from {db}.staging.stg_dcln_rsn_cd
    ),

    enriched as (
        select
            auth.auth_id as authorization_id,
            auth.txn_dt as transaction_date,
            auth.txn_tm as transaction_time,
            auth.txn_ts as transaction_timestamp,
            auth.txn_am as transaction_amount,
            auth.aprvl_cd as approval_status_code,
            case
                when auth.aprvl_cd = 1 then 'Approved'
                when auth.aprvl_cd = 2 then 'Declined'
                else 'Unknown'
            end as approval_status,
            decline_reasons.dcln_rsn_cd as decline_reason_code,
            coalesce(auth.dcln_rsn_tx, decline_reasons.dcln_rsn_desc) as decline_reason_text,
            decline_reasons.dcln_ctgr as decline_category,
            decline_reasons.sft_dcln_flg as is_soft_decline,
            bins.card_brnd as card_brand,
            bins.card_typ as card_type,
            bins.card_lvl as card_level,
            bins.issr_nm as issuing_bank_name,
            bins.reg_flg as is_durbin_regulated,
            bins.cmrcl_flg as is_commercial_card,
            auth.bin_id as card_bin,
            auth.card_lst4 as card_last_four,
            merchants.mrch_id as merchant_id,
            merchants.lctn_dba_nm as merchant_dba_name,
            merchants.corp_dba_nm as corporate_name,
            merchants.mcc as merchant_category_code,
            merchants.mcc_desc as merchant_category_description,
            merchants.cty as merchant_city,
            merchants.st_cd as merchant_state,
            merchants.zip_cd as merchant_zip,
            auth.pymt_mthd as payment_method,
            auth.ntwrk as processing_network,
            auth.entry_md as entry_mode,
            processors.pltf_id as processor_id,
            processors.pltf_nm as processor_name,
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
    )

    select
        authorization_id,
        transaction_date,
        transaction_time,
        transaction_timestamp,
        transaction_amount,
        approval_status_code,
        approval_status,
        decline_reason_code,
        decline_reason_text,
        decline_category,
        is_soft_decline,
        card_brand,
        card_type,
        card_level,
        issuing_bank_name,
        is_durbin_regulated,
        is_commercial_card,
        card_bin,
        card_last_four,
        merchant_id,
        merchant_dba_name,
        corporate_name,
        merchant_category_code,
        merchant_category_description,
        merchant_city,
        merchant_state,
        merchant_zip,
        payment_method,
        processing_network,
        entry_mode,
        processor_id,
        processor_name,
        avs_response_code,
        cvv_response_code

    from enriched
)"""


def mart_authorizations_ddl(db: str) -> str:
    return f"""
create or replace dynamic table {db}.MARTS.AUTHORIZATIONS(
    AUTHORIZATION_KEY,
    TRANSACTION_DATE,
    TRANSACTION_TIME,
    MERCHANT_ID,
    CARD_BRAND,
    CARD_TYPE,
    CARD_CATEGORY,
    ENTRY_MODE,
    APPROVAL_STATUS_CODE,
    APPROVAL_STATUS,
    DECLINE_REASON,
    TRANSACTION_AMOUNT,
    TRANSACTIONS_COUNT,
    MERCHANT_NAME,
    CORPORATE_NAME,
    MERCHANT_CATEGORY_CODE,
    PROCESSOR_ID,
    PROCESSOR_NAME,
    CARD_BIN,
    CARD_LAST_FOUR,
    PAYMENT_METHOD,
    PROCESSING_NETWORK,
    AVS_RESPONSE,
    CVV_RESPONSE
) target_lag = '1 hour' refresh_mode = AUTO initialize = ON_CREATE warehouse = COMPUTE_WH
 as (
    /*
        Marts: Authorizations
        ======================
        Final business-ready table for authorization analytics.
        Referenced by the PAYMENT_ANALYTICS semantic view.
    */

    with enriched as (
        select * from {db}.intermediate.int_authorizations__enriched
    )

    select
        -- Surrogate key
        authorization_id as authorization_key,

        -- Transaction details
        transaction_date,
        transaction_time,

        -- Merchant
        merchant_id,

        -- Card brand
        card_brand,
        card_type,
        case when is_commercial_card then 'Commercial' else 'Consumer' end as card_category,

        -- Entry mode
        entry_mode,

        -- Approval status
        approval_status_code,
        approval_status,
        decline_reason_text as decline_reason,

        -- Amount
        transaction_amount,
        1 as transactions_count,

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
)"""


def main() -> None:
    print("=== Fix: Remove Stale Retry Columns from Dynamic Tables ===\n")
    con = connect(role='ACCOUNTADMIN')
    ok = True

    try:
        # Step 1: Rebuild INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED for all DBs
        print("-- Step 1: Rebuild INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED --")
        for db in DATABASES:
            ok = run_sql(con, int_authorizations_ddl(db),
                         f"{db}.INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED") and ok

        # Step 2: Rebuild MARTS.AUTHORIZATIONS for all DBs
        print("\n-- Step 2: Rebuild MARTS.AUTHORIZATIONS --")
        for db in DATABASES:
            ok = run_sql(con, mart_authorizations_ddl(db),
                         f"{db}.MARTS.AUTHORIZATIONS") and ok

        # Step 3: Re-grant ownership to HOL_ROLE_NN for attendee DBs
        # CREATE OR REPLACE transfers ownership to the executing role (ACCOUNTADMIN).
        print("\n-- Step 3: Re-grant ownership to HOL_ROLE_NN --")
        for db in ATTENDEE_DATABASES:
            suffix = db.split('_')[-1]  # e.g. 'COCO_SDLC_HOL_06' -> '06'
            role = f'HOL_ROLE_{suffix}'
            ok = run_sql(con,
                         f"GRANT OWNERSHIP ON DYNAMIC TABLE {db}.INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED "
                         f"TO ROLE {role} COPY CURRENT GRANTS",
                         f"ownership -> {role}: {db}.INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED") and ok
            ok = run_sql(con,
                         f"GRANT OWNERSHIP ON DYNAMIC TABLE {db}.MARTS.AUTHORIZATIONS "
                         f"TO ROLE {role} COPY CURRENT GRANTS",
                         f"ownership -> {role}: {db}.MARTS.AUTHORIZATIONS") and ok

        # Verification
        print("\n-- Verification: checking for residual retry columns --")
        cur = con.cursor()
        check_dbs = ', '.join(f"'{db}'" for db in DATABASES)
        cur.execute(f"""
            SELECT table_catalog, table_schema, table_name, column_name
            FROM snowflake.account_usage.columns
            WHERE table_catalog IN ({check_dbs})
              AND table_schema IN ('INTERMEDIATE', 'MARTS')
              AND table_name IN ('INT_AUTHORIZATIONS__ENRICHED', 'AUTHORIZATIONS')
              AND column_name IN ('IS_RETRY_ATTEMPT', 'IS_RETRIED_DECLINE', 'RETRY_RECOVERED_COUNT')
              AND deleted IS NULL
        """)
        rows = cur.fetchall()
        if rows:
            print(f"  [WARN] {len(rows)} residual retry column(s) found:")
            for row in rows:
                print(f"         {row[0]}.{row[1]}.{row[2]}.{row[3]}")
        else:
            print("  [OK]   No residual retry columns found across all 7 databases.")

    finally:
        con.close()

    if not ok:
        print("\n[WARN] Some statements failed — review output above.")
        sys.exit(1)
    else:
        print("\nDone.")


if __name__ == '__main__':
    main()
