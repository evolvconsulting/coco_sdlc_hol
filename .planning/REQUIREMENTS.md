# Requirements: COCO SDLC HOL Analytics Portal

**Defined:** 2026-02-28
**Core Value:** Merchants can independently answer questions about their transaction performance without calling support — all 6 payment domains accessible in one self-serve portal.

## v1 Requirements

Requirements for production deployment within 2 days.

### UAT / Functional Verification

- [x] **UAT-01**: Home dashboard displays cross-domain KPI overview with real Snowflake data
- [x] **UAT-02**: Authorization page shows correct KPIs, timeseries, by-brand, declines, and details
- [x] **UAT-03**: Settlement page shows correct KPIs, by-merchant, timeseries, and details
- [x] **UAT-04**: Funding page shows correct KPIs, timeseries, and details
- [x] **UAT-05**: Chargeback page shows correct KPIs, by-reason, and details
- [x] **UAT-06**: Retrieval page shows correct KPIs and details
- [x] **UAT-07**: Adjustment page shows correct KPIs and details
- [x] **UAT-08**: AI chat returns meaningful responses to natural language queries about transaction data

### UX / UI Polish

- [ ] **UX-01**: Navigation and layout are visually consistent across all 6 domain pages
- [ ] **UX-02**: Charts display with correct labels, axes, legends, and data formatting
- [ ] **UX-03**: Empty states and loading states handled gracefully in all charts and data tables
- [ ] **UX-04**: Date pickers and date range filters work correctly and update displayed data
- [ ] **UX-05**: Domain-specific filters function correctly on each analytics page
- [ ] **UX-06**: Portal is usable at standard desktop screen sizes

### Code Quality

- [ ] **CODE-01**: Database, schema, and table names centralized in a single configuration file (not scattered across route files)
- [ ] **CODE-02**: API routes return correct HTTP status codes (4xx/5xx) on errors — not 200 with success=false in body
- [ ] **CODE-03**: Error responses do not expose Snowflake credentials, connection strings, or sensitive query details
- [ ] **CODE-04**: SQL queries for user-provided parameters use parameterized queries instead of string interpolation
- [ ] **CODE-05**: Snowflake connection lifecycle properly managed — no shared global connection across concurrent requests

### Deployment

- [ ] **DEPLOY-01**: Application containerized with Dockerfile compatible with Snowpark Container Services (SPCS)
- [ ] **DEPLOY-02**: Application successfully deployed and accessible on SPCS
- [ ] **DEPLOY-03**: Environment variables and secrets configured correctly in SPCS deployment
- [ ] **DEPLOY-04**: Application connects to Snowflake MARTS schema from SPCS environment and returns real data

## v2 Requirements

Deferred to future milestone. Not in current roadmap.

### Security & Auth

- **SEC-01**: User authentication and session management
- **SEC-02**: Role-based access control (beyond RLS)
- **SEC-03**: Rate limiting on API endpoints
- **SEC-04**: CORS/CSP security headers

### Quality & Reliability

- **QA-01**: Unit test suite for lib utilities (snowflake.ts, cortex.ts, hooks)
- **QA-02**: Integration tests for end-to-end analytics flows
- **QA-03**: E2E tests for user workflows (Playwright)
- **QA-04**: Server-side query result caching (ETag, Cache-Control)
- **QA-05**: Structured logging with correlation IDs and request tracing

## Out of Scope

| Feature | Reason |
|---------|--------|
| Authentication / authorization | RLS + CLNT_ID filter handles data isolation for this milestone; auth adds significant scope |
| Automated test suite | 2-day timeline; manual UAT only for this milestone |
| Rate limiting | Not in scope for this milestone |
| Server-side query caching | Not in scope for this milestone |
| Mobile / responsive breakpoints below desktop | Web-first; desktop use case only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| UAT-01 | Phase 1 | Complete (01-02) |
| UAT-02 | Phase 1 | Complete (01-02) |
| UAT-03 | Phase 1 | Complete (01-02) |
| UAT-04 | Phase 1 | Complete (01-02) |
| UAT-05 | Phase 1 | Complete (01-02) |
| UAT-06 | Phase 1 | Complete (01-02) |
| UAT-07 | Phase 1 | Complete (01-02) |
| UAT-08 | Phase 1 | Complete (01-03) |
| UX-01 | Phase 2 | Pending |
| UX-02 | Phase 2 | Pending |
| UX-03 | Phase 2 | Pending |
| UX-04 | Phase 2 | Pending |
| UX-05 | Phase 2 | Pending |
| UX-06 | Phase 2 | Pending |
| CODE-01 | Phase 3 | Pending |
| CODE-02 | Phase 3 | Pending |
| CODE-03 | Phase 3 | Pending |
| CODE-04 | Phase 3 | Pending |
| CODE-05 | Phase 3 | Pending |
| DEPLOY-01 | Phase 4 | Pending |
| DEPLOY-02 | Phase 4 | Pending |
| DEPLOY-03 | Phase 4 | Pending |
| DEPLOY-04 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-28*
*Last updated: 2026-02-28 after 01-03 completion (UAT-08 marked complete — all Phase 1 UAT requirements satisfied)*
