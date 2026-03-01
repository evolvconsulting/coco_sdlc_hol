# Deferred Items — Phase 03 Code Quality

## Pre-existing TypeScript Error (Out of Scope)

**Discovered during:** 03-03, Task 2 TypeScript verification
**File:** `apps/frontend/src/app/api/authorization/page.tsx` (line 220)
**Error:** `Property 'formatValue' does not exist on type 'IntrinsicAttributes & GaugeChartProps'`
**Why deferred:** Pre-existing error unrelated to the three files modified in plan 03-03. Not caused by current task's changes.
**Recommendation:** Update `GaugeChartProps` type definition to include `formatValue` or remove the prop from the usage site.
