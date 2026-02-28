# COCO SDLC HOL — Credit Card Transaction Analytics Portal

## What This Is

A self-serve analytics portal for merchants using credit card transaction processing services. Merchants can view KPIs, trends, and detailed data across 6 payment domains (authorization, settlement, funding, chargebacks, retrievals, adjustments) and ask natural language questions via AI chat powered by Snowflake Cortex. Built on Next.js with real-time Snowflake data through a dbt MARTS transformation layer.

## Core Value

Merchants can independently answer questions about their transaction performance without calling support — seeing approvals, fees, chargebacks, and funding in one place with their own data.

## Requirements

### Validated

- ✓ Authorization analytics (KPIs, timeseries, by-brand, declines, details) — existing
- ✓ Settlement analytics (KPIs, by-merchant, timeseries, details) — existing
- ✓ Funding analytics (KPIs, timeseries, details) — existing
- ✓ Chargeback analytics (KPIs, by-reason, details) — existing
- ✓ Retrieval analytics (KPIs, details) — existing
- ✓ Adjustment analytics (KPIs, details) — existing
- ✓ AI chat / natural language queries via Snowflake Cortex — existing
- ✓ Row-level security (CLNT_ID filter) — existing
- ✓ dbt transformation pipeline (staging → intermediate → marts) — existing
- ✓ React Query client-side caching (5-minute stale time) — existing

### Active

- [ ] UAT walkthrough — verify all 6 domains work correctly with real Snowflake data
- [ ] Bug fixes — resolve issues found during walkthrough
- [ ] UX/UI polish — improve visual consistency, layout, and usability
- [ ] Code quality — centralize hardcoded configs, fix error handling patterns
- [ ] Deployment to Snowpark Container Services (SPCS) — containerize and deploy

### Out of Scope

- Authentication/authorization — not in scope for this milestone (RLS handles data isolation)
- Automated test suite — not in scope for this milestone
- Rate limiting — not in scope for this milestone
- Server-side query result caching — not in scope for this milestone

## Context

- Portal was built as part of the COCO SDLC hands-on-lab (HOL) project
- All data lives in Snowflake under `COCO_SDLC_HOL.MARTS.*` schema
- RLS hardcoded to `CLNT_ID = 'dmcl'` for single-tenant demo scenario
- Codebase map identified: SQL injection risk (string interpolation in queries), credentials in error responses, hardcoded table/schema names — code quality work should address these
- No existing automated tests; UAT will be manual walkthrough

## Constraints

- **Timeline**: 2 days to production deployment
- **Deployment**: Snowpark Container Services (SPCS) — containerization required
- **Data**: Real Snowflake data via existing MARTS schema (no mocking)
- **Tech Stack**: Next.js, Snowflake SDK, dbt — no stack changes

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Skip auth for this milestone | RLS + CLNT_ID filter provides data isolation for demo; auth adds significant scope | — Pending |
| SPCS deployment target | Keeps everything within Snowflake ecosystem; no external cloud infra needed | — Pending |
| Manual UAT over automated tests | 2-day timeline; automated tests would take longer than the milestone | — Pending |

---
*Last updated: 2026-02-28 after initialization*
