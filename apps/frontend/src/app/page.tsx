'use client';
import { Card, Row, Col, Statistic, Typography, Space, Button, Tag } from 'antd';
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

const { Title, Text, Paragraph } = Typography;

// Mock KPI data for dashboard overview
const dashboardKPIs = {
  authorization: {
    value: 1247893,
    approvalRate: 96.4,
    trend: 2.3,
    trendUp: true,
  },
  settlement: {
    value: 45678234.56,
    netVolume: 42156789.12,
    trend: 5.1,
    trendUp: true,
  },
  funding: {
    value: 38234567.89,
    deposits: 412,
    trend: -1.2,
    trendUp: false,
  },
  chargeback: {
    value: 1234,
    disputeAmount: 234567.89,
    trend: -8.5,
    trendUp: true, // Down is good for chargebacks
  },
  retrieval: {
    value: 567,
    openCount: 89,
    trend: 3.2,
    trendUp: false,
  },
  adjustment: {
    value: -12345.67,
    creditCount: 234,
    debitCount: 156,
    trend: 1.5,
    trendUp: false,
  },
};

const domainIcons: Record<string, React.ReactNode> = {
  authorization: <CreditCardOutlined />,
  settlement: <BankOutlined />,
  funding: <DollarOutlined />,
  chargeback: <WarningOutlined />,
  retrieval: <FileSearchOutlined />,
  adjustment: <SwapOutlined />,
};

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value);
};

const formatNumber = (value: number) => {
  return new Intl.NumberFormat('en-US').format(value);
};

export default function DashboardPage() {
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
        <Link href="/chat">
          <Button type="primary" icon={<MessageOutlined />} size="large">
            Ask Your Data
          </Button>
        </Link>
      </div>

      {/* Quick Stats Row */}
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={8}>
          <Card className="kpi-card">
            <Statistic
              title="Total Authorizations"
              value={dashboardKPIs.authorization.value}
              formatter={(val) => formatNumber(val as number)}
              prefix={<CreditCardOutlined style={{ color: '#FF6600' }} />}
              suffix={
                <Tag color={dashboardKPIs.authorization.trendUp ? 'success' : 'error'}>
                  {dashboardKPIs.authorization.trendUp ? <ArrowUpOutlined /> : <ArrowDownOutlined />}
                  {dashboardKPIs.authorization.trend}%
                </Tag>
              }
            />
            <div className="mt-2">
              <Text type="secondary">Approval Rate: </Text>
              <Text strong style={{ color: '#52c41a' }}>
                {dashboardKPIs.authorization.approvalRate}%
              </Text>
            </div>
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={8}>
          <Card className="kpi-card">
            <Statistic
              title="Net Settlement Volume"
              value={dashboardKPIs.settlement.netVolume}
              formatter={(val) => formatCurrency(val as number)}
              prefix={<BankOutlined style={{ color: '#1890ff' }} />}
              suffix={
                <Tag color={dashboardKPIs.settlement.trendUp ? 'success' : 'error'}>
                  {dashboardKPIs.settlement.trendUp ? <ArrowUpOutlined /> : <ArrowDownOutlined />}
                  {dashboardKPIs.settlement.trend}%
                </Tag>
              }
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={8}>
          <Card className="kpi-card">
            <Statistic
              title="Total Deposits"
              value={dashboardKPIs.funding.value}
              formatter={(val) => formatCurrency(val as number)}
              prefix={<DollarOutlined style={{ color: '#52c41a' }} />}
              suffix={
                <Tag color={dashboardKPIs.funding.trendUp ? 'success' : 'error'}>
                  {dashboardKPIs.funding.trendUp ? <ArrowUpOutlined /> : <ArrowDownOutlined />}
                  {Math.abs(dashboardKPIs.funding.trend)}%
                </Tag>
              }
            />
            <div className="mt-2">
              <Text type="secondary">{dashboardKPIs.funding.deposits} deposits</Text>
            </div>
          </Card>
        </Col>
      </Row>

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
                  <Text strong>Chargeback spike detected</Text>
                  <br />
                  <Text type="secondary" className="text-sm">
                    15% increase in chargebacks for Merchant #4521
                  </Text>
                </div>
                <Tag color="error">Critical</Tag>
              </div>
              <div className="flex items-center gap-3 p-3 bg-yellow-50 rounded-lg">
                <FileSearchOutlined style={{ color: '#faad14', fontSize: 20 }} />
                <div className="flex-1">
                  <Text strong>89 retrievals pending</Text>
                  <br />
                  <Text type="secondary" className="text-sm">
                    23 due within 48 hours
                  </Text>
                </div>
                <Tag color="warning">Attention</Tag>
              </div>
              <div className="flex items-center gap-3 p-3 bg-blue-50 rounded-lg">
                <BankOutlined style={{ color: '#1890ff', fontSize: 20 }} />
                <div className="flex-1">
                  <Text strong>Settlement complete</Text>
                  <br />
                  <Text type="secondary" className="text-sm">
                    Daily batch processed: $2.4M net
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
