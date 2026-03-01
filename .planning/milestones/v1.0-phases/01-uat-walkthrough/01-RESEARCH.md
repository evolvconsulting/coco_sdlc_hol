# Phase 1: UAT Walkthrough - Research

**Researched:** 2026-02-28
**Domain:** Manual UAT for Next.js analytics portal with Snowflake MARTS backend
**Confidence:** HIGH (codebase is directly inspectable; all findings are from source code review, not inference)

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UAT-01 | Home dashboard displays cross-domain KPI overview with real Snowflake data | Dashboard page.tsx calls all 6 domain KPI endpoints concurrently; verify all 6 return non-zero values |
| UAT-02 | Authorization page shows correct KPIs, timeseries, by-brand, declines, and details | 5 distinct API endpoints: `/api/analytics/authorization/{kpis,timeseries,by-brand,declines,details}` |
| UAT-03 | Settlement page shows correct KPIs, by-merchant, timeseries, and details | 4 endpoints: `/api/analytics/settlement/{kpis,by-merchant,timeseries,details}` |
| UAT-04 | Funding page shows correct KPIs, timeseries, and details | 3 endpoints: `/api/analytics/funding/{kpis,timeseries,details}` |
| UAT-05 | Chargeback page shows correct KPIs, by-reason, and details | 3 endpoints: `/api/analytics/chargeback/{kpis,by-reason,details}` |
| UAT-06 | Retrieval page shows correct KPIs and details | 2 endpoints: `/api/analytics/retrieval/{kpis,details}` |
| UAT-07 | Adjustment page shows correct KPIs and details | 2 endpoints: `/api/analytics/adjustment/{kpis,details}` |
| UAT-08 | AI chat returns meaningful responses to natural language queries about transaction data | Cortex Agent at `/api/cortex/chat` using SSE streaming; requires JWT key-pair auth to Snowflake |
</phase_requirements>

---

## Summary

Phase 1 is a structured manual walkthrough of an already-built Next.js 16 + Snowflake analytics portal. The portal has 6 payment domain pages (Authorization, Settlement, Funding, Chargeback, Retrieval, Adjustment) and an AI chat interface. All pages are built and wired to real Snowflake MARTS tables. The task is to run the app, navigate to each page, confirm data loads from Snowflake (not zeros, not errors), and document/fix any bugs found.

The portal depends on environment variables in `apps/frontend/.env.local` for Snowflake connectivity. The single most common failure mode at UAT time is missing or misconfigured `.env.local`. Before any page-level testing, verifying the connection is live (via the metadata endpoint or a test query) is the correct first step. The architecture uses a global singleton connection in `lib/snowflake.ts` — this is intentional for the demo but means a broken connection affects all endpoints simultaneously.

The AI chat (UAT-08) has a separate configuration path from the analytics endpoints. Analytics routes use the `snowflake-sdk` for direct SQL queries; chat uses the Snowflake Cortex Agent REST API via JWT authentication. Both require the same private key, but the chat additionally needs `CORTEX_AGENT_DATABASE`, `CORTEX_AGENT_SCHEMA`, and `CORTEX_AGENT_NAME` environment variables pointing to the deployed Cortex agent.

**Primary recommendation:** Start the app with `npm run dev` from `apps/frontend/`, immediately hit `GET /api/metadata` to confirm the Snowflake connection is live, then walk through each domain page in order, checking the browser network tab for 2xx responses with non-empty data arrays.

---

## Standard Stack

This is a verification/walkthrough phase. No new libraries are needed. The existing stack is the object of verification.

### Core (What We Are Verifying)
| Library | Version | Purpose | Relevance to UAT |
|---------|---------|---------|-----------------|
| Next.js | 16.1.6 | API routes + page rendering | Dev server is `npm run dev` in `apps/frontend/` |
| snowflake-sdk | 2.3.4 | SQL query execution | All analytics endpoints depend on this for data |
| @tanstack/react-query | 5.90.21 | Client-side data fetching | 5-min stale time; use Refresh button or hard-reload to recheck |
| antd | 6.3.0 | Dashboard UI components | Tables, charts, KPI cards all from Ant Design |
| echarts-for-react | 3.0.6 | Timeseries/bar charts | Visualization layer for Authorization timeseries, Settlement timeseries, Funding timeseries |

### Dev Tools Relevant to UAT
| Tool | Version | Purpose |
|---------|---------|---------|
| Browser DevTools | - | Network tab shows individual API call latencies and response bodies |
| curl / browser fetch | - | Direct endpoint testing to isolate UI vs API bugs |
| Snowflake Web UI | - | Cross-check query results against portal values |

**Starting the app:**
```bash
cd C:/Users/TrentFoley/Source/coco_sdlc_hol/apps/frontend
npm run dev
```
App starts at `http://localhost:3000`.

---

## Architecture Patterns

### How Data Flows (Critical for Bug Diagnosis)

```
User Browser
    → page.tsx (React Query hook: useAnalyticsData)
    → GET /api/analytics/{domain}/{endpoint}?startDate=...&endDate=...
    → lib/snowflake.ts (getConnection → executeQuery)
    → Snowflake COCO_SDLC_HOL.MARTS.{TABLE}
    → JSON response: { success: true, data: {...} }
    → Component renders
```

When something shows zeros or errors, the failure is at one of these layers. Browser Network tab pinpoints which.

### Connection Architecture (Key Fact for UAT)

`lib/snowflake.ts` uses a module-level singleton: `let connectionPool: snowflake.Connection | null = null`.

- On first API call, a connection is established and cached.
- All subsequent calls reuse the same connection.
- If the connection is broken mid-session (Snowflake timeout, credential issue), ALL endpoints fail until the Next.js dev server is restarted.
- There is no automatic reconnection logic.

**UAT implication:** If pages that worked start failing, restart the dev server before assuming a code bug.

### Endpoint Map (Complete Reference for UAT-01 through UAT-07)

| Domain Page | Route | Tables Queried | Key Columns |
|-------------|-------|---------------|-------------|
| Home Dashboard | Multiple KPI endpoints | AUTHORIZATIONS, SETTLEMENTS, DEPOSITS, CHARGEBACKS, RETRIEVALS, ADJUSTMENTS | All domain KPI columns |
| Authorization | `/api/analytics/authorization/kpis` | `COCO_SDLC_HOL.MARTS.AUTHORIZATIONS` | `total_transactions`, `approval_status`, `transaction_amount`, `transaction_date` |
| Authorization | `/api/analytics/authorization/timeseries` | `COCO_SDLC_HOL.MARTS.AUTHORIZATIONS` | Daily bucketed counts |
| Authorization | `/api/analytics/authorization/by-brand` | `COCO_SDLC_HOL.MARTS.AUTHORIZATIONS` | `card_brand` |
| Authorization | `/api/analytics/authorization/declines` | `COCO_SDLC_HOL.MARTS.AUTHORIZATIONS` | `decline_reason`, `decline_code` |
| Authorization | `/api/analytics/authorization/details` | `COCO_SDLC_HOL.MARTS.AUTHORIZATIONS` | Full row detail |
| Settlement | `/api/analytics/settlement/kpis` | `COCO_SDLC_HOL.MARTS.SETTLEMENTS` | `net_volume` |
| Settlement | `/api/analytics/settlement/by-merchant` | `COCO_SDLC_HOL.MARTS.SETTLEMENTS` | `merchant` grouping |
| Settlement | `/api/analytics/settlement/timeseries` | `COCO_SDLC_HOL.MARTS.SETTLEMENTS` | Daily amounts |
| Settlement | `/api/analytics/settlement/details` | `COCO_SDLC_HOL.MARTS.SETTLEMENTS` | Full row detail |
| Funding | `/api/analytics/funding/kpis` | `COCO_SDLC_HOL.MARTS.DEPOSITS` | `total_deposits`, `total_funding_records` |
| Funding | `/api/analytics/funding/timeseries` | `COCO_SDLC_HOL.MARTS.DEPOSITS` | Daily deposit amounts |
| Funding | `/api/analytics/funding/details` | `COCO_SDLC_HOL.MARTS.DEPOSITS` | Full row detail |
| Chargeback | `/api/analytics/chargeback/kpis` | `COCO_SDLC_HOL.MARTS.CHARGEBACKS` | `total_chargebacks`, `open_count`, `total_dispute_amount` |
| Chargeback | `/api/analytics/chargeback/by-reason` | `COCO_SDLC_HOL.MARTS.CHARGEBACKS` | `reason_code` grouping |
| Chargeback | `/api/analytics/chargeback/details` | `COCO_SDLC_HOL.MARTS.CHARGEBACKS` | Full row detail |
| Retrieval | `/api/analytics/retrieval/kpis` | `COCO_SDLC_HOL.MARTS.RETRIEVALS` | `total_retrievals`, `open_count` |
| Retrieval | `/api/analytics/retrieval/details` | `COCO_SDLC_HOL.MARTS.RETRIEVALS` | Full row detail |
| Adjustment | `/api/analytics/adjustment/kpis` | `COCO_SDLC_HOL.MARTS.ADJUSTMENTS` | `net_adjustment`, `total_adjustments` |
| Adjustment | `/api/analytics/adjustment/details` | `COCO_SDLC_HOL.MARTS.ADJUSTMENTS` | Full row detail |

### AI Chat Architecture (UAT-08 Specific)

The chat route is completely separate from the analytics routes:

- Uses Snowflake Cortex Agent REST API (`/api/v2/databases/{DB}/schemas/{SCHEMA}/agents/{NAME}:run`)
- Authentication: JWT generated fresh per request using RSA private key (`RS256`)
- Response: Server-Sent Events (SSE) stream, forwarded directly to browser
- Agent endpoint differs from analytics SQL endpoint — requires the Cortex agent to be deployed in Snowflake

**Environment variables required for chat (beyond base Snowflake config):**
```
CORTEX_AGENT_DATABASE=COCO_SDLC_HOL   # or EVOLV_PERFORMANCE_INTELLIGENCE per .env.example
CORTEX_AGENT_SCHEMA=CLEA              # or MARTS
CORTEX_AGENT_NAME=PAYMENT_ANALYTICS_AGENT  # or PERFORMANCE_INTELLIGENCE_AGENT
```

**Note:** The `.env.example` shows `CORTEX_AGENT_DATABASE=EVOLV_PERFORMANCE_INTELLIGENCE` and `CORTEX_AGENT_SCHEMA=CLEA`, which is different from the analytics routes that use `COCO_SDLC_HOL.MARTS`. These may need to be aligned during UAT.

### Anti-Patterns to Avoid During UAT

- **Restarting the browser between pages**: React Query cache persists within session; use the Refresh button on each page to force a real API call.
- **Assuming UI zeros mean no data**: Zero values may mean the date range has no data, the query worked but returned empty results, or the column name mapping is wrong. Check the network response to distinguish.
- **Testing chat before analytics**: Analytics dependencies (SDK connection) are simpler to debug than Cortex Agent (JWT + REST API). Confirm analytics work first.
- **Ignoring the details tables**: KPI cards show aggregate values (easy to verify wrong), but the details data tables show actual row data — these confirm the query is truly hitting Snowflake.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Connection verification | Custom ping script | `GET /api/metadata` endpoint (already exists) | Returns connection status + domain list; built-in to the app |
| SQL correctness check | New test queries | Snowflake Web UI direct query | Cross-check portal values against Snowflake console |
| Bug tracking | Informal notes | Structured bug report format (domain, endpoint, expected, actual) | Planner needs this to create fix tasks |
| Manual API testing | Custom Postman collection | Browser DevTools Network tab or `curl` | Dev server is running; direct endpoint testing is faster |

---

## Common Pitfalls

### Pitfall 1: Blank .env.local or Missing Variables
**What goes wrong:** Every API call returns 503 with `SNOWFLAKE_NOT_CONFIGURED`. Dashboard shows loading spinners or zeros with no error message.
**Why it happens:** `apps/frontend/.env.local` was not created from `.env.example`, or required variables are blank.
**How to avoid:** Before testing any page, verify `GET http://localhost:3000/api/metadata` returns a JSON object (not an error). If it returns `SNOWFLAKE_NOT_CONFIGURED`, fix `.env.local` first.
**Warning signs:** All 6 KPI cards on home dashboard show 0, no charts render, no loading indicators remain.

### Pitfall 2: Wrong Date Range Returns Empty Data
**What goes wrong:** KPI values show 0 or charts show empty — but the Snowflake connection is healthy.
**Why it happens:** Default date range is last 30 days from current date (2026-02-28). If the MARTS tables have data from a different period, the default range misses it.
**How to avoid:** Check actual date range in MARTS tables using Snowflake Web UI: `SELECT MIN(transaction_date), MAX(transaction_date) FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS`. Then set the date filter in the portal to a range that includes actual data.
**Warning signs:** KPI values are exactly 0 for all domains simultaneously.

### Pitfall 3: Stale Connection Breaks Mid-Session
**What goes wrong:** First few pages work, then later pages return errors or blank data.
**Why it happens:** The singleton connection in `snowflake.ts` has no reconnection logic. Snowflake sessions can time out during development.
**How to avoid:** Restart the Next.js dev server (`Ctrl+C`, `npm run dev`) to force a fresh connection.
**Warning signs:** Pages that loaded data earlier now return 503 errors.

### Pitfall 4: AI Chat Shows Unconfigured Error
**What goes wrong:** Chat page shows "Snowflake connection not configured" despite analytics pages working.
**Why it happens:** Chat requires JWT key-pair authentication (SNOWFLAKE_PRIVATE_KEY or SNOWFLAKE_PRIVATE_KEY_PATH). Analytics routes can fall back to password auth; chat route has no password fallback.
**How to avoid:** Ensure `SNOWFLAKE_PRIVATE_KEY` or `SNOWFLAKE_PRIVATE_KEY_PATH` is set in `.env.local`. Password-only auth does not work for chat.
**Warning signs:** Analytics pages work but chat shows SNOWFLAKE_NOT_CONFIGURED or CORTEX_AGENT_ERROR.

### Pitfall 5: Cortex Agent Name/Database Mismatch
**What goes wrong:** Chat shows `CORTEX_AGENT_ERROR` with a 404 from Snowflake.
**Why it happens:** The Cortex agent URL is constructed as `https://{account}.snowflakecomputing.com/api/v2/databases/{CORTEX_AGENT_DATABASE}/schemas/{CORTEX_AGENT_SCHEMA}/agents/{CORTEX_AGENT_NAME}:run`. If any of these three values don't match the actual deployed agent, Snowflake returns 404.
**How to avoid:** Verify in Snowflake console that a Cortex agent named `{CORTEX_AGENT_NAME}` exists in `{CORTEX_AGENT_DATABASE}.{CORTEX_AGENT_SCHEMA}`. Update `.env.local` to match.
**Warning signs:** Network tab shows POST to cortex chat returning 404 or 403.

### Pitfall 6: Data Shows But Values Seem Wrong
**What goes wrong:** KPI cards show numbers but they don't match expected business values.
**Why it happens:** Column name mapping in the route handler may not align with actual MARTS column names. Example: route expects `TOTAL_TRANSACTIONS` but MARTS uses a different column name.
**How to avoid:** Cross-check one KPI value in Snowflake Web UI: `SELECT COUNT(*) FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS WHERE transaction_date BETWEEN '2026-01-29' AND '2026-02-28'`. Compare with portal display.
**Warning signs:** Numbers display but are obviously wrong (authorization count is 1, net settlement is exactly $0.00).

### Pitfall 7: React Query Cache Serves Stale Data
**What goes wrong:** You fix a bug, reload the page, but see the same wrong data.
**Why it happens:** React Query caches responses for 5 minutes. The stale cache is served without a real API call.
**How to avoid:** Use the "Refresh" button on each page (calls `refetch()`), or hard-reload with `Ctrl+Shift+R` to bypass the React Query cache.
**Warning signs:** Network tab shows no API requests when navigating between pages.

---

## Code Examples

These are actual patterns from the codebase, useful for diagnosing bugs.

### How to Directly Test an Endpoint (Isolate UI vs. API)
```bash
# Test authorization KPIs directly
curl "http://localhost:3000/api/analytics/authorization/kpis?startDate=2026-01-01&endDate=2026-02-28"

# Expected success response shape:
# { "success": true, "data": { "totalTransactions": 12345, "approvalRate": 94.5, ... }, "filters": {...} }

# Expected misconfiguration response:
# { "success": false, "error": "Snowflake connection not configured", "code": "SNOWFLAKE_NOT_CONFIGURED" }

# Test connection + metadata
curl "http://localhost:3000/api/metadata"
```

### How to Identify the Correct Data Range in Snowflake
```sql
-- Run in Snowflake Web UI to find date ranges in MARTS tables
SELECT
  'AUTHORIZATIONS' as table_name,
  MIN(transaction_date) as min_date,
  MAX(transaction_date) as max_date,
  COUNT(*) as total_rows
FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS
UNION ALL
SELECT
  'SETTLEMENTS',
  MIN(settlement_date),
  MAX(settlement_date),
  COUNT(*)
FROM COCO_SDLC_HOL.MARTS.SETTLEMENTS
-- ... repeat for other tables
```

### Error Response Pattern (All Analytics Routes)
All analytics routes return this shape on failure (HTTP 503):
```json
{
  "success": false,
  "error": "Failed to connect to Snowflake",
  "message": "Unable to retrieve authorization data...",
  "details": "<raw error string>",
  "code": "SNOWFLAKE_CONNECTION_ERROR"
}
```
The `details` field contains the raw Snowflake error — useful for diagnosis even though it's a security concern (addressed in Phase 3).

### How React Query Cache Behaves
```typescript
// From lib/providers.tsx - cache configuration
// staleTime: 5 minutes — data is considered fresh for 5 min after fetch
// gcTime: 10 minutes — cache entry removed 10 min after component unmounts
// retry: 1 — retries once on failure before showing error state
// refetchOnWindowFocus: false — does NOT refetch when you alt-tab back
```

---

## UAT Walkthrough Script

The planner should use this as the basis for UAT tasks.

### Pre-Flight Checklist
1. Confirm `apps/frontend/.env.local` exists with valid Snowflake credentials
2. Start dev server: `cd apps/frontend && npm run dev`
3. Confirm server starts without errors (watch for TypeScript compile errors)
4. Test connection: `GET http://localhost:3000/api/metadata` — must return 200 with domain list
5. Verify date range coverage: run the date range SQL in Snowflake Web UI to know what dates have data

### Domain-by-Domain Walkthrough

**Home Dashboard (UAT-01)**
- Navigate to `http://localhost:3000/`
- Verify all 6 KPI cards load with non-zero values
- Verify 6 domain cards are visible and clickable
- Verify Alerts section shows chargeback/retrieval/adjustment values
- Check network tab: 6 KPI API calls should all return 200 with `success: true`

**Authorization (UAT-02)**
- Navigate to `/analytics/authorization`
- Verify KPI row (total transactions, approval rate, total amount, avg ticket size)
- Verify timeseries chart renders with data points
- Verify by-brand breakdown shows card brand breakdown
- Verify declines tab/section loads decline data
- Verify details table shows row-level transaction records
- Check all 5 network calls return 200 with non-empty data arrays

**Settlement (UAT-03)**
- Navigate to `/analytics/settlement`
- Verify KPI row (net settlement volume, transaction counts)
- Verify by-merchant breakdown shows merchant data
- Verify timeseries chart renders
- Verify details table has row data

**Funding (UAT-04)**
- Navigate to `/analytics/funding`
- Verify KPI row (total deposits, deposit count)
- Verify timeseries chart renders
- Verify details table has row data

**Chargeback (UAT-05)**
- Navigate to `/analytics/chargeback`
- Verify KPI row (total chargebacks, open count, dispute amount)
- Verify by-reason breakdown shows reason codes
- Verify details table has row data

**Retrieval (UAT-06)**
- Navigate to `/analytics/retrieval`
- Verify KPI row (total retrievals, open count)
- Verify details table has row data

**Adjustment (UAT-07)**
- Navigate to `/analytics/adjustment`
- Verify KPI row (net adjustment, total adjustments)
- Verify details table has row data

**AI Chat (UAT-08)**
- Navigate to `/chat`
- Type: "What is my approval rate for the last 30 days?"
- Verify response streams in (SSE events visible in network tab)
- Verify response is contextually relevant (mentions transactions, percentages, or payment data)
- Note: Response time may be 5-30 seconds for Cortex Agent

### Bug Report Format
When a bug is found, document it as:
```
DOMAIN: [Home / Authorization / Settlement / ...]
ENDPOINT: [/api/analytics/... or /chat]
EXPECTED: [What should appear]
ACTUAL: [What actually appears]
NETWORK: [HTTP status, response body excerpt]
SEVERITY: [Blocker / Major / Minor]
```

---

## State of the Art

| Aspect | Current State | UAT Impact |
|--------|--------------|------------|
| Connection pooling | Singleton (no reconnect) | Must restart dev server if connection drops |
| Error handling | Returns `details: String(error)` in error bodies | Useful for diagnosis; security concern deferred to Phase 3 |
| Date range default | Last 30 days from today | May miss MARTS data depending on when data was loaded |
| React Query cache | 5-min stale, no window-focus refetch | Use Refresh button to force reload during UAT |
| Cortex Agent auth | JWT per request, no caching | New JWT generated on each chat message |

---

## Open Questions

1. **What date range has actual data in MARTS?**
   - What we know: MARTS tables exist and were built from CLX raw data; queries use `transaction_date`, `settlement_date`, etc.
   - What's unclear: The actual date range of data loaded. Default range (last 30 days from today: 2026-01-29 to 2026-02-28) may not overlap with loaded data.
   - Recommendation: Run the date range diagnostic SQL in Snowflake Web UI as the first step of UAT.

2. **Which Cortex Agent name is correct?**
   - What we know: Code default is `PAYMENT_ANALYTICS_AGENT`; `.env.example` shows `PERFORMANCE_INTELLIGENCE_AGENT`; env var `CORTEX_AGENT_NAME` controls this.
   - What's unclear: Which agent name is actually deployed in the Snowflake account.
   - Recommendation: Check the Snowflake console → Cortex Agents list. Update `CORTEX_AGENT_NAME` in `.env.local` to match.

3. **Is the Cortex Agent configured in COCO_SDLC_HOL.MARTS or EVOLV_PERFORMANCE_INTELLIGENCE.CLEA?**
   - What we know: `.env.example` uses `EVOLV_PERFORMANCE_INTELLIGENCE` / `CLEA`; code default uses `COCO_SDLC_HOL` / `CLEA`.
   - What's unclear: The actual database.schema where the Cortex agent is deployed.
   - Recommendation: Verify in Snowflake during pre-flight. The mismatch between `.env.example` and code defaults is a known inconsistency to resolve.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection:
  - `apps/frontend/src/lib/snowflake.ts` — connection lifecycle, query execution, isConfigured() logic
  - `apps/frontend/src/app/api/analytics/authorization/kpis/route.ts` — representative API route pattern (all domains follow same structure)
  - `apps/frontend/src/app/api/cortex/chat/route.ts` — JWT generation, Cortex Agent SSE streaming
  - `apps/frontend/src/app/page.tsx` — home dashboard component, all 6 KPI hooks
  - `apps/frontend/.env.example` — required environment variables
  - `apps/frontend/package.json` — dependencies and npm scripts
- `.planning/codebase/ARCHITECTURE.md` — data flow, endpoint map
- `.planning/codebase/CONCERNS.md` — known bugs and fragile areas
- `.planning/codebase/STACK.md` — dependency versions
- `.planning/REQUIREMENTS.md` — UAT requirement definitions

### Secondary (MEDIUM confidence)
- `.planning/codebase/TESTING.md` — confirms no automated tests exist; manual UAT is the only verification method

### Tertiary (LOW confidence)
- None — all findings are from direct source code inspection.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — confirmed from package.json and source files
- Architecture patterns: HIGH — confirmed from source code inspection of actual route files
- Pitfalls: HIGH — identified from actual code issues in CONCERNS.md and snowflake.ts
- UAT walkthrough script: HIGH — derived from actual endpoint structure and component code

**Research date:** 2026-02-28
**Valid until:** This is for a specific snapshot of the codebase; valid as long as codebase has not changed. Architecture is stable for the 2-day milestone window.
