'use client';

import { useState, useCallback } from 'react';
import { Card, Row, Col, Statistic, Select, DatePicker, Space, Typography, Spin, Tag, Progress, Tabs, Breadcrumb, Button } from 'antd';
import {
  FileSearchOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  FileTextOutlined,
  HomeOutlined,
  ReloadOutlined,
  LineChartOutlined,
  TableOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { DataGrid } from '@/components/grid/DataGrid';
import { ConnectionError } from '@/components/ui/ConnectionError';
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
  const [reasonCode, setReasonCode] = useState<string | null>(null);
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

  const isLoading = kpis.isLoading;
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

  const formatNumber = (value: number) =>
    new Intl.NumberFormat('en-US').format(value);

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(value);

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
        <Spin spinning={isLoading}>
          <Row gutter={[16, 16]}>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Total Retrievals"
                  value={kpiData?.totalRetrievals ?? 0}
                  prefix={<FileTextOutlined style={{ color: domainColors.retrieval.primary }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Total Amount"
                  value={kpiData?.totalAmount ?? 0}
                  precision={0}
                  prefix={<FileSearchOutlined style={{ color: domainColors.retrieval.primary }} />}
                  formatter={(value) => formatCurrency(value as number)}
                />
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Fulfillment Rate"
                  value={kpiData?.fulfillmentRate ?? 0}
                  precision={1}
                  suffix="%"
                  prefix={<CheckCircleOutlined style={{ color: '#52c41a' }} />}
                  styles={{ content: { color: '#52c41a' } }}
                />
                <div className="mt-2">
                  <Progress percent={kpiData?.fulfillmentRate ?? 0} showInfo={false} strokeColor="#52c41a" size="small" />
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Open"
                  value={kpiData?.openCount ?? 0}
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
                  title="Fulfilled"
                  value={kpiData?.fulfilledCount ?? 0}
                  prefix={<CheckCircleOutlined style={{ color: '#52c41a' }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
                <div className="mt-2">
                  <Tag color="green">
                    {kpiData && kpiData.totalRetrievals > 0
                      ? `${((kpiData.fulfilledCount / kpiData.totalRetrievals) * 100).toFixed(1)}% of total`
                      : '0%'}
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Expired"
                  value={kpiData?.expiredCount ?? 0}
                  prefix={<ExclamationCircleOutlined style={{ color: '#ff4d4f' }} />}
                  formatter={(value) => formatNumber(value as number)}
                  styles={{ content: { color: '#ff4d4f' } }}
                />
                <div className="mt-2">
                  <Tag color="red">
                    {kpiData && kpiData.totalRetrievals > 0
                      ? `${((kpiData.expiredCount / kpiData.totalRetrievals) * 100).toFixed(1)}% of total`
                      : '0%'}
                  </Tag>
                </div>
              </Card>
            </Col>
          </Row>
        </Spin>
      ) : (
        <Spin spinning={details.isLoading}>
          <DataGrid
            data={(details.data || []) as Record<string, unknown>[]}
            height={600}
            enablePivot={true}
            enableExport={true}
            title="Retrieval Requests"
          />
        </Spin>
      )}
    </div>
  );
}
