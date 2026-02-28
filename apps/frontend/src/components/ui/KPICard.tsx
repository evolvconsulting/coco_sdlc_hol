'use client';

import { Card, Tag, Tooltip } from 'antd';
import { ArrowUpOutlined, ArrowDownOutlined, InfoCircleOutlined } from '@ant-design/icons';

interface KPICardProps {
  title: string;
  value: number | string;
  prefix?: React.ReactNode;
  suffix?: string;
  trend?: number;
  trendLabel?: string;
  trendInverted?: boolean; // When true, down is good (like chargebacks)
  description?: string;
  format?: 'number' | 'currency' | 'percent';
  loading?: boolean;
  color?: string;
}

export function KPICard({
  title,
  value,
  prefix,
  suffix,
  trend,
  trendLabel,
  trendInverted = false,
  description,
  format = 'number',
  loading = false,
  color,
}: KPICardProps) {
  const formatValue = (val: number | string): string => {
    if (typeof val === 'string') return val;
    
    switch (format) {
      case 'currency':
        return new Intl.NumberFormat('en-US', {
          style: 'currency',
          currency: 'USD',
          minimumFractionDigits: 0,
          maximumFractionDigits: 0,
        }).format(val);
      case 'percent':
        return `${val.toFixed(2)}%`;
      default:
        return new Intl.NumberFormat('en-US').format(val);
    }
  };

  const isTrendPositive = trend !== undefined && (trendInverted ? trend < 0 : trend > 0);
  const trendColor = isTrendPositive ? 'success' : trend !== undefined && trend !== 0 ? 'error' : 'default';

  return (
    <Card 
      className="kpi-card h-full" 
      loading={loading}
      styles={{ body: { padding: '20px' } }}
    >
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-2">
            <span className="text-sm text-gray-500">{title}</span>
            {description && (
              <Tooltip title={description}>
                <InfoCircleOutlined className="text-gray-400 text-xs cursor-help" />
              </Tooltip>
            )}
          </div>
          <div className="flex items-baseline gap-2">
            {prefix && (
              <span style={{ color: color || '#FF6600', fontSize: 20 }}>{prefix}</span>
            )}
            <span 
              className="text-2xl font-bold" 
              style={{ color: color || '#1a1a1a' }}
            >
              {formatValue(value)}
            </span>
            {suffix && <span className="text-sm text-gray-500">{suffix}</span>}
          </div>
        </div>
        
        {trend !== undefined && (
          <Tag 
            color={trendColor}
            className="ml-2"
          >
            {trend > 0 ? <ArrowUpOutlined /> : trend < 0 ? <ArrowDownOutlined /> : null}
            {Math.abs(trend).toFixed(1)}%
            {trendLabel && <span className="ml-1 text-xs">{trendLabel}</span>}
          </Tag>
        )}
      </div>
    </Card>
  );
}
