'use client';

import { useState, useCallback } from 'react';
import { Card, Row, Col, Select, DatePicker, Space, Typography, Tabs, Breadcrumb, Button, Skeleton } from 'antd';
import {
  BankOutlined,
  HomeOutlined,
  ReloadOutlined,
  LineChartOutlined,
  TableOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { TimeSeriesChart } from '@/components/charts/TimeSeriesChart';
import { BarChart } from '@/components/charts/BarChart';
import { DataGrid } from '@/components/grid/DataGrid';
import { ConnectionError } from '@/components/ui/ConnectionError';
import { KPICard } from '@/components/ui';
import { useAnalyticsData } from '@/hooks';
import { domainColors } from '@/lib/theme';
import { formatCompactCurrency } from '@/lib/formatters';
import type {
  SettlementKPIs,
  SettlementTimeSeriesPoint,
  SettlementByMerchant,
  SettlementRecord,
} from '@/types/domain';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

export default function SettlementAnalyticsPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(7, 'day'),
    dayjs(),
  ]);
  const [cardBrand, setCardBrand] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('overview');

  const startDate = dateRange[0].format('YYYY-MM-DD');
  const endDate = dateRange[1].format('YYYY-MM-DD');

  const kpis = useAnalyticsData<SettlementKPIs>('settlement', 'kpis', { startDate, endDate });
  const timeseries = useAnalyticsData<SettlementTimeSeriesPoint[]>('settlement', 'timeseries', { startDate, endDate });
  const byMerchant = useAnalyticsData<SettlementByMerchant[]>('settlement', 'by-merchant', { startDate, endDate });
  const details = useAnalyticsData<SettlementRecord[]>('settlement', 'details', {
    startDate,
    endDate,
    cardBrand: cardBrand || undefined,
  }, { enabled: activeTab === 'details' });

  const isLoading = kpis.isLoading || timeseries.isLoading || byMerchant.isLoading;
  const hasError = kpis.error || timeseries.error || byMerchant.error;
  const errorCode = (hasError as Error & { code?: string })?.code;

  const refetchAll = useCallback(() => {
    kpis.refetch();
    timeseries.refetch();
    byMerchant.refetch();
    if (activeTab === 'details') details.refetch();
  }, [kpis, timeseries, byMerchant, details, activeTab]);

  if (hasError && errorCode === 'SNOWFLAKE_NOT_CONFIGURED') {
    return <ConnectionError code="SNOWFLAKE_NOT_CONFIGURED" onRetry={refetchAll} />;
  }

  const kpiData = kpis.data;
  const days = dateRange[1].diff(dateRange[0], 'day') || 1;

  const formatNumber = (value: number) =>
    new Intl.NumberFormat('en-US').format(value);

  const trendData = (timeseries.data || []).map((d) => ({
    date: String(d.date),
    value: d.netAmount,
  }));

  const merchantData = (byMerchant.data || []).map((d) => ({
    name: d.merchantName,
    value: d.netVolume,
  }));

  return (
    <div className="space-y-6">
      <Breadcrumb
        items={[
          { href: '/', title: <><HomeOutlined /> Home</> },
          { title: 'Analytics' },
          { title: 'Settlement' },
        ]}
      />

      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-12 h-12 rounded-lg" style={{ backgroundColor: `${domainColors.settlement.primary}15` }}>
            <BankOutlined style={{ fontSize: 24, color: domainColors.settlement.primary }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">Settlement Analytics</Title>
            <Text type="secondary">Daily settlement processing and reconciliation metrics</Text>
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
              { value: 'Visa', label: 'Visa' },
              { value: 'Mastercard', label: 'Mastercard' },
              { value: 'American Express', label: 'American Express' },
              { value: 'Discover', label: 'Discover' },
            ]}
          />
          <Button icon={<ReloadOutlined />} onClick={refetchAll}>Refresh</Button>
        </Space>
      </div>

      <Tabs
        activeKey={activeTab}
        onChange={setActiveTab}
        items={[
          { key: 'overview', label: <span><LineChartOutlined /> Overview</span> },
          { key: 'details', label: <span><TableOutlined /> Settlement Details</span> },
        ]}
      />

      {activeTab === 'overview' ? (
        <>
          <Row gutter={[16, 16]}>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Net Settlement Volume"
                value={kpiData?.netVolume ?? 0}
                format="currency"
                color={domainColors.settlement.primary}
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Total Sales Count"
                value={kpiData?.totalSalesCount ?? 0}
                format="number"
                color={domainColors.settlement.primary}
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Gross Sales"
                value={kpiData?.totalSalesAmount ?? 0}
                format="currency"
                color="#52c41a"
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Total Refunds"
                value={kpiData?.totalRefundAmount ?? 0}
                format="currency"
                color="#ff4d4f"
                loading={kpis.isLoading}
                description={kpiData ? `${formatNumber(kpiData.totalRefundCount)} refunds` : undefined}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Total Batches"
                value={kpiData?.totalBatches ?? 0}
                format="number"
                color="#52c41a"
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Daily Avg Volume"
                value={kpiData ? kpiData.netVolume / days : 0}
                format="currency"
                color={domainColors.settlement.primary}
                loading={kpis.isLoading}
              />
            </Col>
          </Row>

          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24} lg={14}>
              <Card title="Settlement Volume Trend" className="h-full">
                {isLoading ? (
                  <Skeleton active paragraph={{ rows: 6 }} style={{ height: 300, padding: '12px' }} />
                ) : (
                  <TimeSeriesChart
                    data={trendData}
                    height={300}
                    color={domainColors.settlement.primary}
                    yAxisLabel="Settlement Amount ($)"
                    showArea={true}
                    formatValue={formatCompactCurrency}
                  />
                )}
              </Card>
            </Col>
            <Col xs={24} lg={10}>
              <Card title="Settlement by Merchant" className="h-full">
                {isLoading ? (
                  <Skeleton active paragraph={{ rows: 6 }} style={{ height: 300, padding: '12px' }} />
                ) : (
                  <BarChart
                    data={merchantData}
                    height={300}
                    colors={[domainColors.settlement.primary]}
                    horizontal={true}
                    formatValue={formatCompactCurrency}
                  />
                )}
              </Card>
            </Col>
          </Row>
        </>
      ) : (
        <DataGrid
          data={(details.data || []) as Record<string, unknown>[]}
          height={600}
          enablePivot={true}
          enableExport={true}
          title="Settlement Transactions"
          loading={details.isLoading}
        />
      )}
    </div>
  );
}
