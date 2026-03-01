'use client';

import { useState, useCallback } from 'react';
import { Row, Col, Select, DatePicker, Space, Typography, Tabs, Breadcrumb, Button } from 'antd';
import {
  FileSearchOutlined,
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
import type { RetrievalKPIs, RetrievalRecord } from '@/types/domain';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

export default function RetrievalAnalyticsPage() {
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().subtract(30, 'day'),
    dayjs(),
  ]);
  const [status, setStatus] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('overview');

  const startDate = dateRange[0].format('YYYY-MM-DD');
  const endDate = dateRange[1].format('YYYY-MM-DD');

  const kpis = useAnalyticsData<RetrievalKPIs>('retrieval', 'kpis', { startDate, endDate });
  const details = useAnalyticsData<RetrievalRecord[]>('retrieval', 'details', {
    startDate,
    endDate,
    status: status || undefined,
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
          { title: 'Retrievals' },
        ]}
      />

      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-12 h-12 rounded-lg" style={{ backgroundColor: `${domainColors.retrieval.primary}15` }}>
            <FileSearchOutlined style={{ fontSize: 24, color: domainColors.retrieval.primary }} />
          </div>
          <div>
            <Title level={3} className="!mb-0">Retrieval Analytics</Title>
            <Text type="secondary">Document retrieval requests and fulfillment tracking</Text>
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
            placeholder="All Status"
            allowClear
            style={{ width: 130 }}
            value={status}
            onChange={setStatus}
            options={[
              { value: 'OPEN', label: 'Open' },
              { value: 'FULFILLED', label: 'Fulfilled' },
              { value: 'EXPIRED', label: 'Expired' },
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
          { key: 'details', label: <span><TableOutlined /> Retrieval Details</span> },
        ]}
      />

      {activeTab === 'overview' ? (
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} lg={8} xl={4}>
            <KPICard
              title="Total Retrievals"
              value={kpiData?.totalRetrievals ?? 0}
              format="number"
              loading={kpis.isLoading}
              color={domainColors.retrieval.primary}
            />
          </Col>
          <Col xs={24} sm={12} lg={8} xl={4}>
            <KPICard
              title="Total Amount"
              value={kpiData?.totalAmount ?? 0}
              format="currency"
              loading={kpis.isLoading}
              color={domainColors.retrieval.primary}
            />
          </Col>
          <Col xs={24} sm={12} lg={8} xl={4}>
            <KPICard
              title="Fulfillment Rate"
              value={kpiData?.fulfillmentRate ?? 0}
              format="percent"
              loading={kpis.isLoading}
              color="#52c41a"
            />
          </Col>
          <Col xs={24} sm={12} lg={8} xl={4}>
            <KPICard
              title="Open"
              value={kpiData?.openCount ?? 0}
              format="number"
              loading={kpis.isLoading}
              description="Requires Action"
            />
          </Col>
          <Col xs={24} sm={12} lg={8} xl={4}>
            <KPICard
              title="Fulfilled"
              value={kpiData?.fulfilledCount ?? 0}
              format="number"
              loading={kpis.isLoading}
              color="#52c41a"
            />
          </Col>
          <Col xs={24} sm={12} lg={8} xl={4}>
            <KPICard
              title="Expired"
              value={kpiData?.expiredCount ?? 0}
              format="number"
              loading={kpis.isLoading}
              color="#ff4d4f"
              trendInverted={true}
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
          title="Retrieval Requests"
        />
      )}
    </div>
  );
}
