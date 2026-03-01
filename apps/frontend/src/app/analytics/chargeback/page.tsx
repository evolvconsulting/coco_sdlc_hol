'use client';

import { useState, useCallback } from 'react';
import { Card, Row, Col, Select, DatePicker, Space, Typography, Tag, Tabs, Breadcrumb, Button, Skeleton } from 'antd';
import {
  FileExclamationOutlined,
  HomeOutlined,
  ReloadOutlined,
  LineChartOutlined,
  TableOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { BarChart } from '@/components/charts/BarChart';
import { DataGrid } from '@/components/grid/DataGrid';
import { ConnectionError } from '@/components/ui/ConnectionError';
import { KPICard } from '@/components/ui';
import { useAnalyticsData } from '@/hooks';
import { domainColors } from '@/lib/theme';
import { formatCompactCurrency } from '@/lib/formatters';
import type { ChargebackKPIs, ChargebackByReason, ChargebackRecord } from '@/types/domain';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

export default function ChargebackAnalyticsPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(30, 'day'),
    dayjs(),
  ]);
  const [reasonCode, setReasonCode] = useState<string | null>(null);
  const [status, setStatus] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('overview');

  const startDate = dateRange[0].format('YYYY-MM-DD');
  const endDate = dateRange[1].format('YYYY-MM-DD');

  const kpis = useAnalyticsData<ChargebackKPIs>('chargeback', 'kpis', { startDate, endDate });
  const byReason = useAnalyticsData<ChargebackByReason[]>('chargeback', 'by-reason', { startDate, endDate });
  const details = useAnalyticsData<ChargebackRecord[]>('chargeback', 'details', {
    startDate,
    endDate,
    reasonCode: reasonCode || undefined,
    status: status || undefined,
  }, { enabled: activeTab === 'details' });

  const isChartLoading = byReason.isLoading;
  const hasError = kpis.error || byReason.error;
  const errorCode = (hasError as Error & { code?: string })?.code;

  const refetchAll = useCallback(() => {
    kpis.refetch();
    byReason.refetch();
    if (activeTab === 'details') details.refetch();
  }, [kpis, byReason, details, activeTab]);

  if (hasError && errorCode === 'SNOWFLAKE_NOT_CONFIGURED') {
    return <ConnectionError code="SNOWFLAKE_NOT_CONFIGURED" onRetry={refetchAll} />;
  }

  const kpiData = kpis.data;

  const reasonData = (byReason.data || []).map((d) => ({
    name: d.reasonDescription || d.reasonCode,
    value: d.amount,
  }));

  return (
    <div className="space-y-6">
      <Breadcrumb
        items={[
          { href: '/', title: <><HomeOutlined /> Home</> },
          { title: 'Analytics' },
          { title: 'Chargebacks' },
        ]}
      />

      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-12 h-12 rounded-lg" style={{ backgroundColor: `${domainColors.chargeback.primary}15` }}>
            <FileExclamationOutlined style={{ fontSize: 24, color: domainColors.chargeback.primary }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">Chargeback Analytics</Title>
            <Text type="secondary">Dispute management and chargeback metrics</Text>
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
              { value: 'OPEN', label: 'Open' },
              { value: 'CLOSED', label: 'Closed' },
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
          { key: 'details', label: <span><TableOutlined /> Chargeback Details</span> },
        ]}
      />

      {activeTab === 'overview' ? (
        <>
          <Row gutter={[16, 16]}>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Total Dispute Amount"
                value={kpiData?.totalDisputeAmount ?? 0}
                format="currency"
                loading={kpis.isLoading}
                color={domainColors.chargeback.primary}
                trendInverted={true}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Chargeback Count"
                value={kpiData?.totalChargebacks ?? 0}
                format="number"
                loading={kpis.isLoading}
                color={domainColors.chargeback.primary}
                trendInverted={true}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Transaction Amount"
                value={kpiData?.totalTransactionAmount ?? 0}
                format="currency"
                loading={kpis.isLoading}
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Win Rate"
                value={kpiData?.winRate ?? 0}
                format="percent"
                loading={kpis.isLoading}
                color="#52c41a"
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Open Disputes"
                value={kpiData?.openCount ?? 0}
                format="number"
                loading={kpis.isLoading}
                description="Requires Action"
              />
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <KPICard
                title="Won / Lost"
                value={kpiData?.wonCount ?? 0}
                format="number"
                loading={kpis.isLoading}
                suffix={` / ${kpiData?.lostCount ?? 0}`}
              />
            </Col>
          </Row>

          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24}>
              {isChartLoading ? (
                <Card>
                  <Skeleton active paragraph={{ rows: 6 }} style={{ height: 300, padding: '12px' }} />
                </Card>
              ) : (
                <Card title="Chargebacks by Reason Code" className="h-full">
                  <BarChart
                    data={reasonData}
                    height={300}
                    colors={[domainColors.chargeback.primary]}
                    horizontal={true}
                    formatValue={formatCompactCurrency}
                  />
                </Card>
              )}
            </Col>
          </Row>
        </>
      ) : (
        <DataGrid
          data={(details.data || []) as Record<string, unknown>[]}
          loading={details.isLoading}
          height={600}
          enablePivot={true}
          enableExport={true}
          title="Chargeback Cases"
        />
      )}
    </div>
  );
}
