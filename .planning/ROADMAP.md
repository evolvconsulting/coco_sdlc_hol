# Roadmap: COCO SDLC HOL Analytics Portal

## Milestones

- ✅ **v1.0 HOL Baseline Application** — Phases 1-4 (shipped 2026-03-01)
- 📋 **v1.1** — (planned — define via `/gsd:new-milestone`)

## Phases

<details>
<summary>✅ v1.0 HOL Baseline Application (Phases 1-4) — SHIPPED 2026-03-01</summary>

- [x] Phase 1: UAT Walkthrough (3/3 plans) — completed 2026-02-28
- [x] Phase 2: UX / UI Polish (4/4 plans) — completed 2026-02-28
- [x] Phase 3: Code Quality (4/4 plans) — completed 2026-03-01
- [x] Phase 4: Deployment (3/3 plans) — completed 2026-03-01

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. UAT Walkthrough | 2/3 | In Progress|  | 2026-02-28 |
| 2. UX / UI Polish | v1.0 | 4/4 | Complete | 2026-02-28 |
| 3. Code Quality | v1.0 | 4/4 | Complete | 2026-03-01 |
| 4. Deployment | v1.0 | 3/3 | Complete | 2026-03-01 |

### Phase 1: Generate hands on lab setup script

**Goal:** Produce a single consolidated idempotent SQL script (hol_setup.sql) that provisions a complete Snowflake HOL environment — database, schemas, RAW tables, reference data, synthetic transactions, pre-compiled dbt model DDL (staging views + intermediate/marts dynamic tables), service user, image repository, and Cortex Agent — runnable by dataops.live or pasted into a Snowflake worksheet.
**Requirements**: TBD
**Depends on:** Phase 0
**Plans:** 2/3 plans executed

Plans:
- [x] 01-01-PLAN.md — Assemble foundation sections (ACCOUNTADMIN bootstrap, warehouse/DB/schema setup, RAW tables, reference data, synthetic transaction generation) — completed 2026-03-01
- [ ] 01-02-PLAN.md — Assemble dbt DDL sections (11 staging views, 6 intermediate dynamic tables, 7 marts dynamic tables from compiled output)
- [ ] 01-03-PLAN.md — Assemble final sections (service user, image repo, semantic view, Cortex Agent), merge into hol_setup.sql, human verification checkpoint
