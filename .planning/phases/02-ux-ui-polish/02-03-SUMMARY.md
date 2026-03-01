---
phase: 02-ux-ui-polish
plan: 03
subsystem: ui
tags: [react, antd, nextjs, skeleton, kpicard, formatters]

# Dependency graph
requires:
  - phase: 02-01
    provides: "formatters.ts canonical formatter functions (formatCompactCurrency, formatCompactCount, formatPercent), KPICard component"
provides:
  - "Authorization page with Skeleton chart loading and canonical formatter imports"
  - "Settlement page with KPICard KPIs, Skeleton chart loading, formatCompactCurrency on charts"
  - "Funding page with KPICard KPIs, Skeleton chart loading, formatCompactCurrency on chart, desktop layout audit complete"
affects: [02-04, 03-ui-hardening]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-chart conditional Skeleton pattern: isLoading ? <Card><Skeleton.../></Card> : <Chart/>"
    - "KPICard with format prop (currency/number/percent) for all domain KPI metrics"
    - "Canonical formatValue props: formatCompactCurrency on currency charts, formatCompactCount on count charts, formatPercent on gauge/rate charts"
    - "DataGrid native loading prop instead of Spin wrapper on details tabs"

key-files:
  created: []
  modified:
    - "apps/frontend/src/app/analytics/authorization/page.tsx"
    - "apps/frontend/src/app/analytics/settlement/page.tsx"
    - "apps/frontend/src/app/analytics/funding/page.tsx"

key-decisions:
  - "Authorization details tab Spin intentionally preserved — tab switch loads fresh data, Spin overlay correct for full replace loading"
  - "formatCompactCurrency excluded from authorization import — no currency-value charts on that page; formatCompactCount and formatPercent used instead"
  - "Settlement cardBrand filter wired to details query only (not overview queries) — correct, overview shows aggregate metrics across all brands"
  - "Funding statusFilter wired to details query only — correct, overview KPIs show all funding records"
  - "KPI Col spans xl={4} for 6-KPI rows confirmed correct at 1440px — 6 cards fill row without overflow"

patterns-established:
  - "All three domain pages now use identical Skeleton loading pattern for overview charts"
  - "KPICard is the standard for all KPI metrics across all domain pages (no more Card+Statistic)"

requirements-completed: [UX-02, UX-03, UX-04, UX-05, UX-06]

# Metrics
duration: 4min
completed: 2026-03-01
---

# Phase 2 Plan 03: Domain Page Polish Summary

**Spin-to-Skeleton migration and KPICard standardization across authorization, settlement, and funding pages using canonical @/lib/formatters throughout**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-01T00:35:45Z
- **Completed:** 2026-03-01T00:39:06Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Authorization overview tab: 4 Skeleton placeholders replace single Spin overlay (GaugeChart, TimeSeriesChart, PieChart, BarChart); formatCompactCount on volume chart, formatPercent on gauge
- Settlement page: 6 Card+Statistic KPIs converted to KPICard; 2 Skeleton placeholders for charts; formatCompactCurrency on TimeSeriesChart and BarChart
- Funding page: 6 Card+Statistic KPIs converted to KPICard; 1 Skeleton placeholder for TimeSeriesChart; formatCompactCurrency applied; desktop layout audit passed

## Task Commits

Each task was committed atomically:

1. **Task 1: Polish authorization page — Spin → Skeleton, formatter import** - `e08e523` (feat)
2. **Task 2: Update settlement page — KPICard conversion, Spin → Skeleton, formatter import** - `eedea7e` (feat)
3. **Task 3: Update funding page — KPICard conversion, Spin → Skeleton, formatter import; desktop layout audit** - `1efd878` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `apps/frontend/src/app/analytics/authorization/page.tsx` - Skeleton loading on 4 overview charts; formatCompactCount on TimeSeriesChart; formatPercent on GaugeChart; details tab Spin preserved
- `apps/frontend/src/app/analytics/settlement/page.tsx` - 6 KPICard conversions; Skeleton on 2 charts; formatCompactCurrency on TimeSeriesChart and BarChart; Tag/Statistic/Spin removed
- `apps/frontend/src/app/analytics/funding/page.tsx` - 6 KPICard conversions; Skeleton on TimeSeriesChart; formatCompactCurrency applied; Statistic/Spin/Tag removed; layout audit complete

## Decisions Made

- **Authorization details tab Spin preserved:** The Spin at the details tab loads a completely fresh DataGrid dataset on tab switch. Since no stale data is shown, a Spin overlay is correct behavior there. This was an explicit plan instruction, confirmed and retained.
- **formatCompactCurrency not imported in authorization:** That page has no currency-value charts (TimeSeriesChart shows transaction counts, GaugeChart shows approval rate). Importing an unused formatter would trigger lint warnings. Only formatCompactCount and formatPercent were imported.
- **Settlement cardBrand filter scope:** The cardBrand Select state is wired to the details query only. The overview KPIs/timeseries/byMerchant queries are not filtered by brand — they show aggregate settlement metrics. This is correct behavior; the brand filter exists to narrow the transaction-level details grid.
- **Funding statusFilter scope:** statusFilter is wired to the details query only. Overview queries show all funding records regardless of status. Correct scoping.

## Date Picker / Filter Audit Findings

**Settlement page:**
- Date range picker updates `dateRange` state → derives `startDate`/`endDate` → passed to `kpis`, `timeseries`, `byMerchant` queries via React Query key. Changing date triggers automatic refetch (React Query cache miss). `isLoading` briefly becomes `true`. Instant-apply preserved.
- `cardBrand` Select → wired to `details` query only. Overview queries use aggregate data regardless of brand. Correct design.

**Funding page:**
- Date range picker updates `dateRange` state → `startDate`/`endDate` → passed to `kpis` and `timeseries` queries. Instant-apply preserved.
- `statusFilter` Select → wired to `details` query only (`status` param). Overview shows all-status aggregates. Correct design.

## Desktop Layout Audit (UX-06)

**Authorization page:** 4 KPI cards use `xs={24} sm={12} lg={6}` — correct for 4-column row at 1440px. Chart rows use `lg={16}/lg={8}` and `lg={12}/lg={12}` — no overflow.

**Settlement page:** 6 KPI cards use `xs={24} sm={12} lg={8} xl={4}` — at 1440px (xl breakpoint), each card gets 4/24 = 16.67% width = 6 cards per row. Correct. Chart row uses `lg={14}/lg={10}` — no overflow.

**Funding page:** 6 KPI cards use `xs={24} sm={12} lg={8} xl={4}` — same as settlement, correct. Single chart row uses `xs={24}` (full width) — no overflow.

No Col sizing issues found across any of the three pages. No fixes needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Removed unused Tag import from settlement page**
- **Found during:** Task 2 (after removing Statistic with Tag children)
- **Issue:** Tag was imported but no longer used after KPICard conversion (refund count moved to KPICard description prop). Unused import would cause lint warnings.
- **Fix:** Removed Tag from antd import list.
- **Files modified:** apps/frontend/src/app/analytics/settlement/page.tsx
- **Committed in:** eedea7e (Task 2 commit)

**2. [Rule 2 - Missing Critical] Removed unused formatCompactCurrency from authorization import**
- **Found during:** Task 1 (after applying formatters to all charts)
- **Issue:** Plan instructed importing formatCompactCurrency but authorization page has no currency-value charts. Unused import causes lint warnings.
- **Fix:** Removed formatCompactCurrency from import, kept formatCompactCount and formatPercent.
- **Files modified:** apps/frontend/src/app/analytics/authorization/page.tsx
- **Committed in:** e08e523 (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 2 — removed unused imports to prevent lint errors)
**Impact on plan:** Minimal. Both fixes improve code hygiene. All must_haves and success criteria fully met.

## Issues Encountered

None - all three pages updated without blockers.

## Next Phase Readiness
- All three reference domain pages (authorization, settlement, funding) are now at the polished reference state
- Skeleton loading pattern established and consistent across all overview tabs
- KPICard is now the uniform KPI component across all 5 domain pages (chargeback/retrieval/adjustment from 02-02, authorization/settlement/funding from this plan)
- Ready for 02-04 visual checkpoint verification

---
## Self-Check: PASSED

- FOUND: apps/frontend/src/app/analytics/authorization/page.tsx
- FOUND: apps/frontend/src/app/analytics/settlement/page.tsx
- FOUND: apps/frontend/src/app/analytics/funding/page.tsx
- FOUND: .planning/phases/02-ux-ui-polish/02-03-SUMMARY.md
- FOUND commit e08e523 (authorization polish)
- FOUND commit eedea7e (settlement update)
- FOUND commit 1efd878 (funding update)

---
*Phase: 02-ux-ui-polish*
*Completed: 2026-03-01*
