-- HOL Setup Script â€” COCO SDLC Hands-On Lab
-- This script provisions a complete Snowflake HOL environment.
-- Run all sections sequentially in a Snowflake worksheet.
-- The script is idempotent: safe to re-run without creating duplicate data or failing on existing objects.

-- ============================================================
-- SECTION 1: ACCOUNTADMIN Bootstrap
-- ============================================================
USE ROLE ACCOUNTADMIN;

-- Enable cross-region inference so Cortex LLM functions can route to available
-- capacity outside the account's home region. Required for Snowflake Cortex
-- inference (e.g. COMPLETE, CLASSIFY_TEXT) to work; out of scope for the lab
-- but must be enabled before lab exercises that use Cortex AI features.
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';

CREATE ROLE IF NOT EXISTS ATTENDEE_ROLE;
GRANT ROLE ATTENDEE_ROLE TO ROLE SYSADMIN;

GRANT CREATE DATABASE ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE ATTENDEE_ROLE;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE ATTENDEE_ROLE;

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
    COMMENT = 'evolv Payment Analytics hands-on lab environment with sample payment data and reference tables';

USE DATABASE COCO_SDLC_HOL;

CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = 'Raw normalized OLTP-style tables with legacy naming conventions';
CREATE SCHEMA IF NOT EXISTS STAGING;
CREATE SCHEMA IF NOT EXISTS INTERMEDIATE;
CREATE SCHEMA IF NOT EXISTS MARTS;
CREATE SCHEMA IF NOT EXISTS PUBLIC;

-- Grant schema-level privileges to ATTENDEE_ROLE (requires ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;
GRANT ALL PRIVILEGES ON DATABASE COCO_SDLC_HOL TO ROLE ATTENDEE_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA COCO_SDLC_HOL.RAW TO ROLE ATTENDEE_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA COCO_SDLC_HOL.STAGING TO ROLE ATTENDEE_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA COCO_SDLC_HOL.INTERMEDIATE TO ROLE ATTENDEE_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA COCO_SDLC_HOL.MARTS TO ROLE ATTENDEE_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA COCO_SDLC_HOL.PUBLIC TO ROLE ATTENDEE_ROLE;
USE ROLE ATTENDEE_ROLE;

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
        AS src(CLNT_ID, MRCH_ID, LCTN_ID, LCTN_DBA_NM, CORP_DBA_NM, LGL_NM, ADDR_LN1, CTY, ST_CD, ZIP_CD, CNTRY_CD, PHN_NR, EMAIL_ADDR, MCC, MCC_DESC, BSNS_TYP, PLTF_ID, TRMNL_CT, STAT_CD, ONBRD_DT)
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
    -- Pre-evaluate random values for correlated decisions and correct distributions
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
            -- Pre-evaluate randoms for correlated approval/decline decisions
            UNIFORM(0, 1, RANDOM()) AS approval_rand,
            (:BASE_APPROVAL_RATE
                - CASE cb.brand WHEN 'American Express' THEN 0.02 ELSE 0 END
                - CASE WHEN m.MCC = '5732' THEN 0.03 ELSE 0 END
                - CASE WHEN m.MCC = '7011' THEN 0.02 ELSE 0 END
            ) AS adjusted_approval_rate,
            -- Pre-evaluate randoms for correct probability distributions
            UNIFORM(1, 100, RANDOM()) AS pymt_rand,
            UNIFORM(1, 100, RANDOM()) AS entry_rand,
            UNIFORM(1, 100, RANDOM()) AS avs_rand,
            UNIFORM(1, 100, RANDOM()) AS cvv_rand
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
        -- Approval code (correlated with decline reason via approval_rand)
        CASE WHEN r.approval_rand < r.adjusted_approval_rate THEN 1 ELSE 2 END AS APRVL_CD,
        -- Decline reason only populated for declined transactions
        CASE WHEN r.approval_rand >= r.adjusted_approval_rate
             THEN (SELECT DCLN_RSN_ID FROM decline_reasons WHERE SFT_DCLN_FLG = (UNIFORM(0,1,RANDOM()) > 0.6) ORDER BY RANDOM() LIMIT 1)
             ELSE NULL END AS DCLN_RSN_ID,
        CASE WHEN r.approval_rand >= r.adjusted_approval_rate
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
        -- Payment method distribution (single random, correct probabilities)
        CASE
            WHEN r.pymt_rand <= 45 THEN 'Chip'
            WHEN r.pymt_rand <= 75 THEN 'Contactless'
            WHEN r.pymt_rand <= 88 THEN 'Swipe'
            ELSE 'Keyed'
        END AS PYMT_MTHD,
        r.ntwrk AS NTWRK,
        -- Entry mode distribution (single random, correct probabilities)
        CASE
            WHEN r.entry_rand <= 50 THEN 'Chip'
            WHEN r.entry_rand <= 80 THEN 'Contactless'
            ELSE 'Manual'
        END AS ENTRY_MD,
        r.PLTF_ID,
        r.PLTF_ID || '-T' || LPAD((MOD(ABS(RANDOM()), GREATEST(r.TRMNL_CT, 1)) + 1)::VARCHAR, 3, '0') AS TRMNL_ID,
        -- Realistic AVS response codes
        CASE
            WHEN r.avs_rand <= 70 THEN 'Y'
            WHEN r.avs_rand <= 82 THEN 'A'
            WHEN r.avs_rand <= 90 THEN 'Z'
            WHEN r.avs_rand <= 95 THEN 'N'
            WHEN r.avs_rand <= 98 THEN 'U'
            ELSE 'S'
        END AS AVS_RSLT,
        -- Realistic CVV response codes
        CASE
            WHEN r.cvv_rand <= 88 THEN 'M'
            WHEN r.cvv_rand <= 93 THEN 'N'
            WHEN r.cvv_rand <= 97 THEN 'P'
            ELSE 'U'
        END AS CVV_RSLT
    FROM raw_txns r
    LEFT JOIN bins b ON b.CARD_BRND = r.brand
    QUALIFY ROW_NUMBER() OVER (PARTITION BY r.txn_date, r.MRCH_KEY, r.hour_of_day ORDER BY RANDOM()) <=
        CEIL(r.store_frequency * r.day_multiplier * r.month_multiplier);

    -- ==========================================================================
    -- Generate Retry Transactions (from declined authorizations)
    -- Retries reuse the same card (BIN + last 4), merchant, and amount
    -- so that the dbt retry detection window functions can match them.
    -- ~8% of declines are retried; ~65% of retries succeed.
    -- ==========================================================================
    INSERT INTO CLX_AUTH (
        AUTH_ID, CLNT_ID, MRCH_KEY, TXN_DT, TXN_TM, TXN_TS, TXN_AM, APRVL_CD,
        DCLN_RSN_ID, DCLN_RSN_TX, BIN_ID, CARD_LST4, PYMT_MTHD, NTWRK,
        ENTRY_MD, PLTF_ID, TRMNL_ID, AVS_RSLT, CVV_RSLT
    )
    WITH declined_txns AS (
        SELECT
            a.CLNT_ID, a.MRCH_KEY, a.TXN_DT, a.TXN_TS, a.TXN_AM,
            a.BIN_ID, a.CARD_LST4, a.NTWRK, a.PLTF_ID, a.TRMNL_ID
        FROM CLX_AUTH a
        WHERE a.APRVL_CD = 2
          AND UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.08
    ),
    retry_candidates AS (
        SELECT
            *,
            UNIFORM(1, 720, RANDOM()) AS retry_offset_minutes,
            UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS success_rand,
            UNIFORM(1, 100, RANDOM()) AS pymt_rand,
            UNIFORM(1, 100, RANDOM()) AS entry_rand,
            UNIFORM(1, 100, RANDOM()) AS avs_rand,
            UNIFORM(1, 100, RANDOM()) AS cvv_rand
        FROM declined_txns
    )
    SELECT
        UUID_STRING() AS AUTH_ID,
        rc.CLNT_ID,
        rc.MRCH_KEY,
        TIMESTAMPADD(MINUTE, rc.retry_offset_minutes, rc.TXN_TS)::DATE AS TXN_DT,
        TIMESTAMPADD(MINUTE, rc.retry_offset_minutes, rc.TXN_TS)::TIME AS TXN_TM,
        TIMESTAMPADD(MINUTE, rc.retry_offset_minutes, rc.TXN_TS) AS TXN_TS,
        rc.TXN_AM,
        CASE WHEN rc.success_rand < 0.65 THEN 1 ELSE 2 END AS APRVL_CD,
        CASE WHEN rc.success_rand >= 0.65
             THEN (SELECT DCLN_RSN_ID FROM DCLN_RSN_CD WHERE DCLN_RSN_ID != 'D042' ORDER BY RANDOM() LIMIT 1)
             ELSE NULL END AS DCLN_RSN_ID,
        CASE WHEN rc.success_rand >= 0.65
             THEN (SELECT DCLN_RSN_DESC FROM DCLN_RSN_CD WHERE DCLN_RSN_ID != 'D042' ORDER BY RANDOM() LIMIT 1)
             ELSE NULL END AS DCLN_RSN_TX,
        rc.BIN_ID,
        rc.CARD_LST4,
        CASE
            WHEN rc.pymt_rand <= 45 THEN 'Chip'
            WHEN rc.pymt_rand <= 75 THEN 'Contactless'
            WHEN rc.pymt_rand <= 88 THEN 'Swipe'
            ELSE 'Keyed'
        END AS PYMT_MTHD,
        rc.NTWRK,
        CASE
            WHEN rc.entry_rand <= 50 THEN 'Chip'
            WHEN rc.entry_rand <= 80 THEN 'Contactless'
            ELSE 'Manual'
        END AS ENTRY_MD,
        rc.PLTF_ID,
        rc.TRMNL_ID,
        CASE
            WHEN rc.avs_rand <= 70 THEN 'Y'
            WHEN rc.avs_rand <= 82 THEN 'A'
            WHEN rc.avs_rand <= 90 THEN 'Z'
            WHEN rc.avs_rand <= 95 THEN 'N'
            WHEN rc.avs_rand <= 98 THEN 'U'
            ELSE 'S'
        END AS AVS_RSLT,
        CASE
            WHEN rc.cvv_rand <= 88 THEN 'M'
            WHEN rc.cvv_rand <= 93 THEN 'N'
            WHEN rc.cvv_rand <= 97 THEN 'P'
            ELSE 'U'
        END AS CVV_RSLT
    FROM retry_candidates rc;

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
            m.MCC,
            m.PLTF_ID
        FROM CLX_AUTH a
        JOIN GLB_BIN b ON a.BIN_ID = b.BIN_ID
        JOIN CLX_MRCH_MSTR m ON a.MRCH_KEY = m.MRCH_KEY
        WHERE a.APRVL_CD = 1
    ),
    settle_agg AS (
        SELECT
            CLNT_ID,
            MRCH_KEY,
            TXN_DT,
            CARD_BRND,
            MAX(MCC) AS MCC,
            MAX(CARD_TYP) AS CARD_TYP,
            MAX(NTWRK) AS NTWRK,
            MAX(PLTF_ID) AS PLTF_ID,
            COUNT(*) AS SALES_CT,
            SUM(TXN_AM) AS SALES_AM
        FROM approved_auths
        GROUP BY TXN_DT, CARD_BRND, MRCH_KEY, CLNT_ID
    )
    SELECT
        UUID_STRING() AS SETTLE_ID,
        CLNT_ID,
        MRCH_KEY,
        DATEADD(DAY, 1, TXN_DT) AS RCRD_DT,
        TXN_DT AS BTCH_DT,
        DATEADD(DAY, 1, TXN_DT) AS PRCS_DT,
        SALES_CT,
        FLOOR(SALES_CT *
            CASE MCC
                WHEN '5732' THEN 0.045
                WHEN '5311' THEN 0.035
                WHEN '7011' THEN 0.025
                ELSE 0.015
            END
        )::NUMBER AS RFND_CT,
        SALES_CT - FLOOR(SALES_CT *
            CASE MCC
                WHEN '5732' THEN 0.045
                WHEN '5311' THEN 0.035
                WHEN '7011' THEN 0.025
                ELSE 0.015
            END
        )::NUMBER AS NET_CT,
        SALES_AM,
        SALES_AM *
            CASE MCC
                WHEN '5732' THEN 0.045
                WHEN '5311' THEN 0.035
                WHEN '7011' THEN 0.025
                ELSE 0.015
            END AS RFND_AM,
        SALES_AM * 0.98 AS PRCS_NET_AM,
        SALES_AM *
            CASE CARD_BRND
                WHEN 'American Express' THEN 0.029
                WHEN 'Discover' THEN 0.024
                ELSE 0.022
            END AS DSCN_AM,
        SALES_AM *
            CASE
                WHEN CARD_BRND = 'American Express' THEN 0.021
                WHEN CARD_TYP = 'Debit' THEN 0.0073
                ELSE 0.018
            END AS INTCHG_AM,
        CARD_BRND,
        CARD_TYP,
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
        PLTF_ID,
        NTWRK
    FROM settle_agg;

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
        s.CLNT_ID,
        s.MRCH_KEY,
        DATEADD(DAY, 1, s.RCRD_DT) AS FUNDED_DT,
        s.RCRD_DT AS SETTLE_DT,
        DATEADD(DAY, 1, s.RCRD_DT) AS EXPCT_DT,
        SUM(s.PRCS_NET_AM) - SUM(s.DSCN_AM) AS DPST_AM,
        SUM(s.PRCS_NET_AM) AS NET_SALES_AM,
        SUM(s.DSCN_AM) AS FEES_AM,
        SUM(s.PRCS_NET_AM) * 0.003 AS CBK_AM,
        0 AS ADJ_AM,
        SUM(s.PRCS_NET_AM) * 0.001 AS RSRV_AM,
        SUM(s.SALES_CT) AS ITEM_CT,
        SUM(s.SALES_CT) AS SALES_CT,
        SUM(s.RFND_CT) AS RFND_CT,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.02 THEN 'Completed' ELSE 'Pending' END AS PYMT_STAT,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.15 THEN 'ACH' ELSE 'Wire' END AS PYMT_MTHD,
        LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0') AS DDA_LST4,
        -- Diversified bank names by platform
        CASE m.PLTF_ID
            WHEN 'OMAHA' THEN 'Chase Bank NA'
            WHEN 'NORTH' THEN 'Wells Fargo Bank'
            WHEN 'CARDNET' THEN 'Bank of America NA'
            WHEN 'BAMS' THEN 'US Bank NA'
            ELSE 'PNC Bank NA'
        END AS BANK_NM,
        'Settlement' AS TXN_CTGR,
        'Net Funding' AS FUND_TYP,
        'FND-' || TO_CHAR(s.RCRD_DT, 'YYYYMMDD') || '-' || s.MRCH_KEY AS BTCH_REF,
        'ACH' || LPAD(UNIFORM(100000000, 999999999, RANDOM())::VARCHAR, 15, '0') AS ACH_TRC,
        m.PLTF_ID
    FROM CLX_SETTLE s
    JOIN CLX_MRCH_MSTR m ON s.MRCH_KEY = m.MRCH_KEY
    GROUP BY s.RCRD_DT, s.MRCH_KEY, s.CLNT_ID, m.PLTF_ID;

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
    ),
    -- Pre-evaluate random values for correct probability distributions
    cbk_candidates AS (
        SELECT
            a.*,
            cr.CBK_RSN_ID,
            cr.RSN_DESC,
            cr.RSN_CTGR,
            UNIFORM(1, 100, RANDOM()) AS stat_rand,
            UNIFORM(1, 100, RANDOM()) AS winloss_rand,
            UNIFORM(1, 100, RANDOM()) AS cycle_rand
        FROM auth_with_brand a
        CROSS JOIN cbk_reasons cr
        WHERE cr.NTWRK = CASE a.CARD_BRND
                WHEN 'Visa' THEN 'Visa'
                WHEN 'Mastercard' THEN 'Mastercard'
                WHEN 'American Express' THEN 'Amex'
                ELSE 'Discover' END
          AND UNIFORM(0, 1, RANDOM()) < GET_CHARGEBACK_RATE(a.MCC)
        QUALIFY ROW_NUMBER() OVER (PARTITION BY a.AUTH_ID ORDER BY RANDOM()) = 1
    )
    SELECT
        UUID_STRING() AS CBK_ID,
        c.CLNT_ID,
        c.MRCH_KEY,
        'CBK-' || DATE_PART(YEAR, c.TXN_DT) || '-' || LPAD(ROW_NUMBER() OVER (ORDER BY RANDOM())::VARCHAR, 8, '0') AS CASE_NR,
        'ARN' || LPAD(UNIFORM(100000000000, 999999999999, RANDOM())::VARCHAR, 15, '0') AS ARN,
        DATEADD(DAY, UNIFORM(15, 45, RANDOM()), c.TXN_DT) AS DSPUT_RCVD_DT,
        c.TXN_DT AS ORIG_TXN_DT,
        DATEADD(DAY, UNIFORM(15, 45, RANDOM()) + 30, c.TXN_DT) AS DUE_DT,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.3
             THEN DATEADD(DAY, UNIFORM(20, 60, RANDOM()), c.TXN_DT)
             ELSE NULL END AS RSLVD_DT,
        c.TXN_AM AS DSPUT_AM,
        c.TXN_AM AS TXN_AM,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.6 THEN c.TXN_AM ELSE 0 END AS REPR_AM,
        -- Chargeback status (single random, correct distribution)
        CASE
            WHEN c.stat_rand BETWEEN 1 AND 15 THEN 'Open'
            WHEN c.stat_rand BETWEEN 16 AND 35 THEN 'Pending'
            WHEN c.stat_rand BETWEEN 36 AND 60 THEN 'Won'
            WHEN c.stat_rand BETWEEN 61 AND 85 THEN 'Lost'
            ELSE 'Closed'
        END AS CBK_STAT,
        -- Win/loss outcome (single random, correct distribution)
        CASE
            WHEN c.winloss_rand BETWEEN 1 AND 35 THEN 'Won'
            WHEN c.winloss_rand BETWEEN 36 AND 85 THEN 'Lost'
            ELSE NULL
        END AS CBK_WIN_LOSS,
        -- Chargeback cycle (single random, correct distribution)
        CASE
            WHEN c.cycle_rand BETWEEN 1 AND 75 THEN '1st Chargeback'
            WHEN c.cycle_rand BETWEEN 76 AND 90 THEN '2nd Chargeback'
            WHEN c.cycle_rand BETWEEN 91 AND 97 THEN 'Pre-Arbitration'
            ELSE 'Arbitration'
        END AS CBK_CYCL,
        c.CBK_RSN_ID,
        c.RSN_DESC AS RSN_DESC_OVRD,
        c.RSN_CTGR,
        c.CARD_BRND,
        c.CARD_LST4,
        c.LCTN_DBA_NM AS MRCH_NM,
        UNIFORM(0,1,RANDOM()) > 0.3 AS RESP_SENT_FLG,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.3
             THEN DATEADD(DAY, UNIFORM(5, 25, RANDOM()), c.TXN_DT)
             ELSE NULL END AS RESP_DT,
        UNIFORM(0,1,RANDOM()) > 0.4 AS DOCS_SBMTD_FLG,
        c.PLTF_ID
    FROM cbk_candidates c;

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
    ),
    -- Pre-evaluate random values for correct probability distributions
    rtrvl_candidates AS (
        SELECT
            a.*,
            UNIFORM(1, 100, RANDOM()) AS stat_rand,
            UNIFORM(1, 100, RANDOM()) AS fulfmt_rand,
            UNIFORM(1, 100, RANDOM()) AS rsn_rand
        FROM auth_with_brand a
        WHERE UNIFORM(0, 1, RANDOM()) < (GET_CHARGEBACK_RATE(a.MCC) * 2.5)
    )
    SELECT
        UUID_STRING() AS RTRVL_ID,
        r.CLNT_ID,
        r.MRCH_KEY,
        'ARN' || LPAD(UNIFORM(100000000000, 999999999999, RANDOM())::VARCHAR, 15, '0') AS ARN,
        DATEADD(DAY, UNIFORM(5, 25, RANDOM()), r.TXN_DT) AS RTRVL_RCVD_DT,
        r.TXN_DT AS SALE_DT,
        DATEADD(DAY, UNIFORM(5, 25, RANDOM()) + 20, r.TXN_DT) AS DUE_DT,
        CASE WHEN UNIFORM(0, 1, RANDOM()) < 0.70
             THEN DATEADD(DAY, UNIFORM(5, 25, RANDOM()) + 10, r.TXN_DT)
             ELSE NULL END AS FULFMT_DT,
        r.TXN_AM AS RTRVL_AM,
        -- Retrieval status (single random, correct distribution)
        CASE
            WHEN r.stat_rand <= 25 THEN 'Open'
            WHEN r.stat_rand <= 50 THEN 'Fulfilled'
            WHEN r.stat_rand <= 75 THEN 'Closed'
            ELSE 'Expired'
        END AS RTRVL_STAT,
        -- Fulfillment status (single random, correct distribution)
        CASE
            WHEN r.fulfmt_rand <= 70 THEN 'Complete'
            WHEN r.fulfmt_rand <= 90 THEN 'Partial'
            ELSE 'None'
        END AS FULFMT_STAT,
        'RQ' || LPAD(UNIFORM(1, 15, RANDOM())::VARCHAR, 2, '0') AS RSN_CD,
        -- Reason description (single random, correct distribution)
        CASE
            WHEN r.rsn_rand <= 30 THEN 'Cardholder Does Not Recognize'
            WHEN r.rsn_rand <= 50 THEN 'Cardholder Request for Copy'
            WHEN r.rsn_rand <= 70 THEN 'Fraud Investigation'
            WHEN r.rsn_rand <= 85 THEN 'Compliance Review'
            ELSE 'Issuer Request'
        END AS RSN_DESC,
        r.CARD_BRND,
        r.CARD_LST4,
        'Transaction receipt, signed copy' AS DOCS_REQD,
        UNIFORM(0, 1, RANDOM()) > 0.3 AS DOCS_SBMTD_FLG,
        CASE WHEN UNIFORM(0,1,RANDOM()) > 0.4 THEN 'Portal' ELSE 'Fax' END AS SBMSN_MTHD,
        r.PLTF_ID
    FROM rtrvl_candidates r;

    SELECT COUNT(*) INTO :total_rtv FROM CLX_RTRVL;

    -- ==========================================================================
    -- Generate Adjustments (fees, credits, monthly charges)
    -- ==========================================================================
    INSERT INTO CLX_ADJ (
        ADJ_ID, CLNT_ID, MRCH_KEY, ADJ_REF_NR, ADJ_DT, EFF_DT, ORIG_TXN_DT,
        ADJ_AM, ADJ_TYP_CD, ADJ_CD, ADJ_DESC, ADJ_CTGR, FEE_TYP_CD,
        FEE_DESC, RLTD_TXN_ID, ADJ_STAT, PLTF_ID, CRT_BY
    )
    WITH adj_types AS (
        SELECT 'C' AS type_cd, 'Monthly Volume Bonus' AS desc_tx, 'CREDIT' AS category, 'MVB' AS adj_cd, 'VOL' AS fee_cd, 'Volume incentive program' AS fee_desc_tx, 50.00 AS min_am, 500.00 AS max_am, 0.05 AS frequency UNION ALL
        SELECT 'D', 'Monthly Statement Fee', 'FEE', 'MSF', 'STMT', 'Monthly account statement generation', 5.00, 25.00, 0.40 UNION ALL
        SELECT 'D', 'PCI Compliance Fee', 'FEE', 'PCI', 'CMPL', 'PCI-DSS compliance program fee', 19.95, 79.95, 0.30 UNION ALL
        SELECT 'C', 'Rate Adjustment Credit', 'RATE', 'RAC', 'RATE', 'Interchange rate correction', 10.00, 150.00, 0.08 UNION ALL
        SELECT 'D', 'Equipment Lease Fee', 'FEE', 'EQP', 'EQMT', 'POS terminal lease agreement', 29.95, 99.95, 0.25 UNION ALL
        SELECT 'D', 'Chargeback Fee', 'FEE', 'CBK', 'DISP', 'Dispute management processing fee', 15.00, 35.00, 0.15 UNION ALL
        SELECT 'C', 'Early Settlement Bonus', 'PROMO', 'ESB', 'PRMO', 'Early settlement incentive program', 25.00, 200.00, 0.03 UNION ALL
        SELECT 'D', 'Annual Account Fee', 'FEE', 'ANN', 'ANNL', 'Annual merchant account maintenance', 79.00, 199.00, 0.02 UNION ALL
        SELECT 'D', 'Batch Processing Fee', 'FEE', 'BPF', 'BTCH', 'Daily batch settlement processing', 0.10, 5.00, 0.50 UNION ALL
        SELECT 'D', 'Network Access Fee', 'FEE', 'NAF', 'NTWK', 'Card network access and routing', 4.95, 14.95, 0.20 UNION ALL
        SELECT 'C', 'Referral Credit', 'PROMO', 'REF', 'RFER', 'Merchant referral bonus program', 50.00, 250.00, 0.02
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
            WHEN 'C' THEN (at.min_am + (at.max_am - at.min_am) * UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()))::NUMBER(15,2)
            ELSE -(at.min_am + (at.max_am - at.min_am) * UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()))::NUMBER(15,2)
        END AS ADJ_AM,
        at.type_cd AS ADJ_TYP_CD,
        at.adj_cd AS ADJ_CD,
        at.desc_tx AS ADJ_DESC,
        at.category AS ADJ_CTGR,
        at.fee_cd AS FEE_TYP_CD,
        at.fee_desc_tx AS FEE_DESC,
        NULL AS RLTD_TXN_ID,
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
-- SECTION 6: dbt Project Deployment from Git
-- ============================================================
-- Instead of creating staging views, intermediate dynamic tables,
-- and marts dynamic tables manually, we deploy a dbt project from
-- Git that creates all transformation objects automatically.
-- ============================================================

-- Step 6a: GitHub API Integration (requires ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION GITHUB_EVOLV_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/evolvconsulting')
  ENABLED = TRUE;

-- Step 6b: Git Repository Object
CREATE OR REPLACE GIT REPOSITORY COCO_SDLC_HOL.PUBLIC.HOL_REPO
  API_INTEGRATION = GITHUB_EVOLV_INTEGRATION
  ORIGIN = 'https://github.com/evolvconsulting/coco_sdlc_hol.git';

GRANT READ ON GIT REPOSITORY COCO_SDLC_HOL.PUBLIC.HOL_REPO
  TO ROLE ATTENDEE_ROLE;

-- Step 6c: External Access Integration for dbt packages (hub.getdbt.com)
CREATE OR REPLACE NETWORK RULE COCO_SDLC_HOL.PUBLIC.DBT_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'codeload.github.com');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION DBT_HUB_EAI
  ALLOWED_NETWORK_RULES = (COCO_SDLC_HOL.PUBLIC.DBT_NETWORK_RULE)
  ENABLED = TRUE;

-- Step 6d: Deploy dbt Project from Git Repository
USE ROLE SYSADMIN;

CREATE OR REPLACE DBT PROJECT COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS
  FROM '@COCO_SDLC_HOL.PUBLIC.HOL_REPO/branches/main/packages/dbt'
  DEFAULT_TARGET = 'dev'
  EXTERNAL_ACCESS_INTEGRATIONS = (DBT_HUB_EAI)
  COMMENT = 'evolv Payment Analytics - dbt project deployed from GitHub';

-- Step 6e: Grant Access
GRANT USAGE ON DBT PROJECT COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS
  TO ROLE ATTENDEE_ROLE;

-- Step 6f: Execute dbt project to create staging views, intermediate
-- dynamic tables, and marts dynamic tables
EXECUTE DBT PROJECT COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS
  ARGS = 'run';

USE ROLE ATTENDEE_ROLE;

-- ============================================================
-- SECTION 7: Service User + RSA Key Secret
-- ============================================================
USE ROLE ACCOUNTADMIN;

-- Service user for SPCS JWT key-pair auth
CREATE USER IF NOT EXISTS COCO_SDLC_HOL_SERVICE_USER
  RSA_PUBLIC_KEY = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4u69NDLk4RWzinMDkhY22V+RgJW2rDlsJHZqYelzzXOWuYIEOsgweNjaE2iipEm6ehTwy+LOisrJlX1CPzfMoCo61e5y7UuZJggA6HxZyv3QjnU5WkyCO10QFJnL2ZIfzOuC3HxlmOICpapsGec4dcL1n4KqoSt6o+dRErfWs9JV/TLxoSGkh4twRqBfSSAN3V1FaunRi3/MU5AquYWLDCvlZKfjZ/GtqB4WbMXhtxx8JNJPkUfDW0zB+vvho0moJQ4iS84Ft/OznkWUtWATP7qZ35N1HIrS8cjIiwaHsJYkwk1xorlEVpPRDvjnEaCAxWjUG3jWqu1ZMds5tPHGBQIDAQAB'
  DEFAULT_ROLE = ATTENDEE_ROLE
  COMMENT = 'Service user for SPCS container key-pair auth';

GRANT ROLE ATTENDEE_ROLE TO USER COCO_SDLC_HOL_SERVICE_USER;

USE ROLE ATTENDEE_ROLE;

-- Private key stored as Secret for container injection
CREATE OR REPLACE SECRET COCO_SDLC_HOL.PUBLIC.coco_sdlc_hol_private_key
  TYPE = GENERIC_STRING
  SECRET_STRING = '-----BEGIN PRIVATE KEY-----
<PASTE_YOUR_UNENCRYPTED_PRIVATE_KEY_HERE>
-----END PRIVATE KEY-----'
  COMMENT = 'Unencrypted RSA private key for SPCS JWT key-pair auth';

-- ============================================================
-- SECTION 8: Semantic View + Cortex Agent
-- ============================================================
USE DATABASE COCO_SDLC_HOL;
USE SCHEMA MARTS;

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'COCO_SDLC_HOL.MARTS',
  $$
name: PAYMENT_ANALYTICS
description: Unified payment analytics semantic layer for evolv Payment Analytics - with merchant relationships

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
      - name: RETRIEVAL_RECEIVED_DATE
        description: Date the retrieval request was received
        expr: RETRIEVAL_RECEIVED_DATE
        data_type: DATE
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
  COMMENT = 'Cortex Agent for natural language queries on evolv Payment Analytics data'
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

-- ============================================================
-- SECTION 9: Final Grants
-- ============================================================
GRANT USAGE ON AGENT COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS_AGENT TO ROLE ATTENDEE_ROLE;
GRANT USAGE ON DBT PROJECT COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS TO ROLE ATTENDEE_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA COCO_SDLC_HOL.MARTS TO ROLE ATTENDEE_ROLE;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA COCO_SDLC_HOL.MARTS TO ROLE ATTENDEE_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA COCO_SDLC_HOL.STAGING TO ROLE ATTENDEE_ROLE;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA COCO_SDLC_HOL.INTERMEDIATE TO ROLE ATTENDEE_ROLE;
