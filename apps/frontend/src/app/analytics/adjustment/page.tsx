'use client';

import { useState, useCallback } from 'react';
import { Card, Row, Col, Statistic, DatePicker, Space, Typography, Spin, Tag, Tabs, Breadcrumb, Button } from 'antd';
import {
  DollarOutlined,
  SwapOutlined,
  PlusCircleOutlined,
  MinusCircleOutlined,
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

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(value);

  const formatNumber = (value: number) =>
    new Intl.NumberFormat('en-US').format(value);

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
        <Spin spinning={isLoading}>
          <Row gutter={[16, 16]}>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Total Adjustments"
                  value={kpiData?.totalAdjustments ?? 0}
                  prefix={<FileTextOutlined style={{ color: domainColors.adjustment.primary }} />}
                  formatter={(value) => formatNumber(value as number)}
                />
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Net Adjustment"
                  value={kpiData?.netAdjustment ?? 0}
                  precision={0}
                  prefix={<DollarOutlined style={{ color: (kpiData?.netAdjustment ?? 0) < 0 ? '#ff4d4f' : '#52c41a' }} />}
                  formatter={(value) => formatCurrency(value as number)}
                  styles={{ content: { color: (kpiData?.netAdjustment ?? 0) < 0 ? '#ff4d4f' : '#52c41a' } }}
                />
                <div className="mt-2">
                  <Tag color={(kpiData?.netAdjustment ?? 0) < 0 ? 'red' : 'green'}>
                    Net {(kpiData?.netAdjustment ?? 0) < 0 ? 'Debit' : 'Credit'}
                  </Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Credit Adjustments"
                  value={kpiData?.totalCredits ?? 0}
                  precision={0}
                  prefix={<PlusCircleOutlined style={{ color: '#52c41a' }} />}
                  formatter={(value) => formatCurrency(value as number)}
                  styles={{ content: { color: '#52c41a' } }}
                />
                <div className="mt-2">
                  <Tag color="green">{formatNumber(kpiData?.creditCount ?? 0)} credits</Tag>
                </div>
              </Card>
            </Col>
            <Col xs={24} sm={12} lg={8} xl={4}>
              <Card>
                <Statistic
                  title="Debit Adjustments"
                  value={kpiData?.totalDebits ?? 0}
                  precision={0}
                  prefix={<MinusCircleOutlined style={{ color: '#ff4d4f' }} />}
                  formatter={(value) => formatCurrency(value as number)}
                  styles={{ content: { color: '#ff4d4f' } }}
                />
                <div className="mt-2">
                  <Tag color="red">{formatNumber(kpiData?.debitCount ?? 0)} debits</Tag>
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
            title="Financial Adjustments"
          />
        </Spin>
      )}
    </div>
  );
}
