---
phase: 03-code-quality
plan: 03
subsystem: api-routes
tags: [error-sanitization, config-migration, security, cortex-chat, query-route, metadata-route]
dependency_graph:
  requires: [03-01]
  provides: [CODE-01, CODE-02, CODE-03]
  affects: [apps/frontend/src/app/api/cortex/chat/route.ts, apps/frontend/src/app/api/query/route.ts, apps/frontend/src/app/api/metadata/route.ts]
tech_stack:
  added: []
  patterns: [config-import, error-sanitization]
key_files:
  created: []
  modified:
    - apps/frontend/src/app/api/cortex/chat/route.ts
    - apps/frontend/src/app/api/query/route.ts
    - apps/frontend/src/app/api/metadata/route.ts
decisions:
  - cortex/chat route had two detail exposure points: details: errorText (CORTEX_AGENT_ERROR) and details: String(error) (INTERNAL_ERROR) — both removed
  - query route had two detail exposure points: details: String(snowflakeError) (QUERY_EXECUTION_ERROR) and details: String(error) (INTERNAL_ERROR) — both removed
  - metadata route local DATABASE/SCHEMA constants replaced with SNOWFLAKE_DATABASE/SNOWFLAKE_SCHEMA from @/lib/config — completes consolidation started in Plan 01
metrics:
  duration: ~2 min
  completed: "2026-03-01"
  tasks_completed: 2
  files_modified: 3
---

# Phase 3 Plan 3: Non-Analytics Route Hardening Summary

Sanitized error responses in cortex/chat and query routes, and migrated metadata route from inline process.env reads to config.ts constants — completing the remaining CODE-01/02/03 surface area outside the analytics directory.

## Tasks Completed

| Task | Name | Commit | Files Modified |
|------|------|--------|----------------|
| 1 | Remove details: String(error) from cortex/chat and query routes | de81c6d | cortex/chat/route.ts, query/route.ts |
| 2 | Migrate metadata/route.ts to config.ts import | 8c5706d | metadata/route.ts |

## Changes Made

### Task 1 — Error Sanitization (cortex/chat/route.ts, query/route.ts)

**cortex/chat/route.ts:**
- Removed `details: errorText,` from CORTEX_AGENT_ERROR response (line 161 — used raw `errorText` from Snowflake, now omitted)
- Removed `details: String(error),` from INTERNAL_ERROR response (line 228)
- `console.error` calls retained in all catch blocks for server-side observability

**query/route.ts:**
- Removed `details: String(snowflakeError),` from QUERY_EXECUTION_ERROR response
- Removed `details: String(error),` from INTERNAL_ERROR response
- `console.error` calls retained in all catch blocks

### Task 2 — Config Migration (metadata/route.ts)

- Added `import { SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA } from '@/lib/config'`
- Removed `const DATABASE = process.env.SNOWFLAKE_DATABASE || 'COCO_SDLC_HOL'`
- Removed `const SCHEMA = process.env.SNOWFLAKE_SCHEMA || 'MARTS'`
- Updated all 6 `fullTableName` template literals in `domainMetadata` from `${DATABASE}.${SCHEMA}.*` to `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.*`
- Updated `connectionConfig.database` and `connectionConfig.schema` fields

## Verification Results

1. Zero occurrences of `details: String(error)` anywhere in `apps/frontend/src/app/api/` — confirmed post-Plan-02+03
2. metadata/route.ts imports from `@/lib/config` at line 3 — confirmed
3. Zero local `const DATABASE` or `const SCHEMA` declarations in metadata/route.ts — confirmed
4. TypeScript check: one pre-existing error in `authorization/page.tsx` (GaugeChartProps.formatValue) — unrelated to this plan's changes, deferred to deferred-items.md

## Deviations from Plan

None — plan executed exactly as written.

The `details: errorText` in cortex/chat/route.ts was the same category of exposure as `details: String(error)` (raw Snowflake response text), so it was included in the removal even though the plan specifically called out `String(error)` notation.

## Deferred Issues

**Pre-existing TypeScript Error (out of scope):**
- `apps/frontend/src/app/analytics/authorization/page.tsx:220` — `Property 'formatValue' does not exist on type 'IntrinsicAttributes & GaugeChartProps'`
- This error existed before Plan 03-03 and is unrelated to any file modified in this plan
- Logged to `.planning/phases/03-code-quality/deferred-items.md`

## Combined with Plan 02

Plans 02 and 03 together achieve full CODE-01/02/03 coverage:
- Plan 02: 19 analytics routes hardened (config imports, parameterized binds, error sanitization)
- Plan 03: 3 non-analytics routes hardened (error sanitization in cortex/chat + query; config migration in metadata)
- Combined: zero `details: String(error)` exposures across all 22 API routes

## Self-Check: PASSED

| Item | Result |
|------|--------|
| apps/frontend/src/app/api/cortex/chat/route.ts | FOUND |
| apps/frontend/src/app/api/query/route.ts | FOUND |
| apps/frontend/src/app/api/metadata/route.ts | FOUND |
| Commit de81c6d (Task 1) | FOUND |
| Commit 8c5706d (Task 2) | FOUND |
