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

-- =============================================================================
-- Grant access (uncomment and modify role as needed)
-- =============================================================================
-- GRANT SELECT ON SEMANTIC VIEW COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS 
--   TO ROLE ANALYST_ROLE;
