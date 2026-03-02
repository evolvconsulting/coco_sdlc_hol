---
phase: 01-generate-hands-on-lab-setup-script
plan: "02"
subsystem: database

tags: [snowflake, dbt, dynamic-tables, staging-views, sql]

# Dependency graph
requires:
  - phase: 01-generate-hands-on-lab-setup-script/01-01
    provides: hol_setup_foundation.sql (Sections 1-5) — database, schemas, raw tables, reference data, synthetic transactions

provides:
  - packages/database/hol_setup_dbt.sql with Sections 6-8
  - 11 staging views in COCO_SDLC_HOL.STAGING
  - 6 intermediate dynamic tables in COCO_SDLC_HOL.INTERMEDIATE
  - 7 marts dynamic tables in COCO_SDLC_HOL.MARTS

affects:
  - 01-03 (consolidation — this file becomes the dbt DDL input to hol_setup.sql)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Snowflake staging views use CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.{model} AS (...) with parentheses"
    - "Snowflake dynamic tables use CREATE OR REPLACE DYNAMIC TABLE ... TARGET_LAG = '1 hour' WAREHOUSE = COMPUTE_WH AS ... without parentheses"
    - "SQL derived exclusively from target/compiled/ (not target/run/) to preserve correct schema assignments"

key-files:
  created:
    - packages/database/hol_setup_dbt.sql
  modified: []

key-decisions:
  - "Marts compiled SQL referenced COCO_SDLC_HOL.STAGING.int_* — corrected to COCO_SDLC_HOL.INTERMEDIATE.int_* per Pitfall 6 from RESEARCH.md"
  - "stg_clx_auth compiled SQL contained no risk_score column — no removal needed, confirmed clean"
  - "Dynamic table DDL does not use parentheses around the AS body (unlike view DDL) — Snowflake syntax requirement"

patterns-established:
  - "Staging DDL pattern: CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.{model} AS ( ... );"
  - "Dynamic table DDL pattern: CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.{schema}.{model} TARGET_LAG = '1 hour' WAREHOUSE = COMPUTE_WH AS ... ;"
  - "Dependency order: staging views -> intermediate dynamic tables -> marts dynamic tables"

requirements-completed: []

# Metrics
duration: 3min
completed: 2026-03-01
---

# Phase 01 Plan 02: dbt DDL Layer Summary

**24-object dbt DDL layer assembled — 11 STAGING views, 6 INTERMEDIATE dynamic tables, 7 MARTS dynamic tables — with compiled SQL from target/compiled/ and correct schema routing fixed from run/ pitfall**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-01T19:06:02Z
- **Completed:** 2026-03-01T19:09:22Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Created packages/database/hol_setup_dbt.sql with all 24 dbt object DDL statements
- Wrapped 11 compiled staging models in `CREATE OR REPLACE VIEW` targeting `COCO_SDLC_HOL.STAGING`
- Wrapped 6 intermediate and 7 marts compiled models in `CREATE OR REPLACE DYNAMIC TABLE` with `TARGET_LAG = '1 hour'` and `WAREHOUSE = COMPUTE_WH`
- Fixed schema routing for marts models: compiled SQL incorrectly referenced `COCO_SDLC_HOL.STAGING.int_*` — corrected to `COCO_SDLC_HOL.INTERMEDIATE.int_*`

## Task Commits

Each task was committed atomically:

1. **Task 1: Assemble staging view DDL (11 models)** - `90cb654` (feat)
2. **Task 2: Append intermediate and marts dynamic table DDL (13 models)** - `e4d0808` (feat)

**Plan metadata:** (docs commit to follow)

## Files Created/Modified

- `packages/database/hol_setup_dbt.sql` - dbt DDL sections 6-8: 11 staging views + 6 intermediate + 7 marts dynamic tables

## Decisions Made

- Marts compiled SQL had a schema mismatch: all intermediate table references used `COCO_SDLC_HOL.STAGING.int_*` instead of `COCO_SDLC_HOL.INTERMEDIATE.int_*`. This was corrected per Pitfall 6 from RESEARCH.md. The compiled models appear to have been generated without fully-qualified INTERMEDIATE schema resolution.
- stg_clx_auth was verified clean — no risk_score column appeared in the compiled output, so no removal was required.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected marts compiled SQL schema references for intermediate tables**
- **Found during:** Task 2 (intermediate and marts DDL assembly)
- **Issue:** All 6 marts models (`authorizations.sql`, `settlements.sql`, `deposits.sql`, `chargebacks.sql`, `retrievals.sql`, `adjustments.sql`) referenced `COCO_SDLC_HOL.STAGING.int_*` instead of `COCO_SDLC_HOL.INTERMEDIATE.int_*` in their FROM clauses
- **Fix:** When wrapping marts compiled SQL in dynamic table DDL, substituted correct `COCO_SDLC_HOL.INTERMEDIATE.int_*` references so marts tables can find their intermediate dependencies at dynamic table creation time
- **Files modified:** packages/database/hol_setup_dbt.sql
- **Verification:** `grep -c "COCO_SDLC_HOL.STAGING.int_" packages/database/hol_setup_dbt.sql` returns 0
- **Committed in:** e4d0808 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in compiled SQL schema routing)
**Impact on plan:** Required fix. Without correction, all 7 marts dynamic tables would fail to create because they reference non-existent intermediate objects in the STAGING schema.

## Issues Encountered

None beyond the schema routing correction documented above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- packages/database/hol_setup_dbt.sql is ready to be combined with hol_setup_foundation.sql in plan 01-03
- All 24 dbt object DDL statements verified: 11 views + 13 dynamic tables
- All references schema-qualified correctly: staging -> intermediate -> marts dependency chain intact

---
*Phase: 01-generate-hands-on-lab-setup-script*
*Completed: 2026-03-01*

## Self-Check: PASSED

- FOUND: packages/database/hol_setup_dbt.sql
- FOUND: .planning/phases/01-generate-hands-on-lab-setup-script/01-02-SUMMARY.md
- FOUND: commit 90cb654 (Task 1)
- FOUND: commit e4d0808 (Task 2)
