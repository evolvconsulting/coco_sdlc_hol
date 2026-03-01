/**
 * Canonical value formatters for chart axes, tooltips, and KPI displays.
 * Used across all analytics domain pages for consistent number presentation.
 *
 * Formatting rules (from CONTEXT.md):
 * - Y-axis labels: compact with currency symbol where applicable ($1.2M, $450K)
 * - Percentage values: always 2 decimal places (94.32%)
 * - Count values: compact notation on axis (1.2M), full number in tooltip
 * - Currency tooltips: compact format (single formatValue prop applies to both axis and tooltip)
 */

/**
 * Compact currency format for chart y-axis labels and tooltips.
 * Examples: 1234567 → "$1.2M", 450000 → "$450K", 500 → "$500"
 */
export const formatCompactCurrency = (value: number): string => {
  const abs = Math.abs(value);
  if (abs >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
  if (abs >= 1_000) return `$${(value / 1_000).toFixed(0)}K`;
  return `$${value.toFixed(0)}`;
};

/**
 * Full precision currency format using Intl.NumberFormat.
 * Examples: 1234567 → "$1,234,567", 450 → "$450"
 * Use for KPICard value display (not chart formatValue props).
 */
export const formatFullCurrency = (value: number): string =>
  new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value);

/**
 * Compact count format for chart y-axis labels.
 * Examples: 1200000 → "1.2M", 45000 → "45K", 500 → "500"
 */
export const formatCompactCount = (value: number): string =>
  new Intl.NumberFormat('en-US', { notation: 'compact' }).format(value);

/**
 * Full count format for readable display.
 * Examples: 1234567 → "1,234,567", 450 → "450"
 * Use for KPICard value display or tooltip-only contexts.
 */
export const formatFullCount = (value: number): string =>
  new Intl.NumberFormat('en-US').format(value);

/**
 * Percentage format — always 2 decimal places.
 * Examples: 94.32 → "94.32%", 100 → "100.00%", 0.5 → "0.50%"
 */
export const formatPercent = (value: number): string => `${value.toFixed(2)}%`;
