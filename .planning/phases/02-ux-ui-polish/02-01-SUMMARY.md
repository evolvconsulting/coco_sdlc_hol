---
phase: 02-ux-ui-polish
plan: 01
subsystem: ui
tags: [antd, react, next.js, formatters, sidebar, navigation]

# Dependency graph
requires: []
provides:
  - Controlled openKeys sidebar with Analytics submenu that stays expanded on direct URL navigation
  - Canonical formatters.ts with 5 exported functions for consistent chart and KPI value presentation
affects:
  - 02-02
  - 02-03

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Controlled Menu component: openKeys derived from usePathname() for router-aware submenu state"
    - "Formatter module: single import source for all chart axis, tooltip, and KPI number formatting"

key-files:
  created:
    - apps/frontend/src/lib/formatters.ts
  modified:
    - apps/frontend/src/components/layout/DashboardLayout.tsx

key-decisions:
  - "defaultOpenKeys changed to controlled openKeys prop — uncontrolled only applies at mount, controlled responds to pathname changes"
  - "formatCompactCurrency uses explicit threshold logic (not Intl compact) for predictable, testable output"
  - "SaveOutlined import removed alongside Saved Reports menu item — no orphaned imports left"

patterns-established:
  - "Formatter pattern: all analytics pages import from apps/frontend/src/lib/formatters.ts rather than defining ad-hoc inline formatters"
  - "Sidebar pattern: openKeys={openKeys} controlled by pathname.startsWith('/analytics') for persistent submenu state"

requirements-completed: [UX-01, UX-02]

# Metrics
duration: 7min
completed: 2026-02-28
---

# Phase 02 Plan 01: Sidebar Fix and Formatter Foundation Summary

**Controlled sidebar openKeys derived from usePathname and five-function formatter module establishing canonical number formatting for all analytics domain pages**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-03-01T00:11:46Z
- **Completed:** 2026-03-01T00:18:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Fixed sidebar Analytics submenu collapse bug by switching from uncontrolled `defaultOpenKeys` to controlled `openKeys` prop
- Removed "Saved Reports" stub menu item and its unused `SaveOutlined` import
- Created `apps/frontend/src/lib/formatters.ts` with 5 canonical formatter exports for consistent chart axis, tooltip, and KPI value display across all domain pages

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix sidebar submenu collapse bug in DashboardLayout.tsx** - `e99a4d0` (fix)
2. **Task 2: Create canonical formatter utility module** - `26c5bb0` (feat)

## Files Created/Modified

- `apps/frontend/src/components/layout/DashboardLayout.tsx` - Changed `defaultOpenKeys` to `openKeys`, removed Saved Reports item and SaveOutlined import
- `apps/frontend/src/lib/formatters.ts` - New module with formatCompactCurrency, formatFullCurrency, formatCompactCount, formatFullCount, formatPercent

## Decisions Made

- `defaultOpenKeys` changed to controlled `openKeys` prop — uncontrolled prop only applies at initial mount and does not respond to client-side navigation; controlled prop tracks pathname changes
- `formatCompactCurrency` uses explicit threshold logic (`>= 1_000_000`, `>= 1_000`) rather than `Intl.NumberFormat compact` — predictable output for testing (`formatCompactCurrency(1234567) === '$1.2M'`)
- `SaveOutlined` import removed alongside the Saved Reports menu item — it was the only usage, so leaving it would be an orphaned import

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 02-02 and 02-03 can now import from `apps/frontend/src/lib/formatters.ts` for chart formatValue props
- Sidebar will correctly persist Analytics submenu open state when navigating between `/analytics/*` routes
- No blockers for subsequent Phase 2 plans

## Self-Check: PASSED

- FOUND: apps/frontend/src/components/layout/DashboardLayout.tsx
- FOUND: apps/frontend/src/lib/formatters.ts
- FOUND: .planning/phases/02-ux-ui-polish/02-01-SUMMARY.md
- FOUND: commit e99a4d0 (fix sidebar)
- FOUND: commit 26c5bb0 (feat formatters)

---
*Phase: 02-ux-ui-polish*
*Completed: 2026-02-28*
