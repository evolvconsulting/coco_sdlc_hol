import { NextRequest, NextResponse } from 'next/server';
import { isConfigured } from '@/lib/snowflake';
import { SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA } from '@/lib/config';

// Domain metadata configuration
const domainMetadata = {
  authorization: {
    tableName: 'AUTHORIZATIONS',
    fullTableName: `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.AUTHORIZATIONS`,
    description: 'Real-time authorization transactions',
    dimensions: [
      { name: 'transaction_date', type: 'date', label: 'Transaction Date' },
      { name: 'card_brand', type: 'string', label: 'Card Brand' },
      { name: 'approval_status', type: 'string', label: 'Approval Status' },
      { name: 'merchant_name', type: 'string', label: 'Merchant Name' },
      { name: 'corporate_name', type: 'string', label: 'Corporation' },
      { name: 'decline_reason', type: 'string', label: 'Decline Reason' },
      { name: 'processor_name', type: 'string', label: 'Processor' },
      { name: 'payment_method', type: 'string', label: 'Payment Method' },
      { name: 'processing_network', type: 'string', label: 'Network' },
    ],
    measures: [
      { name: 'transaction_amount', type: 'number', label: 'Amount', aggregation: 'SUM' },
    ],
  },
  settlement: {
    tableName: 'SETTLEMENTS',
    fullTableName: `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.SETTLEMENTS`,
    description: 'Batch settlement and clearing transactions',
    dimensions: [
      { name: 'settlement_date', type: 'date', label: 'Settlement Date' },
      { name: 'card_brand', type: 'string', label: 'Card Brand' },
      { name: 'merchant_name', type: 'string', label: 'Merchant Name' },
      { name: 'corporate_name', type: 'string', label: 'Corporation' },
      { name: 'interchange_plan_code', type: 'string', label: 'Interchange Plan' },
      { name: 'batch_date', type: 'date', label: 'Batch Date' },
    ],
    measures: [
      { name: 'sales_count', type: 'number', label: 'Sales Count', aggregation: 'SUM' },
      { name: 'refund_count', type: 'number', label: 'Refund Count', aggregation: 'SUM' },
      { name: 'net_amount', type: 'number', label: 'Net Amount', aggregation: 'SUM' },
      { name: 'discount_amount', type: 'number', label: 'Discount Amount', aggregation: 'SUM' },
    ],
  },
  funding: {
    tableName: 'DEPOSITS',
    fullTableName: `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.DEPOSITS`,
    description: 'Funding and deposit information',
    dimensions: [
      { name: 'deposit_date', type: 'date', label: 'Deposit Date' },
      { name: 'payment_status', type: 'string', label: 'Payment Status' },
      { name: 'merchant_name', type: 'string', label: 'Merchant Name' },
      { name: 'transaction_category', type: 'string', label: 'Transaction Category' },
    ],
    measures: [
      { name: 'deposit_amount', type: 'number', label: 'Deposit Amount', aggregation: 'SUM' },
      { name: 'net_sales_amount', type: 'number', label: 'Net Sales', aggregation: 'SUM' },
      { name: 'total_fees_amount', type: 'number', label: 'Fees', aggregation: 'SUM' },
      { name: 'chargeback_amount', type: 'number', label: 'Chargebacks', aggregation: 'SUM' },
    ],
  },
  chargeback: {
    tableName: 'CHARGEBACKS',
    fullTableName: `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.CHARGEBACKS`,
    description: 'Dispute and chargeback data',
    dimensions: [
      { name: 'dispute_received_date', type: 'date', label: 'Dispute Received Date' },
      { name: 'reason_code', type: 'string', label: 'Reason Code' },
      { name: 'reason_description', type: 'string', label: 'Reason Description' },
      { name: 'chargeback_status', type: 'string', label: 'Status' },
      { name: 'outcome', type: 'string', label: 'Outcome' },
      { name: 'lifecycle_stage', type: 'string', label: 'Lifecycle Stage' },
      { name: 'merchant_name', type: 'string', label: 'Merchant Name' },
      { name: 'card_brand', type: 'string', label: 'Card Brand' },
    ],
    measures: [
      { name: 'dispute_amount', type: 'number', label: 'Dispute Amount', aggregation: 'SUM' },
      { name: 'transaction_amount', type: 'number', label: 'Transaction Amount', aggregation: 'SUM' },
    ],
  },
  retrieval: {
    tableName: 'RETRIEVALS',
    fullTableName: `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.RETRIEVALS`,
    description: 'Draft retrieval requests',
    dimensions: [
      { name: 'original_sale_date', type: 'date', label: 'Sale Date' },
      { name: 'retrieval_status', type: 'string', label: 'Status' },
      { name: 'reason_code', type: 'string', label: 'Reason Code' },
      { name: 'response_due_date', type: 'date', label: 'Due Date' },
      { name: 'merchant_name', type: 'string', label: 'Merchant Name' },
      { name: 'card_brand', type: 'string', label: 'Card Brand' },
    ],
    measures: [
      { name: 'retrieval_amount', type: 'number', label: 'Retrieval Amount', aggregation: 'SUM' },
    ],
  },
  adjustment: {
    tableName: 'ADJUSTMENTS',
    fullTableName: `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.ADJUSTMENTS`,
    description: 'Fee adjustments and corrections',
    dimensions: [
      { name: 'adjustment_date', type: 'date', label: 'Adjustment Date' },
      { name: 'adjustment_code', type: 'string', label: 'Adjustment Code' },
      { name: 'adjustment_description', type: 'string', label: 'Description' },
      { name: 'fee_description', type: 'string', label: 'Fee Description' },
      { name: 'merchant_name', type: 'string', label: 'Merchant Name' },
    ],
    measures: [
      { name: 'adjustment_amount', type: 'number', label: 'Adjustment Amount', aggregation: 'SUM' },
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
    database: SNOWFLAKE_DATABASE,
    schema: SNOWFLAKE_SCHEMA,
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
