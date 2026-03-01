'use client';

import ReactECharts from 'echarts-for-react';
import type { EChartsOption } from 'echarts';
import { Card, Typography } from 'antd';

const { Text } = Typography;

interface GaugeChartProps {
  value: number;
  title?: string;
  height?: number;
  min?: number;
  max?: number;
  thresholds?: { value: number; color: string }[];
  suffix?: string;
  description?: string;
  /** Optional custom formatter — when provided, overrides the default "{value}{suffix}" label */
  formatValue?: (value: number) => string;
}

export function GaugeChart({
  value,
  title,
  height = 250,
  min = 0,
  max = 100,
  thresholds = [
    { value: 0.3, color: '#ff4d4f' },
    { value: 0.7, color: '#faad14' },
    { value: 1, color: '#52c41a' },
  ],
  suffix = '%',
  description,
  formatValue,
}: GaugeChartProps) {
  // Determine color based on value
  const normalizedValue = (value - min) / (max - min);
  let valueColor = '#52c41a';
  for (const threshold of thresholds) {
    if (normalizedValue <= threshold.value) {
      valueColor = threshold.color;
      break;
    }
  }

  const option: EChartsOption = {
    series: [
      {
        type: 'gauge',
        startAngle: 200,
        endAngle: -20,
        min,
        max,
        radius: '90%',
        center: ['50%', '60%'],
        splitNumber: 5,
        itemStyle: {
          color: valueColor,
        },
        progress: {
          show: true,
          roundCap: true,
          width: 18,
        },
        pointer: {
          show: false,
        },
        axisLine: {
          roundCap: true,
          lineStyle: {
            width: 18,
            color: [[1, '#e6e6e6']],
          },
        },
        axisTick: {
          show: false,
        },
        splitLine: {
          show: false,
        },
        axisLabel: {
          show: false,
        },
        title: {
          show: false,
        },
        detail: {
          valueAnimation: true,
          offsetCenter: [0, '10%'],
          fontSize: 28,
          fontWeight: 'bold',
          formatter: formatValue ? (v: number) => formatValue(v) : `{value}${suffix}`,
          color: valueColor,
        },
        data: [{ value }],
      },
    ],
  };

  return (
    <Card
      title={title && <Text strong>{title}</Text>}
      className="chart-container"
      styles={{ body: { padding: '12px', textAlign: 'center' } }}
    >
      <ReactECharts option={option} style={{ height }} />
      {description && (
        <Text type="secondary" className="text-sm">
          {description}
        </Text>
      )}
    </Card>
  );
}
