'use client';

import { useState } from 'react';
import { Card, Row, Col, Statistic, Select, DatePicker, Space, Typography, Spin, Tag, Progress, Tabs, Breadcrumb, Button } from 'antd';
import {
  DollarOutlined,
  ExclamationCircleOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  WarningOutlined,
  ArrowUpOutlined,
  FileExclamationOutlined,
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

// Mock data for Chargeback analytics
const mockKPIs = {
  totalChargebackAmount: 1234567.89,
  chargebackCount: 2345,
  chargebackRate: 0.52,
  winRate: 67.5,
  pendingDisputes: 456,
  avgResolutionDays: 28,
};

const mockTrendData: TimeSeriesDataPoint[] = [
  { date: '2024-01-15', value: 165000 },
  { date: '2024-01-16', value: 178000 },
  { date: '2024-01-17', value: 156000 },
  { date: '2024-01-18', value: 189000 },
  { date: '2024-01-19', value: 198000 },
  { date: '2024-01-20', value: 172000 },
  { date: '2024-01-21', value: 176568 },
];

const mockByReasonCode = [
  { name: 'Fraud (10.4)', value: 493827 },
  { name: 'Not Received (13.1)', value: 370370 },
  { name: 'Not as Described (13.3)', value: 185185 },
  { name: 'Credit Not Processed (13.6)', value: 123457 },
  { name: 'Duplicate (12.6)', value: 61728 },
];

const mockByCardBrand = [
  { name: 'Visa', value: 617284 },
  { name: 'Mastercard', value: 370370 },
  { name: 'Amex', value: 185185 },
  { name: 'Discover', value: 61728 },
];

const mockByStatus = [
  { name: 'Won', value: 789012 },
  { name: 'Lost', value: 345678 },
  { name: 'Pending', value: 99877 },
];

const mockChargebackData = [
  {
    CB_DT: '2024-01-21',
    CASE_ID: 'CB20240121001',
    MERCHANT_ID: 'M001234',
    MERCHANT_NAME: 'ABC Retail Corp',
    CARD_BRAND: 'Visa',
    REASON_CD: '10.4',
    REASON_DESC: 'Fraud - Card Absent Environment',
    CB_AM: 456.78,
    ORIG_TRAN_DT: '2024-01-05',
    STATUS: 'Pending',
    DUE_DT: '2024-02-20',
  },
  {
    CB_DT: '2024-01-21',
    CASE_ID: 'CB20240121002',
    MERCHANT_ID: 'M001235',
    MERCHANT_NAME: 'XYZ Foods LLC',
    CARD_BRAND: 'Mastercard',
    REASON_CD: '13.1',
    REASON_DESC: 'Merchandise/Services Not Received',
    CB_AM: 234.56,
    ORIG_TRAN_DT: '2024-01-08',
    STATUS: 'Won',
    DUE_DT: '2024-02-18',
  },
  {
    CB_DT: '2024-01-20',
    CASE_ID: 'CB20240120001',
    MERCHANT_ID: 'M001236',
    MERCHANT_NAME: 'Tech Solutions Inc',
    CARD_BRAND: 'Amex',
    REASON_CD: '13.3',
    REASON_DESC: 'Not as Described',
    CB_AM: 1234.56,
    ORIG_TRAN_DT: '2024-01-02',
    STATUS: 'Pending',
    DUE_DT: '2024-02-15',
  },
  {
    CB_DT: '2024-01-20',
    CASE_ID: 'CB20240120002',
    MERCHANT_ID: 'M001237',
    MERCHANT_NAME: 'Global Services Co',
    CARD_BRAND: 'Visa',
    REASON_CD: '13.6',
    REASON_DESC: 'Credit Not Processed',
    CB_AM: 567.89,
    ORIG_TRAN_DT: '2023-12-28',
    STATUS: 'Lost',
    DUE_DT: '2024-02-10',
  },
  {
    CB_DT: '2024-01-19',
    CASE_ID: 'CB20240119001',
    MERCHANT_ID: 'M001238',
    MERCHANT_NAME: 'Metro Dining Group',
    CARD_BRAND: 'Discover',
    REASON_CD: '12.6',
    REASON_DESC: 'Duplicate Processing',
    CB_AM: 89.99,
    ORIG_TRAN_DT: '2024-01-10',
    STATUS: 'Won',
    DUE_DT: '2024-02-12',
  },
];

export default function ChargebackAnalyticsPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(30, 'day'),
    dayjs(),
  ]);
  const [reasonCode, setReasonCode] = useState<string | null>(null);
  const [status, setStatus] = useState<string | null>(null);
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
          { title: 'Chargebacks' },
        ]}
      />

      {/* Page Header */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div
            className="flex items-center justify-center w-12 h-12 rounded-lg"
            style={{ backgroundColor: `${domainColors.chargeback.primary}15` }}
          >
            <FileExclamationOutlined style={{ fontSize: 24, color: domainColors.chargeback.primary }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">
              Chargeback Analytics
            </Title>
            <Text type="secondary">
              Dispute management and chargeback metrics
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
            placeholder="All Reason Codes"
            allowClear
            style={{ width: 180 }}
            value={reasonCode}
            onChange={setReasonCode}
            options={[
              { value: '10.4', label: '10.4 - Fraud' },
              { value: '13.1', label: '13.1 - Not Received' },
              { value: '13.3', label: '13.3 - Not as Described' },
              { value: '13.6', label: '13.6 - Credit Not Processed' },
              { value: '12.6', label: '12.6 - Duplicate' },
            ]}
          />
          <Select
            placeholder="All Status"
            allowClear
            style={{ width: 130 }}
            value={status}
            onChange={setStatus}
            options={[
              { value: 'pending', label: 'Pending' },
              { value: 'won', label: 'Won' },
              { value: 'lost', label: 'Lost' },
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
                <TableOutlined /> Chargeback Details
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
                  title="Total CB Amount"
                  value={mockKPIs.totalChargebackAmount}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: domainColors.chargeback.primary }} />}
                  formatter={(value) => formatCurrency(value as number)}
                  styles={{ content: { color: domainColors.chargeback.primary } }}
                />
                <div className="mt-2">
                  <Tag color="red" icon={<ArrowUpOutlined />}>
                    +8.2% vs last month
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Chargeback Count"
                  value={mockKPIs.chargebackCount}
                  prefix={<ExclamationCircleOutlined style={{ color: domainColors.chargeback.primary }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
                <div className="mt-2">
                  <Tag color="red" icon={<ArrowUpOutlined />}>
                    +5.4% vs last month
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Chargeback Rate"
                  value={mockKPIs.chargebackRate}
                  precision={2}
                  suffix="%"
                  prefix={<WarningOutlined style={{ color: mockKPIs.chargebackRate > 1 ? '#ff4d4f' : '#faad14' }} />}
                  styles={{ content: { color: mockKPIs.chargebackRate > 1 ? '#ff4d4f' : '#faad14' } }}
                />
                <div className="mt-2">
                  <Tag color={mockKPIs.chargebackRate < 1 ? 'green' : 'red'}>
                    {mockKPIs.chargebackRate < 1 ? 'Within Threshold' : 'Above Threshold'}
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Win Rate"
                  value={mockKPIs.winRate}
                  precision={1}
                  suffix="%"
                  prefix={<CheckCircleOutlined style={{ color: '#52c41a' }} />}
                  styles={{ content: { color: '#52c41a' } }}
                />
                <div className="mt-2">
                  <Progress percent={mockKPIs.winRate} showInfo={false} strokeColor="#52c41a" size="small" />
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Pending Disputes"
                  value={mockKPIs.pendingDisputes}
                  prefix={<ClockCircleOutlined style={{ color: '#faad14' }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
                <div className="mt-2">
                  <Tag color="orange">Requires Action</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Avg Resolution"
                  value={mockKPIs.avgResolutionDays}
                  suffix=" days"
                  prefix={<ClockCircleOutlined style={{ color: '#1890ff' }} />}
                />
                <div className="mt-2">
                  <Tag color="blue">Within SLA</Tag>
                </div>
              </Card>
            </Col>
          </Row>

          {/* Charts Row */}
          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24} lg={14}>
              <Card title="Chargeback Amount Trend" className="h-full">
                <TimeSeriesChart
                  data={mockTrendData}
                  height={300}
                  color={domainColors.chargeback.primary}
                  yAxisLabel="Chargeback Amount ($)"
                  showArea={true}
                  formatValue={(v) => `$${(v / 1000).toFixed(0)}K`}
                />
              </Card>
            </Col>
            <Col xs={24} lg={10}>
              <Card title="Chargebacks by Reason Code" className="h-full">
                <BarChart
                  data={mockByReasonCode}
                  height={300}
                  colors={[domainColors.chargeback.primary]}
                  horizontal={true}
                  formatValue={(v) => `$${(v / 1000).toFixed(0)}K`}
                />
              </Card>
            </Col>
          </Row>

          {/* Second Charts Row */}
          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24} lg={12}>
              <Card title="Chargebacks by Card Brand">
                <BarChart
                  data={mockByCardBrand}
                  height={250}
                  colors={[domainColors.chargeback.primary]}
                  formatValue={(v) => `$${(v / 1000).toFixed(0)}K`}
                />
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="Chargebacks by Status">
                <BarChart
                  data={mockByStatus}
                  height={250}
                  colors={[domainColors.chargeback.primary]}
                  formatValue={(v) => `$${(v / 1000).toFixed(0)}K`}
                />
              </Card>
            </Col>
          </Row>
        </Spin>
      ) : (
        /* Details Tab */
        <DataGrid
          data={mockChargebackData}
          height={600}
          enablePivot={true}
          enableExport={true}
          title="Chargeback Cases"
        />
      )}
    </div>
  );
}
