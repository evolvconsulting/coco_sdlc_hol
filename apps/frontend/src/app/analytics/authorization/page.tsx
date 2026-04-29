'use client';

import { useState, useCallback } from 'react';
import { Row, Col, Typography, Card, DatePicker, Select, Space, Button, Tabs, Breadcrumb, Spin, Skeleton } from 'antd';
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
import { ConnectionError } from '@/components/ui/ConnectionError';
import { useAnalyticsData } from '@/hooks';
import { cardBrandColors } from '@/lib/theme';
import { formatCompactCount, formatPercent } from '@/lib/formatters';
import type {
  AuthorizationKPIs,
  AuthorizationTimeSeriesPoint,
  AuthorizationByBrand,
  AuthorizationDecline,
  AuthorizationRecord,
} from '@/types/domain';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

export default function AuthorizationPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(30, 'day'),
    dayjs(),
  ]);
  const [selectedBrand, setSelectedBrand] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('overview');

  const startDate = dateRange[0].format('YYYY-MM-DD');
  const endDate = dateRange[1].format('YYYY-MM-DD');

  const kpis = useAnalyticsData<AuthorizationKPIs>('authorization', 'kpis', {
    startDate,
    endDate,
    cardBrand: selectedBrand || undefined,
  });

  const timeseries = useAnalyticsData<AuthorizationTimeSeriesPoint[]>('authorization', 'timeseries', {
    startDate,
    endDate,
  });

  const byBrand = useAnalyticsData<AuthorizationByBrand[]>('authorization', 'by-brand', {
    startDate,
    endDate,
  });

  const declinesList = useAnalyticsData<AuthorizationDecline[]>('authorization', 'declines', {
    startDate,
    endDate,
  });

  const details = useAnalyticsData<AuthorizationRecord[]>('authorization', 'details', {
    startDate,
    endDate,
    cardBrand: selectedBrand || undefined,
  }, { enabled: activeTab === 'details' });

  const isLoading = kpis.isLoading || timeseries.isLoading || byBrand.isLoading || declinesList.isLoading;
  const hasError = kpis.error || timeseries.error || byBrand.error || declinesList.error;
  const errorCode = (hasError as Error & { code?: string })?.code;

  const refetchAll = useCallback(() => {
    kpis.refetch();
    timeseries.refetch();
    byBrand.refetch();
    declinesList.refetch();
    if (activeTab === 'details') details.refetch();
  }, [kpis, timeseries, byBrand, declinesList, details, activeTab]);

  if (hasError && errorCode === 'SNOWFLAKE_NOT_CONFIGURED') {
    return <ConnectionError code="SNOWFLAKE_NOT_CONFIGURED" onRetry={refetchAll} />;
  }

  const kpiData = kpis.data;
  const timeSeriesData = (timeseries.data || []).map((d) => ({
    date: String(d.date),
    value: d.transactions,
  }));
  const brandData = (byBrand.data || []).map((d) => ({
    name: d.cardBrand,
    value: d.totalTransactions,
    color: cardBrandColors[d.cardBrand as keyof typeof cardBrandColors],
  }));
  const declineData = (declinesList.data || []).map((d) => ({
    name: d.reason,
    value: d.count,
  }));
  const brandDeclineRates = (byBrand.data || []).map((d) => ({
    brand: d.cardBrand,
    rate: d.totalTransactions > 0
      ? Number(((d.declined / d.totalTransactions) * 100).toFixed(2))
      : 0,
    count: d.totalTransactions,
  }));

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
          <Button icon={<ReloadOutlined />} onClick={refetchAll}>Refresh</Button>
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
                value={kpiData?.totalTransactions ?? 0}
                prefix={<CreditCardOutlined />}
                trend={kpiData?.trends?.transactions}
                trendLabel="vs last period"
                description="Total authorization requests received"
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={6}>
              {isLoading ? (
                <Card>
                  <Skeleton active paragraph={{ rows: 6 }} style={{ height: 180, padding: '12px' }} />
                </Card>
              ) : (
                <GaugeChart
                  value={kpiData?.approvalRate ?? 0}
                  title="Approval Rate"
                  height={180}
                  thresholds={[
                    { value: 0.9, color: '#ff4d4f' },
                    { value: 0.95, color: '#faad14' },
                    { value: 1, color: '#52c41a' },
                  ]}
                  formatValue={formatPercent}
                />
              )}
            </Col>
            <Col xs={24} sm={12} lg={6}>
              <KPICard
                title="Approved Amount"
                value={kpiData?.approvedAmount ?? 0}
                format="currency"
                trend={kpiData?.trends?.amount}
                color="#52c41a"
                description="Total dollar amount approved"
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={6}>
              <KPICard
                title="Avg Ticket Size"
                value={kpiData?.avgTicketSize ?? 0}
                format="currency"
                description="Average transaction amount"
                loading={kpis.isLoading}
              />
            </Col>
          </Row>

          {/* Charts Row */}
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={16}>
              {isLoading ? (
                <Card>
                  <Skeleton active paragraph={{ rows: 6 }} style={{ height: 300, padding: '12px' }} />
                </Card>
              ) : (
                <TimeSeriesChart
                  data={timeSeriesData}
                  title="Daily Transaction Volume"
                  height={300}
                  yAxisLabel="Transactions"
                  formatValue={formatCompactCount}
                />
              )}
            </Col>
            <Col xs={24} lg={8}>
              {isLoading ? (
                <Card>
                  <Skeleton active paragraph={{ rows: 6 }} style={{ height: 300, padding: '12px' }} />
                </Card>
              ) : (
                <PieChart
                  data={brandData}
                  title="Transactions by Card Brand"
                  height={300}
                />
              )}
            </Col>
          </Row>

          {/* Second Charts Row */}
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={12}>
              {isLoading ? (
                <Card>
                  <Skeleton active paragraph={{ rows: 6 }} style={{ height: 300, padding: '12px' }} />
                </Card>
              ) : (
                <BarChart
                  data={declineData}
                  title="Top Decline Reasons"
                  height={300}
                  horizontal
                  colors={['#ff4d4f']}
                />
              )}
            </Col>
            <Col xs={24} lg={12}>
              <Card title={<Text strong>Decline Rate by Card Brand</Text>}>
                <div className="space-y-4">
                  {brandDeclineRates.map((item) => (
                    <div key={item.brand} className="flex items-center gap-4">
                      <div className="w-32">
                        <Text strong>{item.brand}</Text>
                      </div>
                      <div className="flex-1">
                        <div className="h-6 bg-gray-100 rounded-full overflow-hidden">
                          <div
                            className="h-full rounded-full"
                            style={{
                              width: `${Math.min(item.rate * 10, 100)}%`,
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
        <Spin spinning={details.isLoading}>
          <DataGrid
            data={(details.data || []) as Record<string, unknown>[]}
            title="Authorization Transactions"
            height={600}
            enablePivot
            enableExport
          />
        </Spin>
      )}
    </div>
  );
}
