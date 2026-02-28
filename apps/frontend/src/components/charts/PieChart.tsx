'use client';

import ReactECharts from 'echarts-for-react';
import type { EChartsOption } from 'echarts';
import { Card, Typography } from 'antd';

const { Text } = Typography;

interface PieChartDataPoint {
  name: string;
  value: number;
  color?: string;
}

interface PieChartProps {
  data: PieChartDataPoint[];
  title?: string;
  height?: number;
  showLegend?: boolean;
  donut?: boolean;
  formatValue?: (value: number) => string;
  colors?: string[];
}

const defaultColors = ['#FF6600', '#1890ff', '#52c41a', '#722ed1', '#13c2c2', '#faad14', '#eb2f96', '#666666'];

export function PieChart({
  data,
  title,
  height = 300,
  showLegend = true,
  donut = true,
  formatValue,
  colors = defaultColors,
}: PieChartProps) {
  const total = data.reduce((sum, item) => sum + item.value, 0);

  const option: EChartsOption = {
    tooltip: {
      trigger: 'item',
      formatter: (params: unknown) => {
        const item = params as { name: string; value: number; percent: number };
        const formattedValue = formatValue
          ? formatValue(item.value)
          : new Intl.NumberFormat('en-US').format(item.value);
        return `${item.name}<br/>${formattedValue} (${item.percent.toFixed(1)}%)`;
      },
    },
    legend: showLegend
      ? {
          orient: 'vertical',
          right: '5%',
          top: 'center',
          formatter: (name: string) => {
            const item = data.find((d) => d.name === name);
            if (!item) return name;
            const percent = ((item.value / total) * 100).toFixed(1);
            return `${name} (${percent}%)`;
          },
        }
      : undefined,
    series: [
      {
        type: 'pie',
        radius: donut ? ['45%', '70%'] : '70%',
        center: showLegend ? ['35%', '50%'] : ['50%', '50%'],
        avoidLabelOverlap: true,
        itemStyle: {
          borderRadius: 4,
          borderColor: '#fff',
          borderWidth: 2,
        },
        label: {
          show: !showLegend,
          formatter: '{b}: {d}%',
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 14,
            fontWeight: 'bold',
          },
          itemStyle: {
            shadowBlur: 10,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.2)',
          },
        },
        labelLine: {
          show: !showLegend,
        },
        data: data.map((item, index) => ({
          ...item,
          itemStyle: {
            color: item.color || colors[index % colors.length],
          },
        })),
      },
    ],
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
