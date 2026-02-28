'use client';

import { useState, useRef, useEffect, useImperativeHandle, forwardRef, memo, useCallback } from 'react';
import { Input, Button, Typography, Space, Tag, Tooltip, Empty, Spin, Table, Collapse, Dropdown } from 'antd';
import type { MenuProps } from 'antd';
import {
  SendOutlined,
  UserOutlined,
  RobotOutlined,
  CodeOutlined,
  CopyOutlined,
  CheckOutlined,
  ClearOutlined,
  TableOutlined,
  LoadingOutlined,
  SearchOutlined,
  ThunderboltOutlined,
  DatabaseOutlined,
  BulbOutlined,
  BarChartOutlined,
  RightOutlined,
  DownloadOutlined,
  FileExcelOutlined,
} from '@ant-design/icons';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import dynamic from 'next/dynamic';
import * as XLSX from 'xlsx';
import { useCortexAgent, ContentItem } from '@/hooks/useCortexAgent';
import { formatSQL } from '@/lib/cortex';

// Dynamically import VegaEmbed to avoid SSR issues
const VegaEmbed = dynamic(() => import('react-vega').then((mod) => mod.VegaEmbed), {
  ssr: false,
  loading: () => <div className="h-[300px] flex items-center justify-center"><Spin /></div>,
});

const { Text } = Typography;
const { TextArea } = Input;

interface ChatWindowProps {
  initialQuestion?: string;
}

export interface ChatWindowRef {
  sendMessage: (message: string) => void;
}

// Memoized markdown renderer component
const MarkdownContent = memo(function MarkdownContent({ content }: { content: string }) {
  return (
    <ReactMarkdown
      remarkPlugins={[remarkGfm]}
      components={{
        // Style paragraphs
        p: ({ children }) => <p className="mb-2 last:mb-0">{children}</p>,
        // Style lists
        ul: ({ children }) => <ul className="list-disc pl-4 mb-2">{children}</ul>,
        ol: ({ children }) => <ol className="list-decimal pl-4 mb-2">{children}</ol>,
        li: ({ children }) => <li className="mb-1">{children}</li>,
        // Style headings
        h1: ({ children }) => <h1 className="text-xl font-bold mb-2 mt-3">{children}</h1>,
        h2: ({ children }) => <h2 className="text-lg font-bold mb-2 mt-3">{children}</h2>,
        h3: ({ children }) => <h3 className="text-base font-bold mb-2 mt-2">{children}</h3>,
        // Style code
        code: ({ className, children }) => {
          const isInline = !className;
          if (isInline) {
            return <code className="bg-gray-100 px-1 py-0.5 rounded text-sm font-mono">{children}</code>;
          }
          return (
            <pre className="bg-gray-900 text-green-400 p-3 rounded-lg text-xs overflow-x-auto my-2">
              <code>{children}</code>
            </pre>
          );
        },
        // Style tables
        table: ({ children }) => (
          <div className="overflow-x-auto my-2">
            <table className="min-w-full border-collapse border border-gray-300">{children}</table>
          </div>
        ),
        th: ({ children }) => (
          <th className="border border-gray-300 px-3 py-2 bg-gray-100 font-semibold text-left">{children}</th>
        ),
        td: ({ children }) => (
          <td className="border border-gray-300 px-3 py-2">{children}</td>
        ),
        // Style blockquotes
        blockquote: ({ children }) => (
          <blockquote className="border-l-4 border-gray-300 pl-4 my-2 italic text-gray-600">{children}</blockquote>
        ),
        // Style links
        a: ({ href, children }) => (
          <a href={href} className="text-blue-600 hover:underline" target="_blank" rel="noopener noreferrer">
            {children}
          </a>
        ),
        // Style strong/bold
        strong: ({ children }) => <strong className="font-semibold">{children}</strong>,
        // Style emphasis/italic
        em: ({ children }) => <em className="italic">{children}</em>,
      }}
    >
      {content}
    </ReactMarkdown>
  );
});

// Export utility functions
const exportToCSV = (data: Record<string, unknown>[], filename: string) => {
  if (!data || data.length === 0) return;
  
  const headers = Object.keys(data[0]);
  const csvContent = [
    headers.join(','),
    ...data.map(row => 
      headers.map(header => {
        const value = row[header];
        // Escape values that contain commas, quotes, or newlines
        const stringValue = value === null || value === undefined ? '' : String(value);
        if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
          return `"${stringValue.replace(/"/g, '""')}"`;
        }
        return stringValue;
      }).join(',')
    )
  ].join('\n');
  
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `${filename}.csv`;
  link.click();
  URL.revokeObjectURL(link.href);
};

const exportToExcel = (data: Record<string, unknown>[], filename: string, sheetName?: string) => {
  if (!data || data.length === 0) return;
  
  const worksheet = XLSX.utils.json_to_sheet(data);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, sheetName || 'Data');
  
  // Auto-size columns
  const headers = Object.keys(data[0]);
  const colWidths = headers.map(header => {
    const maxLength = Math.max(
      header.length,
      ...data.map(row => String(row[header] || '').length)
    );
    return { wch: Math.min(maxLength + 2, 50) };
  });
  worksheet['!cols'] = colWidths;
  
  XLSX.writeFile(workbook, `${filename}.xlsx`);
};

const generateFilename = (title?: string) => {
  const timestamp = new Date().toISOString().slice(0, 19).replace(/[:-]/g, '');
  const baseTitle = title ? title.replace(/[^a-zA-Z0-9]/g, '_').slice(0, 30) : 'export';
  return `${baseTitle}_${timestamp}`;
};

export const ChatWindow = forwardRef<ChatWindowRef, ChatWindowProps>(
  function ChatWindow({ initialQuestion }, ref) {
  const [inputValue, setInputValue] = useState('');
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const initialQuestionSentRef = useRef(false);
  const { messages, isTyping, agentStatus, sendMessage, clearMessages } = useCortexAgent();

  // Helper to get icon for agent status
  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'planning':
        return <BulbOutlined className="text-yellow-500" />;
      case 'extracting_tool_calls':
        return <SearchOutlined className="text-blue-500" />;
      case 'executing_tools':
      case 'executing_tool':
      case 'invoking_tool':
        return <ThunderboltOutlined className="text-purple-500" />;
      case 'streaming_analyst_results':
      case 'generating_sql':
      case 'postprocessing_sql':
      case 'Executing SQL':
        return <DatabaseOutlined className="text-green-500" />;
      case 'interpreting_question':
        return <BulbOutlined className="text-orange-500" />;
      case 'reasoning_agent_stop':
      case 'reevaluating_plan':
        return <LoadingOutlined className="text-gray-500" />;
      case 'proceeding_to_answer':
      case 'done':
      case 'SUCCESS':
        return <CheckOutlined className="text-green-500" />;
      default:
        return <LoadingOutlined className="text-blue-500" />;
    }
  };

  // Expose sendMessage to parent via ref
  useImperativeHandle(ref, () => ({
    sendMessage: (message: string) => {
      sendMessage(message);
    },
  }), [sendMessage]);

  // Scroll to bottom when new messages arrive or status changes
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isTyping, agentStatus]);

  // Handle initial question from URL (with StrictMode protection)
  useEffect(() => {
    if (initialQuestion && messages.length === 0 && !initialQuestionSentRef.current) {
      initialQuestionSentRef.current = true;
      sendMessage(initialQuestion);
    }
  }, [initialQuestion, messages.length, sendMessage]);

  const handleSend = () => {
    if (inputValue.trim()) {
      sendMessage(inputValue);
      setInputValue('');
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const copyToClipboard = async (text: string, id: string) => {
    await navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  return (
    <div className="flex flex-col">
      {/* Agent status indicator - at top when processing */}
      {isTyping && (
        <div className="border-b border-gray-200 bg-gray-50 p-3">
          <div className="flex items-center gap-3">
            <RobotOutlined className="text-[#FF6600] text-lg" />
            <div className="flex-1">
              {agentStatus ? (
                <div className="flex flex-col gap-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    {getStatusIcon(agentStatus.status)}
                    <Text className="text-sm text-gray-700">
                      {agentStatus.message}
                    </Text>
                    {agentStatus.toolName && (
                      <Tag color="blue" className="text-xs">
                        {agentStatus.toolName.replace(/_/g, ' ')}
                      </Tag>
                    )}
                  </div>
                  {/* Show additional details */}
                  {(agentStatus.details || agentStatus.queryId) && (
                    <div className="ml-5 flex flex-col gap-0.5">
                      {agentStatus.details && (
                        <Text type="secondary" className="text-xs italic">
                          {agentStatus.details}
                        </Text>
                      )}
                      {agentStatus.queryId && (
                        <Text type="secondary" className="text-xs font-mono">
                          Query ID: {agentStatus.queryId}
                        </Text>
                      )}
                    </div>
                  )}
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <Spin size="small" />
                  <Text type="secondary" className="text-sm">
                    Processing...
                  </Text>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Messages area */}
      <div className="p-4 space-y-4">
        {messages.length === 0 ? (
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description={
              <Space orientation="vertical" size="small">
                <Text type="secondary">
                  Ask me anything about your payment data
                </Text>
                <Text type="secondary" className="text-xs">
                  Try: &quot;What is my approval rate by card brand?&quot;
                </Text>
              </Space>
            }
          />
        ) : (
          messages.map((message) => (
            <div
              key={message.id}
              className={`chat-message flex ${
                message.role === 'user' ? 'justify-end' : 'justify-start'
              }`}
            >
              <div
                className={`${
                  message.role === 'user'
                    ? 'max-w-[80%] bg-[#FFF2E8] text-gray-800 border border-[#FFD8BF] rounded-2xl rounded-tr-sm'
                    : 'w-full bg-white border border-gray-200 rounded-2xl rounded-tl-sm'
                } p-4 shadow-sm`}
              >
                {/* SQL Query display - collapsible, above response */}
                {message.role === 'assistant' && message.sql && (
                  <div className="mb-3">
                    <Collapse
                      size="small"
                      expandIcon={({ isActive }) => (
                        <RightOutlined rotate={isActive ? 90 : 0} className="text-blue-500" />
                      )}
                      items={[
                        {
                          key: 'sql',
                          label: (
                            <div className="flex items-center gap-2">
                              <Tag icon={<CodeOutlined />} color="blue" className="m-0">
                                Generated SQL
                              </Tag>
                              <Tooltip title={copiedId === message.id ? 'Copied!' : 'Copy SQL'}>
                                <Button
                                  type="text"
                                  size="small"
                                  icon={
                                    copiedId === message.id ? (
                                      <CheckOutlined className="text-green-500" />
                                    ) : (
                                      <CopyOutlined />
                                    )
                                  }
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    copyToClipboard(message.sql!, message.id);
                                  }}
                                />
                              </Tooltip>
                            </div>
                          ),
                          children: (
                            <pre className="bg-gray-900 text-green-400 p-3 rounded-lg text-xs whitespace-pre-wrap break-words m-0">
                              {formatSQL(message.sql)}
                            </pre>
                          ),
                        },
                      ]}
                      className="bg-gray-50 border-gray-200"
                    />
                  </div>
                )}

                <div className="flex items-start gap-2">
                  {message.role === 'assistant' && (
                    <RobotOutlined className="text-[#FF6600] text-lg mt-1 flex-shrink-0" />
                  )}
                  <div className="flex-1 min-w-0 prose prose-sm max-w-none">
                    {message.role === 'user' ? (
                      <span className="text-gray-800">{message.content}</span>
                    ) : message.contentItems && message.contentItems.length > 0 ? (
                      // Render content items inline in order
                      message.contentItems.map((item, idx) => (
                        <div key={`content-${item.contentIndex}-${idx}`}>
                          {item.type === 'text' && item.text && (
                            <MarkdownContent content={item.text} />
                          )}
                          {item.type === 'chart' && item.vegaLiteSpec && (
                            <div className="my-4">
                              <div className="bg-white rounded border border-gray-200 p-4 w-full">
                                <VegaEmbed
                                  spec={{
                                    ...item.vegaLiteSpec as Record<string, unknown>,
                                    width: 700,
                                    height: 400,
                                    autosize: { type: 'fit', contains: 'padding' },
                                  }}
                                  options={{ 
                                    actions: false,
                                  }}
                                />
                              </div>
                            </div>
                          )}
                          {item.type === 'table' && item.tableData && item.tableData.length > 0 && (
                            <div className="my-4">
                              <div className="flex items-center justify-between mb-2">
                                <div className="flex items-center gap-2">
                                  {item.tableTitle && (
                                    <Tag icon={<TableOutlined />} color="green">
                                      {item.tableTitle}
                                    </Tag>
                                  )}
                                  <Text type="secondary" className="text-xs">
                                    {item.tableData.length} rows
                                  </Text>
                                </div>
                                <Dropdown
                                  menu={{
                                    items: [
                                      {
                                        key: 'csv',
                                        icon: <DownloadOutlined />,
                                        label: 'Export as CSV',
                                        onClick: () => exportToCSV(item.tableData!, generateFilename(item.tableTitle)),
                                      },
                                      {
                                        key: 'excel',
                                        icon: <FileExcelOutlined />,
                                        label: 'Export as Excel',
                                        onClick: () => exportToExcel(item.tableData!, generateFilename(item.tableTitle), item.tableTitle),
                                      },
                                    ],
                                  }}
                                  trigger={['click']}
                                >
                                  <Button 
                                    size="small" 
                                    icon={<DownloadOutlined />}
                                    className="text-gray-500 hover:text-blue-600"
                                  >
                                    Export
                                  </Button>
                                </Dropdown>
                              </div>
                              <Table
                                dataSource={item.tableData.map((row, rowIdx) => ({
                                  ...row,
                                  key: rowIdx,
                                }))}
                                columns={Object.keys(item.tableData[0]).map((key) => {
                                  // Check if this column contains numeric data by sampling first row
                                  const sampleValue = item.tableData![0][key];
                                  const isNumeric = typeof sampleValue === 'number' || 
                                    (typeof sampleValue === 'string' && !isNaN(parseFloat(sampleValue)) && /^-?\d*\.?\d+$/.test(sampleValue));
                                  const keyLower = key.toLowerCase();
                                  const isAmount = keyLower.includes('am') || keyLower.includes('amount') || 
                                    keyLower.includes('sales') || keyLower.includes('fee') || 
                                    keyLower.includes('net') || keyLower.includes('refund') ||
                                    keyLower.includes('interchange') || keyLower.includes('prcs');
                                  const isCount = keyLower.includes('ct') || keyLower.includes('cnt') || 
                                    keyLower.includes('count') || keyLower.includes('total');
                                  
                                  return {
                                    title: key.replace(/_/g, ' '),
                                    dataIndex: key,
                                    key,
                                    ellipsis: true,
                                    align: isNumeric ? 'right' as const : 'left' as const,
                                    render: (value: unknown) => {
                                      if (value === null || value === undefined) {
                                        return <span className="text-gray-400">-</span>;
                                      }
                                      
                                      // Parse numeric strings to numbers
                                      let numValue: number | null = null;
                                      let originalDecimals = 0;
                                      
                                      if (typeof value === 'number') {
                                        numValue = value;
                                        // Determine decimal places from number
                                        const str = value.toString();
                                        const decimalIndex = str.indexOf('.');
                                        originalDecimals = decimalIndex >= 0 ? str.length - decimalIndex - 1 : 0;
                                      } else if (typeof value === 'string' && /^-?\d*\.?\d+$/.test(value)) {
                                        numValue = parseFloat(value);
                                        // Preserve original decimal places from string
                                        const decimalIndex = value.indexOf('.');
                                        originalDecimals = decimalIndex >= 0 ? value.length - decimalIndex - 1 : 0;
                                      }
                                      
                                      if (numValue !== null && !isNaN(numValue)) {
                                        // Format percentages
                                        if (keyLower.includes('rate') || keyLower.includes('percentage') || keyLower.includes('pct')) {
                                          return `${numValue.toFixed(2)}%`;
                                        }
                                        // Format amounts (preserve original decimals, use commas)
                                        if (isAmount) {
                                          return new Intl.NumberFormat('en-US', {
                                            minimumFractionDigits: originalDecimals,
                                            maximumFractionDigits: originalDecimals,
                                          }).format(numValue);
                                        }
                                        // Format counts (no decimals)
                                        if (isCount) {
                                          return new Intl.NumberFormat('en-US', {
                                            minimumFractionDigits: 0,
                                            maximumFractionDigits: 0,
                                          }).format(numValue);
                                        }
                                        // Other numbers - preserve original decimals
                                        return new Intl.NumberFormat('en-US', {
                                          minimumFractionDigits: originalDecimals,
                                          maximumFractionDigits: originalDecimals,
                                        }).format(numValue);
                                      }
                                      // Handle dates
                                      if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}/.test(value)) {
                                        return new Date(value).toLocaleDateString();
                                      }
                                      return String(value);
                                    },
                                  };
                                })}
                                size="small"
                                scroll={{ x: true, y: 400 }}
                                pagination={item.tableData.length > 10 ? { 
                                  pageSize: 10,
                                  showSizeChanger: true,
                                  showTotal: (total) => `${total} rows`,
                                  size: 'small',
                                } : false}
                                className="bg-white rounded border border-gray-200"
                              />
                            </div>
                          )}
                        </div>
                      ))
                    ) : (
                      // Fallback to old rendering if no contentItems
                      <MarkdownContent content={message.content} />
                    )}
                  </div>
                  {message.role === 'user' && (
                    <UserOutlined className="text-[#FF6600] text-lg mt-1 flex-shrink-0" />
                  )}
                </div>

                {/* Timestamp */}
                <Text
                  type="secondary"
                  className={`text-xs mt-2 block ${
                    message.role === 'user' ? 'text-gray-500' : 'text-gray-400'
                  }`}
                >
                  {message.timestamp.toLocaleTimeString()}
                </Text>
              </div>
            </div>
          ))
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input area - sticky at bottom */}
      <div className="border-t border-gray-200 p-4 bg-white sticky bottom-0">
        <div className="flex gap-2">
          <TextArea
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={handleKeyPress}
            placeholder="Ask a question about your payment data..."
            autoSize={{ minRows: 1, maxRows: 4 }}
            className="flex-1"
          />
          <div className="flex flex-col gap-2">
            <Button
              type="primary"
              icon={<SendOutlined />}
              onClick={handleSend}
              disabled={!inputValue.trim() || isTyping}
            >
              Send
            </Button>
            {messages.length > 0 && (
              <Tooltip title="Clear conversation">
                <Button
                  icon={<ClearOutlined />}
                  onClick={clearMessages}
                  size="small"
                />
              </Tooltip>
            )}
          </div>
        </div>
      </div>
    </div>
  );
});
