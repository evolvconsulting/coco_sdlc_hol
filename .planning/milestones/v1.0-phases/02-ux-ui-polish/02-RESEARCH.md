# Phase 2: UX / UI Polish - Research

**Researched:** 2026-02-28
**Domain:** React / Next.js frontend polish — Ant Design 6, ECharts, Tailwind CSS 4
**Confidence:** HIGH (findings based on direct codebase inspection, not assumptions)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Empty states**
- Leave as-is — blank charts with empty axes are acceptable for now
- No empty state component needed in this phase

**Loading experience**
- Replace `<Spin spinning={isLoading}>` overlays with pulsing skeleton placeholders
- Chart cards should show a skeleton shape (pulsing/shimmer animation) while loading
- KPICard already has a built-in `loading` prop — keep using it
- Skeleton should match the approximate shape/height of the real content so layout doesn't shift on load

**Navigation**
- Fix the Analytics submenu to stay expanded whenever the user is on any `/analytics/*` page
- Current bug: `defaultOpenKeys` only sets open state on mount; navigating directly to a domain URL may collapse the submenu
- Fix: use controlled `openKeys` driven by `pathname.startsWith('/analytics')`
- Remove stub nav items that go nowhere — specifically "Saved Reports" should be hidden until it's implemented

**Chart value formatting**
- Y-axis labels: compact with currency symbol where applicable (e.g., `$1.2M`, `$450K`)
- Tooltips on hover: full precise value (e.g., `$1,234,567`)
- Percentage values: always 2 decimal places (e.g., `94.32%`)
- Count values: compact notation (e.g., `1.2M`) on axis, full number in tooltip

**Page structure — strict shared template**
- All 6 domain pages must follow the same structural zones:
  1. Breadcrumb
  2. Page header (icon + title + subtitle)
  3. Filter bar (date range picker + domain-specific filters + Refresh button)
  4. Tabs (Overview / Details, where applicable)
  5. KPI cards row
  6. Chart rows
- Authorization, Settlement, and Funding are the reference implementations
- Adjustment page is the most incomplete (184 lines vs ~250 for others) — needs the most work to reach parity

**Filter behavior**
- Instant-apply on change (keep current React Query refetch behavior)
- No explicit Apply button needed

### Claude's Discretion

None specified — all decisions are locked.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UX-01 | Navigation and layout are visually consistent across all 6 domain pages | Sidebar `openKeys` fix in DashboardLayout + remove "Saved Reports" menu item |
| UX-02 | Charts display with correct labels, axes, legends, and data formatting | ECharts `axisLabel.formatter` already exists in chart components; currency/compact formatters needed |
| UX-03 | Empty states and loading states handled gracefully in all charts and data tables | Replace `<Spin>` wrapping entire sections with per-card `Skeleton` from Ant Design |
| UX-04 | Date pickers and date range filters work correctly and update displayed data | Already implemented via React Query + `useAnalyticsData`; no new work needed beyond verification |
| UX-05 | Domain-specific filters (brand, reason code, status) apply correctly | Already functional; filter selects exist and feed into `useAnalyticsData` params |
| UX-06 | Portal is usable at standard desktop screen sizes | Verify Ant Design `Row/Col` grid usage and content overflow; Tailwind CSS layout audit |
</phase_requirements>

---

## Summary

Phase 2 is primarily a polish pass over existing, functional code. All 6 domain pages already have working data loading, filters, and charts. The work falls into four discrete buckets: (1) fixing the sidebar submenu collapse bug, (2) replacing `<Spin>` loading overlays with skeleton placeholders, (3) standardizing value formatting across all chart axis labels and tooltips, and (4) auditing the Adjustment page to bring it to structural parity with the Authorization reference page.

The most significant structural gap is the Adjustment page (184 lines). It uses `Statistic` components from Ant Design directly instead of the shared `KPICard` component that other pages use. It also has no chart content at all — the overview section is KPIs only. Chargeback and Retrieval pages are in a similar middle state: they use `Statistic` + raw `Card` for KPIs but do have chart content. Authorization, Settlement, and Funding use `KPICard` for most metrics and are the reference implementations.

The loaded technology stack is already fully configured and correct. No new libraries are required. All work is targeted modifications to existing components and page files.

**Primary recommendation:** Work page-by-page in order of most-to-least broken: Adjustment > Chargeback > Retrieval > Settlement > Funding > Authorization. Fix `DashboardLayout.tsx` first since it applies globally.

---

## Standard Stack

### Core (already installed — no new installs needed)

| Library | Version | Purpose | Role in This Phase |
|---------|---------|---------|-------------------|
| `antd` | ^6.3.0 | UI component library | `Skeleton`, `Skeleton.Node` for loading states; `Menu` for sidebar fix |
| `echarts` + `echarts-for-react` | ^6.0.0 + ^3.0.6 | Chart rendering | `axisLabel.formatter` for compact/currency axis labels |
| `tailwindcss` | ^4 | Layout utilities | Responsive grid classes on pages |
| `next` | 16.1.6 | Framework | `usePathname()` already imported in DashboardLayout |
| `dayjs` | ^1.11.19 | Date handling | Already used in all date range pickers |
| `@tanstack/react-query` | ^5.90.21 | Data fetching | `isLoading` state drives all skeleton displays |

### No New Libraries Required

All required functionality exists in the current dependency set. The Ant Design `Skeleton` component is available in `antd` 6.x without additional installation.

**Installation:** None required.

---

## Architecture Patterns

### Recommended File Touch List

```
apps/frontend/src/
├── components/layout/DashboardLayout.tsx   # Sidebar openKeys fix + remove Saved Reports
├── app/analytics/adjustment/page.tsx       # Highest priority: bring to structural parity
├── app/analytics/chargeback/page.tsx       # Convert Statistic → KPICard, add Spin→Skeleton
├── app/analytics/retrieval/page.tsx        # Convert Statistic → KPICard, add Spin→Skeleton
├── app/analytics/settlement/page.tsx       # Spin→Skeleton, format audit
├── app/analytics/funding/page.tsx          # Spin→Skeleton, format audit
└── app/analytics/authorization/page.tsx   # Spin→Skeleton, format audit (reference impl)
```

No new files need to be created. All chart components (`BarChart`, `TimeSeriesChart`, `PieChart`, `GaugeChart`) already accept `formatValue` props and already apply them to both tooltip and axis formatters — the formatters just need to be passed correctly from each page.

### Pattern 1: Sidebar `openKeys` Fix (Controlled vs Uncontrolled)

**What:** The current `DashboardLayout.tsx` uses `defaultOpenKeys` (uncontrolled) which only applies at mount time. When navigating via client-side router to an `/analytics/*` URL, the submenu may not be expanded.

**Fix:** Replace `defaultOpenKeys` with controlled `openKeys` prop. The value is already derived correctly in the component as `const openKeys = pathname.startsWith('/analytics') ? ['analytics'] : []` — it just isn't being used as the `openKeys` prop.

**Current code (line 145-166 of DashboardLayout.tsx):**
```tsx
// Before: uncontrolled
const openKeys = pathname.startsWith('/analytics') ? ['analytics'] : [];
// ...
<Menu
  selectedKeys={selectedKeys}
  defaultOpenKeys={openKeys}   // BUG: mount-only
  items={menuItems}
  // ...
```

**Fixed code:**
```tsx
<Menu
  selectedKeys={selectedKeys}
  openKeys={openKeys}           // FIX: controlled, reactive to pathname
  items={menuItems}
  // ...
```

**Also:** Remove the "Saved Reports" menu item from the `menuItems` array (lines 98-101 of DashboardLayout.tsx). The `SaveOutlined` import can also be removed if no longer used.

### Pattern 2: Skeleton Loading Placeholders (Replacing `<Spin>`)

**What:** Each domain page currently wraps entire `<Spin spinning={isLoading}>` around all KPI cards and charts. This causes a spinner overlay on top of stale/empty content. The replacement is per-card skeleton shapes using Ant Design's `Skeleton`.

**Ant Design 6 Skeleton API (verified from antd docs and codebase):**
- `<Skeleton loading={bool} active>` — wraps content, shows animated placeholder when loading
- `<Skeleton.Node active style={{ width, height }}>` — free-form shape skeleton for chart areas
- `KPICard` already accepts `loading={bool}` prop which triggers Ant Design card skeleton internally — keep as-is

**Pattern for chart card skeleton:**
```tsx
// Replace this pattern:
<Spin spinning={isLoading}>
  <TimeSeriesChart data={trendData} title="Daily Volume" height={300} />
</Spin>

// With this pattern:
{isLoading ? (
  <Card title={<Skeleton.Input active size="small" style={{ width: 160 }} />}>
    <Skeleton.Node active style={{ width: '100%', height: 300 }}>
      <span />
    </Skeleton.Node>
  </Card>
) : (
  <TimeSeriesChart data={trendData} title="Daily Volume" height={300} />
)}
```

**Simpler acceptable pattern** (Card with active skeleton body):
```tsx
{isLoading ? (
  <Card>
    <Skeleton active paragraph={{ rows: 6 }} />
  </Card>
) : (
  <TimeSeriesChart ... />
)}
```

**Key constraint:** Skeleton must match the approximate height of the real content to prevent layout shift. Chart height is always specified as a number prop (e.g., `height={300}`) — match the skeleton height to that value.

### Pattern 3: Value Formatting — Canonical Formatters

The `formatValue` prop already exists on all chart components and applies to both `axisLabel.formatter` and `tooltip.formatter`. The only work is defining the correct formatter functions and passing them consistently.

**Canonical formatters to define (can be utility functions or inline):**

```typescript
// Compact currency — for y-axis labels
const formatCompactCurrency = (value: number): string => {
  if (Math.abs(value) >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
  if (Math.abs(value) >= 1_000) return `$${(value / 1_000).toFixed(0)}K`;
  return `$${value.toFixed(0)}`;
};

// Full currency — for tooltips
const formatFullCurrency = (value: number): string =>
  new Intl.NumberFormat('en-US', {
    style: 'currency', currency: 'USD',
    minimumFractionDigits: 0, maximumFractionDigits: 0,
  }).format(value);

// Compact count — for y-axis labels
const formatCompactCount = (value: number): string =>
  new Intl.NumberFormat('en-US', { notation: 'compact' }).format(value);

// Full count — for tooltips
const formatFullCount = (value: number): string =>
  new Intl.NumberFormat('en-US').format(value);

// Percentage — always 2 decimal places
const formatPercent = (value: number): string => `${value.toFixed(2)}%`;
```

**Critical insight:** The chart components' `formatValue` prop is used for BOTH axis labels AND tooltips (see `BarChart.tsx` lines 89-90 and 106-108). There is no separate `formatAxisValue` vs `formatTooltipValue` prop. This means:
- For currency charts: pass the compact formatter (`$1.2M`) as `formatValue` — this applies to axis and tooltip both
- The tooltip will show the compact value, not the full precise value
- To achieve the "compact axis, precise tooltip" spec from CONTEXT.md, the chart components need a second prop: `formatTooltipValue`

**Decision needed (see Open Questions):** Either extend chart components to support separate `formatTooltipValue`, or accept that tooltip uses compact format. Given phase scope, the simpler path (single format for both) is likely acceptable — verify with user if needed.

### Pattern 4: Adjustment Page Structural Parity

The Adjustment page (184 lines) is the most incomplete. Current state vs. Authorization reference:

| Zone | Authorization (reference) | Adjustment (current state) |
|------|--------------------------|---------------------------|
| Breadcrumb | Present | Present |
| Page header (icon + title + subtitle) | Present (uses domainColors) | Present (uses domainColors) |
| Filter bar (RangePicker + domain filter + Refresh) | Present (brand filter) | Present (no domain-specific filter) |
| Tabs (Overview / Details) | Present | Present |
| KPI cards using `KPICard` component | 4 cards using `KPICard` | 4 `Statistic` inside raw `Card` |
| Charts row | 3 chart rows | NONE — overview has only KPIs |
| Spin → Skeleton | Needs updating | Needs updating |

**Adjustment page lacks any chart content.** The adjustment domain has `kpis` and `details` endpoints, but no `timeseries` or categorical breakdown endpoint (no `by-type` or similar). Check the API route to confirm what data is available before designing chart content.

### Anti-Patterns to Avoid

- **`defaultOpenKeys` for dynamic navigation:** Uncontrolled menu state does not react to `pathname` changes after mount. Always use controlled `openKeys` when the open state must reflect navigation.
- **`<Spin>` wrapping content that already has data:** When query data exists from a previous fetch (React Query cache), a Spin overlay hides valid data. Skeleton placeholders only show when no data exists yet.
- **Hardcoded compact format strings like `$${(v / 1000).toFixed(0)}K`:** Several pages already use ad-hoc format strings (chargeback page line 234, settlement page line 228). These should use the canonical formatter functions for consistency.
- **`Statistic` component instead of `KPICard`:** Chargeback, Retrieval, and Adjustment use Ant Design `Statistic` directly inside raw `Card`. This loses the trend indicator, description tooltip, and consistent styling that `KPICard` provides.
- **`<Spin>` on details tab that only loads on tab switch:** The details tab already uses `{ enabled: activeTab === 'details' }` in React Query. The Spin wrapper is acceptable for details tab content since it's a full replace (no stale data shown).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Animated loading placeholder | Custom CSS shimmer animation | `<Skeleton active>` from antd | Built-in, accessible, matches antd design language |
| Compact number formatter | Custom if/else logic | `Intl.NumberFormat` with `notation: 'compact'` | Browser native, handles edge cases (negative, locale) |
| Controlled menu state | Custom open/close state management | `openKeys` prop on antd `Menu` | Already supported; `openKeys` is the documented controlled pattern |
| Card loading state | Custom overlay or spinner | `<Card loading={bool}>` or `KPICard loading={bool}` | Antd Card has built-in skeleton behavior via `loading` prop |

**Key insight:** Everything needed is already in the installed libraries. This phase is configuration, not construction.

---

## Common Pitfalls

### Pitfall 1: Ant Design Menu `openKeys` vs `defaultOpenKeys`

**What goes wrong:** Using `defaultOpenKeys` with a dynamic value (like one derived from `pathname`) has no effect after mount. The menu stays closed when navigating via `router.push()`.
**Why it happens:** `defaultOpenKeys` is an uncontrolled prop — it only sets initial state. Ant Design's controlled equivalent is `openKeys`.
**How to avoid:** Use `openKeys={openKeys}` where `openKeys` is derived from `pathname`. This is already partially implemented (the value is computed correctly, just passed to the wrong prop).
**Warning signs:** Submenu appears open when refreshing directly on `/analytics/authorization` but collapses after clicking "Dashboard" and then "Authorization" from the menu.

### Pitfall 2: Skeleton Height Mismatch Causes Layout Shift

**What goes wrong:** A skeleton that is shorter or taller than the actual chart causes content to jump when data loads, disrupting the reading experience.
**Why it happens:** Charts have explicit `height` props. Skeletons default to text-line heights unless told otherwise.
**How to avoid:** Always set skeleton container height to match the chart `height` prop. Use `style={{ height: 300 }}` or `style={{ height }}` (where height is the chart's height prop value) on the skeleton container.
**Warning signs:** Page visibly shifts vertically when loading transitions to loaded state.

### Pitfall 3: `formatValue` Applies to Both Axis and Tooltip

**What goes wrong:** Passing a compact formatter (`$1.2M`) makes tooltips show compact values instead of full values (`$1,234,567`), violating the CONTEXT.md spec.
**Why it happens:** `BarChart.tsx` and `TimeSeriesChart.tsx` use a single `formatValue` for both `axisLabel.formatter` and `tooltip.formatter`.
**How to avoid:** Either (a) accept that tooltips use compact format for this phase (simpler), or (b) add a `formatTooltipValue` prop to chart components. Option (a) is lower risk. Option (b) is two small component changes plus updates to all usages.
**Warning signs:** Hovering over a bar chart shows `$1.2M` in tooltip instead of `$1,234,567`.

### Pitfall 4: Adjustment Page Has No Chart API Endpoint

**What goes wrong:** Trying to add chart content to the Adjustment overview without first verifying the API has a timeseries or breakdown endpoint.
**Why it happens:** The Adjustment page currently only calls `useAnalyticsData('adjustment', 'kpis', ...)` and `useAnalyticsData('adjustment', 'details', ...)`. There is no `timeseries` or `by-type` endpoint visible in the codebase.
**How to avoid:** Check the API route file (`apps/frontend/src/app/api/analytics/adjustment/`) before designing the chart section. If no breakdown endpoint exists, the Adjustment overview section stays KPIs-only with better cards (KPICard instead of Statistic).
**Warning signs:** 404 or data error in the Adjustment overview after adding a chart that calls a non-existent endpoint.

### Pitfall 5: `Statistic` vs `KPICard` Inconsistency

**What goes wrong:** Chargeback, Retrieval, and Adjustment use Ant Design `Statistic` inside raw `Card`. This produces a visually different look from Authorization (which uses `KPICard`), violating UX-01 (consistent layout).
**Why it happens:** Different pages were built at different times without enforcing a shared KPI component.
**How to avoid:** Replace `<Card><Statistic .../></Card>` with `<KPICard ... />` on the three non-conforming pages. `KPICard` accepts `title`, `value`, `format`, `trend`, `loading`, `description`, and `color` props.
**Warning signs:** Visual inspection shows KPI cards have different padding, font sizes, or trend indicator styles between Authorization and Chargeback pages.

---

## Code Examples

Verified patterns from codebase inspection:

### Sidebar `openKeys` Fix

```tsx
// File: apps/frontend/src/components/layout/DashboardLayout.tsx

// BEFORE (line ~166):
<Menu
  theme="dark"
  mode="inline"
  selectedKeys={selectedKeys}
  defaultOpenKeys={openKeys}    // uncontrolled — bug
  items={menuItems}

// AFTER:
<Menu
  theme="dark"
  mode="inline"
  selectedKeys={selectedKeys}
  openKeys={openKeys}           // controlled — fixed
  items={menuItems}
```

### Remove "Saved Reports" from menuItems

```tsx
// File: apps/frontend/src/components/layout/DashboardLayout.tsx
// Remove this entry from the menuItems array (lines ~98-101):
{
  key: '/reports',
  icon: <SaveOutlined />,
  label: 'Saved Reports',
},
// Also remove SaveOutlined from the import at the top
```

### Skeleton for Chart Card (minimal approach)

```tsx
import { Skeleton, Card } from 'antd';

// In page component:
{isLoading ? (
  <Card>
    <Skeleton active paragraph={{ rows: 6 }} style={{ padding: '12px' }} />
  </Card>
) : (
  <TimeSeriesChart
    data={trendData}
    title="Daily Transaction Volume"
    height={300}
  />
)}
```

### KPICard with `loading` prop (already works — no changes needed)

```tsx
// Already in authorization/page.tsx — use this pattern across all pages:
<KPICard
  title="Total Transactions"
  value={kpiData?.totalTransactions ?? 0}
  loading={kpis.isLoading}      // triggers antd Card skeleton internally
  format="number"
/>
```

### Canonical Compact Currency Formatter

```typescript
// Define once, use in formatValue prop on chart components:
const formatCompactCurrency = (value: number): string => {
  const abs = Math.abs(value);
  if (abs >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
  if (abs >= 1_000) return `$${(value / 1_000).toFixed(0)}K`;
  return `$${value.toFixed(0)}`;
};

// Usage:
<TimeSeriesChart
  data={trendData}
  height={300}
  formatValue={formatCompactCurrency}
/>
```

**Note:** Several pages already use ad-hoc inline compact formatters (e.g., settlement page line 228: `formatValue={(v) => `$${(v / 1000000).toFixed(1)}M`}`). These inline formatters work but produce slightly inconsistent output (no handling for values under $1M, no sign handling for negative adjustments). The canonical formatter handles all edge cases.

### Converting `Statistic` + `Card` to `KPICard`

```tsx
// BEFORE (chargeback/page.tsx pattern):
<Card>
  <Statistic
    title="Total Dispute Amount"
    value={kpiData?.totalDisputeAmount ?? 0}
    precision={0}
    prefix={<DollarOutlined style={{ color: domainColors.chargeback.primary }} />}
    formatter={(value) => formatCurrency(value as number)}
    styles={{ content: { color: domainColors.chargeback.primary } }}
  />
</Card>

// AFTER:
import { KPICard } from '@/components/ui';

<KPICard
  title="Total Dispute Amount"
  value={kpiData?.totalDisputeAmount ?? 0}
  format="currency"
  loading={kpis.isLoading}
  color={domainColors.chargeback.primary}
/>
```

---

## Current State Audit by Page

Findings from direct codebase inspection (confidence: HIGH):

### DashboardLayout.tsx
| Issue | Location | Fix |
|-------|----------|-----|
| `defaultOpenKeys` bug | Line 167 | Change to `openKeys` prop |
| "Saved Reports" stub menu item | Lines 98-101 | Remove entry + remove `SaveOutlined` import |

### authorization/page.tsx (REFERENCE — 315 lines)
| Issue | Location | Fix |
|-------|----------|-----|
| `<Spin spinning={isLoading}>` | Line 190 | Replace with per-chart Skeleton |
| `<Spin spinning={details.isLoading}>` | Line 302 | Keep — details tab is full-replace loading |
| formatValue on TimeSeriesChart | Line 246 | Uses `Intl.NumberFormat` — keep, already correct for count |

### settlement/page.tsx (258 lines)
| Issue | Location | Fix |
|-------|----------|-----|
| `<Spin spinning={isLoading}>` | Line 146 | Replace with per-chart Skeleton |
| Uses `Statistic` in `Card` for KPIs | Lines 148-214 | Convert to `KPICard` |
| `formatValue={(v) => \`$${(v / 1000000).toFixed(1)}M\`}` | Lines 228, 239 | Replace with canonical formatter |

### funding/page.tsx (237 lines)
| Issue | Location | Fix |
|-------|----------|-----|
| `<Spin spinning={isLoading}>` | Line 131 | Replace with per-chart Skeleton |
| Uses `Statistic` in `Card` for KPIs | Lines 133-204 | Convert to `KPICard` |
| `formatValue={(v) => \`$${(v / 1000000).toFixed(1)}M\`}` | Line 217 | Replace with canonical formatter |

### chargeback/page.tsx (254 lines)
| Issue | Location | Fix |
|-------|----------|-----|
| `<Spin spinning={isLoading}>` | Line 148 | Replace with per-chart Skeleton |
| Uses `Statistic` in `Card` for ALL KPIs | Lines 150-222 | Convert to `KPICard` |
| `formatValue={(v) => \`$${(v / 1000).toFixed(0)}K\`}` | Line 234 | Replace with canonical formatter |

### retrieval/page.tsx (241 lines)
| Issue | Location | Fix |
|-------|----------|-----|
| `<Spin spinning={isLoading}>` | Line 139 | Replace with per-chart Skeleton |
| Uses `Statistic` in `Card` for ALL KPIs | Lines 141-224 | Convert to `KPICard` |
| No chart content in overview | — | Acceptable — retrieval domain has only KPI + details |

### adjustment/page.tsx (184 lines — MOST INCOMPLETE)
| Issue | Location | Fix |
|-------|----------|-----|
| `<Spin spinning={isLoading}>` | Line 110 | Replace with per-Skeleton |
| Uses `Statistic` in `Card` for ALL KPIs | Lines 112-169 | Convert to `KPICard` |
| No chart content in overview | — | Verify API has breakdown endpoint first |
| `xl={4}` column sizing | Lines 112, 122, etc. | Review — may need to match authorization's `lg={6}` pattern |

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `Spin` overlay on entire content section | Per-card `Skeleton` with active animation | Prevents blank page flash; preserves layout during load |
| `defaultOpenKeys` (uncontrolled) | `openKeys` (controlled, driven by `pathname`) | Submenu stays open on direct navigation and client-side navigation |
| Ad-hoc inline formatter strings | Named formatter functions | Consistent output across all chart types |
| Ant Design `Statistic` + raw `Card` | `KPICard` component | Unified trend indicators, loading state, and description tooltips |

**Deprecated/outdated in this codebase:**
- `<Spin spinning={bool}>` wrapping content sections — replace with `Skeleton` for content that renders on first load
- `defaultOpenKeys` for navigation-reactive menus — use `openKeys` instead

---

## Open Questions

1. **Adjustment page chart content**
   - What we know: The Adjustment page currently only has a KPIs API endpoint (`useAnalyticsData('adjustment', 'kpis', ...)`). The overview section has no charts.
   - What's unclear: Does an `adjustment/timeseries` or `adjustment/by-type` API endpoint exist? Without it, no chart can be added.
   - Recommendation: Check the API route file at `apps/frontend/src/app/api/analytics/adjustment/` before planning chart additions. If no breakdown endpoint exists, keep the overview as KPIs-only but converted to `KPICard`.

2. **Separate axis vs. tooltip formatters in chart components**
   - What we know: All 4 chart components (`BarChart`, `TimeSeriesChart`, `PieChart`, `GaugeChart`) use a single `formatValue` prop for both axis labels and tooltips. The CONTEXT.md spec wants compact values on axes and full values in tooltips.
   - What's unclear: Is the two-formatter behavior explicitly required, or is compact-for-both acceptable?
   - Recommendation: For this phase, use a single compact formatter (e.g., `$1.2M`) for both axis and tooltip. This satisfies readability requirements. If full precision in tooltips is required, add a `formatTooltipValue` prop to `BarChart.tsx` and `TimeSeriesChart.tsx` — this is a small, targeted change.

3. **`reasonCode` filter on Retrieval page is UI-only**
   - What we know: The Retrieval page has a `reasonCode` state variable and a Select filter for it (`setReasonCode`), but `reasonCode` is never passed into `useAnalyticsData` for the details query (only `status` is passed).
   - What's unclear: Is the reasonCode filter supposed to apply to the details query?
   - Recommendation: Either remove the reasonCode filter Select from the Retrieval page filter bar, or add `reasonCode: reasonCode || undefined` to the details query params. Audit the API endpoint to confirm it accepts a reasonCode param.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection — `apps/frontend/src/components/layout/DashboardLayout.tsx`, all 6 domain page files, all 4 chart component files, `KPICard.tsx`
- `apps/frontend/package.json` — confirmed library versions: antd 6.3.0, echarts 6.0.0, echarts-for-react 3.0.6, Next.js 16.1.6, React 19.2.3, TanStack Query 5.90.21, Tailwind CSS 4

### Secondary (MEDIUM confidence)
- Ant Design 6 `Skeleton` component API — `Skeleton`, `Skeleton.Node`, `Skeleton.Input`, `Card loading` prop behavior are stable and consistent across antd 5/6
- Ant Design `Menu` `openKeys` vs `defaultOpenKeys` distinction — standard React controlled vs uncontrolled pattern; documented in antd Menu API
- ECharts `axisLabel.formatter` function signature — used directly in existing codebase code; behavior is verified by existing implementation in `BarChart.tsx` line 89-90

### Tertiary (LOW confidence)
- None — all findings based on direct codebase inspection or well-established library patterns

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — confirmed by direct package.json and source file inspection
- Architecture: HIGH — all patterns derived from existing working code in the codebase, not from documentation assumptions
- Pitfalls: HIGH — pitfalls identified from specific line numbers and actual code patterns in the codebase

**Research date:** 2026-02-28
**Valid until:** 2026-03-30 (stable codebase, no fast-moving dependencies affecting this work)
