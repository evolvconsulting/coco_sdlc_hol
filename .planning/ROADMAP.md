# Roadmap: COCO SDLC HOL Analytics Portal

## Overview

The portal is functionally built. This roadmap covers the final mile: verify all 6 payment domains work correctly with real Snowflake data, polish the UI to be consistent and usable, harden the code against security and reliability issues, then containerize and deploy to Snowpark Container Services. Four phases, two days, production.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: UAT Walkthrough** - Verify all 6 payment domains and AI chat return correct data from Snowflake
- [x] **Phase 2: UX / UI Polish** - Make navigation, charts, filters, and states visually consistent and usable
- [x] **Phase 3: Code Quality** - Fix security issues, error handling, and connection management (completed 2026-03-01)
- [x] **Phase 4: Deployment** - Containerize and ship to Snowpark Container Services (completed 2026-03-01)

## Phase Details

### Phase 1: UAT Walkthrough
**Goal**: All 6 payment domains and AI chat are verified to return correct data from real Snowflake MARTS
**Depends on**: Nothing (first phase)
**Requirements**: UAT-01, UAT-02, UAT-03, UAT-04, UAT-05, UAT-06, UAT-07, UAT-08
**Success Criteria** (what must be TRUE):
  1. Home dashboard displays real KPI values from all 6 domains (not zeros, not errors)
  2. Each domain page (Authorization, Settlement, Funding, Chargeback, Retrieval, Adjustment) shows correct KPIs and data tables populated from Snowflake
  3. Authorization page displays correct timeseries, by-brand breakdown, and decline data
  4. AI chat returns a meaningful, contextually correct answer to at least one natural language query about transaction data
  5. Any bugs found during walkthrough are documented and resolved
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — Environment pre-flight: verify .env.local, confirm Snowflake connectivity, discover MARTS data date range
- [x] 01-02-PLAN.md — Domain walkthrough: API smoke-test all 19 endpoints, browser verify all 6 domain pages and home dashboard
- [x] 01-03-PLAN.md — AI chat verification (UAT-08), bug fixes from walkthrough, Phase 1 UAT sign-off

### Phase 2: UX / UI Polish
**Goal**: The portal is visually consistent and usable — merchants can navigate and read data without confusion
**Depends on**: Phase 1
**Requirements**: UX-01, UX-02, UX-03, UX-04, UX-05, UX-06
**Success Criteria** (what must be TRUE):
  1. Navigation looks and behaves the same across all 6 domain pages (consistent sidebar, header, active states)
  2. Every chart displays with correct axis labels, legend, and formatted values (currency, percentages, counts)
  3. Loading and empty states appear correctly — no blank charts, no unhandled spinner states
  4. Date pickers and date range filters visibly update all data on the page when changed
  5. Domain-specific filters (e.g., brand, merchant, reason code) apply correctly to their respective pages
**Plans**: 4 plans

Plans:
- [x] 02-01-PLAN.md — Sidebar fix + formatter foundation: controlled openKeys, remove Saved Reports stub, create formatters.ts
- [x] 02-02-PLAN.md — Domain page KPICard conversion: chargeback, retrieval, adjustment to KPICard + Skeleton loading
- [x] 02-03-PLAN.md — Authorization, settlement, funding polish: KPICard + Skeleton loading + canonical formatters
- [x] 02-04-PLAN.md — Human visual verification: all 6 UX requirements verified and approved

### Phase 3: Code Quality
**Goal**: The codebase is hardened against security vulnerabilities and reliability failures before going to production
**Depends on**: Phase 2
**Requirements**: CODE-01, CODE-02, CODE-03, CODE-04, CODE-05
**Success Criteria** (what must be TRUE):
  1. All database, schema, and table name references resolve to a single config file — no hardcoded strings in route files
  2. API error responses return correct HTTP status codes (4xx/5xx) and do not include Snowflake credentials or connection details
  3. User-supplied query parameters are sent via parameterized queries — no string interpolation in SQL
  4. Each API request creates and closes its own Snowflake connection — no shared global connection state
**Plans**: 3 plans

Plans:
- [ ] 03-01-PLAN.md — Foundation: create config.ts (CODE-01) and refactor snowflake.ts for per-request connections + parameterized query support (CODE-04, CODE-05)
- [ ] 03-02-PLAN.md — Analytics route hardening: apply config imports, parameterized queries, and error sanitization to all 19 analytics routes (CODE-01, CODE-02, CODE-03, CODE-04)
- [ ] 03-03-PLAN.md — Remaining route cleanup: error sanitization for cortex/chat and query routes, config migration for metadata route (CODE-01, CODE-02, CODE-03)

### Phase 4: Deployment
**Goal**: The portal is running in Snowpark Container Services and accessible to merchants with real data
**Depends on**: Phase 3
**Requirements**: DEPLOY-01, DEPLOY-02, DEPLOY-03, DEPLOY-04
**Success Criteria** (what must be TRUE):
  1. A Dockerfile builds successfully and produces an image compatible with SPCS requirements
  2. The application is accessible at an SPCS endpoint — home dashboard loads in a browser
  3. Environment variables and secrets are configured in SPCS (not baked into the image)
  4. Domain pages return real data from Snowflake MARTS when accessed through the SPCS deployment
**Plans**: 3 plans

Plans:
- [ ] 04-01-PLAN.md — Container packaging: update next.config.ts (standalone + outputFileTracingRoot), add /api/health route, write Dockerfile and .dockerignore
- [ ] 04-02-PLAN.md — Snowflake provisioning script: write idempotent setup.sql with Secret, image repo, compute pool, and SPCS service spec (all env vars + secret injection)
- [ ] 04-03-PLAN.md — Build, push, deploy, and verify: docker build + push to Snowflake registry, run setup.sql, confirm portal returns real MARTS data at SPCS endpoint

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. UAT Walkthrough | 3/3 | Complete | 2026-02-28 |
| 2. UX / UI Polish | 4/4 | Complete | 2026-02-28 |
| 3. Code Quality | 4/4 | Complete   | 2026-03-01 |
| 4. Deployment | 3/3 | Complete   | 2026-03-01 |
