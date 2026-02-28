'use client';

import { useState, useCallback, useRef } from 'react';

interface ChartConfig {
  type: string;
  title?: string;
  data: Record<string, unknown>[];
  xAxis?: string;
  yAxis?: string;
  series?: string[];
}

interface VegaLiteSpec {
  $schema?: string;
  [key: string]: unknown;
}

// Content item that can be text, chart, or table, with position info
export interface ContentItem {
  type: 'text' | 'chart' | 'table';
  contentIndex: number;
  text?: string;
  vegaLiteSpec?: VegaLiteSpec;
  tableData?: Record<string, unknown>[];
  tableTitle?: string;
  queryId?: string;
}

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  contentItems?: ContentItem[]; // Ordered content items for inline rendering
  sql?: string;
  data?: Record<string, unknown>[];
  chart?: ChartConfig;
  vegaLiteSpec?: VegaLiteSpec;
  timestamp: Date;
}

interface AgentStatus {
  message: string;
  status: string;
  toolName?: string;
  toolType?: string;
  details?: string;
  queryId?: string;
}

export function useCortexAgent() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [isTyping, setIsTyping] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [agentStatus, setAgentStatus] = useState<AgentStatus | null>(null);
  const abortControllerRef = useRef<AbortController | null>(null);
  const messagesRef = useRef<Message[]>([]);
  const isProcessingRef = useRef(false);

  // Keep messagesRef in sync
  messagesRef.current = messages;

  const sendMessage = useCallback(
    async (message: string) => {
      if (!message.trim()) return;
      
      // Prevent duplicate submissions
      if (isProcessingRef.current) {
        return;
      }
      isProcessingRef.current = true;

      const timestamp = Date.now();
      const userMessageId = `user-${timestamp}`;
      const assistantId = `assistant-${timestamp}`;

      // Add user message immediately
      const userMessage: Message = {
        id: userMessageId,
        role: 'user',
        content: message,
        timestamp: new Date(),
      };

      // Create assistant message placeholder
      const assistantMessage: Message = {
        id: assistantId,
        role: 'assistant',
        content: '',
        timestamp: new Date(),
      };

      // Get current history before adding new messages
      const history = messagesRef.current.map((m) => ({
        role: m.role,
        content: m.content,
      }));

      // Add both messages
      setMessages((prev) => [...prev, userMessage, assistantMessage]);
      setIsTyping(true);
      setIsLoading(true);

      try {
        // Cancel any previous request
        if (abortControllerRef.current) {
          abortControllerRef.current.abort();
        }
        abortControllerRef.current = new AbortController();

        const response = await fetch('/api/cortex/chat', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message,
            history,
          }),
          signal: abortControllerRef.current.signal,
        });

        // Check if response is JSON (error) or SSE stream
        const contentType = response.headers.get('content-type') || '';
        
        if (contentType.includes('application/json')) {
          // Error response
          const errorData = await response.json();
          setMessages((prev) =>
            prev.map((m) =>
              m.id === assistantId
                ? { ...m, content: `Error: ${errorData.message || errorData.error || 'Unknown error'}` }
                : m
            )
          );
          return;
        }

        // Process SSE stream
        const reader = response.body?.getReader();
        if (!reader) {
          throw new Error('No response body');
        }

        const decoder = new TextDecoder();
        let buffer = '';
        let collectedText = '';
        let sql: string | undefined;
        let chartConfig: ChartConfig | undefined;
        let vegaLiteSpec: VegaLiteSpec | undefined;
        let tableData: Record<string, unknown>[] | undefined;
        let currentEvent = '';
        
        // Track content items by their content_index for inline rendering
        const contentItemsMap = new Map<number, ContentItem>();

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split('\n');
          buffer = lines.pop() || '';

          for (const line of lines) {
            if (line.startsWith('event:')) {
              currentEvent = line.slice(6).trim();
            } else if (line.startsWith('data:')) {
              const dataStr = line.slice(5).trim();
              if (!dataStr || dataStr === '[DONE]') continue;

              try {
                const data = JSON.parse(dataStr);
                let textExtracted = false;
                
                // Log all events for debugging
                console.log(`[SSE] Event: ${currentEvent}`, data);
                
                // Handle status events to show what the agent is doing
                if (currentEvent === 'response.status') {
                  setAgentStatus({
                    message: data.message || data.status,
                    status: data.status,
                  });
                } else if (currentEvent === 'response.tool_result.status') {
                  // Extract query ID from details if available
                  let queryId: string | undefined;
                  let detailsMessage: string | undefined;
                  if (data.details) {
                    queryId = data.details.query_id;
                    detailsMessage = data.details.message;
                  }
                  
                  setAgentStatus({
                    message: data.message || `Running ${data.tool_type}`,
                    status: data.status,
                    toolName: data.tool_type,
                    toolType: data.tool_type,
                    details: detailsMessage,
                    queryId: queryId,
                  });
                } else if (currentEvent === 'response.tool_use') {
                  // Show which tool is being invoked with its input
                  const toolInput = data.input?.query || data.input?.question || '';
                  setAgentStatus({
                    message: `Invoking ${data.name}`,
                    status: 'invoking_tool',
                    toolName: data.name,
                    details: toolInput ? `Query: "${toolInput.substring(0, 100)}${toolInput.length > 100 ? '...' : ''}"` : undefined,
                  });
                }
                
                // Only handle delta events for streaming - ignore full "response.text" events
                // which contain duplicated accumulated text
                if (currentEvent === 'message.delta' || currentEvent === 'response.text.delta') {
                  const contentIndex = data.content_index ?? 0;
                  
                  // Extract text from delta events
                  const delta = data.delta || data;
                  const content = delta.content || [];
                  for (const item of content) {
                    if (item.type === 'text' && item.text) {
                      collectedText += item.text;
                      textExtracted = true;
                      
                      // Update content item for this index
                      const existing = contentItemsMap.get(contentIndex);
                      if (existing && existing.type === 'text') {
                        existing.text = (existing.text || '') + item.text;
                      } else {
                        contentItemsMap.set(contentIndex, {
                          type: 'text',
                          contentIndex,
                          text: item.text,
                        });
                      }
                    }
                  }
                  // Also check for direct text field in delta
                  if (data.text && !textExtracted) {
                    collectedText += data.text;
                    textExtracted = true;
                    
                    // Update content item for this index
                    const existing = contentItemsMap.get(contentIndex);
                    if (existing && existing.type === 'text') {
                      existing.text = (existing.text || '') + data.text;
                    } else {
                      contentItemsMap.set(contentIndex, {
                        type: 'text',
                        contentIndex,
                        text: data.text,
                      });
                    }
                  }
                  // Clear status when we start getting actual response text
                  setAgentStatus(null);
                } else if (currentEvent === 'tool.result' || currentEvent === 'response.tool_result') {
                  // Extract SQL, chart config, and data from tool results
                  const extractFromResult = (result: Record<string, unknown>) => {
                    // Extract SQL
                    if (result.sql) {
                      sql = result.sql as string;
                    }
                    // Extract chart configuration from data_to_chart tool
                    if (result.chart || result.chart_config) {
                      const chart = (result.chart || result.chart_config) as Record<string, unknown>;
                      chartConfig = {
                        type: (chart.type as string) || 'bar',
                        title: chart.title as string,
                        data: (chart.data as Record<string, unknown>[]) || [],
                        xAxis: chart.xAxis as string || chart.x_axis as string,
                        yAxis: chart.yAxis as string || chart.y_axis as string,
                        series: chart.series as string[],
                      };
                    }
                    // Extract table data
                    if (result.data && Array.isArray(result.data)) {
                      tableData = result.data as Record<string, unknown>[];
                    }
                    if (result.results && Array.isArray(result.results)) {
                      tableData = result.results as Record<string, unknown>[];
                    }
                  };
                  
                  if (data.tool_results) {
                    for (const result of data.tool_results) {
                      extractFromResult(result);
                    }
                  }
                  // Also check content array for tool results
                  if (data.content && Array.isArray(data.content)) {
                    for (const item of data.content) {
                      if (item.json) {
                        extractFromResult(item.json);
                      }
                      // Check for chart in tool_use_id results
                      if (item.type === 'chart' || item.chart) {
                        const chart = item.chart || item;
                        chartConfig = {
                          type: chart.type || 'bar',
                          title: chart.title,
                          data: chart.data || [],
                          xAxis: chart.xAxis || chart.x_axis,
                          yAxis: chart.yAxis || chart.y_axis,
                          series: chart.series,
                        };
                      }
                    }
                  }
                }
                // NOTE: We intentionally skip 'response.text' and 'response.thinking' events
                // as they contain duplicate accumulated text that's already streamed via delta events
                
                // Handle response.chart events with Vega-Lite specs
                if (currentEvent === 'response.chart') {
                  const contentIndex = data.content_index ?? 0;
                  if (data.chart_spec) {
                    try {
                      const spec = typeof data.chart_spec === 'string' 
                        ? JSON.parse(data.chart_spec) 
                        : data.chart_spec;
                      vegaLiteSpec = spec;
                      
                      // Add chart to content items at its position
                      contentItemsMap.set(contentIndex, {
                        type: 'chart',
                        contentIndex,
                        vegaLiteSpec: spec,
                      });
                      
                      console.log('[SSE] Parsed Vega-Lite spec at index', contentIndex, vegaLiteSpec);
                    } catch (e) {
                      console.error('[SSE] Failed to parse chart_spec:', e);
                    }
                  }
                }
                
                // Handle response.table events with result sets
                if (currentEvent === 'response.table') {
                  const contentIndex = data.content_index ?? 0;
                  const resultSet = data.result_set;
                  
                  console.log('[SSE] response.table processing...');
                  
                  if (resultSet) {
                    let transformedData: Record<string, unknown>[] = [];
                    let columns: string[] = [];
                    
                    // Extract column names from resultSetMetaData.rowType (Snowflake format)
                    if (resultSet.resultSetMetaData?.rowType && Array.isArray(resultSet.resultSetMetaData.rowType)) {
                      columns = resultSet.resultSetMetaData.rowType.map((col: { name: string }) => col.name);
                      console.log('[SSE] Extracted columns from rowType:', columns);
                    }
                    // Fallback: try columns array directly
                    else if (resultSet.columns && Array.isArray(resultSet.columns)) {
                      columns = resultSet.columns.map((col: unknown) => {
                        if (typeof col === 'string') return col;
                        if (typeof col === 'object' && col !== null) {
                          const colObj = col as Record<string, unknown>;
                          return String(colObj.name || colObj.column_name || colObj.NAME || colObj.COLUMN_NAME || colObj.label || '');
                        }
                        return String(col);
                      });
                      console.log('[SSE] Extracted columns from columns array:', columns);
                    }
                    
                    // Transform data rows
                    if (resultSet.data && Array.isArray(resultSet.data) && columns.length > 0) {
                      const rows = resultSet.data as unknown[][];
                      transformedData = rows.map((row: unknown[]) => {
                        const obj: Record<string, unknown> = {};
                        columns.forEach((colName, idx) => {
                          obj[colName] = row[idx];
                        });
                        return obj;
                      });
                      console.log('[SSE] Transformed', transformedData.length, 'rows, sample:', transformedData[0]);
                    }
                    
                    if (transformedData.length > 0 && columns.length > 0) {
                      // Store as table data for fallback rendering
                      tableData = transformedData;
                      
                      // Add table to content items at its position for inline rendering
                      contentItemsMap.set(contentIndex, {
                        type: 'table',
                        contentIndex,
                        tableData: transformedData,
                        tableTitle: data.title,
                        queryId: data.query_id,
                      });
                      
                      console.log('[SSE] Parsed table data at index', contentIndex, 'rows:', transformedData.length, 'columns:', columns.length);
                    }
                  }
                }

                // Build sorted content items array
                const contentItems = Array.from(contentItemsMap.values())
                  .sort((a, b) => a.contentIndex - b.contentIndex);

                // Update message with streamed content
                if (collectedText || sql || chartConfig || vegaLiteSpec || tableData || contentItems.length > 0) {
                  setMessages((prev) =>
                    prev.map((m) =>
                      m.id === assistantId
                        ? { ...m, content: collectedText, contentItems, sql, chart: chartConfig, vegaLiteSpec, data: tableData }
                        : m
                    )
                  );
                }
              } catch {
                // Skip malformed JSON
              }
            }
          }
        }

        // Build final sorted content items array
        const finalContentItems = Array.from(contentItemsMap.values())
          .sort((a, b) => a.contentIndex - b.contentIndex);

        // Final update
        setMessages((prev) =>
          prev.map((m) =>
            m.id === assistantId
              ? { 
                  ...m, 
                  content: collectedText || 'No response from agent',
                  contentItems: finalContentItems,
                  sql,
                  chart: chartConfig,
                  vegaLiteSpec,
                  data: tableData,
                  timestamp: new Date(),
                }
              : m
          )
        );
      } catch (error) {
        if ((error as Error).name === 'AbortError') {
          return; // Request was cancelled
        }
        
        // Update with error message
        setMessages((prev) =>
          prev.map((m) =>
            m.id === assistantId
              ? { ...m, content: `Sorry, I encountered an error: ${(error as Error).message}. Please try again.` }
              : m
          )
        );
      } finally {
        setIsTyping(false);
        setIsLoading(false);
        setAgentStatus(null);
        isProcessingRef.current = false;
      }
    },
    [] // No dependencies - we use refs for current state
  );

  const clearMessages = useCallback(() => {
    // Cancel any pending request
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }
    setMessages([]);
    setIsTyping(false);
    setIsLoading(false);
    setAgentStatus(null);
    isProcessingRef.current = false;
  }, []);

  return {
    messages,
    isTyping,
    isLoading,
    agentStatus,
    sendMessage,
    clearMessages,
  };
}
