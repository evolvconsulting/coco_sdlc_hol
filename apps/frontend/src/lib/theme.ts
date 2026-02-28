// evolv Brand Theme Configuration
// Primary brand color: #FF6600 (evolv Orange)

import type { ThemeConfig } from 'antd';

export const evolvTheme: ThemeConfig = {
  token: {
    // Primary brand colors
    colorPrimary: '#FF6600',
    colorPrimaryHover: '#E65C00',
    colorPrimaryActive: '#CC5200',
    colorPrimaryBg: '#FFF2E8',
    colorPrimaryBgHover: '#FFE4CC',
    colorPrimaryBorder: '#FFB380',
    colorPrimaryBorderHover: '#FF9955',
    colorPrimaryText: '#FF6600',
    colorPrimaryTextHover: '#E65C00',
    colorPrimaryTextActive: '#CC5200',

    // Link colors
    colorLink: '#FF6600',
    colorLinkHover: '#E65C00',
    colorLinkActive: '#CC5200',

    // Success, warning, error colors
    colorSuccess: '#52c41a',
    colorWarning: '#faad14',
    colorError: '#ff4d4f',
    colorInfo: '#1890ff',

    // Background and text
    colorBgContainer: '#ffffff',
    colorBgLayout: '#f5f5f5',
    colorText: '#1a1a1a',
    colorTextSecondary: '#666666',
    colorTextTertiary: '#999999',
    colorTextQuaternary: '#cccccc',

    // Border
    colorBorder: '#d9d9d9',
    colorBorderSecondary: '#f0f0f0',

    // Typography
    fontFamily: '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
    fontSize: 14,
    fontSizeHeading1: 38,
    fontSizeHeading2: 30,
    fontSizeHeading3: 24,
    fontSizeHeading4: 20,
    fontSizeHeading5: 16,

    // Border radius
    borderRadius: 6,
    borderRadiusLG: 8,
    borderRadiusSM: 4,

    // Spacing
    padding: 16,
    paddingLG: 24,
    paddingSM: 12,
    paddingXS: 8,

    // Control heights
    controlHeight: 36,
    controlHeightLG: 44,
    controlHeightSM: 28,
  },
  components: {
    Layout: {
      headerBg: '#1a1a1a',
      siderBg: '#1a1a1a',
      bodyBg: '#f5f5f5',
      headerHeight: 64,
      headerPadding: '0 24px',
    },
    Menu: {
      darkItemBg: '#1a1a1a',
      darkItemSelectedBg: '#FF6600',
      darkItemHoverBg: '#333333',
      darkItemColor: '#ffffff',
      darkItemSelectedColor: '#ffffff',
      itemHeight: 48,
      iconSize: 18,
    },
    Button: {
      primaryShadow: '0 2px 0 rgba(255, 102, 0, 0.1)',
      defaultShadow: '0 2px 0 rgba(0, 0, 0, 0.02)',
    },
    Card: {
      headerBg: '#ffffff',
      paddingLG: 24,
    },
    Table: {
      headerBg: '#fafafa',
      headerColor: '#1a1a1a',
      rowHoverBg: '#fff7f0',
    },
    Statistic: {
      titleFontSize: 14,
      contentFontSize: 24,
    },
  },
};

// Domain-specific colors for charts
export const domainColors = {
  authorization: {
    primary: '#FF6600',
    secondary: '#FFB380',
    approved: '#52c41a',
    declined: '#ff4d4f',
    unknown: '#999999',
  },
  settlement: {
    primary: '#1890ff',
    secondary: '#91d5ff',
    sales: '#52c41a',
    refunds: '#ff4d4f',
    fees: '#faad14',
  },
  funding: {
    primary: '#52c41a',
    secondary: '#b7eb8f',
    deposits: '#52c41a',
    fees: '#ff4d4f',
    chargebacks: '#faad14',
  },
  chargeback: {
    primary: '#ff4d4f',
    secondary: '#ffccc7',
    won: '#52c41a',
    lost: '#ff4d4f',
    pending: '#faad14',
  },
  retrieval: {
    primary: '#722ed1',
    secondary: '#d3adf7',
    fulfilled: '#52c41a',
    expired: '#ff4d4f',
    open: '#faad14',
  },
  adjustment: {
    primary: '#13c2c2',
    secondary: '#87e8de',
    credits: '#52c41a',
    debits: '#ff4d4f',
  },
};

// Card brand colors
export const cardBrandColors: Record<string, string> = {
  Visa: '#1A1F71',
  Mastercard: '#EB001B',
  'American Express': '#006FCF',
  Amex: '#006FCF',
  Discover: '#FF6000',
  JCB: '#0B4EA2',
  'Diners Club': '#004A97',
  UnionPay: '#DE2910',
  Other: '#999999',
};
