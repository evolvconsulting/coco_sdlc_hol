-- =============================================================================
-- Synthetic Transaction Data Generator
-- =============================================================================
-- This script generates realistic synthetic transaction data for testing and
-- demonstration purposes. It populates all fact tables in the RAW schema.
--
-- Run this after:
--   1. 00_create_raw_schema.sql (creates tables)
--   2. 01_reference_data.sql (populates dimension tables)
--
-- Tables populated:
--   - CLX_AUTH (Authorization transactions)
--   - CLX_SETTLE (Settlement transactions)
--   - CLX_FUND (Funding/deposit transactions)
--   - CLX_CBK (Chargeback transactions)
--   - CLX_RTRVL (Retrieval requests)
--   - CLX_ADJ (Adjustments)
-- =============================================================================

USE DATABASE COCO_SDLC_HOL;
USE SCHEMA RAW;


-- =============================================================================
-- Helper function: Generate realistic transaction amounts by MCC
-- =============================================================================
CREATE OR REPLACE FUNCTION GENERATE_REALISTIC_AMOUNT(MCC VARCHAR, HOUR_OF_DAY NUMBER)
RETURNS NUMBER(15,2)
LANGUAGE SQL
AS
$$
    CASE 
        -- Grocery: Average $45, range $5-$350, higher on weekends and evenings
        WHEN MCC = '5411' THEN 
            CASE WHEN HOUR_OF_DAY BETWEEN 17 AND 20 THEN UNIFORM(25.00, 180.00, RANDOM())::NUMBER(15,2)
                 ELSE UNIFORM(8.00, 120.00, RANDOM())::NUMBER(15,2) END
        -- Gas stations: Average $45, range $15-$85
        WHEN MCC IN ('5541', '5542') THEN UNIFORM(18.00, 75.00, RANDOM())::NUMBER(15,2)
        -- Restaurants: Average $55, range $20-$200
        WHEN MCC = '5812' THEN UNIFORM(22.00, 145.00, RANDOM())::NUMBER(15,2)
        -- Fast food: Average $12, range $5-$35
        WHEN MCC = '5814' THEN UNIFORM(6.50, 28.00, RANDOM())::NUMBER(15,2)
        -- Pharmacy: Average $35, range $5-$250
        WHEN MCC = '5912' THEN UNIFORM(8.00, 165.00, RANDOM())::NUMBER(15,2)
        -- Electronics: Average $250, range $15-$2500
        WHEN MCC = '5732' THEN UNIFORM(25.00, 1800.00, RANDOM())::NUMBER(15,2)
        -- Home improvement: Average $85, range $15-$800
        WHEN MCC = '5200' THEN UNIFORM(18.00, 450.00, RANDOM())::NUMBER(15,2)
        -- Department stores: Average $65, range $10-$400
        WHEN MCC = '5311' THEN UNIFORM(15.00, 280.00, RANDOM())::NUMBER(15,2)
        -- Hotels: Average $185, range $75-$600
        WHEN MCC = '7011' THEN UNIFORM(89.00, 485.00, RANDOM())::NUMBER(15,2)
        -- Auto service: Average $95, range $25-$500
        WHEN MCC = '7538' THEN UNIFORM(35.00, 385.00, RANDOM())::NUMBER(15,2)
        -- Healthcare: Average $150, range $25-$1000
        WHEN MCC IN ('8011', '8021') THEN UNIFORM(35.00, 650.00, RANDOM())::NUMBER(15,2)
        -- Default
        ELSE UNIFORM(10.00, 150.00, RANDOM())::NUMBER(15,2)
    END
$$;


-- =============================================================================
-- Helper function: Get realistic chargeback rate by MCC
-- Based on industry statistics
-- =============================================================================
CREATE OR REPLACE FUNCTION GET_CHARGEBACK_RATE(MCC VARCHAR)
RETURNS NUMBER(8,6)
LANGUAGE SQL
AS
$$
    CASE 
        WHEN MCC = '5411' THEN 0.0035    -- Grocery: 0.35%
        WHEN MCC IN ('5541', '5542') THEN 0.0025  -- Gas: 0.25%
        WHEN MCC = '5812' THEN 0.0012    -- Restaurants: 0.12%
        WHEN MCC = '5814' THEN 0.0008    -- Fast food: 0.08%
        WHEN MCC = '5912' THEN 0.0045    -- Pharmacy: 0.45%
        WHEN MCC = '5732' THEN 0.0085    -- Electronics: 0.85% (higher fraud)
        WHEN MCC = '5200' THEN 0.0055    -- Home improvement: 0.55%
        WHEN MCC = '5311' THEN 0.0052    -- Department stores: 0.52%
        WHEN MCC = '7011' THEN 0.0089    -- Hotels: 0.89% (travel is high risk)
        WHEN MCC = '7538' THEN 0.0040    -- Auto service: 0.40%
        WHEN MCC IN ('8011', '8021') THEN 0.0065  -- Healthcare: 0.65%
        ELSE 0.0050  -- Default: 0.50%
    END
$$;


-- =============================================================================
-- Main procedure to generate all synthetic data
-- =============================================================================
CREATE OR REPLACE PROCEDURE GENERATE_SYNTHETIC_DATA(
    START_DATE DATE DEFAULT DATEADD(DAY, -90, CURRENT_DATE()),
    END_DATE DATE DEFAULT CURRENT_DATE(),
    BASE_TXNS_PER_DAY NUMBER DEFAULT 800,
    BASE_APPROVAL_RATE NUMBER DEFAULT 0.965
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    days_count NUMBER;
    total_auth NUMBER := 0;
    total_settle NUMBER := 0;
    total_fund NUMBER := 0;
    total_cbk NUMBER := 0;
    total_rtv NUMBER := 0;
    total_adj NUMBER := 0;
BEGIN
    -- Calculate number of days
    days_count := DATEDIFF(DAY, START_DATE, END_DATE) + 1;
    
    -- Clear existing data
    TRUNCATE TABLE IF EXISTS CLX_AUTH;
    TRUNCATE TABLE IF EXISTS CLX_SETTLE;
    TRUNCATE TABLE IF EXISTS CLX_FUND;
    TRUNCATE TABLE IF EXISTS CLX_CBK;
    TRUNCATE TABLE IF EXISTS CLX_RTRVL;
    TRUNCATE TABLE IF EXISTS CLX_ADJ;
    
    -- ==========================================================================
    -- Generate Authorization Transactions with realistic patterns
    -- ==========================================================================
    INSERT INTO CLX_AUTH (
        AUTH_ID, CLNT_ID, MRCH_KEY, TXN_DT, TXN_TM, TXN_TS, TXN_AM, APRVL_CD,
        DCLN_RSN_ID, DCLN_RSN_TX, BIN_ID, CARD_LST4, PYMT_MTHD, NTWRK,
        ENTRY_MD, PLTF_ID, TRMNL_ID, AVS_RSLT, CVV_RSLT
    )
    WITH date_range AS (
        SELECT 
            DATEADD(DAY, SEQ4(), :START_DATE) AS txn_date,
            -- Day of week adjustment (more transactions on weekends for retail)
            CASE DAYOFWEEK(DATEADD(DAY, SEQ4(), :START_DATE))
                WHEN 0 THEN 1.15  -- Sunday
                WHEN 6 THEN 1.25  -- Saturday
                WHEN 5 THEN 1.10  -- Friday
                ELSE 1.0
            END AS day_multiplier,
            -- Month of year adjustment (holiday shopping, summer travel)
            CASE MONTH(DATEADD(DAY, SEQ4(), :START_DATE))
                WHEN 11 THEN 1.35  -- November (pre-Black Friday)
                WHEN 12 THEN 1.50  -- December (holiday shopping)
                WHEN 1 THEN 0.85   -- January (post-holiday lull)
                WHEN 7 THEN 1.10   -- July (summer travel)
                WHEN 8 THEN 1.05   -- August (back to school)
                ELSE 1.0
            END AS month_multiplier
        FROM TABLE(GENERATOR(ROWCOUNT => :days_count))
    ),
    txn_slots AS (
        -- Generate time slots with realistic hourly distribution
        SELECT 
            SEQ4() AS slot_id,
            -- Peak hours: lunch (11-13) and evening (17-20)
            CASE 
                WHEN SEQ4() % 24 BETWEEN 11 AND 13 THEN 1.8  -- Lunch rush
                WHEN SEQ4() % 24 BETWEEN 17 AND 20 THEN 2.0  -- Evening rush
                WHEN SEQ4() % 24 BETWEEN 9 AND 11 THEN 1.3   -- Morning shopping
                WHEN SEQ4() % 24 BETWEEN 14 AND 16 THEN 1.2  -- Afternoon
                WHEN SEQ4() % 24 BETWEEN 6 AND 8 THEN 0.8    -- Early morning
                WHEN SEQ4() % 24 BETWEEN 21 AND 23 THEN 0.7  -- Late evening
                ELSE 0.2  -- Night (very few transactions)
            END AS hour_weight,
            SEQ4() % 24 AS hour_of_day
        FROM TABLE(GENERATOR(ROWCOUNT => :BASE_TXNS_PER_DAY * 2))
    ),
    merchants AS (
        SELECT 
            MRCH_KEY, CLNT_ID, MCC, PLTF_ID, TRMNL_CT,
            -- Transaction frequency weighting by store type
            CASE 
                WHEN MCC = '5411' THEN 3.0   -- Grocery: highest frequency
                WHEN MCC = '5814' THEN 2.5   -- Fast food: very high frequency
                WHEN MCC IN ('5541', '5542') THEN 2.0  -- Gas: high frequency
                WHEN MCC = '5912' THEN 1.5   -- Pharmacy: medium-high
                WHEN MCC = '5311' THEN 1.3   -- Department stores
                WHEN MCC = '5812' THEN 1.2   -- Restaurants
                WHEN MCC = '5200' THEN 0.8   -- Home improvement: less frequent
                WHEN MCC = '5732' THEN 0.5   -- Electronics: least frequent
                WHEN MCC = '7011' THEN 0.3   -- Hotels: rare
                ELSE 1.0
            END AS store_frequency
        FROM CLX_MRCH_MSTR
        WHERE CLNT_ID = 'dmcl' AND STAT_CD = 'Active'
    ),
    -- Realistic card brand distribution (2024 market share)
    card_brands AS (
        SELECT 'Visa' AS brand, 0.52 AS weight, 'Visa' AS ntwrk UNION ALL
        SELECT 'Mastercard', 0.25, 'Mastercard' UNION ALL
        SELECT 'American Express', 0.19, 'Amex' UNION ALL
        SELECT 'Discover', 0.04, 'Discover'
    ),
    bins AS (
        SELECT BIN_ID, CARD_BRND, CARD_TYP FROM GLB_BIN
    ),
    decline_reasons AS (
        SELECT DCLN_RSN_ID, DCLN_RSN_DESC, SFT_DCLN_FLG
        FROM DCLN_RSN_CD
        WHERE DCLN_RSN_ID != 'D042'  -- Exclude approved reference
    ),
    -- Generate raw transactions with all combinations
    raw_txns AS (
        SELECT
            d.txn_date,
            d.day_multiplier,
            d.month_multiplier,
            t.hour_of_day,
            t.hour_weight,
            m.MRCH_KEY,
            m.CLNT_ID,
            m.MCC,
            m.PLTF_ID,
            m.TRMNL_CT,
            m.store_frequency,
            cb.brand,
            cb.ntwrk,
            cb.weight AS brand_weight,
            RANDOM() AS rand_val
        FROM date_range d
        CROSS JOIN txn_slots t
        CROSS JOIN merchants m
        CROSS JOIN card_brands cb
        WHERE UNIFORM(0, 1, RANDOM()) < (t.hour_weight * m.store_frequency * d.day_multiplier * d.month_multiplier * cb.weight / 50.0)
    )
    SELECT
        UUID_STRING() AS AUTH_ID,
        r.CLNT_ID,
        r.MRCH_KEY,
        r.txn_date AS TXN_DT,
        TIMEADD(MINUTE, UNIFORM(0, 59, RANDOM()), TIMEADD(HOUR, r.hour_of_day, '00:00:00'::TIME)) AS TXN_TM,
        TIMESTAMPADD(MINUTE, UNIFORM(0, 59, RANDOM()), TIMESTAMPADD(HOUR, r.hour_of_day, r.txn_date::TIMESTAMP_NTZ)) AS TXN_TS,
        GENERATE_REALISTIC_AMOUNT(r.MCC, r.hour_of_day) AS TXN_AM,
        -- Approval rate varies by card brand and MCC
        CASE 
            WHEN UNIFORM(0, 1, RANDOM()) < (
                :BASE_APPROVAL_RATE 
                - CASE r.brand WHEN 'American Express' THEN 0.02 ELSE 0 END
                - CASE WHEN r.MCC = '5732' THEN 0.03 ELSE 0 END
                - CASE WHEN r.MCC = '7011' THEN 0.02 ELSE 0 END
            ) THEN 1 
            ELSE 2 
        END AS APRVL_CD,
        CASE WHEN UNIFORM(0, 1, RANDOM()) >= :BASE_APPROVAL_RATE 
             THEN (SELECT DCLN_RSN_ID FROM decline_reasons WHERE SFT_DCLN_FLG = (UNIFORM(0,1,RANDOM()) > 0.6) ORDER BY RANDOM() LIMIT 1) 
             ELSE NULL END AS DCLN_RSN_ID,
        CASE WHEN UNIFORM(0, 1, RANDOM()) >= :BASE_APPROVAL_RATE 
             THEN (SELECT DCLN_RSN_DESC FROM decline_reasons WHERE SFT_DCLN_FLG = (UNIFORM(0,1,RANDOM()) > 0.6) ORDER BY RANDOM() LIMIT 1) 
             ELSE NULL END AS DCLN_RSN_TX,
        COALESCE(b.BIN_ID, 
            CASE r.brand 
                WHEN 'Visa' THEN '411111' 
                WHEN 'Mastercard' THEN '520000'
                WHEN 'American Express' THEN '370000'
                ELSE '601100'
            END) AS BIN_ID,
        LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0') AS CARD_LST4,
        -- Payment method distribution
        CASE UNIFORM(1, 100, RANDOM())
            WHEN BETWEEN 1 AND 45 THEN 'Chip'
            WHEN BETWEEN 46 AND 75 THEN 'Contactless'
            WHEN BETWEEN 76 AND 88 THEN 'Swipe'
            ELSE 'Keyed'
        END AS PYMT_MTHD,
        r.ntwrk AS NTWRK,
        CASE UNIFORM(1, 100, RANDOM())
            WHEN BETWEEN 1 AND 50 THEN 'Chip'
            WHEN BETWEEN 51 AND 80 THEN 'Contactless'
            ELSE 'Manual'
        END AS ENTRY_MD,
        r.PLTF_ID,
        r.PLTF_ID || '-T' || LPAD(UNIFORM(1, r.TRMNL_CT, RANDOM())::VARCHAR, 3, '0') AS TRMNL_ID,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.05 THEN 'Y' ELSE 'N' END AS AVS_RSLT,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.02 THEN 'M' ELSE 'N' END AS CVV_RSLT
    FROM raw_txns r
    LEFT JOIN bins b ON b.CARD_BRND = r.brand
    QUALIFY ROW_NUMBER() OVER (PARTITION BY r.txn_date, r.MRCH_KEY, r.hour_of_day ORDER BY RANDOM()) <= 
        CEIL(r.store_frequency * r.day_multiplier * r.month_multiplier);
    
    SELECT COUNT(*) INTO :total_auth FROM CLX_AUTH;
    
    -- ==========================================================================
    -- Generate Settlement Data (based on approved authorizations)
    -- Settlement happens T+1 with batching by merchant
    -- ==========================================================================
    INSERT INTO CLX_SETTLE (
        SETTLE_ID, CLNT_ID, MRCH_KEY, RCRD_DT, BTCH_DT, PRCS_DT,
        SALES_CT, RFND_CT, NET_CT, SALES_AM, RFND_AM, PRCS_NET_AM,
        DSCN_AM, INTCHG_AM, CARD_BRND, CARD_TYP, PLAN_CD, PLAN_DESC,
        BTCH_REF, PLTF_ID, NTWRK
    )
    WITH approved_auths AS (
        SELECT 
            a.CLNT_ID,
            a.MRCH_KEY,
            a.TXN_DT,
            a.TXN_AM,
            a.NTWRK,
            b.CARD_BRND,
            b.CARD_TYP,
            m.MCC
        FROM CLX_AUTH a
        JOIN GLB_BIN b ON a.BIN_ID = b.BIN_ID
        JOIN CLX_MRCH_MSTR m ON a.MRCH_KEY = m.MRCH_KEY
        WHERE a.APRVL_CD = 1
    )
    SELECT
        UUID_STRING() AS SETTLE_ID,
        CLNT_ID,
        MRCH_KEY,
        DATEADD(DAY, 1, TXN_DT) AS RCRD_DT,
        TXN_DT AS BTCH_DT,
        DATEADD(DAY, 1, TXN_DT) AS PRCS_DT,
        COUNT(*) AS SALES_CT,
        FLOOR(COUNT(*) * 
            CASE MCC
                WHEN '5732' THEN 0.045
                WHEN '5311' THEN 0.035
                WHEN '7011' THEN 0.025
                ELSE 0.015
            END
        )::NUMBER AS RFND_CT,
        COUNT(*) - FLOOR(COUNT(*) * 0.02)::NUMBER AS NET_CT,
        SUM(TXN_AM) AS SALES_AM,
        SUM(TXN_AM) * 
            CASE MCC
                WHEN '5732' THEN 0.045
                WHEN '5311' THEN 0.035
                WHEN '7011' THEN 0.025
                ELSE 0.015
            END AS RFND_AM,
        SUM(TXN_AM) * 0.98 AS PRCS_NET_AM,
        SUM(TXN_AM) * 
            CASE CARD_BRND
                WHEN 'American Express' THEN 0.029
                WHEN 'Discover' THEN 0.024
                ELSE 0.022
            END AS DSCN_AM,
        SUM(TXN_AM) * 
            CASE 
                WHEN CARD_BRND = 'American Express' THEN 0.021
                WHEN CARD_TYP = 'Debit' THEN 0.0073
                ELSE 0.018
            END AS INTCHG_AM,
        CARD_BRND,
        MAX(CARD_TYP) AS CARD_TYP,
        CASE CARD_BRND
            WHEN 'Visa' THEN 'VS01'
            WHEN 'Mastercard' THEN 'MC01'
            WHEN 'American Express' THEN 'AX01'
            ELSE 'DS01'
        END AS PLAN_CD,
        CASE CARD_BRND
            WHEN 'Visa' THEN 'Visa Standard'
            WHEN 'Mastercard' THEN 'Mastercard Standard'
            WHEN 'American Express' THEN 'Amex Merchant'
            ELSE 'Discover Standard'
        END AS PLAN_DESC,
        'BTH-' || TO_CHAR(TXN_DT, 'YYYYMMDD') || '-' || MRCH_KEY AS BTCH_REF,
        MAX(NTWRK) AS PLTF_ID,
        NTWRK
    FROM approved_auths
    GROUP BY TXN_DT, CARD_BRND, MRCH_KEY, CLNT_ID, MCC, NTWRK;
    
    SELECT COUNT(*) INTO :total_settle FROM CLX_SETTLE;
    
    -- ==========================================================================
    -- Generate Funding Data (based on settlements)
    -- Funding happens T+2 with aggregation by merchant
    -- ==========================================================================
    INSERT INTO CLX_FUND (
        FUND_ID, CLNT_ID, MRCH_KEY, FUNDED_DT, SETTLE_DT, EXPCT_DT,
        DPST_AM, NET_SALES_AM, FEES_AM, CBK_AM, ADJ_AM, RSRV_AM,
        ITEM_CT, SALES_CT, RFND_CT, PYMT_STAT, PYMT_MTHD,
        DDA_LST4, BANK_NM, TXN_CTGR, FUND_TYP, BTCH_REF, ACH_TRC, PLTF_ID
    )
    SELECT
        UUID_STRING() AS FUND_ID,
        CLNT_ID,
        MRCH_KEY,
        DATEADD(DAY, 1, RCRD_DT) AS FUNDED_DT,
        RCRD_DT AS SETTLE_DT,
        DATEADD(DAY, 1, RCRD_DT) AS EXPCT_DT,
        SUM(PRCS_NET_AM) - SUM(DSCN_AM) AS DPST_AM,
        SUM(PRCS_NET_AM) AS NET_SALES_AM,
        SUM(DSCN_AM) AS FEES_AM,
        SUM(PRCS_NET_AM) * 0.003 AS CBK_AM,
        0 AS ADJ_AM,
        SUM(PRCS_NET_AM) * 0.001 AS RSRV_AM,
        SUM(SALES_CT) AS ITEM_CT,
        SUM(SALES_CT) AS SALES_CT,
        SUM(RFND_CT) AS RFND_CT,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.02 THEN 'Completed' ELSE 'Pending' END AS PYMT_STAT,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.15 THEN 'ACH' ELSE 'Wire' END AS PYMT_MTHD,
        LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0') AS DDA_LST4,
        'Chase Bank NA' AS BANK_NM,
        'Settlement' AS TXN_CTGR,
        'Net Funding' AS FUND_TYP,
        'FND-' || TO_CHAR(RCRD_DT, 'YYYYMMDD') || '-' || MRCH_KEY AS BTCH_REF,
        'ACH' || LPAD(UNIFORM(100000000, 999999999, RANDOM())::VARCHAR, 15, '0') AS ACH_TRC,
        MAX(PLTF_ID) AS PLTF_ID
    FROM CLX_SETTLE
    GROUP BY RCRD_DT, MRCH_KEY, CLNT_ID;
    
    SELECT COUNT(*) INTO :total_fund FROM CLX_FUND;
    
    -- ==========================================================================
    -- Generate Chargeback Data with industry-realistic rates
    -- ==========================================================================
    INSERT INTO CLX_CBK (
        CBK_ID, CLNT_ID, MRCH_KEY, CASE_NR, ARN, DSPUT_RCVD_DT, ORIG_TXN_DT,
        DUE_DT, RSLVD_DT, DSPUT_AM, TXN_AM, REPR_AM, CBK_STAT, CBK_WIN_LOSS,
        CBK_CYCL, CBK_RSN_ID, RSN_DESC_OVRD, RSN_CTGR, CARD_BRND, CARD_LST4,
        MRCH_NM, RESP_SENT_FLG, RESP_DT, DOCS_SBMTD_FLG, PLTF_ID
    )
    WITH cbk_reasons AS (
        SELECT CBK_RSN_ID, RSN_CD, RSN_DESC, RSN_CTGR, NTWRK
        FROM CBK_RSN_CD
    ),
    auth_with_brand AS (
        SELECT 
            a.*,
            b.CARD_BRND,
            m.LCTN_DBA_NM,
            m.MCC
        FROM CLX_AUTH a
        JOIN GLB_BIN b ON a.BIN_ID = b.BIN_ID
        JOIN CLX_MRCH_MSTR m ON a.MRCH_KEY = m.MRCH_KEY
        WHERE a.APRVL_CD = 1
    )
    SELECT
        UUID_STRING() AS CBK_ID,
        a.CLNT_ID,
        a.MRCH_KEY,
        'CBK-' || DATE_PART(YEAR, a.TXN_DT) || '-' || LPAD(ROW_NUMBER() OVER (ORDER BY RANDOM())::VARCHAR, 8, '0') AS CASE_NR,
        'ARN' || LPAD(UNIFORM(100000000000, 999999999999, RANDOM())::VARCHAR, 15, '0') AS ARN,
        DATEADD(DAY, UNIFORM(15, 45, RANDOM()), a.TXN_DT) AS DSPUT_RCVD_DT,
        a.TXN_DT AS ORIG_TXN_DT,
        DATEADD(DAY, UNIFORM(15, 45, RANDOM()) + 30, a.TXN_DT) AS DUE_DT,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.3 
             THEN DATEADD(DAY, UNIFORM(20, 60, RANDOM()), a.TXN_DT) 
             ELSE NULL END AS RSLVD_DT,
        a.TXN_AM AS DSPUT_AM,
        a.TXN_AM AS TXN_AM,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.6 THEN a.TXN_AM ELSE 0 END AS REPR_AM,
        CASE UNIFORM(1, 100, RANDOM())
            WHEN BETWEEN 1 AND 15 THEN 'Open'
            WHEN BETWEEN 16 AND 35 THEN 'Pending'
            WHEN BETWEEN 36 AND 60 THEN 'Won'
            WHEN BETWEEN 61 AND 85 THEN 'Lost'
            ELSE 'Closed'
        END AS CBK_STAT,
        CASE UNIFORM(1, 100, RANDOM())
            WHEN BETWEEN 1 AND 35 THEN 'Won'
            WHEN BETWEEN 36 AND 85 THEN 'Lost'
            ELSE NULL
        END AS CBK_WIN_LOSS,
        CASE UNIFORM(1, 100, RANDOM())
            WHEN BETWEEN 1 AND 75 THEN '1st Chargeback'
            WHEN BETWEEN 76 AND 90 THEN '2nd Chargeback'
            WHEN BETWEEN 91 AND 97 THEN 'Pre-Arbitration'
            ELSE 'Arbitration'
        END AS CBK_CYCL,
        cr.CBK_RSN_ID,
        cr.RSN_DESC AS RSN_DESC_OVRD,
        cr.RSN_CTGR,
        a.CARD_BRND,
        a.CARD_LST4,
        a.LCTN_DBA_NM AS MRCH_NM,
        UNIFORM(0,1,RANDOM()) > 0.3 AS RESP_SENT_FLG,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.3 
             THEN DATEADD(DAY, UNIFORM(5, 25, RANDOM()), a.TXN_DT) 
             ELSE NULL END AS RESP_DT,
        UNIFORM(0,1,RANDOM()) > 0.4 AS DOCS_SBMTD_FLG,
        a.PLTF_ID
    FROM auth_with_brand a
    CROSS JOIN cbk_reasons cr
    WHERE cr.NTWRK = CASE a.CARD_BRND 
            WHEN 'Visa' THEN 'Visa' 
            WHEN 'Mastercard' THEN 'Mastercard'
            WHEN 'American Express' THEN 'Amex'
            ELSE 'Discover' END
      AND UNIFORM(0, 1, RANDOM()) < GET_CHARGEBACK_RATE(a.MCC)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a.AUTH_ID ORDER BY RANDOM()) = 1;
    
    SELECT COUNT(*) INTO :total_cbk FROM CLX_CBK;
    
    -- ==========================================================================
    -- Generate Retrieval Requests (pre-chargeback inquiries)
    -- Retrieval rate is typically 2-3x the chargeback rate
    -- ==========================================================================
    INSERT INTO CLX_RTRVL (
        RTRVL_ID, CLNT_ID, MRCH_KEY, ARN, RTRVL_RCVD_DT, SALE_DT,
        DUE_DT, FULFMT_DT, RTRVL_AM, RTRVL_STAT, FULFMT_STAT,
        RSN_CD, RSN_DESC, CARD_BRND, CARD_LST4, DOCS_REQD,
        DOCS_SBMTD_FLG, SBMSN_MTHD, PLTF_ID
    )
    WITH auth_with_brand AS (
        SELECT 
            a.*,
            b.CARD_BRND,
            m.MCC
        FROM CLX_AUTH a
        JOIN GLB_BIN b ON a.BIN_ID = b.BIN_ID
        JOIN CLX_MRCH_MSTR m ON a.MRCH_KEY = m.MRCH_KEY
        WHERE a.APRVL_CD = 1
    )
    SELECT
        UUID_STRING() AS RTRVL_ID,
        a.CLNT_ID,
        a.MRCH_KEY,
        'ARN' || LPAD(UNIFORM(100000000000, 999999999999, RANDOM())::VARCHAR, 15, '0') AS ARN,
        DATEADD(DAY, UNIFORM(5, 25, RANDOM()), a.TXN_DT) AS RTRVL_RCVD_DT,
        a.TXN_DT AS SALE_DT,
        DATEADD(DAY, UNIFORM(5, 25, RANDOM()) + 20, a.TXN_DT) AS DUE_DT,
        CASE WHEN UNIFORM(0, 1, RANDOM()) < 0.70 
             THEN DATEADD(DAY, UNIFORM(5, 25, RANDOM()) + 10, a.TXN_DT) 
             ELSE NULL END AS FULFMT_DT,
        a.TXN_AM AS RTRVL_AM,
        CASE UNIFORM(1, 100, RANDOM())
            WHEN BETWEEN 1 AND 25 THEN 'Open'
            WHEN BETWEEN 26 AND 50 THEN 'Fulfilled'
            WHEN BETWEEN 51 AND 75 THEN 'Closed'
            ELSE 'Expired'
        END AS RTRVL_STAT,
        CASE UNIFORM(1, 100, RANDOM())
            WHEN BETWEEN 1 AND 70 THEN 'Complete'
            WHEN BETWEEN 71 AND 90 THEN 'Partial'
            ELSE 'None'
        END AS FULFMT_STAT,
        'RQ' || LPAD(UNIFORM(1, 15, RANDOM())::VARCHAR, 2, '0') AS RSN_CD,
        CASE UNIFORM(1, 100, RANDOM())
            WHEN BETWEEN 1 AND 30 THEN 'Cardholder Does Not Recognize'
            WHEN BETWEEN 31 AND 50 THEN 'Cardholder Request for Copy'
            WHEN BETWEEN 51 AND 70 THEN 'Fraud Investigation'
            WHEN BETWEEN 71 AND 85 THEN 'Compliance Review'
            ELSE 'Issuer Request'
        END AS RSN_DESC,
        a.CARD_BRND,
        a.CARD_LST4,
        'Transaction receipt, signed copy' AS DOCS_REQD,
        UNIFORM(0, 1, RANDOM()) > 0.3 AS DOCS_SBMTD_FLG,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.4 THEN 'Portal' ELSE 'Fax' END AS SBMSN_MTHD,
        a.PLTF_ID
    FROM auth_with_brand a
    WHERE UNIFORM(0, 1, RANDOM()) < (GET_CHARGEBACK_RATE(a.MCC) * 2.5);
    
    SELECT COUNT(*) INTO :total_rtv FROM CLX_RTRVL;
    
    -- ==========================================================================
    -- Generate Adjustments (fees, credits, monthly charges)
    -- ==========================================================================
    INSERT INTO CLX_ADJ (
        ADJ_ID, CLNT_ID, MRCH_KEY, ADJ_REF_NR, ADJ_DT, EFF_DT, ORIG_TXN_DT,
        ADJ_AM, ADJ_TYP_CD, ADJ_CD, ADJ_DESC, ADJ_CTGR, FEE_TYP_CD,
        FEE_DESC, RLTD_TXN_ID, RLTD_TXN_TYP, ADJ_STAT, PLTF_ID, CRT_BY
    )
    WITH adj_types AS (
        SELECT 'C' AS type_cd, 'Monthly Volume Bonus' AS desc_tx, 'CREDIT' AS category, 'MVB' AS adj_cd, 50.00 AS min_am, 500.00 AS max_am, 0.05 AS frequency UNION ALL
        SELECT 'D', 'Monthly Statement Fee', 'FEE', 'MSF', 5.00, 25.00, 0.40 UNION ALL
        SELECT 'D', 'PCI Compliance Fee', 'FEE', 'PCI', 19.95, 79.95, 0.30 UNION ALL
        SELECT 'C', 'Rate Adjustment Credit', 'RATE', 'RAC', 10.00, 150.00, 0.08 UNION ALL
        SELECT 'D', 'Equipment Lease Fee', 'FEE', 'EQP', 29.95, 99.95, 0.25 UNION ALL
        SELECT 'D', 'Chargeback Fee', 'FEE', 'CBK', 15.00, 35.00, 0.15 UNION ALL
        SELECT 'C', 'Early Settlement Bonus', 'PROMO', 'ESB', 25.00, 200.00, 0.03 UNION ALL
        SELECT 'D', 'Annual Account Fee', 'FEE', 'ANN', 79.00, 199.00, 0.02 UNION ALL
        SELECT 'D', 'Batch Processing Fee', 'FEE', 'BPF', 0.10, 5.00, 0.50 UNION ALL
        SELECT 'D', 'Network Access Fee', 'FEE', 'NAF', 4.95, 14.95, 0.20 UNION ALL
        SELECT 'C', 'Referral Credit', 'PROMO', 'REF', 50.00, 250.00, 0.02
    ),
    merchants AS (
        SELECT MRCH_KEY, CLNT_ID, PLTF_ID
        FROM CLX_MRCH_MSTR
        WHERE CLNT_ID = 'dmcl' AND STAT_CD = 'Active'
    ),
    date_range AS (
        SELECT DATEADD(DAY, SEQ4(), :START_DATE) AS adj_date
        FROM TABLE(GENERATOR(ROWCOUNT => :days_count))
    )
    SELECT
        UUID_STRING() AS ADJ_ID,
        m.CLNT_ID,
        m.MRCH_KEY,
        'ADJ-' || DATE_PART(YEAR, d.adj_date) || '-' || LPAD(ROW_NUMBER() OVER (ORDER BY RANDOM())::VARCHAR, 8, '0') AS ADJ_REF_NR,
        d.adj_date AS ADJ_DT,
        d.adj_date AS EFF_DT,
        NULL AS ORIG_TXN_DT,
        CASE at.type_cd 
            WHEN 'C' THEN UNIFORM(at.min_am, at.max_am, RANDOM())::NUMBER(15,2)
            ELSE -UNIFORM(at.min_am, at.max_am, RANDOM())::NUMBER(15,2)
        END AS ADJ_AM,
        at.type_cd AS ADJ_TYP_CD,
        at.adj_cd AS ADJ_CD,
        at.desc_tx AS ADJ_DESC,
        at.category AS ADJ_CTGR,
        at.adj_cd AS FEE_TYP_CD,
        at.desc_tx AS FEE_DESC,
        NULL AS RLTD_TXN_ID,
        NULL AS RLTD_TXN_TYP,
        'Processed' AS ADJ_STAT,
        m.PLTF_ID,
        'SYSTEM' AS CRT_BY
    FROM date_range d
    CROSS JOIN merchants m
    CROSS JOIN adj_types at
    WHERE UNIFORM(0, 1, RANDOM()) < at.frequency / 10.0;
    
    SELECT COUNT(*) INTO :total_adj FROM CLX_ADJ;
    
    RETURN 'Synthetic data generation complete. ' ||
           'Authorizations: ' || :total_auth || ', ' ||
           'Settlements: ' || :total_settle || ', ' ||
           'Funding: ' || :total_fund || ', ' ||
           'Chargebacks: ' || :total_cbk || ', ' ||
           'Retrievals: ' || :total_rtv || ', ' ||
           'Adjustments: ' || :total_adj;
END;
$$;


-- =============================================================================
-- Usage Examples:
-- =============================================================================
-- Generate default 90 days of data:
-- CALL GENERATE_SYNTHETIC_DATA();
--
-- Generate 1 year of data with higher volume:
-- CALL GENERATE_SYNTHETIC_DATA('2025-01-01', '2025-12-31', 1200, 0.96);
--
-- Generate Q4 holiday data:
-- CALL GENERATE_SYNTHETIC_DATA('2025-10-01', '2025-12-31', 1500, 0.965);
-- =============================================================================


-- =============================================================================
-- Verification Queries
-- =============================================================================
SELECT 'Transaction generator created successfully' AS status;

SELECT 
    'CLX_AUTH' AS table_name, COUNT(*) AS row_count FROM CLX_AUTH
UNION ALL SELECT 'CLX_SETTLE', COUNT(*) FROM CLX_SETTLE
UNION ALL SELECT 'CLX_FUND', COUNT(*) FROM CLX_FUND
UNION ALL SELECT 'CLX_CBK', COUNT(*) FROM CLX_CBK
UNION ALL SELECT 'CLX_RTRVL', COUNT(*) FROM CLX_RTRVL
UNION ALL SELECT 'CLX_ADJ', COUNT(*) FROM CLX_ADJ
ORDER BY table_name;
