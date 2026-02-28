'use client';

import { Card, Typography, Space } from 'antd';
import {
  CreditCardOutlined,
  BankOutlined,
  DollarOutlined,
  WarningOutlined,
  FileSearchOutlined,
  SwapOutlined,
} from '@ant-design/icons';
import { suggestedQueries } from '@/lib/cortex';
import { DomainType } from '@/types/domain';

const { Text } = Typography;

interface SuggestedQueriesProps {
  onSelectQuery: (query: string) => void;
}

const domainIcons: Record<DomainType, React.ReactNode> = {
  authorization: <CreditCardOutlined />,
  settlement: <BankOutlined />,
  funding: <DollarOutlined />,
  chargeback: <WarningOutlined />,
  retrieval: <FileSearchOutlined />,
  adjustment: <SwapOutlined />,
};

const domainLabels: Record<DomainType, string> = {
  authorization: 'Authorization',
  settlement: 'Settlement',
  funding: 'Funding',
  chargeback: 'Chargebacks',
  retrieval: 'Retrievals',
  adjustment: 'Adjustments',
};

const domainColors: Record<DomainType, string> = {
  authorization: '#FF6600',
  settlement: '#1890ff',
  funding: '#52c41a',
  chargeback: '#ff4d4f',
  retrieval: '#722ed1',
  adjustment: '#13c2c2',
};

export function SuggestedQueries({ onSelectQuery }: SuggestedQueriesProps) {
  return (
    <div className="space-y-4">
      <Text type="secondary" className="text-sm">
        Click a question to get started
      </Text>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {(Object.keys(suggestedQueries) as DomainType[]).map((domain) => (
          <Card
            key={domain}
            size="small"
            title={
              <Space>
                <span style={{ color: domainColors[domain] }}>
                  {domainIcons[domain]}
                </span>
                <span>{domainLabels[domain]}</span>
              </Space>
            }
            className="h-full"
            styles={{ body: { padding: '12px' } }}
          >
            <Space orientation="vertical" className="w-full" size="small">
              {suggestedQueries[domain].map((query, idx) => (
                <div
                  key={idx}
                  className="p-2 bg-gray-50 rounded cursor-pointer hover:bg-orange-50 transition-colors text-sm"
                  onClick={() => onSelectQuery(query)}
                >
                  {query}
                </div>
              ))}
            </Space>
          </Card>
        ))}
      </div>
    </div>
  );
}
