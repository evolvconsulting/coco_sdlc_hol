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
    tableName: 'AUTHORIZATIONS',
    color: '#FF6600',
  },
  settlement: {
    key: 'settlement',
    label: 'Settlement',
    description: 'Batch settlement and clearing transactions',
    icon: 'BankOutlined',
    tableName: 'SETTLEMENTS',
    color: '#1890ff',
  },
  funding: {
    key: 'funding',
    label: 'Funding',
    description: 'Funding and deposit information',
    icon: 'DollarOutlined',
    tableName: 'DEPOSITS',
    color: '#52c41a',
  },
  chargeback: {
    key: 'chargeback',
    label: 'Chargebacks',
    description: 'Dispute and chargeback management',
    icon: 'WarningOutlined',
    tableName: 'CHARGEBACKS',
    color: '#ff4d4f',
  },
  retrieval: {
    key: 'retrieval',
    label: 'Retrievals',
    description: 'Draft retrieval and document requests',
    icon: 'FileSearchOutlined',
    tableName: 'RETRIEVALS',
    color: '#722ed1',
  },
  adjustment: {
    key: 'adjustment',
    label: 'Adjustments',
    description: 'Fee adjustments and corrections',
    icon: 'SwapOutlined',
    tableName: 'ADJUSTMENTS',
    color: '#13c2c2',
  },
};

// API response wrapper
export interface ApiResponse<T> {
  success: boolean;
  data: T;
  filters?: Record<string, unknown>;
  rowCount?: number;
  error?: string;
  message?: string;
  code?: string;
}

// Authorization types
export interface AuthorizationRecord {
  [key: string]: unknown;
  authId: string;
  txnDate: string;
  cardBrand: string;
  amount: number;
  status: string;
  declineReason: string | null;
  merchantName: string;
  paymentMethod: string;
  network: string;
  riskScore: number;
}

export interface AuthorizationKPIs {
  totalTransactions: number;
  approvedCount: number;
  declinedCount: number;
  approvalRate: number;
  totalAmount: number;
  approvedAmount: number;
  avgTicketSize: number;
  trends: {
    transactions: number;
    approvalRate: number;
    amount: number;
  };
}

export interface AuthorizationTimeSeriesPoint {
  date: string;
  transactions: number;
  approved: number;
  declined: number;
  approvalRate: number;
  amount: number;
}

export interface AuthorizationByBrand {
  cardBrand: string;
  totalTransactions: number;
  approved: number;
  declined: number;
  approvalRate: number;
  totalAmount: number;
}

export interface AuthorizationDecline {
  reason: string;
  count: number;
  amount: number;
  percentage: number;
}

// Settlement types
export interface SettlementRecord {
  [key: string]: unknown;
  settleId: string;
  recordDate: string;
  cardBrand: string;
  merchantName: string;
  salesCount: number;
  salesAmount: number;
  refundCount: number;
  refundAmount: number;
  netAmount: number;
  interchange: number;
}

export interface SettlementKPIs {
  totalBatches: number;
  totalSalesCount: number;
  totalSalesAmount: number;
  totalRefundCount: number;
  totalRefundAmount: number;
  netVolume: number;
  totalInterchange: number;
}

export interface SettlementTimeSeriesPoint {
  date: string;
  salesCount: number;
  salesAmount: number;
  refundCount: number;
  refundAmount: number;
  netAmount: number;
  interchange: number;
}

export interface SettlementByMerchant {
  merchantName: string;
  netVolume: number;
  transactionCount: number;
  grossSales: number;
  refundAmount: number;
  interchange: number;
}

// Funding types
export interface FundingRecord {
  [key: string]: unknown;
  fundId: string;
  fundedDate: string;
  status: string;
  merchantName: string;
  depositAmount: number;
  netSales: number;
  fees: number;
  chargebacks: number;
}

export interface FundingKPIs {
  totalFundingRecords: number;
  totalDeposits: number;
  totalNetSales: number;
  totalFees: number;
  totalChargebacks: number;
  completedCount: number;
  pendingCount: number;
  heldCount: number;
}

export interface FundingTimeSeriesPoint {
  date: string;
  deposits: number;
  netSales: number;
  fees: number;
  chargebacks: number;
  fundingCount: number;
}

// Chargeback types
export interface ChargebackRecord {
  [key: string]: unknown;
  cbkId: string;
  disputeDate: string;
  reasonCode: string;
  reasonDescription: string;
  status: string;
  winLoss: string;
  cycle: string;
  merchantName: string;
  cardBrand: string;
  disputeAmount: number;
  transactionAmount: number;
}

export interface ChargebackKPIs {
  totalChargebacks: number;
  totalDisputeAmount: number;
  totalTransactionAmount: number;
  openCount: number;
  closedCount: number;
  wonCount: number;
  lostCount: number;
  winRate: number;
}

export interface ChargebackByReason {
  reasonCode: string;
  reasonDescription: string;
  count: number;
  amount: number;
  percentage: number;
}

// Retrieval types
export interface RetrievalRecord {
  [key: string]: unknown;
  rtId: string;
  saleDate: string;
  status: string;
  reasonCode: string;
  reasonDescription: string;
  dueDate: string;
  merchantName: string;
  cardBrand: string;
  amount: number;
}

export interface RetrievalKPIs {
  totalRetrievals: number;
  totalAmount: number;
  openCount: number;
  fulfilledCount: number;
  expiredCount: number;
  closedCount: number;
  fulfillmentRate: number;
}

// Adjustment types
export interface AdjustmentRecord {
  [key: string]: unknown;
  adjId: string;
  adjDate: string;
  adjCode: string;
  adjDescription: string;
  feeDescription: string;
  merchantName: string;
  amount: number;
  type: string;
}

export interface AdjustmentKPIs {
  totalAdjustments: number;
  totalCredits: number;
  totalDebits: number;
  netAdjustment: number;
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
