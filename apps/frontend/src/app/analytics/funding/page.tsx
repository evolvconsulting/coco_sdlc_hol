'use client';

import { useState, useCallback } from 'react';
import { Card, Row, Col, Select, DatePicker, Space, Typography, Tabs, Breadcrumb, Button, Skeleton } from 'antd';
import {
  WalletOutlined,
  HomeOutlined,
  ReloadOutlined,
  LineChartOutlined,
  TableOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { TimeSeriesChart } from '@/components/charts/TimeSeriesChart';
import { DataGrid } from '@/components/grid/DataGrid';
import { ConnectionError } from '@/components/ui/ConnectionError';
import { KPICard } from '@/components/ui';
import { useAnalyticsData } from '@/hooks';
import { domainColors } from '@/lib/theme';
import { formatCompactCurrency } from '@/lib/formatters';
import type { FundingKPIs, FundingTimeSeriesPoint, FundingRecord } from '@/types/domain';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

export default function FundingAnalyticsPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(7, 'day'),
    dayjs(),
  ]);
  const [statusFilter, setStatusFilter] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('overview');

  const startDate = dateRange[0].format('YYYY-MM-DD');
  const endDate = dateRange[1].format('YYYY-MM-DD');

  const kpis = useAnalyticsData<FundingKPIs>('funding', 'kpis', { startDate, endDate });
  const timeseries = useAnalyticsData<FundingTimeSeriesPoint[]>('funding', 'timeseries', { startDate, endDate });
  const details = useAnalyticsData<FundingRecord[]>('funding', 'details', {
    startDate,
    endDate,
    status: statusFilter || undefined,
  }, { enabled: activeTab === 'details' });

  const isLoading = kpis.isLoading || timeseries.isLoading;
  const hasError = kpis.error || timeseries.error;
  const errorCode = (hasError as Error & { code?: string })?.code;

  const refetchAll = useCallback(() => {
    kpis.refetch();
    timeseries.refetch();
    if (activeTab === 'details') details.refetch();
  }, [kpis, timeseries, details, activeTab]);

  if (hasError && errorCode === 'SNOWFLAKE_NOT_CONFIGURED') {
    return <ConnectionError code="SNOWFLAKE_NOT_CONFIGURED" onRetry={refetchAll} />;
  }

  const kpiData = kpis.data;

  const trendData = (timeseries.data || []).map((d) => ({
    date: String(d.date),
    value: d.deposits,
  }));

  return (
    <div className="space-y-6">
      <Breadcrumb
        items={[
          { href: '/', title: <><HomeOutlined /> Home</> },
          { title: 'Analytics' },
          { title: 'Funding' },
        ]}
      />

      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-12 h-12 rounded-lg" style={{ backgroundColor: `${domainColors.funding.primary}15` }}>
            <WalletOutlined style={{ fontSize: 24, color: domainColors.funding.primary }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">Funding Analytics</Title>
            <Text type="secondary">Merchant deposit and funding transfer metrics</Text>
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
            placeholder="All Statuses"
            allowClear
            style={{ width: 160 }}
            value={statusFilter}
            onChange={setStatusFilter}
            options={[
              { value: 'COMPLETED', label: 'Completed' },
              { value: 'PENDING', label: 'Pending' },
              { value: 'HELD', label: 'Held' },
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
          { key: 'details', label: <span><TableOutlined /> Funding Details</span> },
        ]}
      />

      {activeTab === 'overview' ? (
        <>
          <Row gutter={[16, 16]}>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Total Deposits"
                value={kpiData?.totalDeposits ?? 0}
                format="currency"
                color={domainColors.funding.primary}
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Funding Records"
                value={kpiData?.totalFundingRecords ?? 0}
                format="number"
                color={domainColors.funding.primary}
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Net Sales"
                value={kpiData?.totalNetSales ?? 0}
                format="currency"
                color="#52c41a"
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Total Fees"
                value={kpiData?.totalFees ?? 0}
                format="currency"
                color="#faad14"
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Completed"
                value={kpiData?.completedCount ?? 0}
                format="number"
                color="#52c41a"
                loading={kpis.isLoading}
                description={
                  kpiData && kpiData.totalFundingRecords > 0
                    ? `${((kpiData.completedCount / kpiData.totalFundingRecords) * 100).toFixed(1)}% of total`
                    : '0% of total'
                }
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Pending"
                value={kpiData?.pendingCount ?? 0}
                format="number"
                color="#faad14"
                loading={kpis.isLoading}
                description="Processing"
              />
            </Col>
          </Row>

          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24}>
              <Card title="Deposit Volume Trend" className="h-full">
                {isLoading ? (
                  <Skeleton active paragraph={{ rows: 6 }} style={{ height: 300, padding: '12px' }} />
                ) : (
                  <TimeSeriesChart
                    data={trendData}
                    height={300}
                    color={domainColors.funding.primary}
                    yAxisLabel="Deposit Amount ($)"
                    showArea={true}
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
          title="Funding Transactions"
          loading={details.isLoading}
        />
      )}
    </div>
  );
}
