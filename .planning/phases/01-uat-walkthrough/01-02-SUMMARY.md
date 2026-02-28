---
phase: 01-uat-walkthrough
plan: 02
subsystem: api
tags: [snowflake, next.js, analytics, uat, sql, turbopack]

# Dependency graph
requires:
  - phase: 01-uat-walkthrough/01-01
    provides: Confirmed MARTS date range (2026-01-13 to 2026-02-22) and working Snowflake connectivity
provides:
  - All 19 API endpoints smoke-tested and verified with real MARTS data
  - All 7 domain pages (Home + 6 analytics) verified in browser with real data
  - UAT-BUGS.md with complete test results
  - 6 SQL column name fixes in /details routes (authorization, settlement, funding, chargeback, retrieval, adjustment)
  - Retrieval date filter column fixed (original_sale_date → retrieval_received_date)
  - Turbopack monorepo root config for lightningcss resolution
affects:
  - 01-03 (bug fix plan — will reference bugs from this UAT)
  - Phase 2 and beyond — all fix patterns established here apply forward

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "MARTS tables use *_key naming convention (not *_id) for primary key columns"
    - "Retrieval table primary date column is retrieval_received_date (not original_sale_date)"
    - "Turbopack requires explicit root config in monorepo to resolve lightningcss"

key-files:
  created:
    - ".planning/phases/01-uat-walkthrough/UAT-BUGS.md"
    - ".planning/phases/01-uat-walkthrough/01-02-SUMMARY.md"
  modified:
    - "apps/frontend/src/app/api/analytics/authorization/details/route.ts"
    - "apps/frontend/src/app/api/analytics/settlement/details/route.ts"
    - "apps/frontend/src/app/api/analytics/funding/details/route.ts"
    - "apps/frontend/src/app/api/analytics/chargeback/details/route.ts"
    - "apps/frontend/src/app/api/analytics/retrieval/details/route.ts"
    - "apps/frontend/src/app/api/analytics/retrieval/kpis/route.ts"
    - "apps/frontend/src/app/api/analytics/adjustment/details/route.ts"
    - "apps/frontend/next.config.ts"

key-decisions:
  - "All 7 UAT domains passed browser verification with date range 2026-01-13 to 2026-02-22"
  - "MARTS tables use *_key not *_id for primary key columns — applies to all 6 domain details routes"
  - "Retrieval primary date column is retrieval_received_date (original_sale_date is ~3 months earlier)"
  - "Turbopack root must point to monorepo root to resolve workspace dependencies like lightningcss"

patterns-established:
  - "Column name pattern: MARTS primary keys are *_key (authorization_key, settlement_key, etc.)"
  - "Date filter pattern: use the domain's primary operational date column, not derived/reference dates"
  - "Turbopack pattern: next.config.ts needs turbopack.root = path.resolve(__dirname, '../..') in monorepo"

requirements-completed: [UAT-01, UAT-02, UAT-03, UAT-04, UAT-05, UAT-06, UAT-07]

# Metrics
duration: ~120min
completed: 2026-02-28
---

# Phase 1 Plan 02: UAT Domain Walkthrough Summary

**All 19 API endpoints verified with real Snowflake MARTS data and all 7 domain pages browser-confirmed, with 8 SQL/config bugs auto-fixed across details routes and turbopack configuration**

## Performance

- **Duration:** ~120 min (includes auto-fix iterations and human browser verification)
- **Started:** 2026-02-28
- **Completed:** 2026-02-28
- **Tasks:** 2 (Task 1: API smoke test, Task 2: browser walkthrough checkpoint)
- **Files modified:** 9

## Accomplishments

- Smoke-tested all 19 endpoints across 6 domains with confirmed MARTS date range (2026-01-13 to 2026-02-22) — 19/19 PASS after auto-fixes
- Identified and fixed 8 bugs (6 SQL column name mismatches, 1 wrong date filter column, 1 turbopack config issue)
- Human-verified all 7 pages in browser — Home Dashboard, Authorization, Settlement, Funding, Chargeback, Retrieval, Adjustment all show real data

## Task Commits

Each task was committed atomically:

1. **Task 1: API smoke-test all domain endpoints** - `136a5ac` (fix) — 6 details routes SQL column name fixes + UAT-BUGS.md created
2. **Task 1 continuation: Retrieval date filter fix** - `4ffa885` (fix) — retrieval/kpis and retrieval/details date column corrected
3. **Task 1 continuation: Turbopack monorepo config** - `4ff07b1` (fix) — next.config.ts turbopack root added

**Plan metadata:** (this commit — docs: complete 01-02 plan)

## Files Created/Modified

- `apps/frontend/src/app/api/analytics/authorization/details/route.ts` - Fixed: authorization_id → authorization_key, removed nonexistent risk_score column
- `apps/frontend/src/app/api/analytics/settlement/details/route.ts` - Fixed: settlement_id → settlement_key
- `apps/frontend/src/app/api/analytics/funding/details/route.ts` - Fixed: deposit_id → deposit_key
- `apps/frontend/src/app/api/analytics/chargeback/details/route.ts` - Fixed: chargeback_id → chargeback_key
- `apps/frontend/src/app/api/analytics/retrieval/details/route.ts` - Fixed: retrieval_id → retrieval_key, original_sale_date → retrieval_received_date
- `apps/frontend/src/app/api/analytics/retrieval/kpis/route.ts` - Fixed: original_sale_date → retrieval_received_date in WHERE clause
- `apps/frontend/src/app/api/analytics/adjustment/details/route.ts` - Fixed: adjustment_id → adjustment_key, fee_description → adjustment_category
- `apps/frontend/next.config.ts` - Added turbopack.root config for monorepo lightningcss resolution
- `.planning/phases/01-uat-walkthrough/UAT-BUGS.md` - Created with smoke test results and browser walkthrough results

## Decisions Made

- MARTS tables use `*_key` naming convention (not `*_id`) for primary key columns — affects all domain details routes
- Retrieval primary date column is `retrieval_received_date`, not `original_sale_date` (original_sale_date range is ~3 months earlier and falls outside the UAT test window)
- Turbopack in a monorepo requires `turbopack.root` set to the workspace root to properly resolve workspace-level packages like lightningcss

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed SQL column name mismatches in all 6 details routes**
- **Found during:** Task 1 (API smoke-test all domain endpoints)
- **Issue:** All 6 domain `/details` routes referenced `*_id` column names (authorization_id, settlement_id, deposit_id, chargeback_id, retrieval_id, adjustment_id) but MARTS tables use `*_key` naming convention. Additionally, `risk_score` (AUTHORIZATIONS table) and `fee_description` (ADJUSTMENTS table) do not exist.
- **Fix:** Renamed all primary key references to `*_key`, removed nonexistent columns, mapped `fee_description → adjustment_category`
- **Files modified:** authorization/details, settlement/details, funding/details, chargeback/details, retrieval/details, adjustment/details
- **Verification:** All 6 endpoints returned `success: true` with data arrays after fix
- **Committed in:** `136a5ac`

**2. [Rule 1 - Bug] Fixed retrieval date filter from original_sale_date to retrieval_received_date**
- **Found during:** Browser walkthrough (Retrieval page showed 0 records)
- **Issue:** Both retrieval/kpis and retrieval/details were filtering on `original_sale_date` which spans 2025-11-29 to 2026-01-28 — entirely outside the UAT test window of 2026-01-13 to 2026-02-22. `retrieval_received_date` spans 2026-01-13 to 2026-02-22, exactly the test window.
- **Fix:** Changed WHERE clause in both routes to use `retrieval_received_date`
- **Files modified:** apps/frontend/src/app/api/analytics/retrieval/kpis/route.ts, apps/frontend/src/app/api/analytics/retrieval/details/route.ts
- **Verification:** Retrieval endpoints now return 23 records; page shows real data in browser
- **Committed in:** `4ffa885`

**3. [Rule 3 - Blocking] Fixed Turbopack lightningcss module resolution failure**
- **Found during:** Attempting to start dev server for browser verification
- **Issue:** Dev server crashed with lightningcss module resolution error. Root cause: multiple `package-lock.json` files in parent directories (`/apps/frontend/`, `/` root) confused Turbopack's dependency resolution.
- **Fix:** Added `turbopack: { root: path.resolve(__dirname, '../..') }` to `next.config.ts` to point Turbopack at the monorepo root
- **Files modified:** apps/frontend/next.config.ts, apps/frontend/package.json, apps/frontend/package-lock.json
- **Verification:** Dev server starts successfully with `npm run dev`
- **Committed in:** `4ff07b1`

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocking issue)
**Impact on plan:** All auto-fixes necessary for correct API behavior and dev server operation. No scope creep.

## Issues Encountered

- Retrieval page showed 0 data in browser despite passing API smoke test — the smoke test used the confirmed date range but the route's WHERE clause used a different date column that returned data within the test window only by coincidence. Discovered during actual visual verification with date picker set to UAT range.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- UAT requirements UAT-01 through UAT-07 all satisfied: all 7 domain pages show real data
- UAT-BUGS.md documents all 8 bugs found (all auto-fixed) — no outstanding blockers for Plan 03
- Plan 03 (code cleanup/hardening) can proceed: SQL injection, credential exposure, hardcoded table names are known pre-existing issues tracked in STATE.md blockers

---
*Phase: 01-uat-walkthrough*
*Completed: 2026-02-28*
