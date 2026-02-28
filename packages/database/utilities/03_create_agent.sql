-- =============================================================================
-- EVOLV PERFORMANCE INTELLIGENCE - Cortex Agent
-- =============================================================================
-- This script creates the Cortex Agent for natural language query processing
-- using the Payment Analytics semantic view.
-- =============================================================================

USE SCHEMA COCO_SDLC_HOL.MARTS;

-- =============================================================================
-- Create the Cortex Agent
-- =============================================================================

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
GRANT USAGE ON AGENT COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS_AGENT TO ROLE SYSADMIN;

-- =============================================================================
-- Sample questions the agent can answer:
-- =============================================================================
/*
Authorization Analytics:
- What is our approval rate this month?
- Show me the decline reasons breakdown
- What's the average ticket size by card brand?
- How many transactions did we process yesterday?
- Which merchants have the highest decline rates?

Settlement Analytics:
- What was our net settlement volume last week?
- Show me the interchange fees by card brand
- What's our effective processing rate?
- Compare sales vs refunds this month

Funding Analytics:
- How much was deposited yesterday?
- Show me the fee breakdown for funding
- What's the total chargeback deduction this month?

Chargeback Analytics:
- How many open chargebacks do we have?
- What's our chargeback win rate?
- Show me chargebacks by reason code
- Which merchants have the most disputes?

Retrieval Analytics:
- How many open retrieval requests?
- What's our fulfillment rate?
- Show me retrievals due this week

Adjustment Analytics:
- What are the total credits vs debits this month?
- Show me adjustments by category
- What fees were applied last month?
*/

-- =============================================================================
-- Verification queries to test the semantic view directly
-- =============================================================================

-- Test 1: Authorization summary (using MARTS tables)
SELECT 
    'Authorization Summary' AS report,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN approval_status = 'Approved' THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN approval_status = 'Declined' THEN 1 ELSE 0 END) AS declined,
    ROUND(AVG(CASE WHEN approval_status = 'Approved' THEN 100.0 ELSE 0 END), 2) AS approval_rate
FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS;

-- Test 2: Card brand breakdown (using MARTS tables)
SELECT 
    card_brand,
    COUNT(*) AS transactions,
    SUM(transaction_amount) AS total_volume,
    ROUND(AVG(CASE WHEN approval_status = 'Approved' THEN 100.0 ELSE 0 END), 2) AS approval_rate
FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS
GROUP BY card_brand
ORDER BY transactions DESC;

-- Test 3: Chargeback summary (using MARTS tables)
SELECT 
    chargeback_status,
    COUNT(*) AS count,
    SUM(dispute_amount) AS dispute_amount
FROM COCO_SDLC_HOL.MARTS.CHARGEBACKS
GROUP BY chargeback_status;
