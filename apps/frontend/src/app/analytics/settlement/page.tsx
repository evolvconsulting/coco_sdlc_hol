'use client';

import { useState } from 'react';
import { Card, Row, Col, Statistic, Select, DatePicker, Space, Typography, Spin, Tag, Tabs, Breadcrumb, Button } from 'antd';
import {
  DollarOutlined,
  CheckCircleOutlined,
  FileTextOutlined,
  BankOutlined,
  ArrowUpOutlined,
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

// Mock data for Settlement analytics
const mockKPIs = {
  totalSettledAmount: 45890234.56,
  settledTransactions: 234567,
  avgSettlementTime: 1.2,
  settlementSuccessRate: 99.8,
  pendingSettlements: 1234,
  dailyAvgVolume: 6541462.08,
};

const mockTrendData: TimeSeriesDataPoint[] = [
  { date: '2024-01-15', value: 42500000 },
  { date: '2024-01-16', value: 44200000 },
  { date: '2024-01-17', value: 43800000 },
  { date: '2024-01-18', value: 46100000 },
  { date: '2024-01-19', value: 41200000 },
  { date: '2024-01-20', value: 38900000 },
  { date: '2024-01-21', value: 45890000 },
];

const mockByCardBrand = [
  { name: 'Visa', value: 22945117 },
  { name: 'Mastercard', value: 13767070 },
  { name: 'Amex', value: 6883535 },
  { name: 'Discover', value: 2294512 },
];

const mockByMerchantCategory = [
  { name: 'Retail', value: 18356094 },
  { name: 'Restaurant', value: 9178047 },
  { name: 'E-Commerce', value: 11472559 },
  { name: 'Services', value: 4589023 },
  { name: 'Travel', value: 2294512 },
];

const mockSettlementData = [
  {
    SETTLE_DT: '2024-01-21',
    MERCHANT_ID: 'M001234',
    MERCHANT_NAME: 'ABC Retail Corp',
    CARD_BRAND: 'Visa',
    SETTLE_TRAN_CT: 1234,
    SETTLE_AM: 156789.45,
    NET_SETTLE_AM: 154567.89,
    FEE_AM: 2221.56,
    BATCH_ID: 'B20240121001',
    STATUS: 'Completed',
  },
  {
    SETTLE_DT: '2024-01-21',
    MERCHANT_ID: 'M001235',
    MERCHANT_NAME: 'XYZ Foods LLC',
    CARD_BRAND: 'Mastercard',
    SETTLE_TRAN_CT: 876,
    SETTLE_AM: 98234.67,
    NET_SETTLE_AM: 97012.45,
    FEE_AM: 1222.22,
    BATCH_ID: 'B20240121002',
    STATUS: 'Completed',
  },
  {
    SETTLE_DT: '2024-01-21',
    MERCHANT_ID: 'M001236',
    MERCHANT_NAME: 'Tech Solutions Inc',
    CARD_BRAND: 'Amex',
    SETTLE_TRAN_CT: 345,
    SETTLE_AM: 234567.89,
    NET_SETTLE_AM: 229876.53,
    FEE_AM: 4691.36,
    BATCH_ID: 'B20240121003',
    STATUS: 'Completed',
  },
  {
    SETTLE_DT: '2024-01-21',
    MERCHANT_ID: 'M001237',
    MERCHANT_NAME: 'Global Services Co',
    CARD_BRAND: 'Visa',
    SETTLE_TRAN_CT: 567,
    SETTLE_AM: 87654.32,
    NET_SETTLE_AM: 86023.23,
    FEE_AM: 1631.09,
    BATCH_ID: 'B20240121004',
    STATUS: 'Pending',
  },
  {
    SETTLE_DT: '2024-01-20',
    MERCHANT_ID: 'M001238',
    MERCHANT_NAME: 'Metro Dining Group',
    CARD_BRAND: 'Discover',
    SETTLE_TRAN_CT: 234,
    SETTLE_AM: 45678.90,
    NET_SETTLE_AM: 44993.55,
    FEE_AM: 685.35,
    BATCH_ID: 'B20240120001',
    STATUS: 'Completed',
  },
];

export default function SettlementAnalyticsPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(7, 'day'),
    dayjs(),
  ]);
  const [cardBrand, setCardBrand] = useState<string | null>(null);
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
          { title: 'Settlement' },
        ]}
      />

      {/* Page Header */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div
            className="flex items-center justify-center w-12 h-12 rounded-lg"
            style={{ backgroundColor: `${domainColors.settlement.primary}15` }}
          >
            <BankOutlined style={{ fontSize: 24, color: domainColors.settlement.primary }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">
              Settlement Analytics
            </Title>
            <Text type="secondary">
              Daily settlement processing and reconciliation metrics
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
            placeholder="All Card Brands"
            allowClear
            style={{ width: 160 }}
            value={cardBrand}
            onChange={setCardBrand}
            options={[
              { value: 'visa', label: 'Visa' },
              { value: 'mastercard', label: 'Mastercard' },
              { value: 'amex', label: 'American Express' },
              { value: 'discover', label: 'Discover' },
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
                <TableOutlined /> Settlement Details
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
                  title="Total Settled Amount"
                  value={mockKPIs.totalSettledAmount}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: domainColors.settlement.primary }} />}
                  formatter={(value) => formatCurrency(value as number)}
                />
                <div className="mt-2">
                  <Tag color="green" icon={<ArrowUpOutlined />}>
                    +5.2% vs last week
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Settled Transactions"
                  value={mockKPIs.settledTransactions}
                  prefix={<FileTextOutlined style={{ color: domainColors.settlement.primary }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
                <div className="mt-2">
                  <Tag color="green" icon={<ArrowUpOutlined />}>
                    +3.8% vs last week
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Success Rate"
                  value={mockKPIs.settlementSuccessRate}
                  precision={1}
                  suffix="%"
                  prefix={<CheckCircleOutlined style={{ color: '#52c41a' }} />}
                />
                <div className="mt-2">
                  <Tag color="green">Excellent</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Avg Settlement Time"
                  value={mockKPIs.avgSettlementTime}
                  precision={1}
                  suffix=" days"
                  styles={{ content: { color: '#52c41a' } }}
                />
                <div className="mt-2">
                  <Tag color="blue">Within SLA</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Pending Settlements"
                  value={mockKPIs.pendingSettlements}
                  prefix={<FileTextOutlined style={{ color: '#faad14' }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
                <div className="mt-2">
                  <Tag color="orange">Processing</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Daily Avg Volume"
                  value={mockKPIs.dailyAvgVolume}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: domainColors.settlement.primary }} />}
                  formatter={(value) => formatCurrency(value as number)}
                />
                <div className="mt-2">
                  <Tag color="green" icon={<ArrowUpOutlined />}>
                    +2.1%
                  </Tag>
                </div>
              </Card>
            </Col>
          </Row>

          {/* Charts Row */}
          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24} lg={14}>
              <Card title="Settlement Volume Trend" className="h-full">
                <TimeSeriesChart
                  data={mockTrendData}
                  height={300}
                  color={domainColors.settlement.primary}
                  yAxisLabel="Settlement Amount ($)"
                  showArea={true}
                  formatValue={(v) => `$${(v / 1000000).toFixed(1)}M`}
                />
              </Card>
            </Col>
            <Col xs={24} lg={10}>
              <Card title="Settlement by Card Brand" className="h-full">
                <BarChart
                  data={mockByCardBrand}
                  height={300}
                  colors={[domainColors.settlement.primary]}
                  horizontal={true}
                  formatValue={(v) => `$${(v / 1000000).toFixed(1)}M`}
                />
              </Card>
            </Col>
          </Row>

          {/* Second Charts Row */}
          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24}>
              <Card title="Settlement by Merchant Category">
                <BarChart
                  data={mockByMerchantCategory}
                  height={250}
                  colors={[domainColors.settlement.primary]}
                  formatValue={(v) => `$${(v / 1000000).toFixed(1)}M`}
                />
              </Card>
            </Col>
          </Row>
        </Spin>
      ) : (
        /* Details Tab */
        <DataGrid
          data={mockSettlementData}
          height={600}
          enablePivot={true}
          enableExport={true}
          title="Settlement Transactions"
        />
      )}
    </div>
  );
}
