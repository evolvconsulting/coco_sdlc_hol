'use client';

import { useState, useRef, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { Typography, Card, Spin } from 'antd';
import { MessageOutlined, BulbOutlined } from '@ant-design/icons';
import { ChatWindow, SuggestedQueries } from '@/components/chat';
import type { ChatWindowRef } from '@/components/chat';

const { Title, Text } = Typography;

function ChatPageContent() {
  const searchParams = useSearchParams();
  const initialQuestion = searchParams.get('q') || undefined;
  const [activeTab, setActiveTab] = useState<string>('chat');
  const chatWindowRef = useRef<ChatWindowRef>(null);

  const handleSelectQuery = (query: string) => {
    // Switch to chat tab and send the message through ChatWindow
    setActiveTab('chat');
    // Use setTimeout to ensure tab switch completes first
    setTimeout(() => {
      chatWindowRef.current?.sendMessage(query);
    }, 0);
  };

  return (
    <div>
      <div className="mb-4">
        <Title level={2} className="!mb-1 !text-xl sm:!text-2xl">
          Ask Your Data
        </Title>
        <Text type="secondary" className="text-sm">
          Use natural language to explore your payment processing data
        </Text>
      </div>

      <Card
        styles={{ body: { padding: 0 } }}
        tabList={[
          {
            key: 'chat',
            tab: (
              <span>
                <MessageOutlined /> Chat
              </span>
            ),
          },
          {
            key: 'suggestions',
            tab: (
              <span>
                <BulbOutlined /> Suggested Questions
              </span>
            ),
          },
        ]}
        activeTabKey={activeTab}
        onTabChange={setActiveTab}
      >
        {activeTab === 'chat' ? (
          <ChatWindow ref={chatWindowRef} initialQuestion={initialQuestion} />
        ) : (
          <div className="p-4">
            <SuggestedQueries onSelectQuery={handleSelectQuery} />
          </div>
        )}
      </Card>
    </div>
  );
}

export default function ChatPage() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center h-64">
        <Spin size="large" />
      </div>
    }>
      <ChatPageContent />
    </Suspense>
  );
}
