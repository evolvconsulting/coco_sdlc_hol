-- =============================================================================
-- RAW Schema DDL - Normalized OLTP-style Tables
-- =============================================================================
-- This script creates the database, RAW schema, and all tables that serve as
-- the source layer for the dbt medallion architecture. Tables use abbreviated
-- column names to emulate legacy OLTP systems.
--
-- Usage: Run this script once to create the schema structure.
-- Then run 01_reference_data.sql and 02_generate_transactions.sql to populate.
-- =============================================================================

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS COCO_SDLC_HOL
    COMMENT = 'Performance Intelligence Dashboard for Fiserv payment analytics';

USE DATABASE COCO_SDLC_HOL;

-- Create RAW schema if not exists
CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = 'Raw normalized OLTP-style tables with legacy naming conventions';

USE SCHEMA RAW;

-- =============================================================================
-- DIMENSION TABLES (Reference Data)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Platform Reference
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


-- -----------------------------------------------------------------------------
-- Global BIN Reference
-- -----------------------------------------------------------------------------
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


-- -----------------------------------------------------------------------------
-- Decline Reason Codes
-- -----------------------------------------------------------------------------
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


-- -----------------------------------------------------------------------------
-- Chargeback Reason Codes
-- -----------------------------------------------------------------------------
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


-- -----------------------------------------------------------------------------
-- Merchant Master
-- -----------------------------------------------------------------------------
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


-- =============================================================================
-- FACT TABLES (Transactional Data)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Authorization Transactions
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


-- -----------------------------------------------------------------------------
-- Settlement Transactions
-- -----------------------------------------------------------------------------
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


-- -----------------------------------------------------------------------------
-- Funding/Deposit Transactions
-- -----------------------------------------------------------------------------
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


-- -----------------------------------------------------------------------------
-- Chargeback Transactions
-- -----------------------------------------------------------------------------
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


-- -----------------------------------------------------------------------------
-- Retrieval Requests
-- -----------------------------------------------------------------------------
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


-- -----------------------------------------------------------------------------
-- Adjustments
-- -----------------------------------------------------------------------------
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


-- =============================================================================
-- Grant permissions
-- =============================================================================
GRANT USAGE ON SCHEMA RAW TO ROLE SYSADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA RAW TO ROLE SYSADMIN;

-- Verification
SELECT 'RAW schema created with ' || COUNT(*) || ' tables' AS status 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'RAW';
