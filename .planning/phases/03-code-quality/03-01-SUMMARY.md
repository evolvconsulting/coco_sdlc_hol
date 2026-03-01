---
phase: 03-code-quality
plan: 01
subsystem: api
tags: [snowflake, typescript, config, security, parameterized-queries, connection-lifecycle]

# Dependency graph
requires:
  - phase: 02-ux-ui-polish
    provides: Working frontend app with all 6 analytics domains functional

provides:
  - Centralized DB/schema/table config in config.ts (14 constants across 6 domains)
  - Per-request Snowflake connection lifecycle (no global singleton)
  - Parameterized query support via binds parameter in executeQuery()
  - Removed bypassable sanitizeSQL(), executeQueryWithRLS(), closeConnection()

affects:
  - 03-02 (route parameterization — depends on executeQuery binds signature)
  - All analytics API routes (will import FULL_TABLE_* from config.ts)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Import FULL_TABLE_* constants from @/lib/config — no hardcoded DB.SCHEMA.TABLE in SQL"
    - "Per-request connection lifecycle — createConnection() called inside executeQuery(), destroy() fired in complete callback"
    - "Optional binds array on executeQuery(sql, binds?) for parameterized queries"

key-files:
  created:
    - apps/frontend/src/lib/config.ts
  modified:
    - apps/frontend/src/lib/snowflake.ts

key-decisions:
  - "sanitizeSQL() removed entirely — parameterized queries eliminate need; regex approach is bypassable false security"
  - "Per-request connections over pooling — simpler and safer; pooling deferred to future performance phase"
  - "SNOWFLAKE_DATABASE and SNOWFLAKE_SCHEMA read from process.env in config.ts — FULL_TABLE_* computed at module load time"
  - "connection.destroy() called fire-and-forget inside complete callback — no awaiting or chaining"
  - "TABLE_* (bare name) and FULL_TABLE_* (fully qualified) both exported — routes use FULL_TABLE_* in SQL"

patterns-established:
  - "config.ts as single source of truth: all DB/schema/table references import from @/lib/config"
  - "executeQuery signature: (sql: string, binds?: (string | number | null)[]) — binds passed as array to connection.execute()"

requirements-completed: [CODE-01, CODE-04, CODE-05]

# Metrics
duration: 2min
completed: 2026-03-01
---

# Phase 3 Plan 01: Config + Snowflake Foundation Summary

**Centralized config.ts with 14 DB/schema/table constants and per-request Snowflake connections with parameterized query support via optional binds array**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-01T13:56:01Z
- **Completed:** 2026-03-01T13:57:39Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 refactored)

## Accomplishments

- Created `apps/frontend/src/lib/config.ts` as single source of truth for all Snowflake DB/schema/table references (14 exports: 2 env-driven, 6 bare table names, 6 fully-qualified references)
- Refactored `apps/frontend/src/lib/snowflake.ts` to eliminate the global `connectionPool` singleton — each API request now creates a fresh connection and destroys it after query completion
- Added optional `binds` parameter to `executeQuery()` enabling parameterized queries — Plan 02 route files can now pass user inputs as bound values instead of string interpolation
- Removed `sanitizeSQL()`, `executeQueryWithRLS()`, and `closeConnection()` — no longer needed with per-request connections and parameterized queries

## Task Commits

Each task was committed atomically:

1. **Task 1: Create apps/frontend/src/lib/config.ts** - `287a9c7` (feat)
2. **Task 2: Refactor apps/frontend/src/lib/snowflake.ts** - `2b869b3` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `apps/frontend/src/lib/config.ts` - New file: 14 exported constants (SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA, TABLE_*, FULL_TABLE_*) for all 6 payment analytics domains
- `apps/frontend/src/lib/snowflake.ts` - Refactored: removed connectionPool global, renamed getConnection() to createConnection() (private), added binds parameter to executeQuery(), removed sanitizeSQL/executeQueryWithRLS/closeConnection, updated getTableMetadata() to use config.ts constants

## Decisions Made

- sanitizeSQL() removed entirely — bypassable regex approach documented in CONTEXT.md; parameterized binds provide real protection
- Per-request connection lifecycle over pooling — simpler for this phase, pooling is a future performance optimization
- FULL_TABLE_* computed at module load using template literals from SNOWFLAKE_DATABASE/SNOWFLAKE_SCHEMA — trusted config values, not user input, so interpolation in SQL is correct
- connection.destroy() fired fire-and-forget inside the complete callback — does not block resolve/reject path

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

A pre-existing TypeScript error in `src/app/analytics/authorization/page.tsx` (GaugeChartProps missing `formatValue` property) was present before this plan's changes and is unrelated to config.ts or snowflake.ts. TypeScript checks for config.ts and snowflake.ts produced zero errors.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `executeQuery(sql, binds?)` signature is in place — Plan 02 (route parameterization) can now update all 19 route files to pass user inputs as binds arrays
- `FULL_TABLE_*` constants are ready — all routes can replace hardcoded `COCO_SDLC_HOL.MARTS.AUTHORIZATIONS` etc. with `FULL_TABLE_AUTHORIZATIONS` imports
- The pre-existing GaugeChart TypeScript error in authorization page.tsx should be addressed before Phase 3 is considered fully clean — logged as out-of-scope for this plan

---
*Phase: 03-code-quality*
*Completed: 2026-03-01*
