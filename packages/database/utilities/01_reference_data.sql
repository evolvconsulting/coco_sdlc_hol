-- =============================================================================
-- Reference Data Population Script
-- =============================================================================
-- This script populates dimension/reference tables in the RAW schema.
-- Run this after 00_create_raw_schema.sql has created the schema structure.
--
-- Tables populated:
--   - PLTF_REF (Platform Reference)
--   - GLB_BIN (Global BIN Reference)
--   - DCLN_RSN_CD (Decline Reason Codes)
--   - CBK_RSN_CD (Chargeback Reason Codes)
--   - CLX_MRCH_MSTR (Merchant Master)
-- =============================================================================

USE DATABASE COCO_SDLC_HOL;
USE SCHEMA RAW;


-- =============================================================================
-- PLTF_REF: Platform Reference Data
-- =============================================================================
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


-- =============================================================================
-- GLB_BIN: Global BIN Reference Data
-- =============================================================================
-- BIN data with card brand, type, level, and issuer information
-- =============================================================================
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


-- =============================================================================
-- DCLN_RSN_CD: Decline Reason Codes
-- =============================================================================
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


-- =============================================================================
-- CBK_RSN_CD: Chargeback Reason Codes by Network
-- =============================================================================
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


-- =============================================================================
-- CLX_MRCH_MSTR: Merchant Master (Store Portfolio)
-- =============================================================================
-- Diverse merchant portfolio across multiple industries
-- =============================================================================
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


-- =============================================================================
-- Verification
-- =============================================================================
SELECT 'Reference data loaded successfully' AS status;

SELECT 
    'PLTF_REF' AS table_name, COUNT(*) AS row_count FROM PLTF_REF
UNION ALL SELECT 'GLB_BIN', COUNT(*) FROM GLB_BIN
UNION ALL SELECT 'DCLN_RSN_CD', COUNT(*) FROM DCLN_RSN_CD
UNION ALL SELECT 'CBK_RSN_CD', COUNT(*) FROM CBK_RSN_CD
UNION ALL SELECT 'CLX_MRCH_MSTR', COUNT(*) FROM CLX_MRCH_MSTR
ORDER BY table_name;
