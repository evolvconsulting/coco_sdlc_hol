-- HOL Setup Script — COCO SDLC Hands-On Lab
-- This script provisions a complete Snowflake HOL environment.
-- Run all sections sequentially in a Snowflake worksheet.
-- The script is idempotent: safe to re-run without creating duplicate data or failing on existing objects.

-- ============================================================
-- SECTION 1: ACCOUNTADMIN Bootstrap
-- ============================================================
USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS ATTENDEE_ROLE;
GRANT ROLE ATTENDEE_ROLE TO ROLE SYSADMIN;

GRANT CREATE DATABASE ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT CREATE SCHEMA ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT CREATE TABLE ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT CREATE COMPUTE POOL ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE ATTENDEE_ROLE;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT CREATE SECRET ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT CREATE AGENT ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT CREATE IMAGE REPOSITORY ON ACCOUNT TO ROLE ATTENDEE_ROLE;

CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  COMMENT = 'HOL warehouse for dbt dynamic tables and Cortex Agent';

GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ATTENDEE_ROLE;

-- ============================================================
-- SECTION 2: Database, Warehouse, and Schema Setup
-- ============================================================
USE ROLE ATTENDEE_ROLE;

CREATE DATABASE IF NOT EXISTS COCO_SDLC_HOL
    COMMENT = 'Performance Intelligence Dashboard for Fiserv payment analytics';

USE DATABASE COCO_SDLC_HOL;

CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = 'Raw normalized OLTP-style tables with legacy naming conventions';
CREATE SCHEMA IF NOT EXISTS STAGING;
CREATE SCHEMA IF NOT EXISTS INTERMEDIATE;
CREATE SCHEMA IF NOT EXISTS MARTS;
CREATE SCHEMA IF NOT EXISTS PUBLIC;

-- ============================================================
-- SECTION 3: RAW Schema Tables
-- ============================================================
USE SCHEMA COCO_SDLC_HOL.RAW;

-- -----------------------------------------------------------------------------
-- DIMENSION TABLES (Reference Data)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE PLTF_REF (
    PLTF_ID         VARCHAR(20)     NOT NULL    COMMENT 'Platform ID (PK)',
    PLTF_NM         VARCHAR(100)                COMMENT 'Platform name',
    PLTF_CD         VARCHAR(10)                 COMMENT 'Platform code',
    ACTV_FLG        BOOLEAN         DEFAULT TRUE COMMENT 'Active flag',
    CRT_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Created timestamp',

    CONSTRAINT PK_PLTF_REF PRIMARY KEY (PLTF_ID)
)
COMMENT = 'Platform/Processor reference data';


CREATE OR REPLACE TABLE GLB_BIN (
    BIN_ID          VARCHAR(10)     NOT NULL    COMMENT 'Bank Identification Number (PK)',
    CARD_BRND       VARCHAR(50)                 COMMENT 'Card brand (Visa, Mastercard, etc.)',
    CARD_TYP        VARCHAR(20)                 COMMENT 'Card type (Credit, Debit)',
    CARD_LVL        VARCHAR(50)                 COMMENT 'Card level (Classic, Gold, Platinum)',
    CARD_PROD       VARCHAR(100)                COMMENT 'Card product name',
    ISSR_NM         VARCHAR(200)                COMMENT 'Issuing bank name',
    ISSR_CNTRY      VARCHAR(3)                  COMMENT 'Issuer country code',
    ISSR_PHN        VARCHAR(20)                 COMMENT 'Issuer phone number',
    CMRCL_FLG       BOOLEAN         DEFAULT FALSE COMMENT 'Commercial card flag',
    PREPD_FLG       BOOLEAN         DEFAULT FALSE COMMENT 'Prepaid card flag',
    REG_FLG         BOOLEAN         DEFAULT TRUE  COMMENT 'Regulated flag',
    NTWRK           VARCHAR(20)                 COMMENT 'Network identifier',
    CRT_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Created timestamp',
    UPD_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Updated timestamp',

    CONSTRAINT PK_GLB_BIN PRIMARY KEY (BIN_ID)
)
COMMENT = 'Global BIN reference with card metadata';


CREATE OR REPLACE TABLE DCLN_RSN_CD (
    DCLN_RSN_ID     VARCHAR(20)     NOT NULL    COMMENT 'Decline reason ID (PK)',
    DCLN_RSN_CD     VARCHAR(10)                 COMMENT 'Decline reason code',
    DCLN_RSN_DESC   VARCHAR(500)                COMMENT 'Decline reason description',
    DCLN_CTGR       VARCHAR(50)                 COMMENT 'Decline category',
    MRCH_ACTN       VARCHAR(500)                COMMENT 'Recommended merchant action',
    CUST_MSG        VARCHAR(500)                COMMENT 'Customer-facing message',
    SFT_DCLN_FLG    BOOLEAN         DEFAULT FALSE COMMENT 'Soft decline flag',
    FRD_FLG         BOOLEAN         DEFAULT FALSE COMMENT 'Fraud-related flag',

    CONSTRAINT PK_DCLN_RSN_CD PRIMARY KEY (DCLN_RSN_ID)
)
COMMENT = 'Authorization decline reason codes reference';


CREATE OR REPLACE TABLE CBK_RSN_CD (
    CBK_RSN_ID      VARCHAR(20)     NOT NULL    COMMENT 'Chargeback reason ID (PK)',
    NTWRK           VARCHAR(20)                 COMMENT 'Card network (Visa, Mastercard, etc.)',
    RSN_CD          VARCHAR(20)                 COMMENT 'Reason code',
    RSN_DESC        VARCHAR(500)                COMMENT 'Reason description',
    RSN_CTGR        VARCHAR(100)                COMMENT 'Reason category',
    RESP_DYS        NUMBER(5)                   COMMENT 'Response days allowed',
    REQ_DOCS        VARCHAR(1000)               COMMENT 'Required documentation',
    DFNS_TIPS       VARCHAR(2000)               COMMENT 'Defense tips for merchant',

    CONSTRAINT PK_CBK_RSN_CD PRIMARY KEY (CBK_RSN_ID)
)
COMMENT = 'Chargeback reason codes by card brand';


CREATE OR REPLACE TABLE CLX_MRCH_MSTR (
    MRCH_KEY        VARCHAR(36)     NOT NULL    COMMENT 'Merchant key UUID (PK)',
    CLNT_ID         VARCHAR(20)     NOT NULL    COMMENT 'Client identifier',
    MRCH_ID         VARCHAR(50)                 COMMENT 'External merchant ID',
    LCTN_ID         VARCHAR(50)                 COMMENT 'Store/location ID',
    LCTN_DBA_NM     VARCHAR(200)                COMMENT 'Location DBA name',
    CORP_DBA_NM     VARCHAR(200)                COMMENT 'Corporate DBA name',
    LGL_NM          VARCHAR(200)                COMMENT 'Legal business name',
    ADDR_LN1        VARCHAR(200)                COMMENT 'Address line 1',
    CTY             VARCHAR(100)                COMMENT 'City',
    ST_CD           VARCHAR(10)                 COMMENT 'State code',
    ZIP_CD          VARCHAR(20)                 COMMENT 'ZIP/Postal code',
    CNTRY_CD        VARCHAR(3)      DEFAULT 'US' COMMENT 'Country code',
    PHN_NR          VARCHAR(20)                 COMMENT 'Phone number',
    EMAIL_ADDR      VARCHAR(200)                COMMENT 'Email address',
    MCC             VARCHAR(10)                 COMMENT 'Merchant Category Code',
    MCC_DESC        VARCHAR(200)                COMMENT 'MCC description',
    BSNS_TYP        VARCHAR(100)                COMMENT 'Business type',
    PLTF_ID         VARCHAR(20)                 COMMENT 'Platform ID (FK to PLTF_REF)',
    TRMNL_CT        NUMBER(10)      DEFAULT 1   COMMENT 'Terminal count',
    STAT_CD         VARCHAR(20)     DEFAULT 'Active' COMMENT 'Status code',
    ONBRD_DT        DATE                        COMMENT 'Onboarding date',
    CRT_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Created timestamp',
    UPD_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Updated timestamp',

    CONSTRAINT PK_CLX_MRCH_MSTR PRIMARY KEY (MRCH_KEY)
)
COMMENT = 'Merchant master data with legacy OLTP naming';


-- -----------------------------------------------------------------------------
-- FACT TABLES (Transactional Data)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE CLX_AUTH (
    AUTH_ID         VARCHAR(36)     NOT NULL    COMMENT 'Authorization ID UUID (PK)',
    CLNT_ID         VARCHAR(20)     NOT NULL    COMMENT 'Client identifier',
    MRCH_KEY        VARCHAR(36)                 COMMENT 'Merchant key (FK to CLX_MRCH_MSTR)',
    TXN_DT          DATE            NOT NULL    COMMENT 'Transaction date',
    TXN_TM          TIME                        COMMENT 'Transaction time',
    TXN_TS          TIMESTAMP_NTZ               COMMENT 'Transaction timestamp',
    TXN_AM          NUMBER(15,2)                COMMENT 'Transaction amount',
    APRVL_CD        NUMBER(5)                   COMMENT 'Approval code (1=Approved, 2=Declined)',
    DCLN_RSN_ID     VARCHAR(20)                 COMMENT 'Decline reason ID (FK to DCLN_RSN_CD)',
    DCLN_RSN_TX     VARCHAR(500)                COMMENT 'Decline reason text',
    BIN_ID          VARCHAR(10)                 COMMENT 'BIN (FK to GLB_BIN)',
    CARD_LST4       VARCHAR(4)                  COMMENT 'Card last 4 digits',
    PYMT_MTHD       VARCHAR(50)                 COMMENT 'Payment method (Chip, Contactless, Swipe)',
    NTWRK           VARCHAR(20)                 COMMENT 'Card network',
    ENTRY_MD        VARCHAR(50)                 COMMENT 'Entry mode',
    PLTF_ID         VARCHAR(20)                 COMMENT 'Platform ID (FK to PLTF_REF)',
    TRMNL_ID        VARCHAR(50)                 COMMENT 'Terminal ID',
    AVS_RSLT        VARCHAR(10)                 COMMENT 'AVS result code',
    CVV_RSLT        VARCHAR(10)                 COMMENT 'CVV result code',
    CRT_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Created timestamp',
    UPD_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Updated timestamp',

    CONSTRAINT PK_CLX_AUTH PRIMARY KEY (AUTH_ID)
)
COMMENT = 'Authorization transactions with legacy column names';


CREATE OR REPLACE TABLE CLX_SETTLE (
    SETTLE_ID       VARCHAR(36)     NOT NULL    COMMENT 'Settlement ID UUID (PK)',
    CLNT_ID         VARCHAR(20)     NOT NULL    COMMENT 'Client identifier',
    MRCH_KEY        VARCHAR(36)                 COMMENT 'Merchant key (FK to CLX_MRCH_MSTR)',
    RCRD_DT         DATE                        COMMENT 'Record date',
    BTCH_DT         DATE                        COMMENT 'Batch date',
    PRCS_DT         DATE                        COMMENT 'Process date',
    SALES_CT        NUMBER(15)                  COMMENT 'Sales count',
    RFND_CT         NUMBER(15)                  COMMENT 'Refund count',
    NET_CT          NUMBER(15)                  COMMENT 'Net count',
    SALES_AM        NUMBER(15,2)                COMMENT 'Sales amount',
    RFND_AM         NUMBER(15,2)                COMMENT 'Refund amount',
    PRCS_NET_AM     NUMBER(15,2)                COMMENT 'Process net amount',
    DSCN_AM         NUMBER(15,2)                COMMENT 'Discount amount (fees)',
    INTCHG_AM       NUMBER(15,2)                COMMENT 'Interchange amount',
    CARD_BRND       VARCHAR(50)                 COMMENT 'Card brand',
    CARD_TYP        VARCHAR(20)                 COMMENT 'Card type',
    PLAN_CD         VARCHAR(20)                 COMMENT 'Plan code',
    PLAN_DESC       VARCHAR(200)                COMMENT 'Plan description',
    BTCH_REF        VARCHAR(50)                 COMMENT 'Batch reference',
    PLTF_ID         VARCHAR(20)                 COMMENT 'Platform ID (FK to PLTF_REF)',
    NTWRK           VARCHAR(20)                 COMMENT 'Network',
    CRT_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Created timestamp',
    UPD_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Updated timestamp',

    CONSTRAINT PK_CLX_SETTLE PRIMARY KEY (SETTLE_ID)
)
COMMENT = 'Settlement transactions with legacy column names';


CREATE OR REPLACE TABLE CLX_FUND (
    FUND_ID         VARCHAR(36)     NOT NULL    COMMENT 'Funding ID UUID (PK)',
    CLNT_ID         VARCHAR(20)     NOT NULL    COMMENT 'Client identifier',
    MRCH_KEY        VARCHAR(36)                 COMMENT 'Merchant key (FK to CLX_MRCH_MSTR)',
    FUNDED_DT       DATE                        COMMENT 'Funded date',
    SETTLE_DT       DATE                        COMMENT 'Settlement date',
    EXPCT_DT        DATE                        COMMENT 'Expected date',
    DPST_AM         NUMBER(15,2)                COMMENT 'Deposit amount',
    NET_SALES_AM    NUMBER(15,2)                COMMENT 'Net sales amount',
    FEES_AM         NUMBER(15,2)                COMMENT 'Fees amount',
    CBK_AM          NUMBER(15,2)                COMMENT 'Chargeback amount',
    ADJ_AM          NUMBER(15,2)                COMMENT 'Adjustment amount',
    RSRV_AM         NUMBER(15,2)                COMMENT 'Reserve amount',
    ITEM_CT         NUMBER(15)                  COMMENT 'Item count',
    SALES_CT        NUMBER(15)                  COMMENT 'Sales count',
    RFND_CT         NUMBER(15)                  COMMENT 'Refund count',
    PYMT_STAT       VARCHAR(50)                 COMMENT 'Payment status',
    PYMT_MTHD       VARCHAR(50)                 COMMENT 'Payment method (ACH, Wire)',
    DDA_LST4        VARCHAR(4)                  COMMENT 'DDA last 4 digits',
    BANK_NM         VARCHAR(200)                COMMENT 'Bank name',
    TXN_CTGR        VARCHAR(50)                 COMMENT 'Transaction category',
    FUND_TYP        VARCHAR(50)                 COMMENT 'Funding type',
    BTCH_REF        VARCHAR(50)                 COMMENT 'Batch reference',
    ACH_TRC         VARCHAR(50)                 COMMENT 'ACH trace number',
    PLTF_ID         VARCHAR(20)                 COMMENT 'Platform ID (FK to PLTF_REF)',
    CRT_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Created timestamp',
    UPD_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Updated timestamp',

    CONSTRAINT PK_CLX_FUND PRIMARY KEY (FUND_ID)
)
COMMENT = 'Funding/deposit transactions with legacy column names';


CREATE OR REPLACE TABLE CLX_CBK (
    CBK_ID          VARCHAR(36)     NOT NULL    COMMENT 'Chargeback ID UUID (PK)',
    CLNT_ID         VARCHAR(20)     NOT NULL    COMMENT 'Client identifier',
    MRCH_KEY        VARCHAR(36)                 COMMENT 'Merchant key (FK to CLX_MRCH_MSTR)',
    CASE_NR         VARCHAR(50)                 COMMENT 'Case number',
    ARN             VARCHAR(50)                 COMMENT 'Acquirer Reference Number',
    DSPUT_RCVD_DT   DATE                        COMMENT 'Dispute received date',
    ORIG_TXN_DT     DATE                        COMMENT 'Original transaction date',
    DUE_DT          DATE                        COMMENT 'Response due date',
    RSLVD_DT        DATE                        COMMENT 'Resolved date',
    DSPUT_AM        NUMBER(15,2)                COMMENT 'Dispute amount',
    TXN_AM          NUMBER(15,2)                COMMENT 'Transaction amount',
    REPR_AM         NUMBER(15,2)                COMMENT 'Representment amount',
    CBK_STAT        VARCHAR(50)                 COMMENT 'Chargeback status',
    CBK_WIN_LOSS    VARCHAR(20)                 COMMENT 'Win/Loss outcome',
    CBK_CYCL        VARCHAR(50)                 COMMENT 'Chargeback cycle',
    CBK_RSN_ID      VARCHAR(20)                 COMMENT 'Chargeback reason ID (FK to CBK_RSN_CD)',
    RSN_DESC_OVRD   VARCHAR(500)                COMMENT 'Reason description override',
    RSN_CTGR        VARCHAR(100)                COMMENT 'Reason category',
    CARD_BRND       VARCHAR(50)                 COMMENT 'Card brand',
    CARD_LST4       VARCHAR(4)                  COMMENT 'Card last 4 digits',
    MRCH_NM         VARCHAR(200)                COMMENT 'Merchant name',
    RESP_SENT_FLG   BOOLEAN         DEFAULT FALSE COMMENT 'Response sent flag',
    RESP_DT         DATE                        COMMENT 'Response date',
    DOCS_SBMTD_FLG  BOOLEAN         DEFAULT FALSE COMMENT 'Docs submitted flag',
    PLTF_ID         VARCHAR(20)                 COMMENT 'Platform ID (FK to PLTF_REF)',
    CRT_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Created timestamp',
    UPD_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Updated timestamp',

    CONSTRAINT PK_CLX_CBK PRIMARY KEY (CBK_ID)
)
COMMENT = 'Chargeback transactions with legacy column names';


CREATE OR REPLACE TABLE CLX_RTRVL (
    RTRVL_ID        VARCHAR(36)     NOT NULL    COMMENT 'Retrieval ID UUID (PK)',
    CLNT_ID         VARCHAR(20)     NOT NULL    COMMENT 'Client identifier',
    MRCH_KEY        VARCHAR(36)                 COMMENT 'Merchant key (FK to CLX_MRCH_MSTR)',
    ARN             VARCHAR(50)                 COMMENT 'Acquirer Reference Number',
    RTRVL_RCVD_DT   DATE                        COMMENT 'Retrieval received date',
    SALE_DT         DATE                        COMMENT 'Original sale date',
    DUE_DT          DATE                        COMMENT 'Response due date',
    FULFMT_DT       DATE                        COMMENT 'Fulfillment date',
    RTRVL_AM        NUMBER(15,2)                COMMENT 'Retrieval amount',
    RTRVL_STAT      VARCHAR(50)                 COMMENT 'Retrieval status',
    FULFMT_STAT     VARCHAR(50)                 COMMENT 'Fulfillment status',
    RSN_CD          VARCHAR(20)                 COMMENT 'Reason code',
    RSN_DESC        VARCHAR(500)                COMMENT 'Reason description',
    CARD_BRND       VARCHAR(50)                 COMMENT 'Card brand',
    CARD_LST4       VARCHAR(4)                  COMMENT 'Card last 4 digits',
    DOCS_REQD       VARCHAR(500)                COMMENT 'Required documentation',
    DOCS_SBMTD_FLG  BOOLEAN         DEFAULT FALSE COMMENT 'Docs submitted flag',
    SBMSN_MTHD      VARCHAR(50)                 COMMENT 'Submission method',
    PLTF_ID         VARCHAR(20)                 COMMENT 'Platform ID (FK to PLTF_REF)',
    CRT_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Created timestamp',
    UPD_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Updated timestamp',

    CONSTRAINT PK_CLX_RTRVL PRIMARY KEY (RTRVL_ID)
)
COMMENT = 'Retrieval requests with legacy column names';


CREATE OR REPLACE TABLE CLX_ADJ (
    ADJ_ID          VARCHAR(36)     NOT NULL    COMMENT 'Adjustment ID UUID (PK)',
    CLNT_ID         VARCHAR(20)     NOT NULL    COMMENT 'Client identifier',
    MRCH_KEY        VARCHAR(36)                 COMMENT 'Merchant key (FK to CLX_MRCH_MSTR)',
    ADJ_REF_NR      VARCHAR(50)                 COMMENT 'Adjustment reference number',
    ADJ_DT          DATE                        COMMENT 'Adjustment date',
    EFF_DT          DATE                        COMMENT 'Effective date',
    ORIG_TXN_DT     DATE                        COMMENT 'Original transaction date',
    ADJ_AM          NUMBER(15,2)                COMMENT 'Adjustment amount',
    ADJ_TYP_CD      VARCHAR(10)                 COMMENT 'Adjustment type code (C=Credit, D=Debit)',
    ADJ_CD          VARCHAR(20)                 COMMENT 'Adjustment code',
    ADJ_DESC        VARCHAR(500)                COMMENT 'Adjustment description',
    ADJ_CTGR        VARCHAR(100)                COMMENT 'Adjustment category',
    FEE_TYP_CD      VARCHAR(20)                 COMMENT 'Fee type code',
    FEE_DESC        VARCHAR(500)                COMMENT 'Fee description',
    RLTD_TXN_ID     VARCHAR(36)                 COMMENT 'Related transaction ID',
    RLTD_TXN_TYP    VARCHAR(20)                 COMMENT 'Related transaction type',
    ADJ_STAT        VARCHAR(50)                 COMMENT 'Adjustment status',
    PLTF_ID         VARCHAR(20)                 COMMENT 'Platform ID (FK to PLTF_REF)',
    CRT_BY          VARCHAR(100)                COMMENT 'Created by user',
    CRT_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Created timestamp',
    UPD_TS          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Updated timestamp',

    CONSTRAINT PK_CLX_ADJ PRIMARY KEY (ADJ_ID)
)
COMMENT = 'Adjustments with legacy column names';


-- ============================================================
-- SECTION 4: Reference Data
-- ============================================================

MERGE INTO PLTF_REF AS tgt
USING (
    SELECT * FROM VALUES
        ('OMAHA', 'Omaha Platform', 'OMH', TRUE),
        ('NORTH', 'North Platform', 'NTH', TRUE),
        ('CARDNET', 'CardNet Platform', 'CDN', TRUE),
        ('BAMS', 'Bank of America Merchant Services', 'BAMS', TRUE),
        ('FDC', 'First Data Corporation', 'FDC', TRUE),
        ('TSYS', 'TSYS Platform', 'TSYS', TRUE),
        ('ELAVON', 'Elavon Platform', 'ELV', TRUE),
        ('WPG', 'Worldpay Gateway', 'WPG', TRUE)
    AS src(PLTF_ID, PLTF_NM, PLTF_CD, ACTV_FLG)
) AS src
ON tgt.PLTF_ID = src.PLTF_ID
WHEN MATCHED THEN UPDATE SET
    PLTF_NM = src.PLTF_NM,
    PLTF_CD = src.PLTF_CD,
    ACTV_FLG = src.ACTV_FLG
WHEN NOT MATCHED THEN INSERT (PLTF_ID, PLTF_NM, PLTF_CD, ACTV_FLG)
VALUES (src.PLTF_ID, src.PLTF_NM, src.PLTF_CD, src.ACTV_FLG);


MERGE INTO GLB_BIN AS tgt
USING (
    SELECT * FROM VALUES
        -- Visa BINs
        ('411111', 'Visa', 'Credit', 'Classic', 'Visa Classic', 'Chase Bank', 'US', '800-935-9935', FALSE, FALSE, TRUE, 'Visa'),
        ('422222', 'Visa', 'Debit', 'Classic', 'Visa Debit', 'Wells Fargo', 'US', '800-869-3557', FALSE, FALSE, TRUE, 'Visa'),
        ('433333', 'Visa', 'Credit', 'Gold', 'Visa Gold', 'Bank of America', 'US', '800-732-9194', FALSE, FALSE, TRUE, 'Visa'),
        ('444444', 'Visa', 'Credit', 'Platinum', 'Visa Platinum', 'Citi', 'US', '800-950-5114', FALSE, FALSE, TRUE, 'Visa'),
        ('455555', 'Visa', 'Credit', 'Signature', 'Visa Signature', 'Capital One', 'US', '800-227-4825', FALSE, FALSE, TRUE, 'Visa'),
        ('466666', 'Visa', 'Credit', 'Infinite', 'Visa Infinite', 'US Bank', 'US', '800-872-2657', FALSE, FALSE, TRUE, 'Visa'),
        ('477777', 'Visa', 'Debit', 'Business', 'Visa Business Debit', 'PNC Bank', 'US', '888-762-2265', TRUE, FALSE, TRUE, 'Visa'),
        ('488888', 'Visa', 'Credit', 'Corporate', 'Visa Corporate', 'HSBC', 'US', '800-975-4722', TRUE, FALSE, FALSE, 'Visa'),
        ('499999', 'Visa', 'Prepaid', 'Gift', 'Visa Gift Card', 'Blackhawk Network', 'US', '866-543-8382', FALSE, TRUE, FALSE, 'Visa'),

        -- Mastercard BINs
        ('510000', 'Mastercard', 'Credit', 'Standard', 'Mastercard Standard', 'Chase Bank', 'US', '800-935-9935', FALSE, FALSE, TRUE, 'Mastercard'),
        ('520000', 'Mastercard', 'Debit', 'Standard', 'Debit Mastercard', 'Wells Fargo', 'US', '800-869-3557', FALSE, FALSE, TRUE, 'Mastercard'),
        ('530000', 'Mastercard', 'Credit', 'World', 'World Mastercard', 'Bank of America', 'US', '800-732-9194', FALSE, FALSE, TRUE, 'Mastercard'),
        ('540000', 'Mastercard', 'Credit', 'World Elite', 'World Elite Mastercard', 'Citi', 'US', '800-950-5114', FALSE, FALSE, TRUE, 'Mastercard'),
        ('550000', 'Mastercard', 'Credit', 'Business', 'Mastercard Business', 'Capital One', 'US', '800-227-4825', TRUE, FALSE, TRUE, 'Mastercard'),
        ('560000', 'Mastercard', 'Prepaid', 'PayPass', 'Mastercard Prepaid', 'Green Dot', 'US', '866-795-7597', FALSE, TRUE, FALSE, 'Mastercard'),

        -- American Express BINs
        ('370000', 'American Express', 'Credit', 'Green', 'Amex Green', 'American Express', 'US', '800-528-4800', FALSE, FALSE, FALSE, 'Amex'),
        ('371111', 'American Express', 'Credit', 'Gold', 'Amex Gold', 'American Express', 'US', '800-528-4800', FALSE, FALSE, FALSE, 'Amex'),
        ('372222', 'American Express', 'Credit', 'Platinum', 'Amex Platinum', 'American Express', 'US', '800-528-4800', FALSE, FALSE, FALSE, 'Amex'),
        ('373333', 'American Express', 'Credit', 'Business', 'Amex Business', 'American Express', 'US', '800-528-4800', TRUE, FALSE, FALSE, 'Amex'),
        ('374444', 'American Express', 'Credit', 'Centurion', 'Amex Black Card', 'American Express', 'US', '800-528-4800', FALSE, FALSE, FALSE, 'Amex'),

        -- Discover BINs
        ('601100', 'Discover', 'Credit', 'Standard', 'Discover it', 'Discover', 'US', '800-347-2683', FALSE, FALSE, TRUE, 'Discover'),
        ('601111', 'Discover', 'Credit', 'Miles', 'Discover it Miles', 'Discover', 'US', '800-347-2683', FALSE, FALSE, TRUE, 'Discover'),
        ('601122', 'Discover', 'Credit', 'Cashback', 'Discover Cashback', 'Discover', 'US', '800-347-2683', FALSE, FALSE, TRUE, 'Discover'),
        ('601133', 'Discover', 'Debit', 'Standard', 'Discover Debit', 'Discover', 'US', '800-347-2683', FALSE, FALSE, TRUE, 'Discover'),
        ('601144', 'Discover', 'Credit', 'Business', 'Discover Business', 'Discover', 'US', '800-347-2683', TRUE, FALSE, TRUE, 'Discover')
    AS src(BIN_ID, CARD_BRND, CARD_TYP, CARD_LVL, CARD_PROD, ISSR_NM, ISSR_CNTRY, ISSR_PHN, CMRCL_FLG, PREPD_FLG, REG_FLG, NTWRK)
) AS src
ON tgt.BIN_ID = src.BIN_ID
WHEN MATCHED THEN UPDATE SET
    CARD_BRND = src.CARD_BRND,
    CARD_TYP = src.CARD_TYP,
    CARD_LVL = src.CARD_LVL,
    CARD_PROD = src.CARD_PROD,
    ISSR_NM = src.ISSR_NM,
    ISSR_CNTRY = src.ISSR_CNTRY,
    ISSR_PHN = src.ISSR_PHN,
    CMRCL_FLG = src.CMRCL_FLG,
    PREPD_FLG = src.PREPD_FLG,
    REG_FLG = src.REG_FLG,
    NTWRK = src.NTWRK,
    UPD_TS = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT (BIN_ID, CARD_BRND, CARD_TYP, CARD_LVL, CARD_PROD, ISSR_NM, ISSR_CNTRY, ISSR_PHN, CMRCL_FLG, PREPD_FLG, REG_FLG, NTWRK)
VALUES (src.BIN_ID, src.CARD_BRND, src.CARD_TYP, src.CARD_LVL, src.CARD_PROD, src.ISSR_NM, src.ISSR_CNTRY, src.ISSR_PHN, src.CMRCL_FLG, src.PREPD_FLG, src.REG_FLG, src.NTWRK);


MERGE INTO DCLN_RSN_CD AS tgt
USING (
    SELECT * FROM VALUES
        -- Card/Account Issues
        ('D001', '01', 'Refer to card issuer', 'Card Issue', 'Contact issuer for manual authorization', 'Please contact your card issuer', FALSE, FALSE),
        ('D002', '03', 'Invalid merchant', 'Merchant Issue', 'Verify merchant ID configuration', 'Transaction cannot be processed', FALSE, FALSE),
        ('D003', '04', 'Pick up card', 'Card Issue', 'Card should be retained', 'Please use a different card', FALSE, TRUE),
        ('D004', '05', 'Do not honor', 'Generic', 'Retry with different card', 'Transaction declined', TRUE, FALSE),
        ('D005', '12', 'Invalid transaction', 'Transaction Issue', 'Verify transaction type', 'Invalid transaction type', FALSE, FALSE),
        ('D006', '13', 'Invalid amount', 'Transaction Issue', 'Verify amount format', 'Invalid amount', FALSE, FALSE),
        ('D007', '14', 'Invalid card number', 'Card Issue', 'Verify card number entry', 'Invalid card number', FALSE, FALSE),
        ('D008', '15', 'Invalid issuer', 'Card Issue', 'Card network routing issue', 'Card not supported', FALSE, FALSE),

        -- Insufficient Funds
        ('D010', '51', 'Insufficient funds', 'Funds', 'Suggest lower amount or different card', 'Insufficient funds', TRUE, FALSE),
        ('D011', '52', 'No checking account', 'Account', 'Use different payment method', 'Account type not supported', FALSE, FALSE),
        ('D012', '53', 'No savings account', 'Account', 'Use different payment method', 'Account type not supported', FALSE, FALSE),
        ('D013', '61', 'Exceeds withdrawal limit', 'Limit', 'Try smaller amount', 'Exceeds daily limit', TRUE, FALSE),
        ('D014', '65', 'Exceeds activity limit', 'Limit', 'Retry later or use different card', 'Transaction limit exceeded', TRUE, FALSE),

        -- Expired/Restricted
        ('D020', '54', 'Expired card', 'Card Issue', 'Request updated card info', 'Card has expired', FALSE, FALSE),
        ('D021', '57', 'Transaction not permitted - Card', 'Restriction', 'Card not enabled for this transaction type', 'Transaction not allowed', FALSE, FALSE),
        ('D022', '58', 'Transaction not permitted - Terminal', 'Restriction', 'Terminal not configured for this transaction', 'Transaction not allowed', FALSE, FALSE),
        ('D023', '62', 'Restricted card', 'Restriction', 'Card has usage restrictions', 'Card restricted', FALSE, FALSE),

        -- Security/Fraud
        ('D030', '41', 'Pick up card - Lost', 'Fraud', 'Card reported lost', 'Card not valid', FALSE, TRUE),
        ('D031', '43', 'Pick up card - Stolen', 'Fraud', 'Card reported stolen', 'Card not valid', FALSE, TRUE),
        ('D032', '59', 'Suspected fraud', 'Fraud', 'Transaction flagged by fraud systems', 'Transaction cannot be processed', FALSE, TRUE),
        ('D033', 'N7', 'CVV mismatch', 'Security', 'Verify CVV entry', 'Security code incorrect', TRUE, FALSE),
        ('D034', 'N4', 'AVS mismatch', 'Security', 'Verify billing address', 'Address verification failed', TRUE, FALSE),

        -- Technical
        ('D040', '91', 'Issuer unavailable', 'Technical', 'Retry transaction', 'System temporarily unavailable', TRUE, FALSE),
        ('D041', '96', 'System error', 'Technical', 'Retry transaction', 'Please try again', TRUE, FALSE),
        ('D042', '00', 'Approved (reference)', 'Approved', 'Transaction approved', 'Approved', FALSE, FALSE)
    AS src(DCLN_RSN_ID, DCLN_RSN_CD, DCLN_RSN_DESC, DCLN_CTGR, MRCH_ACTN, CUST_MSG, SFT_DCLN_FLG, FRD_FLG)
) AS src
ON tgt.DCLN_RSN_ID = src.DCLN_RSN_ID
WHEN MATCHED THEN UPDATE SET
    DCLN_RSN_CD = src.DCLN_RSN_CD,
    DCLN_RSN_DESC = src.DCLN_RSN_DESC,
    DCLN_CTGR = src.DCLN_CTGR,
    MRCH_ACTN = src.MRCH_ACTN,
    CUST_MSG = src.CUST_MSG,
    SFT_DCLN_FLG = src.SFT_DCLN_FLG,
    FRD_FLG = src.FRD_FLG
WHEN NOT MATCHED THEN INSERT (DCLN_RSN_ID, DCLN_RSN_CD, DCLN_RSN_DESC, DCLN_CTGR, MRCH_ACTN, CUST_MSG, SFT_DCLN_FLG, FRD_FLG)
VALUES (src.DCLN_RSN_ID, src.DCLN_RSN_CD, src.DCLN_RSN_DESC, src.DCLN_CTGR, src.MRCH_ACTN, src.CUST_MSG, src.SFT_DCLN_FLG, src.FRD_FLG);


MERGE INTO CBK_RSN_CD AS tgt
USING (
    SELECT * FROM VALUES
        -- Visa Reason Codes
        ('V-10.1', 'Visa', '10.1', 'EMV Liability Shift - Counterfeit', 'Fraud', 30, 'EMV transaction receipt, terminal capability', 'Ensure EMV chip read was attempted'),
        ('V-10.2', 'Visa', '10.2', 'EMV Liability Shift - Non-Counterfeit', 'Fraud', 30, 'EMV transaction receipt', 'Verify PIN was used for PIN-preferring cards'),
        ('V-10.3', 'Visa', '10.3', 'Other Fraud - Card Present', 'Fraud', 30, 'Signed receipt, ID verification', 'Implement additional fraud prevention measures'),
        ('V-10.4', 'Visa', '10.4', 'Other Fraud - Card Not Present', 'Fraud', 30, 'AVS/CVV match, 3DS authentication', 'Use 3D Secure for CNP transactions'),
        ('V-10.5', 'Visa', '10.5', 'Visa Fraud Monitoring Program', 'Fraud', 30, 'Investigation documentation', 'Review fraud prevention controls'),
        ('V-11.1', 'Visa', '11.1', 'Card Recovery Bulletin', 'Authorization', 30, 'Valid authorization code', 'Always obtain authorization'),
        ('V-11.2', 'Visa', '11.2', 'Declined Authorization', 'Authorization', 30, 'Authorization log', 'Do not process declined transactions'),
        ('V-11.3', 'Visa', '11.3', 'No Authorization', 'Authorization', 30, 'Authorization code', 'Obtain authorization for all transactions'),
        ('V-12.1', 'Visa', '12.1', 'Late Presentment', 'Processing Error', 30, 'Transaction date proof', 'Submit transactions within required timeframe'),
        ('V-12.2', 'Visa', '12.2', 'Incorrect Transaction Code', 'Processing Error', 30, 'Transaction records', 'Use correct transaction codes'),
        ('V-12.3', 'Visa', '12.3', 'Incorrect Currency', 'Processing Error', 30, 'Currency conversion records', 'Process in correct currency'),
        ('V-12.4', 'Visa', '12.4', 'Incorrect Account Number', 'Processing Error', 30, 'Card imprint', 'Verify card number before processing'),
        ('V-12.5', 'Visa', '12.5', 'Incorrect Amount', 'Processing Error', 30, 'Receipt, invoice', 'Verify amount before submission'),
        ('V-12.6', 'Visa', '12.6', 'Duplicate Processing/Paid by Other Means', 'Processing Error', 30, 'Transaction records', 'Check for duplicates before processing'),
        ('V-12.7', 'Visa', '12.7', 'Invalid Data', 'Processing Error', 30, 'Corrected transaction data', 'Validate data before submission'),
        ('V-13.1', 'Visa', '13.1', 'Merchandise/Services Not Received', 'Consumer Dispute', 30, 'Proof of delivery, tracking', 'Obtain signature on delivery'),
        ('V-13.2', 'Visa', '13.2', 'Cancelled Recurring Transaction', 'Consumer Dispute', 30, 'Cancellation policy, communications', 'Honor cancellation requests promptly'),
        ('V-13.3', 'Visa', '13.3', 'Not as Described or Defective', 'Consumer Dispute', 30, 'Product description, return policy', 'Accurate descriptions, quality control'),
        ('V-13.4', 'Visa', '13.4', 'Counterfeit Merchandise', 'Consumer Dispute', 30, 'Authenticity proof', 'Source authentic products only'),
        ('V-13.5', 'Visa', '13.5', 'Misrepresentation', 'Consumer Dispute', 30, 'Marketing materials, terms', 'Clear and accurate advertising'),
        ('V-13.6', 'Visa', '13.6', 'Credit Not Processed', 'Consumer Dispute', 30, 'Refund receipt', 'Process refunds promptly'),
        ('V-13.7', 'Visa', '13.7', 'Cancelled Merchandise/Services', 'Consumer Dispute', 30, 'Cancellation policy compliance', 'Honor cancellation within policy'),
        ('V-13.8', 'Visa', '13.8', 'Original Credit Transaction Not Accepted', 'Consumer Dispute', 30, 'Credit transaction records', 'Verify credit acceptance'),
        ('V-13.9', 'Visa', '13.9', 'Non-Receipt of Cash or Load Value', 'Consumer Dispute', 30, 'ATM/load records', 'Investigate dispensing issues'),

        -- Mastercard Reason Codes
        ('M-4808', 'Mastercard', '4808', 'Authorization-Related Chargeback', 'Authorization', 45, 'Authorization records', 'Obtain valid authorization'),
        ('M-4812', 'Mastercard', '4812', 'Account Number Not On File', 'Processing Error', 45, 'Card validation records', 'Verify account number'),
        ('M-4831', 'Mastercard', '4831', 'Transaction Amount Differs', 'Processing Error', 45, 'Receipt, invoice', 'Process correct amount'),
        ('M-4834', 'Mastercard', '4834', 'Duplicate Transaction', 'Processing Error', 45, 'Transaction log', 'Prevent duplicate submissions'),
        ('M-4837', 'Mastercard', '4837', 'No Cardholder Authorization', 'Fraud', 45, 'Signed receipt, authentication', 'Verify cardholder identity'),
        ('M-4840', 'Mastercard', '4840', 'Fraudulent Processing of Transactions', 'Fraud', 45, 'Investigation records', 'Implement fraud controls'),
        ('M-4841', 'Mastercard', '4841', 'Cancelled Recurring Transaction', 'Consumer Dispute', 45, 'Cancellation records', 'Honor cancellation requests'),
        ('M-4853', 'Mastercard', '4853', 'Cardholder Dispute', 'Consumer Dispute', 45, 'Supporting documentation', 'Document all transactions'),
        ('M-4855', 'Mastercard', '4855', 'Goods or Services Not Provided', 'Consumer Dispute', 45, 'Delivery proof', 'Confirm delivery'),
        ('M-4859', 'Mastercard', '4859', 'Addendum, No-show, ATM Dispute', 'Consumer Dispute', 45, 'Policy documentation', 'Clear no-show policy'),
        ('M-4860', 'Mastercard', '4860', 'Credit Not Processed', 'Consumer Dispute', 45, 'Refund records', 'Process credits promptly'),
        ('M-4863', 'Mastercard', '4863', 'Cardholder Does Not Recognize', 'Fraud', 45, 'Transaction documentation', 'Clear billing descriptors'),
        ('M-4870', 'Mastercard', '4870', 'Chip Liability Shift', 'Fraud', 45, 'EMV capability proof', 'Use chip-enabled terminals'),
        ('M-4871', 'Mastercard', '4871', 'Chip/PIN Liability Shift', 'Fraud', 45, 'PIN verification', 'Require PIN for chip cards'),

        -- American Express Reason Codes
        ('A-A01', 'Amex', 'A01', 'Charge Amount Exceeds Authorization', 'Authorization', 20, 'Authorization records', 'Match auth to settlement'),
        ('A-A02', 'Amex', 'A02', 'No Valid Authorization', 'Authorization', 20, 'Authorization code', 'Always obtain authorization'),
        ('A-A08', 'Amex', 'A08', 'Authorization Approval Expired', 'Authorization', 20, 'Timely settlement proof', 'Settle within auth window'),
        ('A-C02', 'Amex', 'C02', 'Credit Not Processed', 'Consumer Dispute', 20, 'Credit records', 'Issue credits promptly'),
        ('A-C04', 'Amex', 'C04', 'Goods/Services Returned or Refused', 'Consumer Dispute', 20, 'Return records', 'Clear return policy'),
        ('A-C05', 'Amex', 'C05', 'Goods/Services Cancelled', 'Consumer Dispute', 20, 'Cancellation records', 'Honor cancellations'),
        ('A-C08', 'Amex', 'C08', 'Goods/Services Not Received', 'Consumer Dispute', 20, 'Delivery confirmation', 'Track all shipments'),
        ('A-C14', 'Amex', 'C14', 'Paid by Other Means', 'Processing Error', 20, 'Payment records', 'Verify no duplicate payment'),
        ('A-C18', 'Amex', 'C18', 'No Show or CARDeposit Cancelled', 'Consumer Dispute', 20, 'Cancellation policy', 'Clear no-show terms'),
        ('A-C28', 'Amex', 'C28', 'Cancelled Recurring Billing', 'Consumer Dispute', 20, 'Billing records', 'Stop billing on request'),
        ('A-C31', 'Amex', 'C31', 'Goods/Services Not as Described', 'Consumer Dispute', 20, 'Product documentation', 'Accurate descriptions'),
        ('A-C32', 'Amex', 'C32', 'Goods/Services Damaged or Defective', 'Consumer Dispute', 20, 'Quality records', 'Quality assurance'),
        ('A-F10', 'Amex', 'F10', 'Missing Imprint', 'Processing Error', 20, 'Card imprint', 'Obtain proper imprint'),
        ('A-F14', 'Amex', 'F14', 'Missing Signature', 'Processing Error', 20, 'Signed receipt', 'Obtain signature'),
        ('A-F24', 'Amex', 'F24', 'No Cardholder Authorization', 'Fraud', 20, 'Authentication records', 'Verify cardholder'),
        ('A-F29', 'Amex', 'F29', 'Card Not Present', 'Fraud', 20, 'CNP fraud prevention', 'Use fraud screening'),
        ('A-P01', 'Amex', 'P01', 'Unassigned Card Number', 'Processing Error', 20, 'Valid card proof', 'Verify card number'),
        ('A-P03', 'Amex', 'P03', 'Credit Processed as Charge', 'Processing Error', 20, 'Transaction type proof', 'Correct transaction type'),
        ('A-P04', 'Amex', 'P04', 'Charge Processed as Credit', 'Processing Error', 20, 'Transaction type proof', 'Correct transaction type'),
        ('A-P05', 'Amex', 'P05', 'Incorrect Charge Amount', 'Processing Error', 20, 'Invoice, receipt', 'Verify amounts'),

        -- Discover Reason Codes
        ('D-AA', 'Discover', 'AA', 'Cardholder Does Not Recognize', 'Fraud', 30, 'Transaction documentation', 'Clear billing descriptor'),
        ('D-AP', 'Discover', 'AP', 'Cancelled Recurring', 'Consumer Dispute', 30, 'Cancellation records', 'Honor cancellation'),
        ('D-AW', 'Discover', 'AW', 'Altered Amount', 'Processing Error', 30, 'Original records', 'Accurate processing'),
        ('D-CD', 'Discover', 'CD', 'Credit/Debit Posted Incorrectly', 'Processing Error', 30, 'Transaction records', 'Correct posting'),
        ('D-DP', 'Discover', 'DP', 'Duplicate Processing', 'Processing Error', 30, 'Transaction log', 'Prevent duplicates'),
        ('D-EX', 'Discover', 'EX', 'Expired Card', 'Authorization', 30, 'Valid card proof', 'Check expiration'),
        ('D-IC', 'Discover', 'IC', 'Illegible Sales Data', 'Processing Error', 30, 'Clear documentation', 'Legible receipts'),
        ('D-LP', 'Discover', 'LP', 'Late Presentment', 'Processing Error', 30, 'Timely processing proof', 'Submit promptly'),
        ('D-NA', 'Discover', 'NA', 'No Authorization', 'Authorization', 30, 'Authorization records', 'Obtain authorization'),
        ('D-NC', 'Discover', 'NC', 'Not Classified', 'Other', 30, 'Supporting documentation', 'Contact Discover'),
        ('D-NF', 'Discover', 'NF', 'Non-Receipt of Goods/Services', 'Consumer Dispute', 30, 'Delivery proof', 'Confirm delivery'),
        ('D-PM', 'Discover', 'PM', 'Paid by Other Means', 'Processing Error', 30, 'Payment records', 'Verify payment method'),
        ('D-RG', 'Discover', 'RG', 'Non-Receipt of Refund', 'Consumer Dispute', 30, 'Refund records', 'Process refunds'),
        ('D-RM', 'Discover', 'RM', 'Quality Dispute', 'Consumer Dispute', 30, 'Quality documentation', 'Quality assurance'),
        ('D-RN', 'Discover', 'RN', 'Credit Not Received', 'Consumer Dispute', 30, 'Credit records', 'Issue credits promptly'),
        ('D-UA', 'Discover', 'UA', 'Fraud - Card Present', 'Fraud', 30, 'Fraud prevention records', 'Verify identity'),
        ('D-UP', 'Discover', 'UP', 'Fraud - Card Not Present', 'Fraud', 30, 'CNP controls', 'Use fraud screening')
    AS src(CBK_RSN_ID, NTWRK, RSN_CD, RSN_DESC, RSN_CTGR, RESP_DYS, REQ_DOCS, DFNS_TIPS)
) AS src
ON tgt.CBK_RSN_ID = src.CBK_RSN_ID
WHEN MATCHED THEN UPDATE SET
    NTWRK = src.NTWRK,
    RSN_CD = src.RSN_CD,
    RSN_DESC = src.RSN_DESC,
    RSN_CTGR = src.RSN_CTGR,
    RESP_DYS = src.RESP_DYS,
    REQ_DOCS = src.REQ_DOCS,
    DFNS_TIPS = src.DFNS_TIPS
WHEN NOT MATCHED THEN INSERT (CBK_RSN_ID, NTWRK, RSN_CD, RSN_DESC, RSN_CTGR, RESP_DYS, REQ_DOCS, DFNS_TIPS)
VALUES (src.CBK_RSN_ID, src.NTWRK, src.RSN_CD, src.RSN_DESC, src.RSN_CTGR, src.RESP_DYS, src.REQ_DOCS, src.DFNS_TIPS);


MERGE INTO CLX_MRCH_MSTR AS tgt
USING (
    SELECT
        UUID_STRING() AS MRCH_KEY,
        src.*
    FROM (
        SELECT * FROM VALUES
            -- Grocery Stores (MCC 5411)
            ('dmcl', 'M001', 'S001', 'Fresh Market Downtown', 'Fresh Market Inc', 'Fresh Market Incorporated', '123 Main St', 'Columbus', 'OH', '43215', 'US', '614-555-0101', 'downtown@freshmarket.com', '5411', 'Grocery Stores', 'Grocery', 'OMAHA', 3, 'Active', '2023-01-15'),
            ('dmcl', 'M001', 'S002', 'Fresh Market Westside', 'Fresh Market Inc', 'Fresh Market Incorporated', '456 West Broad St', 'Columbus', 'OH', '43204', 'US', '614-555-0102', 'westside@freshmarket.com', '5411', 'Grocery Stores', 'Grocery', 'OMAHA', 2, 'Active', '2023-02-20'),
            ('dmcl', 'M001', 'S003', 'Fresh Market Eastland', 'Fresh Market Inc', 'Fresh Market Incorporated', '789 East Main St', 'Columbus', 'OH', '43213', 'US', '614-555-0103', 'eastland@freshmarket.com', '5411', 'Grocery Stores', 'Grocery', 'OMAHA', 2, 'Active', '2023-03-10'),
            ('dmcl', 'M002', 'S001', 'SaveMore Supermarket', 'SaveMore Foods LLC', 'SaveMore Foods Limited Liability Company', '321 High St', 'Columbus', 'OH', '43215', 'US', '614-555-0201', 'contact@savemore.com', '5411', 'Grocery Stores', 'Grocery', 'NORTH', 4, 'Active', '2022-11-01'),
            ('dmcl', 'M002', 'S002', 'SaveMore Supermarket North', 'SaveMore Foods LLC', 'SaveMore Foods Limited Liability Company', '654 Morse Rd', 'Columbus', 'OH', '43229', 'US', '614-555-0202', 'north@savemore.com', '5411', 'Grocery Stores', 'Grocery', 'NORTH', 3, 'Active', '2023-01-15'),

            -- Gas Stations (MCC 5541/5542)
            ('dmcl', 'M003', 'S001', 'QuickFuel Station #101', 'QuickFuel Corp', 'QuickFuel Corporation', '100 Broad St', 'Columbus', 'OH', '43215', 'US', '614-555-0301', 'station101@quickfuel.com', '5541', 'Service Stations', 'Gas Station', 'CARDNET', 2, 'Active', '2022-06-15'),
            ('dmcl', 'M003', 'S002', 'QuickFuel Station #102', 'QuickFuel Corp', 'QuickFuel Corporation', '200 High St', 'Columbus', 'OH', '43215', 'US', '614-555-0302', 'station102@quickfuel.com', '5541', 'Service Stations', 'Gas Station', 'CARDNET', 2, 'Active', '2022-07-20'),
            ('dmcl', 'M003', 'S003', 'QuickFuel Station #103', 'QuickFuel Corp', 'QuickFuel Corporation', '300 Neil Ave', 'Columbus', 'OH', '43215', 'US', '614-555-0303', 'station103@quickfuel.com', '5541', 'Service Stations', 'Gas Station', 'CARDNET', 2, 'Active', '2022-08-10'),
            ('dmcl', 'M004', 'S001', 'EcoGas Convenience', 'EcoGas LLC', 'EcoGas Limited Liability Company', '500 Cleveland Ave', 'Columbus', 'OH', '43215', 'US', '614-555-0401', 'info@ecogas.com', '5542', 'Automated Fuel Dispensers', 'Gas Station', 'OMAHA', 4, 'Active', '2023-04-01'),

            -- Restaurants (MCC 5812)
            ('dmcl', 'M005', 'S001', 'The Capital Grille', 'Capital Dining Group', 'Capital Dining Group Inc', '4015 Townsfair Way', 'Columbus', 'OH', '43219', 'US', '614-555-0501', 'columbus@capitalgrille.com', '5812', 'Eating Places and Restaurants', 'Restaurant', 'NORTH', 5, 'Active', '2021-09-15'),
            ('dmcl', 'M006', 'S001', 'Lindeys Restaurant', 'Lindeys Inc', 'Lindeys Incorporated', '169 E Beck St', 'Columbus', 'OH', '43206', 'US', '614-555-0601', 'info@lindeys.com', '5812', 'Eating Places and Restaurants', 'Restaurant', 'OMAHA', 3, 'Active', '2022-01-10'),
            ('dmcl', 'M007', 'S001', 'The Refectory', 'Refectory Restaurant LLC', 'Refectory Restaurant Limited Liability Company', '1092 Bethel Rd', 'Columbus', 'OH', '43220', 'US', '614-555-0701', 'reservations@refectory.com', '5812', 'Eating Places and Restaurants', 'Restaurant', 'OMAHA', 2, 'Active', '2022-03-20'),
            ('dmcl', 'M008', 'S001', 'Buca di Beppo', 'Planet Hollywood Intl', 'Planet Hollywood International Inc', '343 N Front St', 'Columbus', 'OH', '43215', 'US', '614-555-0801', 'columbus@bucadibeppo.com', '5812', 'Eating Places and Restaurants', 'Restaurant', 'CARDNET', 4, 'Active', '2022-05-15'),

            -- Fast Food (MCC 5814)
            ('dmcl', 'M009', 'S001', 'Wendys #4521', 'Wendys Company', 'The Wendys Company', '1234 Broad St', 'Columbus', 'OH', '43215', 'US', '614-555-0901', 'store4521@wendys.com', '5814', 'Fast Food Restaurants', 'Fast Food', 'OMAHA', 2, 'Active', '2022-02-01'),
            ('dmcl', 'M009', 'S002', 'Wendys #4522', 'Wendys Company', 'The Wendys Company', '5678 High St', 'Columbus', 'OH', '43214', 'US', '614-555-0902', 'store4522@wendys.com', '5814', 'Fast Food Restaurants', 'Fast Food', 'OMAHA', 2, 'Active', '2022-02-15'),
            ('dmcl', 'M010', 'S001', 'Chipotle German Village', 'Chipotle Mexican Grill', 'Chipotle Mexican Grill Inc', '795 S Third St', 'Columbus', 'OH', '43206', 'US', '614-555-1001', 'germanvillage@chipotle.com', '5814', 'Fast Food Restaurants', 'Fast Food', 'NORTH', 2, 'Active', '2022-04-10'),
            ('dmcl', 'M010', 'S002', 'Chipotle Short North', 'Chipotle Mexican Grill', 'Chipotle Mexican Grill Inc', '1062 N High St', 'Columbus', 'OH', '43201', 'US', '614-555-1002', 'shortnorth@chipotle.com', '5814', 'Fast Food Restaurants', 'Fast Food', 'NORTH', 2, 'Active', '2022-05-20'),
            ('dmcl', 'M011', 'S001', 'Five Guys Easton', 'Five Guys Enterprises', 'Five Guys Enterprises LLC', '3960 Townsfair Way', 'Columbus', 'OH', '43219', 'US', '614-555-1101', 'easton@fiveguys.com', '5814', 'Fast Food Restaurants', 'Fast Food', 'CARDNET', 2, 'Active', '2023-01-05'),

            -- Pharmacies (MCC 5912)
            ('dmcl', 'M012', 'S001', 'CVS Pharmacy #3421', 'CVS Health Corp', 'CVS Health Corporation', '1000 N High St', 'Columbus', 'OH', '43201', 'US', '614-555-1201', 'store3421@cvs.com', '5912', 'Drug Stores and Pharmacies', 'Pharmacy', 'OMAHA', 2, 'Active', '2021-08-15'),
            ('dmcl', 'M012', 'S002', 'CVS Pharmacy #3422', 'CVS Health Corp', 'CVS Health Corporation', '2000 E Broad St', 'Columbus', 'OH', '43209', 'US', '614-555-1202', 'store3422@cvs.com', '5912', 'Drug Stores and Pharmacies', 'Pharmacy', 'OMAHA', 2, 'Active', '2021-09-20'),
            ('dmcl', 'M013', 'S001', 'Walgreens #12456', 'Walgreens Boots Alliance', 'Walgreens Boots Alliance Inc', '3000 W Broad St', 'Columbus', 'OH', '43204', 'US', '614-555-1301', 'store12456@walgreens.com', '5912', 'Drug Stores and Pharmacies', 'Pharmacy', 'NORTH', 3, 'Active', '2022-01-10'),

            -- Electronics (MCC 5732)
            ('dmcl', 'M014', 'S001', 'Best Buy Easton', 'Best Buy Co Inc', 'Best Buy Co Inc', '3900 Morse Crossing', 'Columbus', 'OH', '43219', 'US', '614-555-1401', 'easton@bestbuy.com', '5732', 'Electronics Stores', 'Electronics', 'CARDNET', 6, 'Active', '2021-06-01'),
            ('dmcl', 'M014', 'S002', 'Best Buy Polaris', 'Best Buy Co Inc', 'Best Buy Co Inc', '1250 Polaris Pkwy', 'Columbus', 'OH', '43240', 'US', '614-555-1402', 'polaris@bestbuy.com', '5732', 'Electronics Stores', 'Electronics', 'CARDNET', 5, 'Active', '2021-07-15'),
            ('dmcl', 'M015', 'S001', 'Micro Center Columbus', 'Micro Electronics Inc', 'Micro Electronics Incorporated', '747 Bethel Rd', 'Columbus', 'OH', '43214', 'US', '614-555-1501', 'columbus@microcenter.com', '5732', 'Electronics Stores', 'Electronics', 'OMAHA', 8, 'Active', '2020-03-10'),

            -- Home Improvement (MCC 5200)
            ('dmcl', 'M016', 'S001', 'Home Depot #3805', 'Home Depot Inc', 'The Home Depot Inc', '5765 N Hamilton Rd', 'Columbus', 'OH', '43230', 'US', '614-555-1601', 'store3805@homedepot.com', '5200', 'Home Supply Warehouse Stores', 'Home Improvement', 'NORTH', 10, 'Active', '2020-11-15'),
            ('dmcl', 'M016', 'S002', 'Home Depot #3806', 'Home Depot Inc', 'The Home Depot Inc', '2323 W Dublin Granville Rd', 'Columbus', 'OH', '43235', 'US', '614-555-1602', 'store3806@homedepot.com', '5200', 'Home Supply Warehouse Stores', 'Home Improvement', 'NORTH', 8, 'Active', '2021-02-20'),
            ('dmcl', 'M017', 'S001', 'Lowes #2108', 'Lowes Companies Inc', 'Lowes Companies Inc', '3450 Stelzer Rd', 'Columbus', 'OH', '43219', 'US', '614-555-1701', 'store2108@lowes.com', '5200', 'Home Supply Warehouse Stores', 'Home Improvement', 'OMAHA', 8, 'Active', '2021-05-10'),

            -- Department Stores (MCC 5311)
            ('dmcl', 'M018', 'S001', 'Nordstrom Easton', 'Nordstrom Inc', 'Nordstrom Incorporated', '4025 Townsfair Way', 'Columbus', 'OH', '43219', 'US', '614-555-1801', 'easton@nordstrom.com', '5311', 'Department Stores', 'Department Store', 'CARDNET', 12, 'Active', '2019-10-01'),
            ('dmcl', 'M019', 'S001', 'Macys Polaris', 'Macys Inc', 'Macys Incorporated', '1500 Polaris Pkwy', 'Columbus', 'OH', '43240', 'US', '614-555-1901', 'polaris@macys.com', '5311', 'Department Stores', 'Department Store', 'NORTH', 10, 'Active', '2020-01-15'),
            ('dmcl', 'M020', 'S001', 'Target Easton', 'Target Corp', 'Target Corporation', '3880 Morse Crossing', 'Columbus', 'OH', '43219', 'US', '614-555-2001', 'easton@target.com', '5311', 'Department Stores', 'Department Store', 'OMAHA', 15, 'Active', '2019-06-20'),

            -- Hotels (MCC 7011)
            ('dmcl', 'M021', 'S001', 'Hilton Columbus Downtown', 'Hilton Worldwide', 'Hilton Worldwide Holdings Inc', '401 N High St', 'Columbus', 'OH', '43215', 'US', '614-555-2101', 'downtown@hilton.com', '7011', 'Hotels and Motels', 'Hotel', 'CARDNET', 4, 'Active', '2020-03-01'),
            ('dmcl', 'M022', 'S001', 'Marriott Columbus', 'Marriott International', 'Marriott International Inc', '250 N High St', 'Columbus', 'OH', '43215', 'US', '614-555-2201', 'columbus@marriott.com', '7011', 'Hotels and Motels', 'Hotel', 'NORTH', 3, 'Active', '2020-04-15'),
            ('dmcl', 'M023', 'S001', 'Le Meridien Columbus', 'Marriott International', 'Marriott International Inc', '620 N High St', 'Columbus', 'OH', '43215', 'US', '614-555-2301', 'lemeridien@marriott.com', '7011', 'Hotels and Motels', 'Hotel', 'NORTH', 2, 'Active', '2021-08-01'),

            -- Auto Service (MCC 7538)
            ('dmcl', 'M024', 'S001', 'Jiffy Lube #1234', 'Shell Oil Products', 'Shell Oil Products US', '1500 E Dublin Granville Rd', 'Columbus', 'OH', '43229', 'US', '614-555-2401', 'store1234@jiffylube.com', '7538', 'Auto Service Shops', 'Auto Service', 'OMAHA', 2, 'Active', '2022-06-01'),
            ('dmcl', 'M025', 'S001', 'Discount Tire #OH21', 'Discount Tire Co', 'Discount Tire Company', '5500 N Hamilton Rd', 'Columbus', 'OH', '43230', 'US', '614-555-2501', 'oh21@discounttire.com', '7538', 'Auto Service Shops', 'Auto Service', 'CARDNET', 3, 'Active', '2022-07-15'),
            ('dmcl', 'M026', 'S001', 'Firestone Complete Auto Care', 'Bridgestone Americas', 'Bridgestone Americas Inc', '2750 E Main St', 'Columbus', 'OH', '43209', 'US', '614-555-2601', 'columbus@firestone.com', '7538', 'Auto Service Shops', 'Auto Service', 'OMAHA', 4, 'Active', '2022-09-01'),

            -- Healthcare (MCC 8011/8021)
            ('dmcl', 'M027', 'S001', 'OSU Wexner Medical Center', 'Ohio State University', 'The Ohio State University Wexner Medical Center', '410 W 10th Ave', 'Columbus', 'OH', '43210', 'US', '614-555-2701', 'billing@osumc.edu', '8011', 'Doctors', 'Healthcare', 'NORTH', 20, 'Active', '2019-01-01'),
            ('dmcl', 'M028', 'S001', 'OhioHealth Riverside', 'OhioHealth Corp', 'OhioHealth Corporation', '3535 Olentangy River Rd', 'Columbus', 'OH', '43214', 'US', '614-555-2801', 'billing@ohiohealth.com', '8011', 'Doctors', 'Healthcare', 'OMAHA', 15, 'Active', '2019-03-15'),
            ('dmcl', 'M029', 'S001', 'Mount Carmel Health', 'Trinity Health', 'Trinity Health Corporation', '793 W State St', 'Columbus', 'OH', '43222', 'US', '614-555-2901', 'billing@mchs.com', '8011', 'Doctors', 'Healthcare', 'CARDNET', 12, 'Active', '2019-05-20'),
            ('dmcl', 'M030', 'S001', 'Bright Smiles Dental', 'Bright Smiles LLC', 'Bright Smiles Limited Liability Company', '1400 Dublin Rd', 'Columbus', 'OH', '43215', 'US', '614-555-3001', 'info@brightsmiles.com', '8021', 'Dentists and Orthodontists', 'Healthcare', 'OMAHA', 2, 'Active', '2022-01-10')
        AS (CLNT_ID, MRCH_ID, LCTN_ID, LCTN_DBA_NM, CORP_DBA_NM, LGL_NM, ADDR_LN1, CTY, ST_CD, ZIP_CD, CNTRY_CD, PHN_NR, EMAIL_ADDR, MCC, MCC_DESC, BSNS_TYP, PLTF_ID, TRMNL_CT, STAT_CD, ONBRD_DT)
    ) src
) AS src
ON tgt.CLNT_ID = src.CLNT_ID AND tgt.MRCH_ID = src.MRCH_ID AND tgt.LCTN_ID = src.LCTN_ID
WHEN MATCHED THEN UPDATE SET
    LCTN_DBA_NM = src.LCTN_DBA_NM,
    CORP_DBA_NM = src.CORP_DBA_NM,
    LGL_NM = src.LGL_NM,
    ADDR_LN1 = src.ADDR_LN1,
    CTY = src.CTY,
    ST_CD = src.ST_CD,
    ZIP_CD = src.ZIP_CD,
    CNTRY_CD = src.CNTRY_CD,
    PHN_NR = src.PHN_NR,
    EMAIL_ADDR = src.EMAIL_ADDR,
    MCC = src.MCC,
    MCC_DESC = src.MCC_DESC,
    BSNS_TYP = src.BSNS_TYP,
    PLTF_ID = src.PLTF_ID,
    TRMNL_CT = src.TRMNL_CT,
    STAT_CD = src.STAT_CD,
    ONBRD_DT = src.ONBRD_DT::DATE,
    UPD_TS = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT (
    MRCH_KEY, CLNT_ID, MRCH_ID, LCTN_ID, LCTN_DBA_NM, CORP_DBA_NM, LGL_NM,
    ADDR_LN1, CTY, ST_CD, ZIP_CD, CNTRY_CD, PHN_NR, EMAIL_ADDR,
    MCC, MCC_DESC, BSNS_TYP, PLTF_ID, TRMNL_CT, STAT_CD, ONBRD_DT
)
VALUES (
    src.MRCH_KEY, src.CLNT_ID, src.MRCH_ID, src.LCTN_ID, src.LCTN_DBA_NM, src.CORP_DBA_NM, src.LGL_NM,
    src.ADDR_LN1, src.CTY, src.ST_CD, src.ZIP_CD, src.CNTRY_CD, src.PHN_NR, src.EMAIL_ADDR,
    src.MCC, src.MCC_DESC, src.BSNS_TYP, src.PLTF_ID, src.TRMNL_CT, src.STAT_CD, src.ONBRD_DT::DATE
);


-- ============================================================
-- SECTION 5: Synthetic Transaction Data
-- ============================================================

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


-- Only generate if tables are empty
EXECUTE IMMEDIATE $$
BEGIN
    IF ((SELECT COUNT(*) FROM COCO_SDLC_HOL.RAW.CLX_AUTH) = 0) THEN
        CALL COCO_SDLC_HOL.RAW.GENERATE_SYNTHETIC_DATA();
    END IF;
END;
$$;

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

-- ============================================================
-- SECTION 9: Service User + RSA Key Secret
-- ============================================================

-- Service user for SPCS JWT key-pair auth
CREATE USER IF NOT EXISTS COCO_SDLC_HOL_SERVICE_USER
  RSA_PUBLIC_KEY = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4u69NDLk4RWzinMDkhY22V+RgJW2rDlsJHZqYelzzXOWuYIEOsgweNjaE2iipEm6ehTwy+LOisrJlX1CPzfMoCo61e5y7UuZJggA6HxZyv3QjnU5WkyCO10QFJnL2ZIfzOuC3HxlmOICpapsGec4dcL1n4KqoSt6o+dRErfWs9JV/TLxoSGkh4twRqBfSSAN3V1FaunRi3/MU5AquYWLDCvlZKfjZ/GtqB4WbMXhtxx8JNJPkUfDW0zB+vvho0moJQ4iS84Ft/OznkWUtWATP7qZ35N1HIrS8cjIiwaHsJYkwk1xorlEVpPRDvjnEaCAxWjUG3jWqu1ZMds5tPHGBQIDAQAB'
  DEFAULT_ROLE = ATTENDEE_ROLE
  COMMENT = 'Service user for SPCS container key-pair auth';

GRANT ROLE ATTENDEE_ROLE TO USER COCO_SDLC_HOL_SERVICE_USER;

-- Private key stored as Secret for container injection
CREATE OR REPLACE SECRET COCO_SDLC_HOL.PUBLIC.coco_sdlc_hol_private_key
  TYPE = GENERIC_STRING
  SECRET_STRING = '-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDi7r00MuThFbOK
cwOSFjbZX5GAlbasOWwkdmph6XPNc5a5ggQ6yDB42NoTaKKkSbp6FPDL4s6KysmV
fUI/N8ygKjrV7nLtS5kmCADofFnK/dCOdTlaTII7XRAUmcvZkh/M64LcfGWY4gKl
qmwZ5zh1wvWfgqqhK3qj51ESt9az0lX9MvGhIaSHi3BGoF9JIA3dXUVq6dGLf8xT
kCq5hYsMK+Vkp+Nn8a2oHhZsxeG3HHwk0k+RR8NbTMH6++GjSaglDiJLzgW387Oe
RZS1YBM/upnfk3UcitLxyMiLBoewliTCTXGiuURWk9EO+OcRoIDFaNQbeNaq7Vkx
2zm08cYFAgMBAAECggEAAjO7kZVz2J/noqglwiwygvUuzR75/pC94dp/T+A4AwFq
sA9yeVwmpXZcCWFHM/QEmflfJWjxeAtqanR+D21I1rE9agS64atNev7yL7W//+lq
6NL7SAr8t+6ms9h5Nka5EpM8RuW/7TxpahBt2GnnITQ2D3XxMDt8hwYjdU/KegS2
3UGRLNL1YWifAMZTniCucHe5hYXQsa4Eo6VaxbHQcmz8o26GwXoJ4Jm55yqUvxic
9E/RVwl0AKyG5kYwhY1OFv5G6SIoKzlW/FzqsfWsZs0zW2NoqATv7BFv7MvJbVMC
4EL1E/6h36Aoev3v9siWS14r7yN14cqjoJKHkAZRKQKBgQD3inj8t25FSLnIn0V2
hk02eBwo8maKIfkoTZemPWPlfICmJqAVER4cktkAVTx1ZvfDCsyiJqUOEhn2GEVR
YOSdPQMEdnpYzHeviUZQBPguN/hSsgskVFcwXTSFVISKw0Tfj41Mdl/PbuWhoqDY
iai0zNIP+APM1yPjg7ZJT5eoiQKBgQDqr/tB51UNqYibo64UHRhf5lNUsAJgZG3G
mLOnjA7AIiRtoN67KBKk7t2MucUTUatVrrwCsb+TMwvhe1fn+lP1MI45gRY0oFNL
WhfmpLRQUbnhqO1RHOZ4XwQ2uHcmcgB1dFo0ScBXJ092okIOHsMC9P/zdDCynVV6
bPgZ7+WanQKBgQCEwwqil4qXtCqYE/wAVoVg2khYGbGvEgt8dykHatOCCCVDd2HS
Cq04q/WgfRaA7Omi/M7FhK5vfnvYBipfO/VA87EDmruBlp/2UEyarB+jQjd3uq/J
G0br1IFPpQW1God805P312EJcrPL3dogaKxH07YyBFWdbiF8a26/oOV46QKBgCVM
svJWgf4Z48xYx2IK/cTAJp5fGwGW9JuLyYHnkLCYvJFv7/Zu+AeerzeejuPzJvgH
PXpwJbKPemPr5pzH/HALt48MJStYD+T5/LJ7muzpEFH9NzqdDUQ0VcccqlNB6zC/
vVZyIk+3v7lrMHRuDzB5H/ThkpvQxbUffI8iwatBAoGBAKpAXsh3x0IBdlhXjLqn
EgAxcCyzA0s7Ypi6tS+wsFxaGlOgOpYTd7reVxxcBDeFgoQWfp14F05t8b3TflVc
Aw6XTpsI5Pj7pTI08j/mm8JgRnOoahv3V742eUeNCPyqjlu6moUdQ0nfQx/XIuTa
IWtMheYgsvDmdyaBX+joRy9w
-----END PRIVATE KEY-----'
  COMMENT = 'Unencrypted RSA private key for SPCS JWT key-pair auth';

-- ============================================================
-- SECTION 10: Image Repository
-- ============================================================
CREATE IMAGE REPOSITORY IF NOT EXISTS COCO_SDLC_HOL.PUBLIC.coco_sdlc_hol_repo;

-- ============================================================
-- SECTION 11: Semantic View + Cortex Agent
-- ============================================================
USE DATABASE COCO_SDLC_HOL;
USE SCHEMA MARTS;

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'COCO_SDLC_HOL.MARTS',
  $$
name: PAYMENT_ANALYTICS
description: Unified payment analytics semantic layer for Fiserv Performance Intelligence - with merchant relationships

tables:
  # ============================================================================
  # MERCHANTS - Store/Location reference table (enables relationships)
  # ============================================================================
  - name: MERCHANTS
    description: Merchant and store reference data for location-based analytics
    base_table:
      database: COCO_SDLC_HOL
      schema: MARTS
      table: DIM_MERCHANTS
    primary_key:
      columns:
        - MERCHANT_ID
    synonyms:
      - stores
      - locations
      - merchants
      - store locations
    dimensions:
      - name: MERCHANT_ID
        description: Unique merchant identifier
        expr: MERCHANT_ID
        data_type: VARCHAR
        synonyms:
          - MID
          - store ID
      - name: MERCHANT_NAME
        description: Merchant DBA name
        expr: MERCHANT_NAME
        data_type: VARCHAR
        synonyms:
          - store name
          - DBA name
      - name: CORPORATE_NAME
        description: Corporate parent name
        expr: CORPORATE_NAME
        data_type: VARCHAR
        synonyms:
          - corp name
          - parent company
      - name: CITY
        description: Merchant city
        expr: CITY
        data_type: VARCHAR
        synonyms:
          - store city
      - name: STATE
        description: Merchant state
        expr: STATE
        data_type: VARCHAR
        synonyms:
          - store state
      - name: ZIP_CODE
        description: Merchant ZIP code
        expr: ZIP_CODE
        data_type: VARCHAR
      - name: MCC_CODE
        description: Merchant Category Code
        expr: MCC_CODE
        data_type: VARCHAR
        synonyms:
          - MCC
          - merchant category
      - name: MCC_DESCRIPTION
        description: Merchant category description
        expr: MCC_DESCRIPTION
        data_type: VARCHAR
      - name: BUSINESS_TYPE
        description: Type of business
        expr: BUSINESS_TYPE
        data_type: VARCHAR
      - name: STATUS
        description: Merchant status (Active/Inactive)
        expr: STATUS
        data_type: VARCHAR
      - name: ONBOARDING_DATE
        description: Date merchant was onboarded
        expr: ONBOARDING_DATE
        data_type: DATE

  # ============================================================================
  # AUTHORIZATIONS - Authorization transaction records
  # ============================================================================
  - name: AUTHORIZATIONS
    description: Authorization transactions for payment processing
    base_table:
      database: COCO_SDLC_HOL
      schema: MARTS
      table: AUTHORIZATIONS
    primary_key:
      columns:
        - AUTHORIZATION_KEY
    synonyms:
      - authorizations
      - auths
      - auth transactions
      - card transactions
    dimensions:
      - name: AUTHORIZATION_KEY
        description: Unique identifier for authorization
        expr: AUTHORIZATION_KEY
        data_type: VARCHAR
      - name: TRANSACTION_DATE
        description: Date of the authorization transaction
        expr: TRANSACTION_DATE
        data_type: DATE
        synonyms:
          - auth date
          - transaction date
          - txn date
      - name: MERCHANT_ID
        description: Merchant identifier for relationship join
        expr: MERCHANT_ID
        data_type: VARCHAR
      - name: CARD_BRAND
        description: Card network brand (Visa, Mastercard, etc.)
        expr: CARD_BRAND
        data_type: VARCHAR
        synonyms:
          - brand
          - card network
      - name: CARD_TYPE
        description: Type of card product
        expr: CARD_TYPE
        data_type: VARCHAR
      - name: CARD_CATEGORY
        description: Card category (consumer/commercial)
        expr: CARD_CATEGORY
        data_type: VARCHAR
      - name: ENTRY_MODE
        description: Point of sale entry mode (swipe, dip, tap)
        expr: ENTRY_MODE
        data_type: VARCHAR
        synonyms:
          - POS entry mode
      - name: APPROVAL_STATUS
        description: Authorization approval status (Approved/Declined)
        expr: APPROVAL_STATUS
        data_type: VARCHAR
        synonyms:
          - auth status
          - status
      - name: DECLINE_REASON
        description: Reason for declined authorization
        expr: DECLINE_REASON
        data_type: VARCHAR
      - name: PROCESSOR_NAME
        description: Payment processor name
        expr: PROCESSOR_NAME
        data_type: VARCHAR
        synonyms:
          - processor
          - acquirer
    facts:
      - name: TRANSACTION_AMOUNT
        description: Transaction amount in USD
        expr: TRANSACTION_AMOUNT
        data_type: NUMBER
        synonyms:
          - transaction amount
          - auth amount
          - dollar amount
          - amount
      - name: TRANSACTIONS_COUNT
        description: Count of transactions (1 per row)
        expr: TRANSACTIONS_COUNT
        data_type: NUMBER
        synonyms:
          - auth count
          - transaction count

  # ============================================================================
  # SETTLEMENTS - Settlement batch records
  # ============================================================================
  - name: SETTLEMENTS
    description: Settlement and clearing transactions
    base_table:
      database: COCO_SDLC_HOL
      schema: MARTS
      table: SETTLEMENTS
    primary_key:
      columns:
        - SETTLEMENT_KEY
    synonyms:
      - settlements
      - settlement transactions
      - batches
      - clearing
    dimensions:
      - name: SETTLEMENT_KEY
        description: Unique identifier for settlement
        expr: SETTLEMENT_KEY
        data_type: VARCHAR
      - name: SETTLEMENT_DATE
        description: Date of settlement
        expr: SETTLEMENT_DATE
        data_type: DATE
        synonyms:
          - settle date
          - batch date
      - name: MERCHANT_ID
        description: Merchant identifier for relationship join
        expr: MERCHANT_ID
        data_type: VARCHAR
      - name: CARD_BRAND
        description: Card brand
        expr: CARD_BRAND
        data_type: VARCHAR
      - name: CARD_TYPE
        description: Card type
        expr: CARD_TYPE
        data_type: VARCHAR
    facts:
      - name: SALES_COUNT
        description: Number of sales transactions
        expr: SALES_COUNT
        data_type: NUMBER
        synonyms:
          - sales count
          - transaction count
      - name: SALES_AMOUNT
        description: Total sales amount
        expr: SALES_AMOUNT
        data_type: NUMBER
        synonyms:
          - sales amount
          - gross sales
      - name: REFUND_COUNT
        description: Number of refunds
        expr: REFUND_COUNT
        data_type: NUMBER
        synonyms:
          - refund count
          - refunds
      - name: REFUND_AMOUNT
        description: Total refund amount
        expr: REFUND_AMOUNT
        data_type: NUMBER
        synonyms:
          - refund amount
      - name: NET_AMOUNT
        description: Net processed amount
        expr: NET_AMOUNT
        data_type: NUMBER
        synonyms:
          - net amount
          - net sales
          - net volume
      - name: INTERCHANGE_AMOUNT
        description: Interchange fees
        expr: INTERCHANGE_AMOUNT
        data_type: NUMBER
        synonyms:
          - interchange
          - interchange fees

  # ============================================================================
  # DEPOSITS - Funding and deposit records
  # ============================================================================
  - name: DEPOSITS
    description: Funding and deposit records
    base_table:
      database: COCO_SDLC_HOL
      schema: MARTS
      table: DEPOSITS
    primary_key:
      columns:
        - DEPOSIT_KEY
    synonyms:
      - funding
      - deposits
      - payments
      - disbursements
    dimensions:
      - name: DEPOSIT_KEY
        description: Unique identifier for deposit
        expr: DEPOSIT_KEY
        data_type: VARCHAR
      - name: DEPOSIT_DATE
        description: Date of deposit
        expr: DEPOSIT_DATE
        data_type: DATE
        synonyms:
          - funding date
          - bank date
      - name: MERCHANT_ID
        description: Merchant identifier for relationship join
        expr: MERCHANT_ID
        data_type: VARCHAR
      - name: PAYMENT_STATUS
        description: Status of payment
        expr: PAYMENT_STATUS
        data_type: VARCHAR
      - name: PAYMENT_METHOD
        description: Method of payment
        expr: PAYMENT_METHOD
        data_type: VARCHAR
    facts:
      - name: DEPOSIT_AMOUNT
        description: Deposit amount
        expr: DEPOSIT_AMOUNT
        data_type: NUMBER
        synonyms:
          - deposit
          - deposit amount
          - funded amount
      - name: NET_SALES_AMOUNT
        description: Net sales amount
        expr: NET_SALES_AMOUNT
        data_type: NUMBER
        synonyms:
          - net sales
      - name: TOTAL_FEES_AMOUNT
        description: Total fees
        expr: TOTAL_FEES_AMOUNT
        data_type: NUMBER
        synonyms:
          - fees
          - fee amount
      - name: CHARGEBACK_AMOUNT
        description: Chargeback deductions
        expr: CHARGEBACK_AMOUNT
        data_type: NUMBER
        synonyms:
          - chargebacks

  # ============================================================================
  # CHARGEBACKS - Chargeback and dispute records
  # ============================================================================
  - name: CHARGEBACKS
    description: Chargeback and dispute records
    base_table:
      database: COCO_SDLC_HOL
      schema: MARTS
      table: CHARGEBACKS
    primary_key:
      columns:
        - CHARGEBACK_KEY
    synonyms:
      - chargebacks
      - disputes
      - cbk
      - chargeback transactions
    dimensions:
      - name: CHARGEBACK_KEY
        description: Unique identifier for chargeback
        expr: CHARGEBACK_KEY
        data_type: VARCHAR
      - name: DISPUTE_RECEIVED_DATE
        description: Date dispute was received
        expr: DISPUTE_RECEIVED_DATE
        data_type: DATE
        synonyms:
          - chargeback date
          - dispute date
      - name: RESPONSE_DUE_DATE
        description: Due date for response
        expr: RESPONSE_DUE_DATE
        data_type: DATE
      - name: ORIGINAL_TRANSACTION_DATE
        description: Date of original transaction
        expr: ORIGINAL_TRANSACTION_DATE
        data_type: DATE
      - name: MERCHANT_ID
        description: Merchant identifier for relationship join
        expr: MERCHANT_ID
        data_type: VARCHAR
      - name: CHARGEBACK_STATUS
        description: Current status of chargeback
        expr: CHARGEBACK_STATUS
        data_type: VARCHAR
        synonyms:
          - CBK status
          - dispute status
      - name: OUTCOME
        description: Chargeback outcome (Won/Lost/Pending)
        expr: OUTCOME
        data_type: VARCHAR
      - name: LIFECYCLE_STAGE
        description: Current stage in dispute lifecycle
        expr: LIFECYCLE_STAGE
        data_type: VARCHAR
      - name: REASON_CODE
        description: Chargeback reason code
        expr: REASON_CODE
        data_type: VARCHAR
      - name: REASON_DESCRIPTION
        description: Description of chargeback reason
        expr: REASON_DESCRIPTION
        data_type: VARCHAR
      - name: CARD_BRAND
        description: Card brand
        expr: CARD_BRAND
        data_type: VARCHAR
    facts:
      - name: DISPUTE_AMOUNT
        description: Dispute amount
        expr: DISPUTE_AMOUNT
        data_type: NUMBER
        synonyms:
          - dispute amount
          - chargeback amount
          - amount
      - name: TRANSACTION_AMOUNT
        description: Original transaction amount
        expr: TRANSACTION_AMOUNT
        data_type: NUMBER
        synonyms:
          - original amount
      - name: DISPUTES_COUNT
        description: Count of disputes (1 per row)
        expr: DISPUTES_COUNT
        data_type: NUMBER
        synonyms:
          - chargeback count
          - dispute count

  # ============================================================================
  # RETRIEVALS - Retrieval request records
  # ============================================================================
  - name: RETRIEVALS
    description: Retrieval requests
    base_table:
      database: COCO_SDLC_HOL
      schema: MARTS
      table: RETRIEVALS
    primary_key:
      columns:
        - RETRIEVAL_KEY
    synonyms:
      - retrievals
      - retrieval requests
      - copy requests
    dimensions:
      - name: RETRIEVAL_KEY
        description: Unique identifier for retrieval
        expr: RETRIEVAL_KEY
        data_type: VARCHAR
      - name: ORIGINAL_SALE_DATE
        description: Date of original sale
        expr: ORIGINAL_SALE_DATE
        data_type: DATE
      - name: RESPONSE_DUE_DATE
        description: Due date for response
        expr: RESPONSE_DUE_DATE
        data_type: DATE
      - name: MERCHANT_ID
        description: Merchant identifier for relationship join
        expr: MERCHANT_ID
        data_type: VARCHAR
      - name: RETRIEVAL_STATUS
        description: Current retrieval status (Open/Closed/Expired)
        expr: RETRIEVAL_STATUS
        data_type: VARCHAR
        synonyms:
          - RR status
      - name: REASON_CODE
        description: Retrieval reason code
        expr: REASON_CODE
        data_type: VARCHAR
      - name: CARD_BRAND
        description: Card brand
        expr: CARD_BRAND
        data_type: VARCHAR
    facts:
      - name: RETRIEVAL_AMOUNT
        description: Retrieval dollar amount
        expr: RETRIEVAL_AMOUNT
        data_type: NUMBER
        synonyms:
          - amount
          - retrieval amount
      - name: RETRIEVALS_COUNT
        description: Count of retrievals (1 per row)
        expr: RETRIEVALS_COUNT
        data_type: NUMBER
        synonyms:
          - retrieval count

  # ============================================================================
  # ADJUSTMENTS - Fee adjustments and corrections
  # ============================================================================
  - name: ADJUSTMENTS
    description: Fee adjustments and corrections
    base_table:
      database: COCO_SDLC_HOL
      schema: MARTS
      table: ADJUSTMENTS
    primary_key:
      columns:
        - ADJUSTMENT_KEY
    synonyms:
      - adjustments
      - fee adjustments
      - corrections
    dimensions:
      - name: ADJUSTMENT_KEY
        description: Unique identifier for adjustment
        expr: ADJUSTMENT_KEY
        data_type: VARCHAR
      - name: ADJUSTMENT_DATE
        description: Date of adjustment
        expr: ADJUSTMENT_DATE
        data_type: DATE
      - name: MERCHANT_ID
        description: Merchant identifier for relationship join
        expr: MERCHANT_ID
        data_type: VARCHAR
      - name: ADJUSTMENT_TYPE
        description: Type of adjustment (Credit/Debit)
        expr: ADJUSTMENT_TYPE
        data_type: VARCHAR
        synonyms:
          - credit/debit
      - name: ADJUSTMENT_CODE
        description: Adjustment reason code
        expr: ADJUSTMENT_CODE
        data_type: VARCHAR
      - name: ADJUSTMENT_CATEGORY
        description: Category of adjustment
        expr: ADJUSTMENT_CATEGORY
        data_type: VARCHAR
    facts:
      - name: ADJUSTMENT_AMOUNT
        description: Adjustment amount
        expr: ADJUSTMENT_AMOUNT
        data_type: NUMBER
        synonyms:
          - amount
          - adjustment amount

# ==============================================================================
# RELATIONSHIPS - Enable cross-table joins via merchant
# ==============================================================================
relationships:
  - name: AUTH_TO_MERCHANT
    left_table: AUTHORIZATIONS
    right_table: MERCHANTS
    relationship_columns:
      - left_column: MERCHANT_ID
        right_column: MERCHANT_ID
    join_type: left_outer
    relationship_type: many_to_one

  - name: SETTLEMENT_TO_MERCHANT
    left_table: SETTLEMENTS
    right_table: MERCHANTS
    relationship_columns:
      - left_column: MERCHANT_ID
        right_column: MERCHANT_ID
    join_type: left_outer
    relationship_type: many_to_one

  - name: DEPOSIT_TO_MERCHANT
    left_table: DEPOSITS
    right_table: MERCHANTS
    relationship_columns:
      - left_column: MERCHANT_ID
        right_column: MERCHANT_ID
    join_type: left_outer
    relationship_type: many_to_one

  - name: CHARGEBACK_TO_MERCHANT
    left_table: CHARGEBACKS
    right_table: MERCHANTS
    relationship_columns:
      - left_column: MERCHANT_ID
        right_column: MERCHANT_ID
    join_type: left_outer
    relationship_type: many_to_one

  - name: RETRIEVAL_TO_MERCHANT
    left_table: RETRIEVALS
    right_table: MERCHANTS
    relationship_columns:
      - left_column: MERCHANT_ID
        right_column: MERCHANT_ID
    join_type: left_outer
    relationship_type: many_to_one

  - name: ADJUSTMENT_TO_MERCHANT
    left_table: ADJUSTMENTS
    right_table: MERCHANTS
    relationship_columns:
      - left_column: MERCHANT_ID
        right_column: MERCHANT_ID
    join_type: left_outer
    relationship_type: many_to_one

# ==============================================================================
# METRICS - Pre-defined business calculations
# ==============================================================================
metrics:
  - name: APPROVAL_RATE
    description: Percentage of authorizations approved
    expr: SUM(CASE WHEN AUTHORIZATIONS.APPROVAL_STATUS = 'Approved' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(AUTHORIZATIONS.AUTHORIZATION_KEY), 0)
    data_type: NUMBER
    synonyms:
      - auth approval rate
      - approval percentage

  - name: TOTAL_AUTHORIZATION_VOLUME
    description: Total authorization amount
    expr: SUM(AUTHORIZATIONS.TRANSACTION_AMOUNT)
    data_type: NUMBER
    synonyms:
      - total auth volume
      - total authorizations

  - name: AVERAGE_TRANSACTION_AMOUNT
    description: Average transaction amount
    expr: AVG(AUTHORIZATIONS.TRANSACTION_AMOUNT)
    data_type: NUMBER
    synonyms:
      - avg txn amount
      - ATV

  - name: NET_SETTLEMENT_VOLUME
    description: Total net settlement amount
    expr: SUM(SETTLEMENTS.NET_AMOUNT)
    data_type: NUMBER
    synonyms:
      - total settlements
      - net settlements

  - name: TOTAL_DEPOSITS
    description: Total deposit amount
    expr: SUM(DEPOSITS.DEPOSIT_AMOUNT)
    data_type: NUMBER
    synonyms:
      - total funding
      - total funded

  - name: EFFECTIVE_FEE_RATE
    description: Processing fees as percentage of sales
    expr: SUM(DEPOSITS.TOTAL_FEES_AMOUNT) * 100.0 / NULLIF(SUM(DEPOSITS.NET_SALES_AMOUNT), 0)
    data_type: NUMBER
    synonyms:
      - fee percentage
      - fee rate

  - name: CHARGEBACK_VOLUME
    description: Total chargeback amount
    expr: SUM(CHARGEBACKS.DISPUTE_AMOUNT)
    data_type: NUMBER
    synonyms:
      - total chargebacks
      - dispute volume

  - name: CHARGEBACK_WIN_RATE
    description: Percentage of chargebacks won
    expr: SUM(CASE WHEN CHARGEBACKS.OUTCOME = 'Won' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(CHARGEBACKS.CHARGEBACK_KEY), 0)
    data_type: NUMBER
    synonyms:
      - dispute win rate
      - CBK win rate

  - name: CHARGEBACK_RATE
    description: Chargeback count as percentage of total transactions
    expr: COUNT(CHARGEBACKS.CHARGEBACK_KEY) * 100.0 / NULLIF(SUM(AUTHORIZATIONS.TRANSACTIONS_COUNT), 0)
    data_type: NUMBER
    synonyms:
      - CBK rate
      - dispute rate

  - name: NET_ADJUSTMENTS
    description: Net adjustment amount
    expr: SUM(ADJUSTMENTS.ADJUSTMENT_AMOUNT)
    data_type: NUMBER
    synonyms:
      - total adjustments

  - name: RETRIEVAL_FULFILLMENT_RATE
    description: Percentage of retrievals fulfilled (closed)
    expr: SUM(CASE WHEN RETRIEVALS.RETRIEVAL_STATUS = 'CLOSED' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(RETRIEVALS.RETRIEVAL_KEY), 0)
    data_type: NUMBER
    synonyms:
      - RR fulfillment rate
$$,
  FALSE  -- Set to TRUE to validate only without creating
);

CREATE OR REPLACE AGENT PAYMENT_ANALYTICS_AGENT
  COMMENT = 'Cortex Agent for natural language queries on Evolv Performance Intelligence payment data'
  PROFILE = '{"display_name": "Payment Analytics Assistant", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: claude-sonnet-4-5

  orchestration:
    budget:
      seconds: 60
      tokens: 16000

  instructions:
    response: "You are a helpful payment analytics assistant. Provide clear, concise answers about payment transactions, settlements, funding, chargebacks, and merchant performance. Format numerical data appropriately with dollar signs and percentages where relevant."
    orchestration: "Use the PaymentAnalyst tool for all questions related to payment transactions, authorization volumes, settlement data, funding status, chargebacks, retrievals, adjustments, and merchant/store performance metrics."
    system: "You are a payment analytics expert helping users understand their transaction data, identify trends, and analyze merchant performance."
    sample_questions:
      - question: "What was our total authorization volume last month?"
        answer: "I'll analyze the authorization data to calculate the total volume for last month."
      - question: "Which merchants have the highest chargeback rates?"
        answer: "Let me query the chargeback data to identify merchants with elevated dispute rates."
      - question: "Show me the funding status breakdown"
        answer: "I'll retrieve the funding transaction data grouped by payment status."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "PaymentAnalyst"
        description: "Analyzes payment transaction data including authorizations, settlements, funding, chargebacks, retrievals, and adjustments across merchants and stores"

  tool_resources:
    PaymentAnalyst:
      semantic_view: "COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS"
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
  $$;

-- =============================================================================
-- Grant permissions on the agent
-- =============================================================================
GRANT USAGE ON AGENT COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS_AGENT TO ROLE ATTENDEE_ROLE;

-- ============================================================
-- SECTION 12: Final Grants
-- ============================================================
GRANT USAGE ON AGENT COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS_AGENT TO ROLE ATTENDEE_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA COCO_SDLC_HOL.MARTS TO ROLE ATTENDEE_ROLE;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA COCO_SDLC_HOL.MARTS TO ROLE ATTENDEE_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA COCO_SDLC_HOL.STAGING TO ROLE ATTENDEE_ROLE;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA COCO_SDLC_HOL.INTERMEDIATE TO ROLE ATTENDEE_ROLE;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA COCO_SDLC_HOL.MARTS TO ROLE ATTENDEE_ROLE;
