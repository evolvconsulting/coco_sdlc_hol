'use client';

import React, { useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { Menu, Typography, Avatar, Dropdown, Space, Button } from 'antd';
import type { MenuProps } from 'antd';
import {
  DashboardOutlined,
  CreditCardOutlined,
  BankOutlined,
  DollarOutlined,
  WarningOutlined,
  FileSearchOutlined,
  SwapOutlined,
  MessageOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  UserOutlined,
  SettingOutlined,
  LogoutOutlined,
  QuestionCircleOutlined,
} from '@ant-design/icons';

const { Text } = Typography;

// evolv Logo SVG Component
const EvolvLogo = ({ collapsed }: { collapsed: boolean }) => (
  <div className="flex items-center justify-center h-16 px-4">
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 183.16 57.2"
      className={`transition-all duration-300 ${collapsed ? 'h-6 w-auto' : 'h-8 w-auto'}`}
    >
      <path fill="#d25633" d="M125.48,33a21,21,0,1,1-21.13-20.92A20.72,20.72,0,0,1,125.48,33Zm-38.06.12c0,9.13,7.23,17.2,16.7,17.19a17.08,17.08,0,0,0,17.45-17.22,17.07,17.07,0,0,0-17.48-17.36C94.53,15.74,87.42,23.83,87.42,33.12Z"/>
      <path fill="#d25633" d="M135.24,54.07h0a2,2,0,0,1-2-2l0-48.24a2,2,0,0,1,2-2h0a2,2,0,0,1,2,2l0,48.25A2,2,0,0,1,135.24,54.07Z"/>
      <path fill="#d25633" d="M79.35,13a1.84,1.84,0,0,0-1.68,1.11L65.59,42.21a1.83,1.83,0,0,1-3.36,0L49.87,14.09A1.83,1.83,0,0,0,48.19,13h0a1.83,1.83,0,0,0-1.68,2.56L62,52.84A1.86,1.86,0,0,0,63.63,54l.07,0H64a.87.87,0,0,0,.26,0,1.86,1.86,0,0,0,1.34-1.34S81,15.53,81,15.53A1.84,1.84,0,0,0,79.35,13Z"/>
      <path fill="#d25633" d="M178.24,12.89a1.83,1.83,0,0,0-1.68,1.1L164.48,42.13a1.83,1.83,0,0,1-3.36,0L148.76,14a1.83,1.83,0,0,0-1.68-1.1h0a1.84,1.84,0,0,0-1.68,2.57l15.54,37.28a1.87,1.87,0,0,0,1.58,1.14h.38a.93.93,0,0,0,.27,0,1.92,1.92,0,0,0,1.34-1.34l15.42-37.09A1.83,1.83,0,0,0,178.24,12.89Z"/>
      <path fill="#d25633" d="M11.3,33.4l28.69,0a1.69,1.69,0,0,0,1.68-1.79C41,20.83,34,12.09,22.41,12.1,10.68,12.11,3,21.77,3,33c0,11.39,7.58,21,19.48,21,7.91,0,14.12-3.51,17.76-10.47h0a1.84,1.84,0,0,0,.17-.77,1.91,1.91,0,0,0-1.91-1.91,1.89,1.89,0,0,0-1.72,1.11.88.88,0,0,0-.12.15C33.7,47,28.88,50.33,23,50.33c-9.3,0-15.64-7.31-16.5-16.72l-3.26-.38,3.67-3.47a15.82,15.82,0,0,1,15.62-14c8.26,0,14.34,6.6,15.31,14l-21.49,0Z"/>
    </svg>
    {!collapsed && (
      <Text className="ml-2 text-white text-xs opacity-70">
        Performance Intelligence
      </Text>
    )}
  </div>
);

const menuItems: MenuProps['items'] = [
  {
    key: '/',
    icon: <DashboardOutlined />,
    label: 'Dashboard',
  },
  {
    key: '/analytics/authorization',
    icon: <CreditCardOutlined />,
    label: 'Authorization',
  },
  {
    key: '/analytics/settlement',
    icon: <BankOutlined />,
    label: 'Settlement',
  },
  {
    key: '/analytics/funding',
    icon: <DollarOutlined />,
    label: 'Funding',
  },
  {
    key: '/analytics/chargeback',
    icon: <WarningOutlined />,
    label: 'Chargebacks',
  },
  {
    key: '/analytics/retrieval',
    icon: <FileSearchOutlined />,
    label: 'Retrievals',
  },
  {
    key: '/analytics/adjustment',
    icon: <SwapOutlined />,
    label: 'Adjustments',
  },
  {
    key: '/chat',
    icon: <MessageOutlined />,
    label: 'Ask Data',
  },
];

const userMenuItems: MenuProps['items'] = [
  {
    key: 'profile',
    icon: <UserOutlined />,
    label: 'Profile',
  },
  {
    key: 'settings',
    icon: <SettingOutlined />,
    label: 'Settings',
  },
  {
    type: 'divider',
  },
  {
    key: 'help',
    icon: <QuestionCircleOutlined />,
    label: 'Help & Support',
  },
  {
    type: 'divider',
  },
  {
    key: 'logout',
    icon: <LogoutOutlined />,
    label: 'Sign Out',
    danger: true,
  },
];

export function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [collapsed, setCollapsed] = useState(false);
  const pathname = usePathname();
  const router = useRouter();

  const handleMenuClick: MenuProps['onClick'] = (e) => {
    router.push(e.key);
  };

  const selectedKeys = [pathname];

  return (
    <div className="min-h-screen">
      {/* Fixed Sidebar */}
      <aside
        className="fixed left-0 top-0 bottom-0 z-20 transition-all duration-200"
        style={{ 
          background: '#1a1a1a',
          overflowY: 'auto',
          overflowX: 'hidden',
          height: '100vh',
          width: collapsed ? 80 : 260,
          boxShadow: '2px 0 8px rgba(0, 0, 0, 0.05)',
        }}
      >
        <EvolvLogo collapsed={collapsed} />
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={selectedKeys}
          items={menuItems}
          onClick={handleMenuClick}
          inlineCollapsed={collapsed}
          style={{ 
            background: '#1a1a1a',
            borderRight: 0,
          }}
        />
      </aside>

      {/* Main Content Area */}
      <div 
        className="transition-all duration-200"
        style={{ 
          marginLeft: collapsed ? 80 : 260, 
          minHeight: '100vh',
        }}
      >
        <header
          className="flex items-center justify-between sticky top-0 z-10"
          style={{ 
            background: '#ffffff',
            borderBottom: '1px solid #f0f0f0',
            padding: '0 24px',
            height: 64,
          }}
        >
          <div className="flex items-center">
            <Button
              type="text"
              icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
              onClick={() => setCollapsed(!collapsed)}
              className="text-lg"
            />
          </div>

          <div className="flex items-center gap-4">
            <Text className="text-sm text-gray-500">
              Client: <Text strong>DMCL</Text>
            </Text>
            <Dropdown
              menu={{ items: userMenuItems }}
              trigger={['click']}
              placement="bottomRight"
            >
              <Space className="cursor-pointer hover:bg-gray-100 px-3 py-2 rounded-lg transition-colors">
                <Avatar
                  size={32}
                  style={{ backgroundColor: '#FF6600' }}
                  icon={<UserOutlined />}
                />
                <div className="hidden sm:block">
                  <Text className="block text-sm font-medium leading-none">Demo User</Text>
                  <Text className="block text-xs text-gray-500">demo@evolvconsulting.com</Text>
                </div>
              </Space>
            </Dropdown>
          </div>
        </header>

        <main 
          className="p-6" 
          style={{ 
            background: '#f5f5f5',
            minHeight: 'calc(100vh - 64px)',
          }}
        >
          <div className="max-w-full">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
