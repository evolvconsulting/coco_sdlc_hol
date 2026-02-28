'use client';

import { useState } from 'react';
import { Row, Col, Typography, Card, DatePicker, Select, Space, Button, Tabs, Breadcrumb } from 'antd';
import {
  CreditCardOutlined,
  ReloadOutlined,
  HomeOutlined,
  TableOutlined,
  LineChartOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { KPICard } from '@/components/ui';
import { GaugeChart, TimeSeriesChart, PieChart, BarChart } from '@/components/charts';
import { DataGrid } from '@/components/grid';
import { cardBrandColors } from '@/lib/theme';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

// Mock data for authorization analytics
const mockKPIs = {
  totalTransactions: 1247893,
  approvedCount: 1202668,
  declinedCount: 45225,
  approvalRate: 96.38,
  totalAmount: 89234567.89,
  approvedAmount: 86123456.78,
  avgTicketSize: 71.52,
  trends: {
    transactions: 2.3,
    approvalRate: 0.5,
    amount: 4.1,
  },
};

const mockTimeSeriesData = [
  { date: '2026-02-01', value: 42356 },
  { date: '2026-02-02', value: 38912 },
  { date: '2026-02-03', value: 35678 },
  { date: '2026-02-04', value: 41234 },
  { date: '2026-02-05', value: 44567 },
  { date: '2026-02-06', value: 48901 },
  { date: '2026-02-07', value: 45234 },
  { date: '2026-02-08', value: 43567 },
  { date: '2026-02-09', value: 39876 },
  { date: '2026-02-10', value: 36543 },
  { date: '2026-02-11', value: 42109 },
  { date: '2026-02-12', value: 45678 },
  { date: '2026-02-13', value: 49012 },
  { date: '2026-02-14', value: 52345 },
  { date: '2026-02-15', value: 48765 },
  { date: '2026-02-16', value: 44321 },
  { date: '2026-02-17', value: 40987 },
  { date: '2026-02-18', value: 43654 },
  { date: '2026-02-19', value: 47321 },
  { date: '2026-02-20', value: 50987 },
  { date: '2026-02-21', value: 48654 },
];

const mockCardBrandData = [
  { name: 'Visa', value: 523456, color: cardBrandColors['Visa'] },
  { name: 'Mastercard', value: 312789, color: cardBrandColors['Mastercard'] },
  { name: 'American Express', value: 98234, color: cardBrandColors['American Express'] },
  { name: 'Discover', value: 45123, color: cardBrandColors['Discover'] },
];

const mockDeclineReasons = [
  { name: 'Insufficient Funds', value: 15234 },
  { name: 'Invalid Card', value: 8901 },
  { name: 'Expired Card', value: 7654 },
  { name: 'Do Not Honor', value: 5432 },
  { name: 'Lost/Stolen', value: 3210 },
  { name: 'Other', value: 4794 },
];

const mockDetailData = [
  { TXNDATE: '2026-02-21', CARD_BRND: 'Visa', LCTN_DBA_NM: 'WALMART SUPERCENTER #4521', AMOUNT: 156.78, APPROVALCODE: 1, DECLINEREASON: null },
  { TXNDATE: '2026-02-21', CARD_BRND: 'Mastercard', LCTN_DBA_NM: 'TARGET STORE #1234', AMOUNT: 89.99, APPROVALCODE: 1, DECLINEREASON: null },
  { TXNDATE: '2026-02-21', CARD_BRND: 'Visa', LCTN_DBA_NM: 'COSTCO WHOLESALE #789', AMOUNT: 234.56, APPROVALCODE: 2, DECLINEREASON: 'Insufficient Funds' },
  { TXNDATE: '2026-02-21', CARD_BRND: 'American Express', LCTN_DBA_NM: 'BEST BUY #3456', AMOUNT: 1299.99, APPROVALCODE: 1, DECLINEREASON: null },
  { TXNDATE: '2026-02-21', CARD_BRND: 'Discover', LCTN_DBA_NM: 'HOME DEPOT #5678', AMOUNT: 456.23, APPROVALCODE: 1, DECLINEREASON: null },
  { TXNDATE: '2026-02-20', CARD_BRND: 'Visa', LCTN_DBA_NM: 'CVS PHARMACY #2345', AMOUNT: 45.67, APPROVALCODE: 1, DECLINEREASON: null },
  { TXNDATE: '2026-02-20', CARD_BRND: 'Mastercard', LCTN_DBA_NM: 'WALGREENS #6789', AMOUNT: 32.10, APPROVALCODE: 2, DECLINEREASON: 'Invalid Card' },
  { TXNDATE: '2026-02-20', CARD_BRND: 'Visa', LCTN_DBA_NM: 'LOWES HOME IMP #4567', AMOUNT: 567.89, APPROVALCODE: 1, DECLINEREASON: null },
];

export default function AuthorizationPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(30, 'day'),
    dayjs(),
  ]);
  const [selectedBrand, setSelectedBrand] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('overview');

  return (
    <div className="space-y-6">
      {/* Breadcrumb */}
      <Breadcrumb
        items={[
          { href: '/', title: <><HomeOutlined /> Home</> },
          { title: 'Analytics' },
          { title: 'Authorization' },
        ]}
      />

      {/* Page Header */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div
            className="flex items-center justify-center w-12 h-12 rounded-lg"
            style={{ backgroundColor: '#FF660015' }}
          >
            <CreditCardOutlined style={{ fontSize: 24, color: '#FF6600' }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">
              Authorization Analytics
            </Title>
            <Text type="secondary">
              Real-time transaction authorization data
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
            value={selectedBrand}
            onChange={setSelectedBrand}
            options={[
              { value: 'Visa', label: 'Visa' },
              { value: 'Mastercard', label: 'Mastercard' },
              { value: 'American Express', label: 'American Express' },
              { value: 'Discover', label: 'Discover' },
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
                <TableOutlined /> Transaction Details
              </span>
            ),
          },
        ]}
      />

      {activeTab === 'overview' ? (
        <>
          {/* KPI Cards */}
          <Row gutter={[16, 16]}>
            <Col xs={24} sm={12} lg={6}>
              <KPICard
                title="Total Transactions"
                value={mockKPIs.totalTransactions}
                prefix={<CreditCardOutlined />}
                trend={mockKPIs.trends.transactions}
                trendLabel="vs last period"
                description="Total authorization requests received"
              />
            </Col>
            <Col xs={24} sm={12} lg={6}>
              <GaugeChart
                value={mockKPIs.approvalRate}
                title="Approval Rate"
                height={180}
                thresholds={[
                  { value: 0.9, color: '#ff4d4f' },
                  { value: 0.95, color: '#faad14' },
                  { value: 1, color: '#52c41a' },
                ]}
              />
            </Col>
            <Col xs={24} sm={12} lg={6}>
              <KPICard
                title="Approved Amount"
                value={mockKPIs.approvedAmount}
                format="currency"
                trend={mockKPIs.trends.amount}
                color="#52c41a"
                description="Total dollar amount approved"
              />
            </Col>
            <Col xs={24} sm={12} lg={6}>
              <KPICard
                title="Avg Ticket Size"
                value={mockKPIs.avgTicketSize}
                format="currency"
                description="Average transaction amount"
              />
            </Col>
          </Row>

          {/* Charts Row */}
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={16}>
              <TimeSeriesChart
                data={mockTimeSeriesData}
                title="Daily Transaction Volume"
                height={300}
                yAxisLabel="Transactions"
                formatValue={(v) => new Intl.NumberFormat('en-US').format(v)}
              />
            </Col>
            <Col xs={24} lg={8}>
              <PieChart
                data={mockCardBrandData}
                title="Transactions by Card Brand"
                height={300}
              />
            </Col>
          </Row>

          {/* Second Charts Row */}
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={12}>
              <BarChart
                data={mockDeclineReasons}
                title="Top Decline Reasons"
                height={300}
                horizontal
                colors={['#ff4d4f']}
              />
            </Col>
            <Col xs={24} lg={12}>
              <Card title={<Text strong>Decline Rate by Card Brand</Text>}>
                <div className="space-y-4">
                  {[
                    { brand: 'Visa', rate: 2.98, count: 523456 },
                    { brand: 'Mastercard', rate: 4.37, count: 312789 },
                    { brand: 'American Express', rate: 2.60, count: 98234 },
                    { brand: 'Discover', rate: 4.68, count: 45123 },
                  ].map((item) => (
                    <div key={item.brand} className="flex items-center gap-4">
                      <div className="w-32">
                        <Text strong>{item.brand}</Text>
                      </div>
                      <div className="flex-1">
                        <div className="h-6 bg-gray-100 rounded-full overflow-hidden">
                          <div
                            className="h-full rounded-full"
                            style={{
                              width: `${item.rate * 10}%`,
                              backgroundColor: '#ff4d4f',
                            }}
                          />
                        </div>
                      </div>
                      <div className="w-16 text-right">
                        <Text strong style={{ color: item.rate <= 3 ? '#52c41a' : '#faad14' }}>
                          {item.rate}%
                        </Text>
                      </div>
                    </div>
                  ))}
                </div>
              </Card>
            </Col>
          </Row>
        </>
      ) : (
        /* Details Tab */
        <DataGrid
          data={mockDetailData}
          title="Authorization Transactions"
          height={600}
          enablePivot
          enableExport
        />
      )}
    </div>
  );
}
