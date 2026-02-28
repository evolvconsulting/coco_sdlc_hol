'use client';

import React from 'react';
import { Result, Button, Typography } from 'antd';
import { 
  DisconnectOutlined, 
  ReloadOutlined,
  SettingOutlined,
  CloudServerOutlined 
} from '@ant-design/icons';

const { Text, Paragraph } = Typography;

export type ConnectionErrorCode = 
  | 'SNOWFLAKE_NOT_CONFIGURED'
  | 'SNOWFLAKE_CONNECTION_ERROR'
  | 'CORTEX_AGENT_ERROR'
  | 'QUERY_EXECUTION_ERROR'
  | 'INTERNAL_ERROR';

interface ConnectionErrorProps {
  code?: ConnectionErrorCode;
  title?: string;
  message?: string;
  details?: string;
  onRetry?: () => void;
  showDetails?: boolean;
}

const errorConfig: Record<ConnectionErrorCode, { icon: React.ReactNode; title: string; message: string }> = {
  SNOWFLAKE_NOT_CONFIGURED: {
    icon: <SettingOutlined style={{ color: '#faad14' }} />,
    title: 'Snowflake Not Configured',
    message: 'The application requires a connection to Snowflake. Please configure your Snowflake credentials in the environment settings.',
  },
  SNOWFLAKE_CONNECTION_ERROR: {
    icon: <DisconnectOutlined style={{ color: '#ff4d4f' }} />,
    title: 'Connection Failed',
    message: 'Unable to connect to Snowflake. Please check your network connection and credentials, then try again.',
  },
  CORTEX_AGENT_ERROR: {
    icon: <CloudServerOutlined style={{ color: '#ff4d4f' }} />,
    title: 'AI Assistant Unavailable',
    message: 'Unable to reach the AI assistant. Please check your Snowflake connection and try again.',
  },
  QUERY_EXECUTION_ERROR: {
    icon: <DisconnectOutlined style={{ color: '#ff4d4f' }} />,
    title: 'Query Failed',
    message: 'Unable to execute the query. Please check your query syntax and try again.',
  },
  INTERNAL_ERROR: {
    icon: <DisconnectOutlined style={{ color: '#ff4d4f' }} />,
    title: 'Something Went Wrong',
    message: 'An unexpected error occurred. Please try again or contact support if the issue persists.',
  },
};

export function ConnectionError({ 
  code = 'SNOWFLAKE_CONNECTION_ERROR',
  title,
  message,
  details,
  onRetry,
  showDetails = false,
}: ConnectionErrorProps) {
  const config = errorConfig[code] || errorConfig.INTERNAL_ERROR;
  
  return (
    <div style={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center', 
      minHeight: '400px',
      padding: '24px',
    }}>
      <Result
        icon={config.icon}
        title={title || config.title}
        subTitle={message || config.message}
        extra={[
          onRetry && (
            <Button 
              key="retry" 
              type="primary" 
              icon={<ReloadOutlined />}
              onClick={onRetry}
            >
              Try Again
            </Button>
          ),
        ].filter(Boolean)}
      >
        {showDetails && details && (
          <div style={{ 
            marginTop: '16px', 
            padding: '12px', 
            background: 'rgba(0,0,0,0.02)', 
            borderRadius: '6px',
            textAlign: 'left',
          }}>
            <Text type="secondary" strong>Technical Details:</Text>
            <Paragraph 
              type="secondary" 
              style={{ 
                marginTop: '8px', 
                marginBottom: 0,
                fontSize: '12px',
                fontFamily: 'monospace',
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-word',
              }}
            >
              {details}
            </Paragraph>
          </div>
        )}
      </Result>
    </div>
  );
}

// Simplified version for inline use in cards/sections
export function ConnectionErrorInline({ 
  message = 'Unable to load data',
  onRetry,
}: { 
  message?: string;
  onRetry?: () => void;
}) {
  return (
    <div style={{ 
      display: 'flex', 
      flexDirection: 'column',
      justifyContent: 'center', 
      alignItems: 'center', 
      padding: '24px',
      color: '#8c8c8c',
      textAlign: 'center',
    }}>
      <DisconnectOutlined style={{ fontSize: '32px', marginBottom: '12px', color: '#ff4d4f' }} />
      <Text type="secondary">{message}</Text>
      {onRetry && (
        <Button 
          type="link" 
          size="small"
          icon={<ReloadOutlined />}
          onClick={onRetry}
          style={{ marginTop: '8px' }}
        >
          Retry
        </Button>
      )}
    </div>
  );
}

export default ConnectionError;
