'use client';

import { useState } from 'react';
import { Card, Row, Col, Statistic, Select, DatePicker, Space, Typography, Spin, Tag, Progress, Tabs, Breadcrumb, Button } from 'antd';
import {
  DollarOutlined,
  BankOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  WalletOutlined,
  ArrowUpOutlined,
  ArrowDownOutlined,
  HomeOutlined,
  ReloadOutlined,
  LineChartOutlined,
  TableOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { TimeSeriesChart, type TimeSeriesDataPoint } from '@/components/charts/TimeSeriesChart';
import { BarChart } from '@/components/charts/BarChart';
import { DataGrid } from '@/components/grid/DataGrid';
import { domainColors } from '@/lib/theme';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

// Mock data for Funding analytics
const mockKPIs = {
  totalFundedAmount: 38456789.12,
  fundedDeposits: 12345,
  avgFundingTime: 0.8,
  fundingSuccessRate: 99.5,
  pendingFunds: 2345678.90,
  rejectedFunds: 45678.12,
};

const mockTrendData: TimeSeriesDataPoint[] = [
  { date: '2024-01-15', value: 35200000 },
  { date: '2024-01-16', value: 37800000 },
  { date: '2024-01-17', value: 36500000 },
  { date: '2024-01-18', value: 39200000 },
  { date: '2024-01-19', value: 34800000 },
  { date: '2024-01-20', value: 32100000 },
  { date: '2024-01-21', value: 38456789 },
];

const mockByFundingMethod = [
  { name: 'ACH', value: 26919752 },
  { name: 'Wire Transfer', value: 7691358 },
  { name: 'Same Day ACH', value: 3845679 },
];

const mockByStatus = [
  { name: 'Completed', value: 35456789 },
  { name: 'Pending', value: 2345678 },
  { name: 'Processing', value: 608644 },
  { name: 'Rejected', value: 45678 },
];

const mockFundingData = [
  {
    FUND_DT: '2024-01-21',
    MERCHANT_ID: 'M001234',
    MERCHANT_NAME: 'ABC Retail Corp',
    FUND_METHOD: 'ACH',
    DEPOSIT_AM: 145678.90,
    FEE_AM: 1456.79,
    NET_DEPOSIT_AM: 144222.11,
    BANK_ACCT_LAST4: '****4567',
    STATUS: 'Completed',
    FUND_REF: 'F20240121001',
  },
  {
    FUND_DT: '2024-01-21',
    MERCHANT_ID: 'M001235',
    MERCHANT_NAME: 'XYZ Foods LLC',
    FUND_METHOD: 'ACH',
    DEPOSIT_AM: 87234.56,
    FEE_AM: 872.35,
    NET_DEPOSIT_AM: 86362.21,
    BANK_ACCT_LAST4: '****8901',
    STATUS: 'Completed',
    FUND_REF: 'F20240121002',
  },
  {
    FUND_DT: '2024-01-21',
    MERCHANT_ID: 'M001236',
    MERCHANT_NAME: 'Tech Solutions Inc',
    FUND_METHOD: 'Wire Transfer',
    DEPOSIT_AM: 234567.89,
    FEE_AM: 4691.36,
    NET_DEPOSIT_AM: 229876.53,
    BANK_ACCT_LAST4: '****2345',
    STATUS: 'Completed',
    FUND_REF: 'F20240121003',
  },
  {
    FUND_DT: '2024-01-21',
    MERCHANT_ID: 'M001237',
    MERCHANT_NAME: 'Global Services Co',
    FUND_METHOD: 'Same Day ACH',
    DEPOSIT_AM: 56789.12,
    FEE_AM: 851.84,
    NET_DEPOSIT_AM: 55937.28,
    BANK_ACCT_LAST4: '****6789',
    STATUS: 'Pending',
    FUND_REF: 'F20240121004',
  },
  {
    FUND_DT: '2024-01-20',
    MERCHANT_ID: 'M001238',
    MERCHANT_NAME: 'Metro Dining Group',
    FUND_METHOD: 'ACH',
    DEPOSIT_AM: 34567.89,
    FEE_AM: 345.68,
    NET_DEPOSIT_AM: 34222.21,
    BANK_ACCT_LAST4: '****0123',
    STATUS: 'Completed',
    FUND_REF: 'F20240120001',
  },
];

export default function FundingAnalyticsPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(7, 'day'),
    dayjs(),
  ]);
  const [fundingMethod, setFundingMethod] = useState<string | null>(null);
  const [loading] = useState(false);
  const [activeTab, setActiveTab] = useState('overview');

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);

  const formatNumber = (value: number) =>
    new Intl.NumberFormat('en-US').format(value);

  return (
    <div className="space-y-6">
      {/* Breadcrumb */}
      <Breadcrumb
        items={[
          { href: '/', title: <><HomeOutlined /> Home</> },
          { title: 'Analytics' },
          { title: 'Funding' },
        ]}
      />

      {/* Page Header */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div
            className="flex items-center justify-center w-12 h-12 rounded-lg"
            style={{ backgroundColor: `${domainColors.funding.primary}15` }}
          >
            <WalletOutlined style={{ fontSize: 24, color: domainColors.funding.primary }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">
              Funding Analytics
            </Title>
            <Text type="secondary">
              Merchant deposit and funding transfer metrics
            </Text>
          </div>
        </div>

        <Space wrap>
          <RangePicker
            value={dateRange}
            onChange={(dates) => dates && setDateRange(dates as [dayjs.Dayjs, dayjs.Dayjs])}
            presets={[
              { label: 'Today', value: [dayjs(), dayjs()] },
              { label: 'Last 7 Days', value: [dayjs().subtract(7, 'day'), dayjs()] },
              { label: 'Last 30 Days', value: [dayjs().subtract(30, 'day'), dayjs()] },
              { label: 'This Month', value: [dayjs().startOf('month'), dayjs()] },
              { label: 'Last Month', value: [dayjs().subtract(1, 'month').startOf('month'), dayjs().subtract(1, 'month').endOf('month')] },
            ]}
          />
          <Select
            placeholder="All Methods"
            allowClear
            style={{ width: 160 }}
            value={fundingMethod}
            onChange={setFundingMethod}
            options={[
              { value: 'ach', label: 'ACH' },
              { value: 'wire', label: 'Wire Transfer' },
              { value: 'sameday', label: 'Same Day ACH' },
            ]}
          />
          <Button icon={<ReloadOutlined />}>Refresh</Button>
        </Space>
      </div>

      {/* Tabs */}
      <Tabs
        activeKey={activeTab}
        onChange={setActiveTab}
        items={[
          {
            key: 'overview',
            label: (
              <span>
                <LineChartOutlined /> Overview
              </span>
            ),
          },
          {
            key: 'details',
            label: (
              <span>
                <TableOutlined /> Funding Details
              </span>
            ),
          },
        ]}
      />

      {activeTab === 'overview' ? (
        <Spin spinning={loading}>
          {/* KPI Cards */}
          <Row gutter={[16, 16]}>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Total Funded Amount"
                  value={mockKPIs.totalFundedAmount}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: domainColors.funding.primary }} />}
                  formatter={(value) => formatCurrency(value as number)}
                />
                <div className="mt-2">
                  <Tag color="green" icon={<ArrowUpOutlined />}>
                    +4.7% vs last week
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Total Deposits"
                  value={mockKPIs.fundedDeposits}
                  prefix={<BankOutlined style={{ color: domainColors.funding.primary }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
                <div className="mt-2">
                  <Tag color="green" icon={<ArrowUpOutlined />}>
                    +2.3% vs last week
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Success Rate"
                  value={mockKPIs.fundingSuccessRate}
                  precision={1}
                  suffix="%"
                  prefix={<CheckCircleOutlined style={{ color: '#52c41a' }} />}
                />
                <div className="mt-2">
                  <Progress percent={mockKPIs.fundingSuccessRate} showInfo={false} strokeColor="#52c41a" size="small" />
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Avg Funding Time"
                  value={mockKPIs.avgFundingTime}
                  precision={1}
                  suffix=" days"
                  prefix={<ClockCircleOutlined style={{ color: '#52c41a' }} />}
                  styles={{ content: { color: '#52c41a' } }}
                />
                <div className="mt-2">
                  <Tag color="green">Within SLA</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Pending Funds"
                  value={mockKPIs.pendingFunds}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: '#faad14' }} />}
                  formatter={(value) => formatCurrency(value as number)}
                />
                <div className="mt-2">
                  <Tag color="orange">Processing</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Rejected Funds"
                  value={mockKPIs.rejectedFunds}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: '#ff4d4f' }} />}
                  formatter={(value) => formatCurrency(value as number)}
                  styles={{ content: { color: '#ff4d4f' } }}
                />
                <div className="mt-2">
                  <Tag color="red" icon={<ArrowDownOutlined />}>
                    0.1% of total
                  </Tag>
                </div>
              </Card>
            </Col>
          </Row>

          {/* Charts Row */}
          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24} lg={14}>
              <Card title="Funding Volume Trend" className="h-full">
                <TimeSeriesChart
                  data={mockTrendData}
                  height={300}
                  color={domainColors.funding.primary}
                  yAxisLabel="Funding Amount ($)"
                  showArea={true}
                  formatValue={(v) => `$${(v / 1000000).toFixed(1)}M`}
                />
              </Card>
            </Col>
            <Col xs={24} lg={10}>
              <Card title="Funding by Method" className="h-full">
                <BarChart
                  data={mockByFundingMethod}
                  height={300}
                  colors={[domainColors.funding.primary]}
                  horizontal={true}
                  formatValue={(v) => `$${(v / 1000000).toFixed(1)}M`}
                />
              </Card>
            </Col>
          </Row>

          {/* Second Charts Row */}
          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24}>
              <Card title="Funding by Status">
                <BarChart
                  data={mockByStatus}
                  height={250}
                  colors={[domainColors.funding.primary]}
                  formatValue={(v) => `$${(v / 1000000).toFixed(1)}M`}
                />
              </Card>
            </Col>
          </Row>
        </Spin>
      ) : (
        /* Details Tab */
        <DataGrid
          data={mockFundingData}
          height={600}
          enablePivot={true}
          enableExport={true}
          title="Funding Transactions"
        />
      )}
    </div>
  );
}
