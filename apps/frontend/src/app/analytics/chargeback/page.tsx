'use client';

import { useState, useCallback } from 'react';
import { Card, Row, Col, Statistic, Select, DatePicker, Space, Typography, Spin, Tag, Progress, Tabs, Breadcrumb, Button } from 'antd';
import {
  DollarOutlined,
  ExclamationCircleOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  WarningOutlined,
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
import { useAnalyticsData } from '@/hooks';
import { domainColors } from '@/lib/theme';
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

  const isLoading = kpis.isLoading || byReason.isLoading;
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

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(value);

  const formatNumber = (value: number) =>
    new Intl.NumberFormat('en-US').format(value);

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
        <Spin spinning={isLoading}>
          <Row gutter={[16, 16]}>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Total Dispute Amount"
                  value={kpiData?.totalDisputeAmount ?? 0}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: domainColors.chargeback.primary }} />}
                  formatter={(value) => formatCurrency(value as number)}
                  styles={{ content: { color: domainColors.chargeback.primary } }}
                />
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Chargeback Count"
                  value={kpiData?.totalChargebacks ?? 0}
                  prefix={<ExclamationCircleOutlined style={{ color: domainColors.chargeback.primary }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Transaction Amount"
                  value={kpiData?.totalTransactionAmount ?? 0}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: '#faad14' }} />}
                  formatter={(value) => formatCurrency(value as number)}
                />
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Win Rate"
                  value={kpiData?.winRate ?? 0}
                  precision={1}
                  suffix="%"
                  prefix={<CheckCircleOutlined style={{ color: '#52c41a' }} />}
                  styles={{ content: { color: '#52c41a' } }}
                />
                <div className="mt-2">
                  <Progress percent={kpiData?.winRate ?? 0} showInfo={false} strokeColor="#52c41a" size="small" />
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Open Disputes"
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
                  title="Won / Lost"
                  value={kpiData?.wonCount ?? 0}
                  prefix={<WarningOutlined style={{ color: '#1890ff' }} />}
                  suffix={` / ${kpiData?.lostCount ?? 0}`}
                />
                <div className="mt-2">
                  <Tag color="blue">{formatNumber(kpiData?.closedCount ?? 0)} closed</Tag>
                </div>
              </Card>
            </Col>
          </Row>

          <Row gutter={[16, 16]} className="mt-4">
            <Col xs={24}>
              <Card title="Chargebacks by Reason Code" className="h-full">
                <BarChart
                  data={reasonData}
                  height={300}
                  colors={[domainColors.chargeback.primary]}
                  horizontal={true}
                  formatValue={(v) => `$${(v / 1000).toFixed(0)}K`}
                />
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
            title="Chargeback Cases"
          />
        </Spin>
      )}
    </div>
  );
}
