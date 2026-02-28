'use client';

import { useState, useCallback, useMemo } from 'react';
import {
  Card,
  Row,
  Col,
  Select,
  DatePicker,
  InputNumber,
  Button,
  Space,
  Tag,
  Collapse,
  Typography,
  Tooltip,
  Divider,
} from 'antd';
import {
  FilterOutlined,
  ClearOutlined,
  SearchOutlined,
  SaveOutlined,
  DownloadOutlined,
  PlusOutlined,
  CloseOutlined,
} from '@ant-design/icons';
import dayjs, { Dayjs } from 'dayjs';
import type { DomainType } from '@/types/domain';

const { Text } = Typography;
const { RangePicker } = DatePicker;

// Filter field configuration by domain
const domainFilterFields: Record<DomainType, FilterFieldConfig[]> = {
  authorization: [
    { key: 'card_brand', label: 'Card Brand', type: 'select', options: ['Visa', 'Mastercard', 'Amex', 'Discover'] },
    { key: 'auth_resp_cd', label: 'Response Code', type: 'select', options: ['00 - Approved', '05 - Declined', '51 - Insufficient Funds', '14 - Invalid Card'] },
    { key: 'tran_type', label: 'Transaction Type', type: 'select', options: ['Sale', 'Refund', 'Auth Only', 'Void'] },
    { key: 'entry_mode', label: 'Entry Mode', type: 'select', options: ['Chip', 'Swipe', 'Manual', 'Contactless', 'E-Commerce'] },
    { key: 'auth_am', label: 'Amount', type: 'range', min: 0, max: 100000 },
    { key: 'merchant_id', label: 'Merchant ID', type: 'text' },
  ],
  settlement: [
    { key: 'card_brand', label: 'Card Brand', type: 'select', options: ['Visa', 'Mastercard', 'Amex', 'Discover'] },
    { key: 'settle_status', label: 'Status', type: 'select', options: ['Completed', 'Pending', 'Failed'] },
    { key: 'batch_id', label: 'Batch ID', type: 'text' },
    { key: 'settle_am', label: 'Settlement Amount', type: 'range', min: 0, max: 1000000 },
    { key: 'merchant_id', label: 'Merchant ID', type: 'text' },
  ],
  funding: [
    { key: 'fund_method', label: 'Funding Method', type: 'select', options: ['ACH', 'Wire Transfer', 'Same Day ACH'] },
    { key: 'fund_status', label: 'Status', type: 'select', options: ['Completed', 'Pending', 'Processing', 'Rejected'] },
    { key: 'deposit_am', label: 'Deposit Amount', type: 'range', min: 0, max: 1000000 },
    { key: 'merchant_id', label: 'Merchant ID', type: 'text' },
  ],
  chargeback: [
    { key: 'card_brand', label: 'Card Brand', type: 'select', options: ['Visa', 'Mastercard', 'Amex', 'Discover'] },
    { key: 'reason_cd', label: 'Reason Code', type: 'select', options: ['10.4 - Fraud', '13.1 - Not Received', '13.3 - Not as Described', '13.6 - Credit Not Processed'] },
    { key: 'cb_status', label: 'Status', type: 'select', options: ['Pending', 'Won', 'Lost', 'In Progress'] },
    { key: 'cb_am', label: 'Chargeback Amount', type: 'range', min: 0, max: 50000 },
    { key: 'merchant_id', label: 'Merchant ID', type: 'text' },
  ],
  retrieval: [
    { key: 'card_brand', label: 'Card Brand', type: 'select', options: ['Visa', 'Mastercard', 'Amex', 'Discover'] },
    { key: 'reason_cd', label: 'Reason', type: 'select', options: ['Cardholder Inquiry', 'Fraud Investigation', 'Compliance Review', 'Dispute Support'] },
    { key: 'retr_status', label: 'Status', type: 'select', options: ['Pending', 'Fulfilled', 'Expired'] },
    { key: 'merchant_id', label: 'Merchant ID', type: 'text' },
  ],
  adjustment: [
    { key: 'adj_type', label: 'Adjustment Type', type: 'select', options: ['Fee Adjustment', 'Rate Correction', 'Chargeback Reversal', 'Settlement Error', 'Promotional Credit'] },
    { key: 'adj_category', label: 'Category', type: 'select', options: ['Credit', 'Debit'] },
    { key: 'adj_status', label: 'Status', type: 'select', options: ['Posted', 'Pending', 'Rejected'] },
    { key: 'adj_am', label: 'Amount', type: 'range', min: -50000, max: 50000 },
    { key: 'merchant_id', label: 'Merchant ID', type: 'text' },
  ],
};

interface FilterFieldConfig {
  key: string;
  label: string;
  type: 'select' | 'multiselect' | 'range' | 'text' | 'date';
  options?: string[];
  min?: number;
  max?: number;
}

interface FilterValue {
  field: string;
  operator: string;
  value: string | number | [number, number] | [Dayjs, Dayjs];
}

interface QueryBuilderProps {
  domain: DomainType;
  onApplyFilters: (filters: FilterValue[], dateRange: [Dayjs, Dayjs]) => void;
  onExport?: (format: 'csv' | 'excel') => void;
  onSaveQuery?: (name: string, filters: FilterValue[]) => void;
}

export function QueryBuilder({
  domain,
  onApplyFilters,
  onExport,
  onSaveQuery,
}: QueryBuilderProps) {
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs]>([
    dayjs().subtract(30, 'day'),
    dayjs(),
  ]);
  const [filters, setFilters] = useState<FilterValue[]>([]);
  const [activeFilters, setActiveFilters] = useState<string[]>([]);

  const availableFields = useMemo(() => domainFilterFields[domain] || [], [domain]);

  const addFilter = useCallback((fieldKey: string) => {
    const fieldConfig = availableFields.find((f) => f.key === fieldKey);
    if (!fieldConfig) return;

    const newFilter: FilterValue = {
      field: fieldKey,
      operator: fieldConfig.type === 'range' ? 'between' : 'equals',
      value: fieldConfig.type === 'range' ? [fieldConfig.min || 0, fieldConfig.max || 100] : '',
    };

    setFilters([...filters, newFilter]);
    setActiveFilters([...activeFilters, fieldKey]);
  }, [filters, activeFilters, availableFields]);

  const removeFilter = useCallback((index: number) => {
    const newFilters = [...filters];
    const removedField = newFilters[index].field;
    newFilters.splice(index, 1);
    setFilters(newFilters);
    setActiveFilters(activeFilters.filter((f) => f !== removedField));
  }, [filters, activeFilters]);

  const updateFilterValue = useCallback((index: number, value: FilterValue['value']) => {
    const newFilters = [...filters];
    newFilters[index] = { ...newFilters[index], value };
    setFilters(newFilters);
  }, [filters]);

  const clearAllFilters = useCallback(() => {
    setFilters([]);
    setActiveFilters([]);
  }, []);

  const handleApply = useCallback(() => {
    onApplyFilters(filters, dateRange);
  }, [filters, dateRange, onApplyFilters]);

  const renderFilterInput = (filter: FilterValue, index: number) => {
    const fieldConfig = availableFields.find((f) => f.key === filter.field);
    if (!fieldConfig) return null;

    switch (fieldConfig.type) {
      case 'select':
      case 'multiselect':
        return (
          <Select
            mode={fieldConfig.type === 'multiselect' ? 'multiple' : undefined}
            placeholder={`Select ${fieldConfig.label}`}
            style={{ width: 200 }}
            value={filter.value as string}
            onChange={(value) => updateFilterValue(index, value)}
            options={fieldConfig.options?.map((opt) => ({ value: opt, label: opt }))}
            allowClear
          />
        );
      case 'range':
        const rangeValue = filter.value as [number, number];
        return (
          <Space>
            <InputNumber
              placeholder="Min"
              style={{ width: 100 }}
              value={rangeValue[0]}
              onChange={(val) => updateFilterValue(index, [val || 0, rangeValue[1]])}
              min={fieldConfig.min}
              max={fieldConfig.max}
            />
            <Text type="secondary">to</Text>
            <InputNumber
              placeholder="Max"
              style={{ width: 100 }}
              value={rangeValue[1]}
              onChange={(val) => updateFilterValue(index, [rangeValue[0], val || 0])}
              min={fieldConfig.min}
              max={fieldConfig.max}
            />
          </Space>
        );
      case 'text':
        return (
          <Select
            mode="tags"
            placeholder={`Enter ${fieldConfig.label}`}
            style={{ width: 200 }}
            value={filter.value ? [filter.value as string] : []}
            onChange={(values) => updateFilterValue(index, values[0] || '')}
          />
        );
      default:
        return null;
    }
  };

  const unusedFields = availableFields.filter((f) => !activeFilters.includes(f.key));

  return (
    <Card className="mb-6">
      <Collapse
        defaultActiveKey={['filters']}
        ghost
        items={[
          {
            key: 'filters',
            label: (
              <Space>
                <FilterOutlined />
                <Text strong>Query Builder</Text>
                {filters.length > 0 && (
                  <Tag color="orange">{filters.length} filter{filters.length > 1 ? 's' : ''}</Tag>
                )}
              </Space>
            ),
            children: (
              <div className="space-y-4">
                {/* Date Range - Always Present */}
                <Row gutter={[16, 16]} align="middle">
                  <Col>
                    <Text strong>Date Range:</Text>
                  </Col>
                  <Col>
                    <RangePicker
                      value={dateRange}
                      onChange={(dates) => dates && setDateRange(dates as [Dayjs, Dayjs])}
                      allowClear={false}
                      presets={[
                        { label: 'Today', value: [dayjs(), dayjs()] },
                        { label: 'Last 7 Days', value: [dayjs().subtract(7, 'day'), dayjs()] },
                        { label: 'Last 30 Days', value: [dayjs().subtract(30, 'day'), dayjs()] },
                        { label: 'Last 90 Days', value: [dayjs().subtract(90, 'day'), dayjs()] },
                        { label: 'This Month', value: [dayjs().startOf('month'), dayjs()] },
                        { label: 'Last Month', value: [dayjs().subtract(1, 'month').startOf('month'), dayjs().subtract(1, 'month').endOf('month')] },
                      ]}
                    />
                  </Col>
                </Row>

                <Divider className="my-3" />

                {/* Active Filters */}
                {filters.length > 0 && (
                  <div className="space-y-3">
                    <Text strong>Active Filters:</Text>
                    {filters.map((filter, index) => {
                      const fieldConfig = availableFields.find((f) => f.key === filter.field);
                      return (
                        <Row key={index} gutter={[8, 8]} align="middle" className="bg-gray-50 p-2 rounded">
                          <Col flex="150px">
                            <Text>{fieldConfig?.label}</Text>
                          </Col>
                          <Col flex="auto">
                            {renderFilterInput(filter, index)}
                          </Col>
                          <Col>
                            <Button
                              type="text"
                              icon={<CloseOutlined />}
                              onClick={() => removeFilter(index)}
                              danger
                            />
                          </Col>
                        </Row>
                      );
                    })}
                  </div>
                )}

                {/* Add Filter Dropdown */}
                {unusedFields.length > 0 && (
                  <div>
                    <Select
                      placeholder="+ Add Filter"
                      style={{ width: 200 }}
                      value={undefined}
                      onChange={addFilter}
                      options={unusedFields.map((f) => ({ value: f.key, label: f.label }))}
                      suffixIcon={<PlusOutlined />}
                    />
                  </div>
                )}

                <Divider className="my-3" />

                {/* Action Buttons */}
                <Row justify="space-between">
                  <Col>
                    <Space>
                      <Button
                        type="primary"
                        icon={<SearchOutlined />}
                        onClick={handleApply}
                      >
                        Apply Filters
                      </Button>
                      <Button
                        icon={<ClearOutlined />}
                        onClick={clearAllFilters}
                        disabled={filters.length === 0}
                      >
                        Clear All
                      </Button>
                    </Space>
                  </Col>
                  <Col>
                    <Space>
                      {onSaveQuery && (
                        <Tooltip title="Save this query for later">
                          <Button icon={<SaveOutlined />}>Save Query</Button>
                        </Tooltip>
                      )}
                      {onExport && (
                        <Select
                          placeholder="Export"
                          style={{ width: 130 }}
                          suffixIcon={<DownloadOutlined />}
                          options={[
                            { value: 'csv', label: 'Export CSV' },
                            { value: 'excel', label: 'Export Excel' },
                          ]}
                          onChange={(format) => onExport(format as 'csv' | 'excel')}
                        />
                      )}
                    </Space>
                  </Col>
                </Row>
              </div>
            ),
          },
        ]}
      />
    </Card>
  );
}

export type { FilterValue, FilterFieldConfig };
