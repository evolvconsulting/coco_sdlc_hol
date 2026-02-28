'use client';

import ReactECharts from 'echarts-for-react';
import type { EChartsOption } from 'echarts';
import { Card, Typography } from 'antd';

const { Text } = Typography;

interface TimeSeriesDataPoint {
  date: string;
  value: number;
  category?: string;
}

export type { TimeSeriesDataPoint };

interface TimeSeriesChartProps {
  data: TimeSeriesDataPoint[];
  title?: string;
  height?: number;
  xAxisLabel?: string;
  yAxisLabel?: string;
  color?: string;
  showArea?: boolean;
  formatValue?: (value: number) => string;
  multiSeries?: boolean;
}

export function TimeSeriesChart({
  data,
  title,
  height = 300,
  xAxisLabel,
  yAxisLabel,
  color = '#FF6600',
  showArea = true,
  formatValue,
  multiSeries = false,
}: TimeSeriesChartProps) {
  // Group data by category if multi-series
  const seriesData = multiSeries
    ? Object.entries(
        data.reduce((acc, item) => {
          const category = item.category || 'default';
          if (!acc[category]) acc[category] = [];
          acc[category].push(item);
          return acc;
        }, {} as Record<string, TimeSeriesDataPoint[]>)
      )
    : [['default', data]];

  const colors = ['#FF6600', '#1890ff', '#52c41a', '#722ed1', '#13c2c2', '#faad14'];

  const option: EChartsOption = {
    tooltip: {
      trigger: 'axis',
      formatter: (params: unknown) => {
        const items = Array.isArray(params) ? params : [params];
        const lines = items.map((item: { marker?: string; seriesName?: string; value: number; axisValue?: string }) => {
          const value = formatValue
            ? formatValue(item.value)
            : new Intl.NumberFormat('en-US').format(item.value);
          return `${item.marker} ${item.seriesName}: ${value}`;
        });
        const firstItem = items[0] as { axisValue?: string };
        return `${firstItem.axisValue || ''}<br/>${lines.join('<br/>')}`;
      },
    },
    legend: multiSeries
      ? {
          data: seriesData.map(([category]) => String(category)),
          bottom: 0,
        }
      : undefined,
    grid: {
      left: '3%',
      right: '4%',
      bottom: multiSeries ? '15%' : '3%',
      top: '10%',
      containLabel: true,
    },
    xAxis: {
      type: 'category',
      data: [...new Set(data.map((d) => d.date))],
      name: xAxisLabel,
      nameLocation: 'middle',
      nameGap: 30,
      axisLabel: {
        formatter: (value: string) => {
          const date = new Date(value);
          return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        },
      },
    },
    yAxis: {
      type: 'value',
      name: yAxisLabel,
      nameLocation: 'middle',
      nameGap: 50,
      axisLabel: {
        formatter: (value: number) =>
          formatValue ? formatValue(value) : new Intl.NumberFormat('en-US', { notation: 'compact' }).format(value),
      },
    },
    series: seriesData.map(([category, points], index) => ({
      name: String(category),
      type: 'line' as const,
      data: (points as TimeSeriesDataPoint[]).map((d) => d.value),
      smooth: true,
      lineStyle: {
        width: 2,
        color: multiSeries ? colors[index % colors.length] : color,
      },
      itemStyle: {
        color: multiSeries ? colors[index % colors.length] : color,
      },
      areaStyle: showArea
        ? {
            color: {
              type: 'linear',
              x: 0,
              y: 0,
              x2: 0,
              y2: 1,
              colorStops: [
                { offset: 0, color: `${multiSeries ? colors[index % colors.length] : color}40` },
                { offset: 1, color: `${multiSeries ? colors[index % colors.length] : color}05` },
              ],
            },
          }
        : undefined,
    })),
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
