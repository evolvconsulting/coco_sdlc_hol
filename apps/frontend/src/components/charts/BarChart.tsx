'use client';

import ReactECharts from 'echarts-for-react';
import type { EChartsOption } from 'echarts';
import { Card, Typography } from 'antd';

const { Text } = Typography;

interface BarChartDataPoint {
  name: string;
  value: number;
  category?: string;
}

interface BarChartProps {
  data: BarChartDataPoint[];
  title?: string;
  height?: number;
  horizontal?: boolean;
  showLegend?: boolean;
  stacked?: boolean;
  formatValue?: (value: number) => string;
  colors?: string[];
  xAxisLabel?: string;
  yAxisLabel?: string;
}

const defaultColors = ['#FF6600', '#1890ff', '#52c41a', '#722ed1', '#13c2c2', '#faad14'];

export function BarChart({
  data,
  title,
  height = 300,
  horizontal = false,
  showLegend = false,
  stacked = false,
  formatValue,
  colors = defaultColors,
  xAxisLabel,
  yAxisLabel,
}: BarChartProps) {
  // Group by category if present
  const categories = [...new Set(data.map((d) => d.category).filter((c): c is string => c !== undefined))];
  const hasCategories = categories.length > 0;
  const names = [...new Set(data.map((d) => d.name))];

  const series = hasCategories
    ? categories.map((category, index) => ({
        name: category,
        type: 'bar' as const,
        stack: stacked ? 'total' : undefined,
        data: names.map((name) => {
          const item = data.find((d) => d.name === name && d.category === category);
          return item?.value || 0;
        }),
        itemStyle: {
          color: colors[index % colors.length],
          borderRadius: horizontal ? [0, 4, 4, 0] : [4, 4, 0, 0],
        },
      }))
    : [
        {
          type: 'bar' as const,
          data: data.map((d, index) => ({
            value: d.value,
            itemStyle: {
              color: colors[index % colors.length],
              borderRadius: horizontal ? [0, 4, 4, 0] : [4, 4, 0, 0],
            },
          })),
        },
      ];

  const categoryAxis = {
    type: 'category' as const,
    data: names,
    axisLabel: {
      rotate: horizontal ? 0 : names.length > 5 ? 45 : 0,
      interval: 0,
    },
    name: horizontal ? yAxisLabel : xAxisLabel,
    nameLocation: 'middle' as const,
    nameGap: 40,
  };

  const valueAxis = {
    type: 'value' as const,
    axisLabel: {
      formatter: (value: number) =>
        formatValue ? formatValue(value) : new Intl.NumberFormat('en-US', { notation: 'compact' }).format(value),
    },
    name: horizontal ? xAxisLabel : yAxisLabel,
    nameLocation: 'middle' as const,
    nameGap: 50,
  };

  const option: EChartsOption = {
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow',
      },
      formatter: (params: unknown) => {
        const items = Array.isArray(params) ? params : [params];
        const lines = items.map((item: { marker?: string; seriesName?: string; value: number; name?: string }) => {
          const value = formatValue
            ? formatValue(item.value)
            : new Intl.NumberFormat('en-US').format(item.value);
          return hasCategories ? `${item.marker} ${item.seriesName}: ${value}` : value;
        });
        const firstItem = items[0] as { name?: string };
        return `${firstItem.name || ''}<br/>${lines.join('<br/>')}`;
      },
    },
    legend: showLegend && hasCategories
      ? {
          data: categories,
          bottom: 0,
        }
      : undefined,
    grid: {
      left: '3%',
      right: '4%',
      bottom: showLegend ? '15%' : '3%',
      top: '10%',
      containLabel: true,
    },
    xAxis: horizontal ? valueAxis : categoryAxis,
    yAxis: horizontal ? categoryAxis : valueAxis,
    series,
  };

  return (
    <Card
      title={title && <Text strong>{title}</Text>}
      className="chart-container"
      styles={{ body: { padding: '12px' } }}
    >
      <ReactECharts option={option} style={{ height }} />
    </Card>
  );
}
