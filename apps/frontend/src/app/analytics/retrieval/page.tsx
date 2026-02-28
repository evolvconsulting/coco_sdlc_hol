'use client';

import { useState } from 'react';
import { Card, Row, Col, Statistic, Select, DatePicker, Space, Typography, Spin, Tag, Progress, Tabs, Breadcrumb, Button } from 'antd';
import {
  FileSearchOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  ArrowUpOutlined,
  ArrowDownOutlined,
  FileTextOutlined,
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

// Mock data for Retrieval analytics
const mockKPIs = {
  totalRetrievals: 3456,
  pendingRetrievals: 234,
  responseRate: 94.5,
  avgResponseTime: 3.2,
  expiredRetrievals: 45,
  fulfilledRetrievals: 3177,
};

const mockTrendData: TimeSeriesDataPoint[] = [
  { date: '2024-01-15', value: 456 },
  { date: '2024-01-16', value: 512 },
  { date: '2024-01-17', value: 478 },
  { date: '2024-01-18', value: 534 },
  { date: '2024-01-19', value: 423 },
  { date: '2024-01-20', value: 389 },
  { date: '2024-01-21', value: 494 },
];

const mockByReasonCode = [
  { name: 'Cardholder Inquiry', value: 1382 },
  { name: 'Fraud Investigation', value: 1037 },
  { name: 'Compliance Review', value: 691 },
  { name: 'Dispute Support', value: 346 },
];

const mockByCardBrand = [
  { name: 'Visa', value: 1728 },
  { name: 'Mastercard', value: 1037 },
  { name: 'Amex', value: 518 },
  { name: 'Discover', value: 173 },
];

const mockByStatus = [
  { name: 'Fulfilled', value: 3177 },
  { name: 'Pending', value: 234 },
  { name: 'Expired', value: 45 },
];

const mockRetrievalData = [
  {
    RETR_DT: '2024-01-21',
    CASE_ID: 'R20240121001',
    MERCHANT_ID: 'M001234',
    MERCHANT_NAME: 'ABC Retail Corp',
    CARD_BRAND: 'Visa',
    REASON_CD: 'CI',
    REASON_DESC: 'Cardholder Inquiry',
    TRAN_AM: 156.78,
    ORIG_TRAN_DT: '2024-01-10',
    STATUS: 'Pending',
    DUE_DT: '2024-02-04',
    DAYS_REMAINING: 14,
  },
  {
    RETR_DT: '2024-01-21',
    CASE_ID: 'R20240121002',
    MERCHANT_ID: 'M001235',
    MERCHANT_NAME: 'XYZ Foods LLC',
    CARD_BRAND: 'Mastercard',
    REASON_CD: 'FI',
    REASON_DESC: 'Fraud Investigation',
    TRAN_AM: 234.56,
    ORIG_TRAN_DT: '2024-01-08',
    STATUS: 'Fulfilled',
    DUE_DT: '2024-02-02',
    DAYS_REMAINING: 0,
  },
  {
    RETR_DT: '2024-01-20',
    CASE_ID: 'R20240120001',
    MERCHANT_ID: 'M001236',
    MERCHANT_NAME: 'Tech Solutions Inc',
    CARD_BRAND: 'Amex',
    REASON_CD: 'CR',
    REASON_DESC: 'Compliance Review',
    TRAN_AM: 567.89,
    ORIG_TRAN_DT: '2024-01-05',
    STATUS: 'Pending',
    DUE_DT: '2024-02-01',
    DAYS_REMAINING: 11,
  },
  {
    RETR_DT: '2024-01-19',
    CASE_ID: 'R20240119001',
    MERCHANT_ID: 'M001237',
    MERCHANT_NAME: 'Global Services Co',
    CARD_BRAND: 'Visa',
    REASON_CD: 'DS',
    REASON_DESC: 'Dispute Support',
    TRAN_AM: 89.99,
    ORIG_TRAN_DT: '2024-01-02',
    STATUS: 'Fulfilled',
    DUE_DT: '2024-01-29',
    DAYS_REMAINING: 0,
  },
  {
    RETR_DT: '2024-01-18',
    CASE_ID: 'R20240118001',
    MERCHANT_ID: 'M001238',
    MERCHANT_NAME: 'Metro Dining Group',
    CARD_BRAND: 'Discover',
    REASON_CD: 'CI',
    REASON_DESC: 'Cardholder Inquiry',
    TRAN_AM: 45.67,
    ORIG_TRAN_DT: '2024-01-01',
    STATUS: 'Expired',
    DUE_DT: '2024-01-28',
    DAYS_REMAINING: -3,
  },
];

export default function RetrievalAnalyticsPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(30, 'day'),
    dayjs(),
  ]);
  const [reasonCode, setReasonCode] = useState<string | null>(null);
  const [status, setStatus] = useState<string | null>(null);
  const [loading] = useState(false);
  const [activeTab, setActiveTab] = useState('overview');

  const formatNumber = (value: number) =>
    new Intl.NumberFormat('en-US').format(value);

  return (
    <div className="space-y-6">
      {/* Breadcrumb */}
      <Breadcrumb
        items={[
          { href: '/', title: <><HomeOutlined /> Home</> },
          { title: 'Analytics' },
          { title: 'Retrievals' },
        ]}
      />

      {/* Page Header */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div
            className="flex items-center justify-center w-12 h-12 rounded-lg"
            style={{ backgroundColor: `${domainColors.retrieval.primary}15` }}
          >
            <FileSearchOutlined style={{ fontSize: 24, color: domainColors.retrieval.primary }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">
              Retrieval Analytics
            </Title>
            <Text type="secondary">
              Document retrieval requests and fulfillment tracking
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
            placeholder="All Reasons"
            allowClear
            style={{ width: 180 }}
            value={reasonCode}
            onChange={setReasonCode}
            options={[
              { value: 'CI', label: 'Cardholder Inquiry' },
              { value: 'FI', label: 'Fraud Investigation' },
              { value: 'CR', label: 'Compliance Review' },
              { value: 'DS', label: 'Dispute Support' },
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
              { value: 'fulfilled', label: 'Fulfilled' },
              { value: 'expired', label: 'Expired' },
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
                <TableOutlined /> Retrieval Details
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
                  title="Total Retrievals"
                  value={mockKPIs.totalRetrievals}
                  prefix={<FileTextOutlined style={{ color: domainColors.retrieval.primary }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
                <div className="mt-2">
                  <Tag color="blue" icon={<ArrowUpOutlined />}>
                    +3.2% vs last month
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Pending Requests"
                  value={mockKPIs.pendingRetrievals}
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
                  title="Response Rate"
                  value={mockKPIs.responseRate}
                  precision={1}
                  suffix="%"
                  prefix={<CheckCircleOutlined style={{ color: '#52c41a' }} />}
                  styles={{ content: { color: '#52c41a' } }}
                />
                <div className="mt-2">
                  <Progress percent={mockKPIs.responseRate} showInfo={false} strokeColor="#52c41a" size="small" />
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Avg Response Time"
                  value={mockKPIs.avgResponseTime}
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
                  title="Fulfilled"
                  value={mockKPIs.fulfilledRetrievals}
                  prefix={<CheckCircleOutlined style={{ color: '#52c41a' }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
                <div className="mt-2">
                  <Tag color="green">91.9% of total</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Expired"
                  value={mockKPIs.expiredRetrievals}
                  prefix={<ExclamationCircleOutlined style={{ color: '#ff4d4f' }} />}
                  formatter={(value) => formatNumber(value as number)}
                  styles={{ content: { color: '#ff4d4f' } }}
                />
                <div className="mt-2">
                  <Tag color="red" icon={<ArrowDownOutlined />}>
                    1.3% of total
                  </Tag>
                </div>
              </Card>
            </Col>
          </Row>

          {/* Charts Row */}
          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24} lg={14}>
              <Card title="Retrieval Request Trend" className="h-full">
                <TimeSeriesChart
                  data={mockTrendData}
                  height={300}
                  color={domainColors.retrieval.primary}
                  yAxisLabel="Retrieval Count"
                  showArea={true}
                  formatValue={(v) => formatNumber(v)}
                />
              </Card>
            </Col>
            <Col xs={24} lg={10}>
              <Card title="Retrievals by Reason" className="h-full">
                <BarChart
                  data={mockByReasonCode}
                  height={300}
                  colors={[domainColors.retrieval.primary]}
                  horizontal={true}
                  formatValue={(v) => formatNumber(v)}
                />
              </Card>
            </Col>
          </Row>

          {/* Second Charts Row */}
          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24} lg={12}>
              <Card title="Retrievals by Card Brand">
                <BarChart
                  data={mockByCardBrand}
                  height={250}
                  colors={[domainColors.retrieval.primary]}
                  formatValue={(v) => formatNumber(v)}
                />
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="Retrievals by Status">
                <BarChart
                  data={mockByStatus}
                  height={250}
                  colors={[domainColors.retrieval.primary]}
                  formatValue={(v) => formatNumber(v)}
                />
              </Card>
            </Col>
          </Row>
        </Spin>
      ) : (
        /* Details Tab */
        <DataGrid
          data={mockRetrievalData}
          height={600}
          enablePivot={true}
          enableExport={true}
          title="Retrieval Requests"
        />
      )}
    </div>
  );
}
