'use client';

import { useState } from 'react';
import { Card, Row, Col, Statistic, Select, DatePicker, Space, Typography, Spin, Tag, Tabs, Breadcrumb, Button } from 'antd';
import {
  DollarOutlined,
  SwapOutlined,
  PlusCircleOutlined,
  MinusCircleOutlined,
  FileTextOutlined,
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

// Mock data for Adjustment analytics
const mockKPIs = {
  totalAdjustments: 4567,
  netAdjustmentAmount: -234567.89,
  creditAdjustments: 1890234.56,
  debitAdjustments: 2124802.45,
  avgAdjustmentAmount: 456.78,
  pendingAdjustments: 123,
};

const mockTrendData: TimeSeriesDataPoint[] = [
  { date: '2024-01-15', value: -28000 },
  { date: '2024-01-16', value: -35000 },
  { date: '2024-01-17', value: -22000 },
  { date: '2024-01-18', value: -41000 },
  { date: '2024-01-19', value: -38000 },
  { date: '2024-01-20', value: -32000 },
  { date: '2024-01-21', value: -38568 },
];

const mockByAdjustmentType = [
  { name: 'Fee Adjustment', value: 1234567 },
  { name: 'Rate Correction', value: 567890 },
  { name: 'Chargeback Reversal', value: 456789 },
  { name: 'Settlement Error', value: 234567 },
  { name: 'Promotional Credit', value: 123456 },
];

const mockByCategory = [
  { name: 'Credits', value: 1890235 },
  { name: 'Debits', value: 2124802 },
];

const mockByCardBrand = [
  { name: 'Visa', value: 1826286 },
  { name: 'Mastercard', value: 1095772 },
  { name: 'Amex', value: 547886 },
  { name: 'Discover', value: 182629 },
];

const mockAdjustmentData = [
  {
    ADJ_DT: '2024-01-21',
    ADJ_ID: 'A20240121001',
    MERCHANT_ID: 'M001234',
    MERCHANT_NAME: 'ABC Retail Corp',
    ADJ_TYPE: 'Fee Adjustment',
    ADJ_CATEGORY: 'Credit',
    ADJ_AM: 1234.56,
    REASON_CD: 'FEE_WAIVER',
    REASON_DESC: 'Monthly fee waiver - loyalty program',
    STATUS: 'Posted',
    ORIG_REF: 'INV20240101001',
  },
  {
    ADJ_DT: '2024-01-21',
    ADJ_ID: 'A20240121002',
    MERCHANT_ID: 'M001235',
    MERCHANT_NAME: 'XYZ Foods LLC',
    ADJ_TYPE: 'Rate Correction',
    ADJ_CATEGORY: 'Credit',
    ADJ_AM: 567.89,
    REASON_CD: 'RATE_ERR',
    REASON_DESC: 'Interchange rate correction',
    STATUS: 'Posted',
    ORIG_REF: 'SETTLE20240115',
  },
  {
    ADJ_DT: '2024-01-20',
    ADJ_ID: 'A20240120001',
    MERCHANT_ID: 'M001236',
    MERCHANT_NAME: 'Tech Solutions Inc',
    ADJ_TYPE: 'Chargeback Reversal',
    ADJ_CATEGORY: 'Credit',
    ADJ_AM: 2345.67,
    REASON_CD: 'CB_REV',
    REASON_DESC: 'Chargeback won - funds returned',
    STATUS: 'Posted',
    ORIG_REF: 'CB20240105001',
  },
  {
    ADJ_DT: '2024-01-20',
    ADJ_ID: 'A20240120002',
    MERCHANT_ID: 'M001237',
    MERCHANT_NAME: 'Global Services Co',
    ADJ_TYPE: 'Settlement Error',
    ADJ_CATEGORY: 'Debit',
    ADJ_AM: -3456.78,
    REASON_CD: 'SETTLE_ERR',
    REASON_DESC: 'Duplicate settlement correction',
    STATUS: 'Pending',
    ORIG_REF: 'SETTLE20240118',
  },
  {
    ADJ_DT: '2024-01-19',
    ADJ_ID: 'A20240119001',
    MERCHANT_ID: 'M001238',
    MERCHANT_NAME: 'Metro Dining Group',
    ADJ_TYPE: 'Promotional Credit',
    ADJ_CATEGORY: 'Credit',
    ADJ_AM: 500.00,
    REASON_CD: 'PROMO',
    REASON_DESC: 'New merchant promotional credit',
    STATUS: 'Posted',
    ORIG_REF: 'PROMO2024Q1',
  },
];

export default function AdjustmentAnalyticsPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(30, 'day'),
    dayjs(),
  ]);
  const [adjustmentType, setAdjustmentType] = useState<string | null>(null);
  const [category, setCategory] = useState<string | null>(null);
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
          { title: 'Adjustments' },
        ]}
      />

      {/* Page Header */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div
            className="flex items-center justify-center w-12 h-12 rounded-lg"
            style={{ backgroundColor: `${domainColors.adjustment.primary}15` }}
          >
            <SwapOutlined style={{ fontSize: 24, color: domainColors.adjustment.primary }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">
              Adjustment Analytics
            </Title>
            <Text type="secondary">
              Financial adjustments, credits, and debit tracking
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
            placeholder="All Types"
            allowClear
            style={{ width: 180 }}
            value={adjustmentType}
            onChange={setAdjustmentType}
            options={[
              { value: 'fee', label: 'Fee Adjustment' },
              { value: 'rate', label: 'Rate Correction' },
              { value: 'cb_rev', label: 'Chargeback Reversal' },
              { value: 'settle', label: 'Settlement Error' },
              { value: 'promo', label: 'Promotional Credit' },
            ]}
          />
          <Select
            placeholder="All Categories"
            allowClear
            style={{ width: 130 }}
            value={category}
            onChange={setCategory}
            options={[
              { value: 'credit', label: 'Credits' },
              { value: 'debit', label: 'Debits' },
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
                <TableOutlined /> Adjustment Details
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
                  title="Total Adjustments"
                  value={mockKPIs.totalAdjustments}
                  prefix={<FileTextOutlined style={{ color: domainColors.adjustment.primary }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
                <div className="mt-2">
                  <Tag color="blue" icon={<ArrowUpOutlined />}>
                    +2.8% vs last month
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Net Adjustment"
                  value={mockKPIs.netAdjustmentAmount}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: mockKPIs.netAdjustmentAmount < 0 ? '#ff4d4f' : '#52c41a' }} />}
                  formatter={(value) => formatCurrency(value as number)}
                  styles={{ content: { color: mockKPIs.netAdjustmentAmount < 0 ? '#ff4d4f' : '#52c41a' } }}
                />
                <div className="mt-2">
                  <Tag color={mockKPIs.netAdjustmentAmount < 0 ? 'red' : 'green'}>
                    Net {mockKPIs.netAdjustmentAmount < 0 ? 'Debit' : 'Credit'}
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Credit Adjustments"
                  value={mockKPIs.creditAdjustments}
                  precision={0}
                  prefix={<PlusCircleOutlined style={{ color: '#52c41a' }} />}
                  formatter={(value) => formatCurrency(value as number)}
                  styles={{ content: { color: '#52c41a' } }}
                />
                <div className="mt-2">
                  <Tag color="green">47.1% of total</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Debit Adjustments"
                  value={mockKPIs.debitAdjustments}
                  precision={0}
                  prefix={<MinusCircleOutlined style={{ color: '#ff4d4f' }} />}
                  formatter={(value) => formatCurrency(value as number)}
                  styles={{ content: { color: '#ff4d4f' } }}
                />
                <div className="mt-2">
                  <Tag color="red">52.9% of total</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Avg Adjustment"
                  value={mockKPIs.avgAdjustmentAmount}
                  precision={2}
                  prefix={<DollarOutlined style={{ color: domainColors.adjustment.primary }} />}
                  formatter={(value) => formatCurrency(value as number)}
                />
                <div className="mt-2">
                  <Tag color="blue">Per transaction</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Pending"
                  value={mockKPIs.pendingAdjustments}
                  prefix={<FileTextOutlined style={{ color: '#faad14' }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
                <div className="mt-2">
                  <Tag color="orange">Awaiting Approval</Tag>
                </div>
              </Card>
            </Col>
          </Row>

          {/* Charts Row */}
          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24} lg={14}>
              <Card title="Net Adjustment Trend" className="h-full">
                <TimeSeriesChart
                  data={mockTrendData}
                  height={300}
                  color={domainColors.adjustment.primary}
                  yAxisLabel="Net Amount ($)"
                  showArea={true}
                  formatValue={(v) => `$${(v / 1000).toFixed(0)}K`}
                />
              </Card>
            </Col>
            <Col xs={24} lg={10}>
              <Card title="Adjustments by Type" className="h-full">
                <BarChart
                  data={mockByAdjustmentType}
                  height={300}
                  colors={[domainColors.adjustment.primary]}
                  horizontal={true}
                  formatValue={(v) => `$${(v / 1000).toFixed(0)}K`}
                />
              </Card>
            </Col>
          </Row>

          {/* Second Charts Row */}
          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24} lg={12}>
              <Card title="Credits vs Debits">
                <BarChart
                  data={mockByCategory}
                  height={250}
                  colors={[domainColors.adjustment.primary]}
                  formatValue={(v) => `$${(v / 1000000).toFixed(2)}M`}
                />
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="Adjustments by Card Brand">
                <BarChart
                  data={mockByCardBrand}
                  height={250}
                  colors={[domainColors.adjustment.primary]}
                  formatValue={(v) => `$${(v / 1000000).toFixed(2)}M`}
                />
              </Card>
            </Col>
          </Row>
        </Spin>
      ) : (
        /* Details Tab */
        <DataGrid
          data={mockAdjustmentData}
          height={600}
          enablePivot={true}
          enableExport={true}
          title="Financial Adjustments"
        />
      )}
    </div>
  );
}
