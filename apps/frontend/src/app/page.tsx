'use client';

import { useCallback } from 'react';
import { Card, Row, Col, Statistic, Typography, Space, Button, Tag, Spin } from 'antd';
import {
  CreditCardOutlined,
  BankOutlined,
  DollarOutlined,
  WarningOutlined,
  FileSearchOutlined,
  SwapOutlined,
  ArrowUpOutlined,
  ArrowDownOutlined,
  ArrowRightOutlined,
  MessageOutlined,
} from '@ant-design/icons';
import Link from 'next/link';
import { DOMAINS } from '@/types/domain';
import { useAnalyticsData } from '@/hooks';
import type {
  AuthorizationKPIs,
  SettlementKPIs,
  FundingKPIs,
  ChargebackKPIs,
  RetrievalKPIs,
  AdjustmentKPIs,
} from '@/types/domain';

const { Title, Text, Paragraph } = Typography;

const domainIcons: Record<string, React.ReactNode> = {
  authorization: <CreditCardOutlined />,
  settlement: <BankOutlined />,
  funding: <DollarOutlined />,
  chargeback: <WarningOutlined />,
  retrieval: <FileSearchOutlined />,
  adjustment: <SwapOutlined />,
};

const formatCurrency = (value: number) =>
  new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(value);

const formatNumber = (value: number) =>
  new Intl.NumberFormat('en-US').format(value);

// Default date range: last 30 days
const endDate = new Date().toISOString().split('T')[0];
const startDateObj = new Date();
startDateObj.setDate(startDateObj.getDate() - 30);
const startDate = startDateObj.toISOString().split('T')[0];

export default function DashboardPage() {
  const authKpis = useAnalyticsData<AuthorizationKPIs>('authorization', 'kpis', { startDate, endDate });
  const settleKpis = useAnalyticsData<SettlementKPIs>('settlement', 'kpis', { startDate, endDate });
  const fundKpis = useAnalyticsData<FundingKPIs>('funding', 'kpis', { startDate, endDate });
  const cbKpis = useAnalyticsData<ChargebackKPIs>('chargeback', 'kpis', { startDate, endDate });
  const retKpis = useAnalyticsData<RetrievalKPIs>('retrieval', 'kpis', { startDate, endDate });
  const adjKpis = useAnalyticsData<AdjustmentKPIs>('adjustment', 'kpis', { startDate, endDate });

  const isLoading = authKpis.isLoading || settleKpis.isLoading || fundKpis.isLoading;

  const refetchAll = useCallback(() => {
    authKpis.refetch();
    settleKpis.refetch();
    fundKpis.refetch();
    cbKpis.refetch();
    retKpis.refetch();
    adjKpis.refetch();
  }, [authKpis, settleKpis, fundKpis, cbKpis, retKpis, adjKpis]);

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <Title level={2} className="!mb-1">
            Performance Intelligence
          </Title>
          <Text type="secondary">
            Analytics overview for DMCL - Last 30 days
          </Text>
        </div>
        <Space>
          <Button onClick={refetchAll}>Refresh</Button>
          <Link href="/chat">
            <Button type="primary" icon={<MessageOutlined />} size="large">
              Ask Your Data
            </Button>
          </Link>
        </Space>
      </div>

      {/* Quick Stats Row */}
      <Spin spinning={isLoading}>
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} lg={8}>
            <Card className="kpi-card">
              <Statistic
                title="Total Authorizations"
                value={authKpis.data?.totalTransactions ?? 0}
                formatter={(val) => formatNumber(val as number)}
                prefix={<CreditCardOutlined style={{ color: '#FF6600' }} />}
                suffix={
                  authKpis.data?.trends?.transactions !== undefined ? (
                    <Tag color={authKpis.data.trends.transactions >= 0 ? 'success' : 'error'}>
                      {authKpis.data.trends.transactions >= 0 ? <ArrowUpOutlined /> : <ArrowDownOutlined />}
                      {Math.abs(authKpis.data.trends.transactions)}%
                    </Tag>
                  ) : null
                }
              />
              <div className="mt-2">
                <Text type="secondary">Approval Rate: </Text>
                <Text strong style={{ color: '#52c41a' }}>
                  {authKpis.data?.approvalRate ?? 0}%
                </Text>
              </div>
            </Card>
          </Col>

          <Col xs={24} sm={12} lg={8}>
            <Card className="kpi-card">
              <Statistic
                title="Net Settlement Volume"
                value={settleKpis.data?.netVolume ?? 0}
                formatter={(val) => formatCurrency(val as number)}
                prefix={<BankOutlined style={{ color: '#1890ff' }} />}
              />
            </Card>
          </Col>

          <Col xs={24} sm={12} lg={8}>
            <Card className="kpi-card">
              <Statistic
                title="Total Deposits"
                value={fundKpis.data?.totalDeposits ?? 0}
                formatter={(val) => formatCurrency(val as number)}
                prefix={<DollarOutlined style={{ color: '#52c41a' }} />}
              />
              <div className="mt-2">
                <Text type="secondary">{formatNumber(fundKpis.data?.totalFundingRecords ?? 0)} deposits</Text>
              </div>
            </Card>
          </Col>
        </Row>
      </Spin>

      {/* Domain Cards */}
      <div>
        <Title level={4} className="!mb-4">
          Analytics Domains
        </Title>
        <Row gutter={[16, 16]}>
          {Object.values(DOMAINS).map((domain) => (
            <Col xs={24} sm={12} lg={8} key={domain.key}>
              <Link href={`/analytics/${domain.key}`}>
                <Card
                  hoverable
                  className="h-full"
                  styles={{ body: { padding: '20px' } }}
                >
                  <Space orientation="vertical" size="small" className="w-full">
                    <Space>
                      <div
                        className="flex items-center justify-center w-10 h-10 rounded-lg text-xl"
                        style={{ backgroundColor: `${domain.color}15`, color: domain.color }}
                      >
                        {domainIcons[domain.key]}
                      </div>
                      <div>
                        <Text strong className="text-base">
                          {domain.label}
                        </Text>
                      </div>
                    </Space>
                    <Paragraph type="secondary" className="!mb-0 text-sm">
                      {domain.description}
                    </Paragraph>
                    <div className="flex items-center justify-between mt-2">
                      <Text type="secondary" className="text-xs">
                        {domain.tableName}
                      </Text>
                      <ArrowRightOutlined style={{ color: domain.color }} />
                    </div>
                  </Space>
                </Card>
              </Link>
            </Col>
          ))}
        </Row>
      </div>

      {/* Recent Activity / Quick Actions */}
      <Row gutter={[16, 16]}>
        <Col xs={24} lg={12}>
          <Card title="Alerts & Notifications" extra={<Link href="/alerts">View All</Link>}>
            <Space orientation="vertical" className="w-full" size="middle">
              <div className="flex items-center gap-3 p-3 bg-red-50 rounded-lg">
                <WarningOutlined style={{ color: '#ff4d4f', fontSize: 20 }} />
                <div className="flex-1">
                  <Text strong>Chargebacks</Text>
                  <br />
                  <Text type="secondary" className="text-sm">
                    {formatNumber(cbKpis.data?.totalChargebacks ?? 0)} total disputes ({formatCurrency(cbKpis.data?.totalDisputeAmount ?? 0)})
                  </Text>
                </div>
                <Tag color="error">{formatNumber(cbKpis.data?.openCount ?? 0)} open</Tag>
              </div>
              <div className="flex items-center gap-3 p-3 bg-yellow-50 rounded-lg">
                <FileSearchOutlined style={{ color: '#faad14', fontSize: 20 }} />
                <div className="flex-1">
                  <Text strong>Retrievals pending</Text>
                  <br />
                  <Text type="secondary" className="text-sm">
                    {formatNumber(retKpis.data?.openCount ?? 0)} open of {formatNumber(retKpis.data?.totalRetrievals ?? 0)} total
                  </Text>
                </div>
                <Tag color="warning">Attention</Tag>
              </div>
              <div className="flex items-center gap-3 p-3 bg-blue-50 rounded-lg">
                <SwapOutlined style={{ color: '#13c2c2', fontSize: 20 }} />
                <div className="flex-1">
                  <Text strong>Adjustments</Text>
                  <br />
                  <Text type="secondary" className="text-sm">
                    Net: {formatCurrency(adjKpis.data?.netAdjustment ?? 0)} ({formatNumber(adjKpis.data?.totalAdjustments ?? 0)} total)
                  </Text>
                </div>
                <Tag color="processing">Info</Tag>
              </div>
            </Space>
          </Card>
        </Col>

        <Col xs={24} lg={12}>
          <Card title="Quick Questions" extra={<Link href="/chat">Ask More</Link>}>
            <Space orientation="vertical" className="w-full" size="middle">
              {[
                'What is my approval rate by card brand this month?',
                'Show top 10 merchants by settlement volume',
                'What are my chargeback trends over the last 12 months?',
                'How much did I pay in interchange fees last week?',
              ].map((question, idx) => (
                <Link href={`/chat?q=${encodeURIComponent(question)}`} key={idx}>
                  <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-orange-50 transition-colors cursor-pointer">
                    <MessageOutlined style={{ color: '#FF6600' }} />
                    <Text className="flex-1">{question}</Text>
                    <ArrowRightOutlined className="text-gray-400" />
                  </div>
                </Link>
              ))}
            </Space>
          </Card>
        </Col>
      </Row>
    </div>
  );
}
