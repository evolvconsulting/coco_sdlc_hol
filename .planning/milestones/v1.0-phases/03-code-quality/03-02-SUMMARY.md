---
phase: 03-code-quality
plan: 02
subsystem: api
tags: [snowflake, typescript, parameterized-queries, security, sql-injection, config]

# Dependency graph
requires:
  - phase: 03-01
    provides: FULL_TABLE_* constants in config.ts and executeQuery(sql, binds?) signature in snowflake.ts

provides:
  - All 19 analytics API routes hardened — FULL_TABLE_* from config, parameterized binds, no error detail exposure

affects:
  - 03-03 (remaining code quality tasks — routes are now clean)
  - Any future analytics routes (follow same three-change pattern)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "All analytics routes import FULL_TABLE_* from @/lib/config — zero hardcoded DB.SCHEMA.TABLE strings"
    - "User-supplied query params (dates, filters) passed as positional binds array to executeQuery"
    - "LIMIT/OFFSET remain integer literals after parseInt() — Snowflake does not support parameterized LIMIT/OFFSET"
    - "catch blocks log error server-side via console.error but return no details field to client"

key-files:
  created: []
  modified:
    - apps/frontend/src/app/api/analytics/authorization/kpis/route.ts
    - apps/frontend/src/app/api/analytics/authorization/timeseries/route.ts
    - apps/frontend/src/app/api/analytics/authorization/by-brand/route.ts
    - apps/frontend/src/app/api/analytics/authorization/declines/route.ts
    - apps/frontend/src/app/api/analytics/authorization/details/route.ts
    - apps/frontend/src/app/api/analytics/settlement/kpis/route.ts
    - apps/frontend/src/app/api/analytics/settlement/timeseries/route.ts
    - apps/frontend/src/app/api/analytics/settlement/by-merchant/route.ts
    - apps/frontend/src/app/api/analytics/settlement/details/route.ts
    - apps/frontend/src/app/api/analytics/funding/kpis/route.ts
    - apps/frontend/src/app/api/analytics/funding/timeseries/route.ts
    - apps/frontend/src/app/api/analytics/funding/details/route.ts
    - apps/frontend/src/app/api/analytics/chargeback/kpis/route.ts
    - apps/frontend/src/app/api/analytics/chargeback/by-reason/route.ts
    - apps/frontend/src/app/api/analytics/chargeback/details/route.ts
    - apps/frontend/src/app/api/analytics/retrieval/kpis/route.ts
    - apps/frontend/src/app/api/analytics/retrieval/details/route.ts
    - apps/frontend/src/app/api/analytics/adjustment/kpis/route.ts
    - apps/frontend/src/app/api/analytics/adjustment/details/route.ts

key-decisions:
  - "adjustment/details type filter ('credit'/'debit') maps to numeric comparison (>= 0 / < 0) — no user string interpolated into SQL so no bind needed"
  - "funding/details status param passed directly as bind — value is user-supplied string (COMPLETED/PENDING/HELD), not a fixed enum mapping"
  - "Pre-existing GaugeChartProps TypeScript error in authorization/page.tsx out of scope — present before this plan and unrelated to route files"

patterns-established:
  - "Three-change pattern for analytics routes: (1) FULL_TABLE_* import, (2) binds array + ? placeholders, (3) remove details: String(error)"
  - "binds array always starts with [startDate, endDate] — optional filters pushed conditionally in same block as SQL fragment"

requirements-completed: [CODE-01, CODE-02, CODE-03, CODE-04]

# Metrics
duration: 8min
completed: 2026-03-01
---

# Phase 3 Plan 02: Route Hardening Summary

**19 analytics API routes hardened in one pass — FULL_TABLE_* config imports replace all hardcoded COCO_SDLC_HOL.MARTS.* strings, user-supplied params passed as parameterized binds, and error details removed from all catch block responses**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-01T13:59:42Z
- **Completed:** 2026-03-01T14:07:00Z
- **Tasks:** 2
- **Files modified:** 19

## Accomplishments

- Replaced every `COCO_SDLC_HOL.MARTS.*` hardcoded table reference across all 19 routes with `FULL_TABLE_*` constants imported from `@/lib/config` — zero hardcoded database names remain
- Parameterized all user-supplied query parameters (startDate, endDate, cardBrand, status, merchant-related filters) as positional binds arrays passed to `executeQuery()` — SQL injection path eliminated
- Removed `details: String(error)` from all 19 catch blocks — Snowflake error messages (which can contain connection strings, credentials, or schema details) are no longer exposed in API responses

## Task Commits

Each task was committed atomically:

1. **Task 1: Authorization routes (5 files)** - `d2882c0` (feat)
2. **Task 2: Remaining 14 analytics routes** - `73da47e` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `apps/frontend/src/app/api/analytics/authorization/kpis/route.ts` - FULL_TABLE_AUTHORIZATIONS, binds [startDate, endDate, cardBrand?], no details
- `apps/frontend/src/app/api/analytics/authorization/timeseries/route.ts` - FULL_TABLE_AUTHORIZATIONS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/authorization/by-brand/route.ts` - FULL_TABLE_AUTHORIZATIONS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/authorization/declines/route.ts` - FULL_TABLE_AUTHORIZATIONS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/authorization/details/route.ts` - FULL_TABLE_AUTHORIZATIONS, binds [startDate, endDate, cardBrand?, status?], LIMIT/OFFSET literal, no details
- `apps/frontend/src/app/api/analytics/settlement/kpis/route.ts` - FULL_TABLE_SETTLEMENTS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/settlement/timeseries/route.ts` - FULL_TABLE_SETTLEMENTS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/settlement/by-merchant/route.ts` - FULL_TABLE_SETTLEMENTS, binds [startDate, endDate], LIMIT literal, no details
- `apps/frontend/src/app/api/analytics/settlement/details/route.ts` - FULL_TABLE_SETTLEMENTS, binds [startDate, endDate], LIMIT/OFFSET literal, no details
- `apps/frontend/src/app/api/analytics/funding/kpis/route.ts` - FULL_TABLE_DEPOSITS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/funding/timeseries/route.ts` - FULL_TABLE_DEPOSITS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/funding/details/route.ts` - FULL_TABLE_DEPOSITS, binds [startDate, endDate, status?], LIMIT/OFFSET literal, no details
- `apps/frontend/src/app/api/analytics/chargeback/kpis/route.ts` - FULL_TABLE_CHARGEBACKS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/chargeback/by-reason/route.ts` - FULL_TABLE_CHARGEBACKS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/chargeback/details/route.ts` - FULL_TABLE_CHARGEBACKS, binds [startDate, endDate, status?], LIMIT/OFFSET literal, no details
- `apps/frontend/src/app/api/analytics/retrieval/kpis/route.ts` - FULL_TABLE_RETRIEVALS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/retrieval/details/route.ts` - FULL_TABLE_RETRIEVALS, binds [startDate, endDate, status?], LIMIT/OFFSET literal, no details
- `apps/frontend/src/app/api/analytics/adjustment/kpis/route.ts` - FULL_TABLE_ADJUSTMENTS, binds [startDate, endDate], no details
- `apps/frontend/src/app/api/analytics/adjustment/details/route.ts` - FULL_TABLE_ADJUSTMENTS, binds [startDate, endDate], type filter uses numeric comparison (no bind), LIMIT/OFFSET literal, no details

## Decisions Made

- adjustment/details `type` param ('credit'/'debit') maps to `adjustment_amount >= 0` or `adjustment_amount < 0` — a numeric comparison with no user-supplied value in SQL, so no bind is needed. This is safe by structure.
- funding/details `status` param is passed directly as a bind (user string sent to Snowflake as a bound value, not interpolated) — parameterization protects against injection regardless of the enum values
- Pre-existing GaugeChartProps TypeScript error in `authorization/page.tsx` is out of scope for this plan (noted in 03-01 SUMMARY, exists before any changes here)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The pre-existing TypeScript error in `src/app/analytics/authorization/page.tsx` (GaugeChartProps missing `formatValue` property) surfaced again in the TypeScript compile check. This error exists before this plan's changes and is in a page component, not a route file. All 19 route files compile cleanly. Logged as out-of-scope.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All 19 analytics routes are now hardened — parameterized queries, config-driven table names, and sanitized error responses
- CODE-01 through CODE-04 requirements are satisfied
- Plan 03-03 can proceed with any remaining code quality tasks

## Self-Check: PASSED

- Files exist: all 19 route files confirmed present
- Commits exist: d2882c0 and 73da47e confirmed in git log
- Zero hardcoded COCO_SDLC_HOL.MARTS.* references in analytics routes
- Zero `details: String(error)` in analytics routes
- 19/19 analytics routes import from @/lib/config

---
*Phase: 03-code-quality*
*Completed: 2026-03-01*
