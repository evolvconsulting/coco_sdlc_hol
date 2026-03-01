---
phase: 02-ux-ui-polish
plan: "02"
subsystem: frontend-analytics
tags: [ux, kpicard, skeleton, loading, formatters, chargeback, retrieval, adjustment]
dependency_graph:
  requires:
    - "02-01"  # formatters.ts created in 02-01
  provides:
    - "chargeback page with KPICard + Skeleton loading"
    - "retrieval page with KPICard"
    - "adjustment page with KPICard"
  affects:
    - "apps/frontend/src/app/analytics/chargeback/page.tsx"
    - "apps/frontend/src/app/analytics/retrieval/page.tsx"
    - "apps/frontend/src/app/analytics/adjustment/page.tsx"
tech_stack:
  patterns:
    - "KPICard replaces Card+Statistic for all domain KPI metrics"
    - "Skeleton with matched height replaces Spin for chart loading states"
    - "DataGrid loading prop replaces Spin wrapper on details tab"
    - "formatCompactCurrency from @/lib/formatters applied to BarChart formatValue"
key_files:
  modified:
    - apps/frontend/src/app/analytics/chargeback/page.tsx
    - apps/frontend/src/app/analytics/retrieval/page.tsx
    - apps/frontend/src/app/analytics/adjustment/page.tsx
decisions:
  - "Retrieval reasonCode filter Select removed (API route does not accept reasonCode param — would be orphaned)"
  - "Adjustment stays KPIs-only — no chart components added (no timeseries/breakdown endpoint exists)"
  - "Adjustment column sizing updated from lg=8/xl=4 to lg=6 to match authorization reference layout"
  - "Details tab Spin replaced with DataGrid loading prop (DataGrid has native loading support)"
metrics:
  duration: "~15 min"
  completed: "2026-03-01"
  tasks_completed: 3
  files_modified: 3
---

# Phase 2 Plan 2: Domain Page KPICard Conversion Summary

**One-liner:** Converted chargeback, retrieval, and adjustment pages from Card+Statistic to KPICard with Skeleton chart loading and canonical formatters, achieving visual parity with the authorization reference.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Chargeback page — KPICard, Skeleton, formatCompactCurrency | 245f914 |
| 2 | Retrieval page — KPICard, remove orphaned reasonCode filter | 4582852 |
| 3 | Adjustment page — KPICard, column sizing fix, KPIs-only | 3718fe3 |

## KPI Cards Converted

### Chargeback Page (6 metrics)
- Total Dispute Amount (format="currency", trendInverted=true, chargeback primary color)
- Chargeback Count (format="number", trendInverted=true, chargeback primary color)
- Transaction Amount (format="currency")
- Win Rate (format="percent", green color)
- Open Disputes (format="number", description="Requires Action")
- Won / Lost (format="number", suffix showing lost count)

### Retrieval Page (6 metrics)
- Total Retrievals (format="number", retrieval primary color)
- Total Amount (format="currency", retrieval primary color)
- Fulfillment Rate (format="percent", green color)
- Open (format="number", description="Requires Action")
- Fulfilled (format="number", green color)
- Expired (format="number", red color, trendInverted=true)

### Adjustment Page (4 metrics)
- Total Adjustments (format="number", adjustment primary color)
- Net Adjustment (format="currency", dynamic color based on positive/negative value)
- Credit Adjustments (format="currency", green color, description shows credit count)
- Debit Adjustments (format="currency", red color, description shows debit count)

## Retrieval ReasonCode Filter Decision

**Decision: Removed.** The retrieval/details API route (`apps/frontend/src/app/api/analytics/retrieval/details/route.ts`) only accepts `status` as a filter parameter — there is no `reasonCode` handling in the WHERE clause. The `reasonCode` state variable and filter Select were both removed to prevent an orphaned UI control that would appear to filter but have no effect.

## Chart Loading Skeleton Heights

- **Chargeback** — BarChart (Chargebacks by Reason Code): Skeleton height=300 matching `height={300}` prop on BarChart
- **Retrieval** — No chart content in overview (KPIs only); no Skeleton needed
- **Adjustment** — No chart content (no API endpoint); no Skeleton needed

## Adjustment Page Notes

The adjustment page has no timeseries or breakdown API endpoint. The overview section correctly stays KPIs-only. The Spin wrapper was simply removed since KPICard handles per-card loading state via its `loading` prop. No chart placeholders or empty state were added.

Column sizing was updated from `lg={8} xl={4}` to `lg={6}` to match the authorization reference page, which uses `lg={6}` for its 4-card KPI row.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Feature] DataGrid loading prop used instead of Spin wrapper**
- **Found during:** Tasks 1, 2, 3
- **Issue:** DataGrid has a native `loading` prop. Using Spin as a wrapper is redundant and inconsistent.
- **Fix:** Replaced `<Spin spinning={details.isLoading}><DataGrid ...></Spin>` with `<DataGrid loading={details.isLoading} .../>` on all three pages
- **Files modified:** All three domain pages

## Self-Check

### Files Exist
- apps/frontend/src/app/analytics/chargeback/page.tsx — FOUND
- apps/frontend/src/app/analytics/retrieval/page.tsx — FOUND
- apps/frontend/src/app/analytics/adjustment/page.tsx — FOUND

### Commits Exist
- 245f914 (chargeback) — FOUND
- 4582852 (retrieval) — FOUND
- 3718fe3 (adjustment) — FOUND

## Self-Check: PASSED
