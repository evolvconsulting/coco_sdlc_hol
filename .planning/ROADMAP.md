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
| 1. Generate HOL Setup Script | 3/3 | Complete | 2026-03-06 |
| 2. UX / UI Polish | 3/3 | Complete   | 2026-03-06 | 2026-02-28 |
| 3. Code Quality | 2/2 | Complete   | 2026-03-06 | 2026-03-01 |
| 4. Deployment | v1.0 | 3/3 | Complete | 2026-03-01 |

### Phase 1: Generate hands on lab setup script

**Goal:** Produce a single consolidated idempotent SQL script (hol_setup.sql) that provisions a complete Snowflake HOL environment — database, schemas, RAW tables, reference data, synthetic transactions, pre-compiled dbt model DDL (staging views + intermediate/marts dynamic tables), service user, image repository, and Cortex Agent — runnable by dataops.live or pasted into a Snowflake worksheet.
**Requirements**: TBD
**Depends on:** Phase 0
**Plans:** 3/3 plans executed (phase complete)

Plans:
- [x] 01-01-PLAN.md — Assemble foundation sections (ACCOUNTADMIN bootstrap, warehouse/DB/schema setup, RAW tables, reference data, synthetic transaction generation) — completed 2026-03-01
- [x] 01-02-PLAN.md — Assemble dbt DDL sections (11 staging views, 6 intermediate dynamic tables, 7 marts dynamic tables from compiled output) — completed 2026-03-01
- [x] 01-03-PLAN.md — Assemble final sections (service user, image repo, semantic view, Cortex Agent), merge into hol_setup.sql, human verification checkpoint — completed 2026-03-06

### Phase 2: Create the Hands on Lab instruction guide

**Goal:** Produce a single comprehensive markdown guide (HANDS_ON_LAB.md) that walks HOL participants through using Cortex Code to make code changes across the full SDLC — from reading a Jira ticket through committing and creating a PR — demonstrating AI-assisted development workflows on a real payment analytics codebase.
**Requirements**: HOL-01 (architecture overview), HOL-02 (setup verification), HOL-03 (Cortex Code primer), HOL-04 (Task 1 dbt/semantic/agent changes), HOL-05 (Task 1 verification), HOL-06 (Confluence update), HOL-07 (Task 2 frontend KPI card), HOL-08 (wrap-up and takeaways), HOL-09 (troubleshooting appendix)
**Depends on:** Phase 1
**Plans:** 3/3 plans complete

Plans:
- [ ] 02-01-PLAN.md — Write foundation sections: header, architecture overview, setup verification, Cortex Code primer
- [ ] 02-02-PLAN.md — Write Task 1 walkthrough (retry success rate metric end-to-end) and context switch
- [ ] 02-03-PLAN.md — Write Task 2 walkthrough (KPI card), wrap-up, appendix, and human verification

### Phase 3: Generate reference content for Jira tickets and Confluence documentation

**Goal:** Produce reference .wiki files for Jira tickets (epic, two main stories, three backlog items) and a Confluence data dictionary page, then create the actual artifacts in Atlassian Cloud via REST API -- supporting the two development tasks in HANDS_ON_LAB.md and making the Jira board feel like a real project.
**Requirements**: CONTENT-01 (Jira wiki markup files), CONTENT-02 (Confluence data dictionary), API-01 (Epic created), API-02 (Stories linked to epic), API-03 (Confluence page created), API-04 (Data dictionary omits retry_success_rate)
**Depends on:** Phase 2
**Plans:** 2/2 plans complete

Plans:
- [ ] 03-01-PLAN.md — Generate Jira .wiki reference files (epic + 2 stories + 3 backlog) and Confluence data dictionary .wiki file
- [ ] 03-02-PLAN.md — Create Atlassian artifact creation script and execute with human verification
