'use client';

import { useState, useCallback } from 'react';
import { Row, Col, DatePicker, Space, Typography, Tabs, Breadcrumb, Button } from 'antd';
import {
  SwapOutlined,
  HomeOutlined,
  ReloadOutlined,
  LineChartOutlined,
  TableOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { DataGrid } from '@/components/grid/DataGrid';
import { ConnectionError } from '@/components/ui/ConnectionError';
import { KPICard } from '@/components/ui';
import { useAnalyticsData } from '@/hooks';
import { domainColors } from '@/lib/theme';
import type { AdjustmentKPIs, AdjustmentRecord } from '@/types/domain';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

export default function AdjustmentAnalyticsPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(30, 'day'),
    dayjs(),
  ]);
  const [activeTab, setActiveTab] = useState('overview');

  const startDate = dateRange[0].format('YYYY-MM-DD');
  const endDate = dateRange[1].format('YYYY-MM-DD');

  const kpis = useAnalyticsData<AdjustmentKPIs>('adjustment', 'kpis', { startDate, endDate });
  const details = useAnalyticsData<AdjustmentRecord[]>('adjustment', 'details', {
    startDate,
    endDate,
  }, { enabled: activeTab === 'details' });

  const hasError = kpis.error;
  const errorCode = (hasError as Error & { code?: string })?.code;

  const refetchAll = useCallback(() => {
    kpis.refetch();
    if (activeTab === 'details') details.refetch();
  }, [kpis, details, activeTab]);

  if (hasError && errorCode === 'SNOWFLAKE_NOT_CONFIGURED') {
    return <ConnectionError code="SNOWFLAKE_NOT_CONFIGURED" onRetry={refetchAll} />;
  }

  const kpiData = kpis.data;

  return (
    <div className="space-y-6">
      <Breadcrumb
        items={[
          { href: '/', title: <><HomeOutlined /> Home</> },
          { title: 'Analytics' },
          { title: 'Adjustments' },
        ]}
      />

      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-12 h-12 rounded-lg" style={{ backgroundColor: `${domainColors.adjustment.primary}15` }}>
            <SwapOutlined style={{ fontSize: 24, color: domainColors.adjustment.primary }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">Adjustment Analytics</Title>
            <Text type="secondary">Financial adjustments, credits, and debit tracking</Text>
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
          <Button icon={<ReloadOutlined />} onClick={refetchAll}>Refresh</Button>
        </Space>
      </div>

      <Tabs
        activeKey={activeTab}
        onChange={setActiveTab}
        items={[
          { key: 'overview', label: <span><LineChartOutlined /> Overview</span> },
          { key: 'details', label: <span><TableOutlined /> Adjustment Details</span> },
        ]}
      />

      {activeTab === 'overview' ? (
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} lg={6}>
            <KPICard
              title="Total Adjustments"
              value={kpiData?.totalAdjustments ?? 0}
              format="number"
              loading={kpis.isLoading}
              color={domainColors.adjustment.primary}
            />
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <KPICard
              title="Net Adjustment"
              value={kpiData?.netAdjustment ?? 0}
              format="currency"
              loading={kpis.isLoading}
              color={(kpiData?.netAdjustment ?? 0) < 0 ? '#ff4d4f' : '#52c41a'}
              description={(kpiData?.netAdjustment ?? 0) < 0 ? 'Net Debit' : 'Net Credit'}
            />
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <KPICard
              title="Credit Adjustments"
              value={kpiData?.totalCredits ?? 0}
              format="currency"
              loading={kpis.isLoading}
              color="#52c41a"
              description={`${kpiData?.creditCount ?? 0} credits`}
            />
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <KPICard
              title="Debit Adjustments"
              value={kpiData?.totalDebits ?? 0}
              format="currency"
              loading={kpis.isLoading}
              color="#ff4d4f"
              description={`${kpiData?.debitCount ?? 0} debits`}
            />
          </Col>
        </Row>
      ) : (
        <DataGrid
          data={(details.data || []) as Record<string, unknown>[]}
          loading={details.isLoading}
          height={600}
          enablePivot={true}
          enableExport={true}
          title="Financial Adjustments"
        />
      )}
    </div>
  );
}
