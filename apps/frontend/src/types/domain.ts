// Domain types for Performance Intelligence Dashboard

export type DomainType =
  | 'authorization'
  | 'settlement'
  | 'funding'
  | 'chargeback'
  | 'retrieval'
  | 'adjustment';

export interface DomainConfig {
  key: DomainType;
  label: string;
  description: string;
  icon: string;
  tableName: string;
  color: string;
}

export const DOMAINS: Record<DomainType, DomainConfig> = {
  authorization: {
    key: 'authorization',
    label: 'Authorization',
    description: 'Real-time transaction authorization data',
    icon: 'CreditCardOutlined',
    tableName: 'AUTH_DMCL_V1',
    color: '#FF6600',
  },
  settlement: {
    key: 'settlement',
    label: 'Settlement',
    description: 'Batch settlement and clearing transactions',
    icon: 'BankOutlined',
    tableName: 'SETTLE_DMCL_V1',
    color: '#1890ff',
  },
  funding: {
    key: 'funding',
    label: 'Funding',
    description: 'Funding and deposit information',
    icon: 'DollarOutlined',
    tableName: 'FUND_DMCL_V1',
    color: '#52c41a',
  },
  chargeback: {
    key: 'chargeback',
    label: 'Chargebacks',
    description: 'Dispute and chargeback management',
    icon: 'WarningOutlined',
    tableName: 'CHARGEBACK_DMCL_V1',
    color: '#ff4d4f',
  },
  retrieval: {
    key: 'retrieval',
    label: 'Retrievals',
    description: 'Draft retrieval and document requests',
    icon: 'FileSearchOutlined',
    tableName: 'RETRIEVAL_DMCL_V1',
    color: '#722ed1',
  },
  adjustment: {
    key: 'adjustment',
    label: 'Adjustments',
    description: 'Fee adjustments and corrections',
    icon: 'SwapOutlined',
    tableName: 'ADJ_DMCL_V1',
    color: '#13c2c2',
  },
};

// Authorization specific types
export interface AuthorizationRecord {
  TXNDATE: string;
  TXNTIME: string;
  AMOUNT: number;
  APPROVALCODE: 0 | 1 | 2; // 0: Unknown, 1: Approved, 2: Declined
  CARD_BRND: string;
  LCTN_DBA_NM: string;
  DECLINEREASON?: string;
  PLTF_ID: number;
}

export interface AuthorizationKPIs {
  totalTransactions: number;
  approvedCount: number;
  declinedCount: number;
  approvalRate: number;
  totalAmount: number;
  approvedAmount: number;
  avgTicketSize: number;
}

// Settlement specific types
export interface SettlementRecord {
  RECORD_DT: string;
  SALES_CT: number;
  REFUND_CNT: number;
  PRCS_NET_AMT: number;
  DSCN_AM: number;
  CARD_BRND: string;
  LCTN_DBA_NM: string;
}

export interface SettlementKPIs {
  salesCount: number;
  refundCount: number;
  netCount: number;
  netAmount: number;
  discountAmount: number;
  avgTicketSize: number;
}

// Funding specific types
export interface FundingRecord {
  FUNDED_DT: string;
  DEPOSIT_AM: number;
  NET_SALES_AM: number;
  FEES_AM: number;
  CHARGEBACK_AM: number;
  PAYMENT_STATUS: string;
}

export interface FundingKPIs {
  totalDeposits: number;
  netSales: number;
  totalFees: number;
  totalChargebacks: number;
  itemCount: number;
}

// Chargeback specific types
export interface ChargebackRecord {
  DSPUT_RCVD_DT: string;
  DSPUT_AMT: number;
  DSPUT_RSN_CD: string;
  CBK_STATUS: string;
  CBK_WIN_LOSS: string;
  CHARGEBACK_CYCLE: string;
}

export interface ChargebackKPIs {
  chargebackCount: number;
  disputeAmount: number;
  wonCount: number;
  lostCount: number;
  winRate: number;
  pendingCount: number;
}

// Retrieval specific types
export interface RetrievalRecord {
  RT_ACQR_REF_NR: string;
  RT_SALE_DT: string;
  RT_DOLLAR_AM: number;
  RV_CB_STATUS: 'OPEN' | 'CLOSED' | 'EXPIRED';
  RT_FULFILMT_DT?: string;
  RT_RTRVL_DUE_DT: string;
}

export interface RetrievalKPIs {
  totalRetrievals: number;
  openCount: number;
  closedCount: number;
  expiredCount: number;
  totalAmount: number;
  fulfillmentRate: number;
}

// Adjustment specific types
export interface AdjustmentRecord {
  ADJ_DT: string;
  ADJ_AM: number;
  ADJ_TYPE_CD: 'C' | 'D'; // Credit or Debit
  ADJ_DESC_TX: string;
  FEE_DESC_TX?: string;
}

export interface AdjustmentKPIs {
  adjustmentCount: number;
  creditAmount: number;
  debitAmount: number;
  netAmount: number;
  creditCount: number;
  debitCount: number;
}

// Query result types
export interface QueryResult {
  columns: string[];
  rows: Record<string, unknown>[];
  rowCount: number;
  executionTime: number;
  sql?: string;
}

// Chart data types
export interface TimeSeriesDataPoint {
  date: string;
  value: number;
  category?: string;
}

export interface PieChartDataPoint {
  name: string;
  value: number;
  color?: string;
}

export interface BarChartDataPoint {
  name: string;
  value: number;
  category?: string;
}
