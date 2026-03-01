# Phase 2: UX / UI Polish - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Polish the portal's visual consistency and usability across all 6 analytics domain pages (authorization, settlement, funding, chargebacks, retrievals, adjustments). This phase covers: consistent navigation behavior, readable chart formatting, skeleton loading states, and uniform page structure. Adding new features or new domain pages is out of scope.

</domain>

<decisions>
## Implementation Decisions

### Empty states
- Leave as-is — blank charts with empty axes are acceptable for now
- No empty state component needed in this phase

### Loading experience
- Replace `<Spin spinning={isLoading}>` overlays with pulsing skeleton placeholders
- Chart cards should show a skeleton shape (pulsing/shimmer animation) while loading
- KPICard already has a built-in `loading` prop — keep using it
- Skeleton should match the approximate shape/height of the real content so layout doesn't shift on load

### Navigation
- Fix the Analytics submenu to stay expanded whenever the user is on any `/analytics/*` page
- Current bug: `defaultOpenKeys` only sets open state on mount; navigating directly to a domain URL may collapse the submenu
- Fix: use controlled `openKeys` driven by `pathname.startsWith('/analytics')`
- Remove stub nav items that go nowhere — specifically "Saved Reports" should be hidden until it's implemented

### Chart value formatting
- Y-axis labels: compact with currency symbol where applicable (e.g., `$1.2M`, `$450K`)
- Tooltips on hover: full precise value (e.g., `$1,234,567`)
- Percentage values: always 2 decimal places (e.g., `94.32%`)
- Count values: compact notation (e.g., `1.2M`) on axis, full number in tooltip

### Page structure — strict shared template
- All 6 domain pages must follow the same structural zones:
  1. Breadcrumb
  2. Page header (icon + title + subtitle)
  3. Filter bar (date range picker + domain-specific filters + Refresh button)
  4. Tabs (Overview / Details, where applicable)
  5. KPI cards row
  6. Chart rows
- Authorization, Settlement, and Funding are the reference implementations
- Adjustment page is the most incomplete (184 lines vs ~250 for others) — needs the most work to reach parity

### Filter behavior
- Instant-apply on change (keep current React Query refetch behavior)
- No explicit Apply button needed

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `KPICard` (`components/ui/KPICard.tsx`): Has built-in `loading` prop — already shows Ant Design card skeleton. Use as-is.
- `DashboardLayout` (`components/layout/DashboardLayout.tsx`): Sidebar uses `defaultOpenKeys` (mount-only) — needs to be changed to controlled `openKeys` for analytics submenu fix
- `BarChart`, `GaugeChart`, `PieChart`, `TimeSeriesChart` (`components/charts/`): All accept `formatValue` prop for custom value formatting — use this to implement compact currency formatting
- `Spin` from Ant Design: Currently wraps entire content sections — replace with Ant Design `Skeleton` for chart placeholders
- `useAnalyticsData` hook: Auto-refetches when params change — filter instant-apply already works

### Established Patterns
- Ant Design 6 (`antd`) is the component library — use `Skeleton`, `Skeleton.Node`, or `Skeleton.Image` for loading placeholders
- ECharts via `echarts-for-react`: Chart formatting is done via ECharts `axisLabel.formatter` — already used in BarChart for compact number format, needs currency variant
- Tailwind CSS 4 for layout utilities
- All domain pages import `useAnalyticsData` from `@/hooks` — loading state is `.isLoading` on each query

### Integration Points
- `DashboardLayout` wraps all pages via `app/layout.tsx` — sidebar fix applies globally
- `BarChart.tsx` has `formatValue` prop that applies to both tooltip and axis — currency formatter should be passed from page components
- 6 domain pages: `app/analytics/{domain}/page.tsx` — each page manages its own state, filters, and data hooks independently (no shared page component currently)

</code_context>

<specifics>
## Specific Ideas

- Authorization page is most complete and well-structured — use it as the baseline reference
- Settlement and Funding pages are also good references
- Adjustment page (184 lines) needs the most structural work to reach parity
- Skeleton placeholders should pulse/shimmer (Ant Design's default Skeleton animation is acceptable)
- The sidebar fix is a targeted change to `DashboardLayout.tsx` — `openKeys` controlled by `pathname`

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-ux-ui-polish*
*Context gathered: 2026-02-28*
