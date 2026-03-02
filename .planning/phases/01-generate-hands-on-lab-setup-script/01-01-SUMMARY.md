---
phase: 01-generate-hands-on-lab-setup-script
plan: "01"
subsystem: database
tags: [snowflake, sql, hol-setup, ddl, reference-data, synthetic-data]
dependency_graph:
  requires: []
  provides: [packages/database/hol_setup_foundation.sql]
  affects: [packages/database/hol_setup.sql]
tech_stack:
  added: []
  patterns: [idempotent-merge, execute-immediate-guard, create-or-replace]
key_files:
  created:
    - packages/database/hol_setup_foundation.sql
  modified: []
decisions:
  - GRANT CREATE IMAGE REPOSITORY added to ACCOUNTADMIN bootstrap (not in original research block but required for SPCS image workflows)
  - COMPUTE_WH creation placed in ACCOUNTADMIN section before role switch (GRANT USAGE must be granted by ACCOUNTADMIN)
  - USE SCHEMA COCO_SDLC_HOL.RAW used fully qualified throughout instead of bare USE SCHEMA RAW
  - No bare CALL to GENERATE_SYNTHETIC_DATA — only guarded by EXECUTE IMMEDIATE with COUNT(*) check
metrics:
  duration: 6 minutes
  completed_date: "2026-03-01"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 0
---

# Phase 01 Plan 01: HOL Setup Foundation Script Summary

Single idempotent SQL file assembling ACCOUNTADMIN bootstrap, warehouse/database/schema setup, 11 RAW table DDL statements, 5 MERGE INTO reference data loads, and the GENERATE_SYNTHETIC_DATA procedure with idempotency-guarded EXECUTE IMMEDIATE call into `packages/database/hol_setup_foundation.sql`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write ACCOUNTADMIN bootstrap, warehouse, database, and schema setup | b5433e7 | packages/database/hol_setup_foundation.sql (created) |
| 2 | Append RAW tables, reference data, and synthetic transaction generation | 01ad2d3 | packages/database/hol_setup_foundation.sql (extended) |

## Output Produced

**File:** `packages/database/hol_setup_foundation.sql` (1,272 lines)

**Structure:**
- SECTION 1: ACCOUNTADMIN Bootstrap — role creation, 11 privilege grants, warehouse creation with GRANT USAGE
- SECTION 2: Database, Warehouse, and Schema Setup — ATTENDEE_ROLE context, COCO_SDLC_HOL database, 5 schemas (RAW, STAGING, INTERMEDIATE, MARTS, PUBLIC)
- SECTION 3: RAW Schema Tables — 11 CREATE OR REPLACE TABLE statements (PLTF_REF, GLB_BIN, DCLN_RSN_CD, CBK_RSN_CD, CLX_MRCH_MSTR, CLX_AUTH, CLX_SETTLE, CLX_FUND, CLX_CBK, CLX_RTRVL, CLX_ADJ)
- SECTION 4: Reference Data — 5 MERGE INTO loads (idempotent by design)
- SECTION 5: Synthetic Transaction Data — GENERATE_REALISTIC_AMOUNT function, GET_CHARGEBACK_RATE function, GENERATE_SYNTHETIC_DATA procedure, EXECUTE IMMEDIATE idempotency guard

## Verification Results

| Check | Expected | Result |
|-------|----------|--------|
| USE ROLE ACCOUNTADMIN | 1 | 1 |
| USE ROLE ATTENDEE_ROLE | 1 | 1 |
| GRANT BIND SERVICE ENDPOINT | 1 | 1 |
| Bare CALL GENERATE_SYNTHETIC_DATA | 0 | 0 |
| MERGE INTO count | 5 | 5 |
| CREATE OR REPLACE TABLE count | 11 | 11 |
| risk_score column present | 0 | 0 |

All success criteria met.

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written.

### Minor Additions (within plan scope)

**GRANT CREATE IMAGE REPOSITORY added to ACCOUNTADMIN bootstrap**
- The plan listed this grant explicitly in the task action (line 132 of PLAN.md)
- Included faithfully as specified

**COMPUTE_WH warehouse creation in ACCOUNTADMIN section**
- Plan noted the executor must handle role context for GRANT USAGE
- Resolved by creating warehouse and issuing GRANT USAGE before `USE ROLE ATTENDEE_ROLE` switch
- This matches the plan's intent: "add GRANT USAGE ON WAREHOUSE to the ACCOUNTADMIN section after the CREATE WAREHOUSE, then switch roles"

## Self-Check: PASSED

- File exists: `packages/database/hol_setup_foundation.sql` — FOUND
- Task 1 commit b5433e7 — FOUND
- Task 2 commit 01ad2d3 — FOUND
