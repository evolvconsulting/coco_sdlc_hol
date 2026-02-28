# UAT Bug Report — Phase 1
**Date:** 2026-02-28

## Bugs Found

| # | Domain | Endpoint | Expected | Actual | Network | Severity |
|---|--------|----------|----------|--------|---------|----------|
| 1 | Authorization | /api/analytics/authorization/details | success: true, data array | SQL compilation error: invalid identifier 'AUTHORIZATION_ID' | 503 SNOWFLAKE_CONNECTION_ERROR | Major |
| 2 | Settlement | /api/analytics/settlement/details | success: true, data array | SQL compilation error: invalid identifier 'SETTLEMENT_ID' | 503 SNOWFLAKE_CONNECTION_ERROR | Major |
| 3 | Funding | /api/analytics/funding/details | success: true, data array | SQL compilation error: invalid identifier 'DEPOSIT_ID' | 503 SNOWFLAKE_CONNECTION_ERROR | Major |
| 4 | Chargeback | /api/analytics/chargeback/details | success: true, data array | SQL compilation error: invalid identifier 'CHARGEBACK_ID' | 503 SNOWFLAKE_CONNECTION_ERROR | Major |
| 5 | Retrieval | /api/analytics/retrieval/details | success: true, data array | SQL compilation error: invalid identifier 'RETRIEVAL_ID' | 503 SNOWFLAKE_CONNECTION_ERROR | Major |
| 6 | Adjustment | /api/analytics/adjustment/details | success: true, data array | SQL compilation errors: invalid identifier 'ADJUSTMENT_ID', 'FEE_DESCRIPTION' | 503 SNOWFLAKE_CONNECTION_ERROR | Major |

**Root cause:** All `/details` route files reference `*_id` column names (e.g., `authorization_id`, `settlement_id`) but the actual MARTS table primary key columns use `*_key` naming convention (e.g., `AUTHORIZATION_KEY`, `SETTLEMENT_KEY`). Additionally, `risk_score` (AUTHORIZATIONS) and `fee_description` (ADJUSTMENTS) do not exist in the actual table schemas.

**Status: AUTO-FIXED** — Column names corrected in all 6 details route files (Rule 1 auto-fix). All endpoints now return `success: true` with data.

## API Smoke Test Results

### Run Conditions
- **Date range:** 2026-01-13 to 2026-02-22
- **Tested at:** 2026-02-28
- **Dev server:** http://localhost:3000
- **Method:** curl with JSON response parsing

### Results After Auto-fix

| Endpoint | Status | Notes |
|----------|--------|-------|
| /api/analytics/authorization/kpis | PASS | success: true, data non-empty (2969 transactions) |
| /api/analytics/authorization/timeseries | PASS | success: true, data array with daily points |
| /api/analytics/authorization/by-brand | PASS | success: true, card brand breakdown (Visa, Mastercard, etc.) |
| /api/analytics/authorization/declines | PASS | success: true, decline reasons with counts |
| /api/analytics/authorization/details | PASS (after fix) | Fixed: authorization_id → authorization_key, removed risk_score |
| /api/analytics/settlement/kpis | PASS | success: true, data non-empty |
| /api/analytics/settlement/by-merchant | PASS | success: true, merchant breakdown |
| /api/analytics/settlement/timeseries | PASS | success: true, daily timeseries |
| /api/analytics/settlement/details | PASS (after fix) | Fixed: settlement_id → settlement_key |
| /api/analytics/funding/kpis | PASS | success: true, data non-empty (151 records) |
| /api/analytics/funding/timeseries | PASS | success: true, daily timeseries |
| /api/analytics/funding/details | PASS (after fix) | Fixed: deposit_id → deposit_key |
| /api/analytics/chargeback/kpis | PASS | success: true, data non-empty (213 chargebacks) |
| /api/analytics/chargeback/by-reason | PASS | success: true, reason code breakdown |
| /api/analytics/chargeback/details | PASS (after fix) | Fixed: chargeback_id → chargeback_key |
| /api/analytics/retrieval/kpis | PASS | success: true, data non-empty (23 retrievals) |
| /api/analytics/retrieval/details | PASS (after fix) | Fixed: retrieval_id → retrieval_key |
| /api/analytics/adjustment/kpis | PASS | success: true, data non-empty (98 adjustments) |
| /api/analytics/adjustment/details | PASS (after fix) | Fixed: adjustment_id → adjustment_key, fee_description → adjustment_category |

**Summary:** 19/19 endpoints PASS after auto-fix. 13/19 passed without fixes. 6/19 had SQL column name bugs (all in /details routes).

## Browser Walkthrough Results

*Awaiting human verification — see checkpoint below.*

| Page | URL | Status |
|------|-----|--------|
| Home Dashboard (UAT-01) | http://localhost:3000/ | Pending |
| Authorization (UAT-02) | http://localhost:3000/analytics/authorization | Pending |
| Settlement (UAT-03) | http://localhost:3000/analytics/settlement | Pending |
| Funding (UAT-04) | http://localhost:3000/analytics/funding | Pending |
| Chargeback (UAT-05) | http://localhost:3000/analytics/chargeback | Pending |
| Retrieval (UAT-06) | http://localhost:3000/analytics/retrieval | Pending |
| Adjustment (UAT-07) | http://localhost:3000/analytics/adjustment | Pending |
