'use client';

import { useCallback, useMemo, useRef, useState } from 'react';
import { AgGridReact } from 'ag-grid-react';
import { 
  AllCommunityModule, 
  ModuleRegistry,
  CellSelectionModule,
  SideBarModule,
  StatusBarModule,
  RowGroupingModule,
  PivotModule,
  ExcelExportModule,
  ColumnsToolPanelModule,
  FiltersToolPanelModule,
  LicenseManager,
} from 'ag-grid-enterprise';
import type {
  ColDef,
  GridReadyEvent,
  GridApi,
  ValueFormatterParams,
  CellClassParams,
} from 'ag-grid-community';
import { Button, Space, Dropdown, Tooltip, Switch, Typography } from 'antd';
import type { MenuProps } from 'antd';
import {
  DownloadOutlined,
  FullscreenOutlined,
  FullscreenExitOutlined,
  PieChartOutlined,
} from '@ant-design/icons';

const { Text } = Typography;

// Suppress AG Grid license warnings in development
// In production, set a valid license key via environment variable
if (process.env.NEXT_PUBLIC_AG_GRID_LICENSE_KEY) {
  LicenseManager.setLicenseKey(process.env.NEXT_PUBLIC_AG_GRID_LICENSE_KEY);
}

// Register AG Grid modules (Community + Enterprise)
ModuleRegistry.registerModules([
  AllCommunityModule,
  CellSelectionModule,
  SideBarModule,
  StatusBarModule,
  RowGroupingModule,
  PivotModule,
  ExcelExportModule,
  ColumnsToolPanelModule,
  FiltersToolPanelModule,
]);

interface DataGridProps<T = Record<string, unknown>> {
  data: T[];
  columns?: ColDef<T>[];
  height?: string | number;
  enablePivot?: boolean;
  enableGrouping?: boolean;
  enableExport?: boolean;
  onRowClick?: (row: T) => void;
  loading?: boolean;
  title?: string;
}

// Currency formatter
const currencyFormatter = (params: ValueFormatterParams): string => {
  if (params.value == null) return '';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(params.value as number);
};

// Number formatter
const numberFormatter = (params: ValueFormatterParams): string => {
  if (params.value == null) return '';
  return new Intl.NumberFormat('en-US').format(params.value as number);
};

// Percentage formatter
const percentFormatter = (params: ValueFormatterParams): string => {
  if (params.value == null) return '';
  return `${(params.value as number).toFixed(2)}%`;
};

// Date formatter
const dateFormatter = (params: ValueFormatterParams): string => {
  if (params.value == null) return '';
  const date = new Date(params.value as string);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};

// Auto-detect column formatter based on column name
function getFormatterForColumn(columnName: string): ((params: ValueFormatterParams) => string) | undefined {
  const lowerName = columnName.toLowerCase();
  
  if (lowerName.includes('amount') || lowerName.includes('volume') || lowerName.includes('fee') || 
      lowerName.includes('deposit') || lowerName.includes('sales') || lowerName.includes('_am')) {
    return currencyFormatter;
  }
  
  if (lowerName.includes('rate') || lowerName.includes('percent') || lowerName.includes('_pct')) {
    return percentFormatter;
  }
  
  if (lowerName.includes('date') || lowerName.includes('_dt')) {
    return dateFormatter;
  }
  
  if (lowerName.includes('count') || lowerName.includes('_ct') || lowerName.includes('_cnt')) {
    return numberFormatter;
  }
  
  return undefined;
}

// Cell class for conditional styling
function getCellClass(params: CellClassParams): string {
  const colName = params.colDef.field?.toLowerCase() || '';
  
  // Color rates green/red based on value
  if (colName.includes('rate') && typeof params.value === 'number') {
    if (colName.includes('approval') && params.value >= 95) return 'text-green-600';
    if (colName.includes('approval') && params.value < 90) return 'text-red-600';
  }
  
  // Color amounts
  if (typeof params.value === 'number' && params.value < 0) {
    return 'text-red-600';
  }
  
  return '';
}

export function DataGrid<T extends Record<string, unknown>>({
  data,
  columns: customColumns,
  height = 500,
  enablePivot = true,
  enableGrouping: _enableGrouping, // eslint-disable-line @typescript-eslint/no-unused-vars
  enableExport = true,
  onRowClick,
  loading = false,
  title,
}: DataGridProps<T>) {
  const gridRef = useRef<AgGridReact<T>>(null);
  const [gridApi, setGridApi] = useState<GridApi<T> | null>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [pivotMode, setPivotMode] = useState(false);

  // Auto-generate columns from data if not provided
  const columnDefs = useMemo<ColDef<T>[]>(() => {
    if (customColumns) return customColumns;
    
    if (data.length === 0) return [];
    
    const firstRow = data[0];
    return Object.keys(firstRow).map((key) => {
      const formatter = getFormatterForColumn(key);
      const isNumeric = typeof firstRow[key] === 'number';
      
      return {
        field: key as keyof T & string,
        headerName: key.replace(/_/g, ' ').replace(/\b\w/g, (l) => l.toUpperCase()),
        sortable: true,
        filter: true,
        resizable: true,
        valueFormatter: formatter,
        cellClass: getCellClass,
        enablePivot: isNumeric,
        enableValue: isNumeric,
        enableRowGroup: !isNumeric,
        aggFunc: isNumeric ? 'sum' : undefined,
        type: isNumeric ? 'numericColumn' : undefined,
      } as ColDef<T>;
    });
  }, [data, customColumns]);

  const defaultColDef = useMemo<ColDef>(() => ({
    flex: 1,
    minWidth: 100,
    sortable: true,
    filter: true,
    resizable: true,
  }), []);

  const onGridReady = useCallback((params: GridReadyEvent<T>) => {
    setGridApi(params.api);
  }, []);

  const handleExportCSV = useCallback(() => {
    gridApi?.exportDataAsCsv({
      fileName: `${title || 'data'}_export_${new Date().toISOString().split('T')[0]}.csv`,
    });
  }, [gridApi, title]);

  const handleExportExcel = useCallback(() => {
    gridApi?.exportDataAsExcel({
      fileName: `${title || 'data'}_export_${new Date().toISOString().split('T')[0]}.xlsx`,
      sheetName: title || 'Data',
    });
  }, [gridApi, title]);

  const exportMenuItems: MenuProps['items'] = [
    {
      key: 'csv',
      label: 'Export as CSV',
      onClick: handleExportCSV,
    },
    {
      key: 'excel',
      label: 'Export as Excel',
      onClick: handleExportExcel,
    },
  ];

  const toggleFullscreen = useCallback(() => {
    setIsFullscreen(!isFullscreen);
  }, [isFullscreen]);

  const togglePivotMode = useCallback((checked: boolean) => {
    setPivotMode(checked);
    gridApi?.setGridOption('pivotMode', checked);
  }, [gridApi]);

  return (
    <div
      className={`data-table-container ${
        isFullscreen ? 'fixed inset-0 z-50 bg-white' : ''
      }`}
      style={{ overflow: 'hidden' }}
    >
      {/* Toolbar */}
      <div className="flex items-center justify-between p-3 border-b border-gray-200 bg-gray-50 flex-wrap gap-2">
        <div className="flex items-center gap-4 min-w-0">
          {title && (
            <Text strong className="text-base truncate">
              {title}
            </Text>
          )}
          <Text type="secondary" className="text-sm whitespace-nowrap">
            {data.length} rows
          </Text>
        </div>

        <Space>
          {enablePivot && (
            <Tooltip title="Enable pivot mode for advanced analysis">
              <Space>
                <PieChartOutlined />
                <Switch
                  size="small"
                  checked={pivotMode}
                  onChange={togglePivotMode}
                />
                <Text type="secondary" className="text-xs">
                  Pivot
                </Text>
              </Space>
            </Tooltip>
          )}

          {enableExport && (
            <Dropdown menu={{ items: exportMenuItems }} trigger={['click']}>
              <Button icon={<DownloadOutlined />} size="small">
                Export
              </Button>
            </Dropdown>
          )}

          <Tooltip title={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}>
            <Button
              icon={isFullscreen ? <FullscreenExitOutlined /> : <FullscreenOutlined />}
              size="small"
              onClick={toggleFullscreen}
            />
          </Tooltip>
        </Space>
      </div>

      {/* AG Grid */}
      <div
        className="ag-theme-alpine"
        style={{ height: isFullscreen ? 'calc(100vh - 52px)' : height, width: '100%' }}
      >
        <AgGridReact<T>
          ref={gridRef}
          rowData={data}
          columnDefs={columnDefs}
          defaultColDef={defaultColDef}
          onGridReady={onGridReady}
          onRowClicked={onRowClick ? (e) => onRowClick(e.data as T) : undefined}
          loading={loading}
          animateRows={true}
          pagination={true}
          paginationPageSize={50}
          paginationPageSizeSelector={[25, 50, 100, 200]}
          rowSelection={{ mode: 'singleRow', enableClickSelection: false }}
          cellSelection={true}
          pivotMode={pivotMode}
          sideBar={enablePivot ? {
            toolPanels: [
              {
                id: 'columns',
                labelDefault: 'Columns',
                labelKey: 'columns',
                iconKey: 'columns',
                toolPanel: 'agColumnsToolPanel',
              },
              {
                id: 'filters',
                labelDefault: 'Filters',
                labelKey: 'filters',
                iconKey: 'filter',
                toolPanel: 'agFiltersToolPanel',
              },
            ],
          } : undefined}
          statusBar={{
            statusPanels: [
              { statusPanel: 'agTotalAndFilteredRowCountComponent', align: 'left' },
              { statusPanel: 'agSelectedRowCountComponent', align: 'center' },
              { statusPanel: 'agAggregationComponent', align: 'right' },
            ],
          }}
        />
      </div>
    </div>
  );
}
