import { NextRequest, NextResponse } from 'next/server';
import { isConfigured } from '@/lib/snowflake';

// Database configuration from environment
const DATABASE = process.env.SNOWFLAKE_DATABASE || 'COCO_SDLC_HOL';
const SCHEMA = process.env.SNOWFLAKE_SCHEMA || 'CLEA';

// Domain metadata configuration
const domainMetadata = {
  authorization: {
    tableName: 'AUTH_DMCL_V1',
    fullTableName: `${DATABASE}.${SCHEMA}.AUTH_DMCL_V1`,
    description: 'Real-time authorization transactions',
    dimensions: [
      { name: 'TXNDATE', type: 'date', label: 'Transaction Date' },
      { name: 'CARD_BRND', type: 'string', label: 'Card Brand' },
      { name: 'APPROVALCODE', type: 'number', label: 'Approval Code' },
      { name: 'LCTN_DBA_NM', type: 'string', label: 'Merchant Name' },
      { name: 'CORP_DBA_NM', type: 'string', label: 'Corporation' },
      { name: 'DECLINEREASON', type: 'string', label: 'Decline Reason' },
      { name: 'PLTF_ID', type: 'number', label: 'Processor ID' },
      { name: 'PAYMENTMETHOD', type: 'string', label: 'Payment Method' },
      { name: 'NETWORK', type: 'string', label: 'Network' },
    ],
    measures: [
      { name: 'AMOUNT', type: 'number', label: 'Amount', aggregation: 'SUM' },
      { name: 'TXNCOUNT', type: 'number', label: 'Transaction Count', aggregation: 'COUNT' },
    ],
  },
  settlement: {
    tableName: 'SETTLE_DMCL_V1',
    fullTableName: `${DATABASE}.${SCHEMA}.SETTLE_DMCL_V1`,
    description: 'Batch settlement and clearing transactions',
    dimensions: [
      { name: 'RECORD_DT', type: 'date', label: 'Settlement Date' },
      { name: 'CARD_BRND', type: 'string', label: 'Card Brand' },
      { name: 'LCTN_DBA_NM', type: 'string', label: 'Merchant Name' },
      { name: 'CORP_DBA_NM', type: 'string', label: 'Corporation' },
      { name: 'PLAN_CD', type: 'string', label: 'Interchange Plan' },
      { name: 'BATCH_DT', type: 'date', label: 'Batch Date' },
    ],
    measures: [
      { name: 'SALES_CT', type: 'number', label: 'Sales Count', aggregation: 'SUM' },
      { name: 'REFUND_CNT', type: 'number', label: 'Refund Count', aggregation: 'SUM' },
      { name: 'PRCS_NET_AMT', type: 'number', label: 'Net Amount', aggregation: 'SUM' },
      { name: 'DSCN_AM', type: 'number', label: 'Discount Amount', aggregation: 'SUM' },
    ],
  },
  funding: {
    tableName: 'FUND_DMCL_V1',
    fullTableName: `${DATABASE}.${SCHEMA}.FUND_DMCL_V1`,
    description: 'Funding and deposit information',
    dimensions: [
      { name: 'FUNDED_DT', type: 'date', label: 'Funded Date' },
      { name: 'PAYMENT_STATUS', type: 'string', label: 'Payment Status' },
      { name: 'LCTN_DBA_NM', type: 'string', label: 'Merchant Name' },
      { name: 'TRAN_CATEGORY', type: 'string', label: 'Transaction Category' },
    ],
    measures: [
      { name: 'DEPOSIT_AM', type: 'number', label: 'Deposit Amount', aggregation: 'SUM' },
      { name: 'NET_SALES_AM', type: 'number', label: 'Net Sales', aggregation: 'SUM' },
      { name: 'FEES_AM', type: 'number', label: 'Fees', aggregation: 'SUM' },
      { name: 'CHARGEBACK_AM', type: 'number', label: 'Chargebacks', aggregation: 'SUM' },
    ],
  },
  chargeback: {
    tableName: 'CHARGEBACK_DMCL_V1',
    fullTableName: `${DATABASE}.${SCHEMA}.CHARGEBACK_DMCL_V1`,
    description: 'Dispute and chargeback data',
    dimensions: [
      { name: 'DSPUT_RCVD_DT', type: 'date', label: 'Dispute Received Date' },
      { name: 'DSPUT_RSN_CD', type: 'string', label: 'Reason Code' },
      { name: 'CBK_STATUS', type: 'string', label: 'Status' },
      { name: 'CBK_WIN_LOSS', type: 'string', label: 'Win/Loss' },
      { name: 'CHARGEBACK_CYCLE', type: 'string', label: 'Cycle' },
      { name: 'MRCH_NM', type: 'string', label: 'Merchant Name' },
      { name: 'CARD_BRND', type: 'string', label: 'Card Brand' },
    ],
    measures: [
      { name: 'DSPUT_AMT', type: 'number', label: 'Dispute Amount', aggregation: 'SUM' },
      { name: 'TXN_AMT', type: 'number', label: 'Transaction Amount', aggregation: 'SUM' },
    ],
  },
  retrieval: {
    tableName: 'RETRIEVAL_DMCL_V1',
    fullTableName: `${DATABASE}.${SCHEMA}.RETRIEVAL_DMCL_V1`,
    description: 'Draft retrieval requests',
    dimensions: [
      { name: 'RT_SALE_DT', type: 'date', label: 'Sale Date' },
      { name: 'RV_CB_STATUS', type: 'string', label: 'Status' },
      { name: 'RT_RSN_CD', type: 'string', label: 'Reason Code' },
      { name: 'RT_RTRVL_DUE_DT', type: 'date', label: 'Due Date' },
      { name: 'LCTN_DBA_NM', type: 'string', label: 'Merchant Name' },
      { name: 'CARD_BRND', type: 'string', label: 'Card Brand' },
    ],
    measures: [
      { name: 'RT_DOLLAR_AM', type: 'number', label: 'Retrieval Amount', aggregation: 'SUM' },
    ],
  },
  adjustment: {
    tableName: 'ADJ_DMCL_V1',
    fullTableName: `${DATABASE}.${SCHEMA}.ADJ_DMCL_V1`,
    description: 'Fee adjustments and corrections',
    dimensions: [
      { name: 'ADJ_DT', type: 'date', label: 'Adjustment Date' },
      { name: 'ADJ_CD', type: 'string', label: 'Adjustment Code' },
      { name: 'ADJ_DESC_TX', type: 'string', label: 'Description' },
      { name: 'FEE_DESC_TX', type: 'string', label: 'Fee Description' },
      { name: 'LCTN_DBA_NM', type: 'string', label: 'Merchant Name' },
    ],
    measures: [
      { name: 'ADJ_AM', type: 'number', label: 'Adjustment Amount', aggregation: 'SUM' },
    ],
  },
};

// GET /api/metadata - Get domain metadata and connection info
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const domain = searchParams.get('domain');
  const info = searchParams.get('info');

  // Configuration info for client
  const connectionConfig = {
    database: DATABASE,
    schema: SCHEMA,
    isConnected: isConfigured(),
  };

  // Return connection info
  if (info === 'connection') {
    return NextResponse.json({
      ...connectionConfig,
      domains: Object.keys(domainMetadata),
    });
  }

  if (domain) {
    // Return specific domain metadata
    const metadata = domainMetadata[domain as keyof typeof domainMetadata];
    if (!metadata) {
      return NextResponse.json(
        { error: `Domain '${domain}' not found` },
        { status: 404 }
      );
    }
    return NextResponse.json({
      ...metadata,
      connection: connectionConfig,
    });
  }

  // Return all domains
  const domains = Object.entries(domainMetadata).map(([key, value]) => ({
    key,
    tableName: value.tableName,
    fullTableName: value.fullTableName,
    description: value.description,
    dimensionCount: value.dimensions.length,
    measureCount: value.measures.length,
  }));

  return NextResponse.json({
    domains,
    connection: connectionConfig,
  });
}
