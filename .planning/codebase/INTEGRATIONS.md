# External Integrations

**Analysis Date:** 2026-02-28

## APIs & External Services

**Snowflake Cortex Agent:**
- Service: Snowflake Cortex Agent REST API - Provides natural language query interface to Snowflake data
  - SDK/Client: Custom fetch-based client in `src/lib/cortex.ts`
  - Configuration: `CORTEX_API_URL` environment variable (defaults to `/api/cortex`)
  - Authentication: Implicit (leverages Snowflake JWT)
  - Endpoints: `/api/cortex/chat` (standard), `/api/cortex/chat/stream` (streaming with SSE)
  - Semantic model: `evolv_payment_analytics`

## Data Storage

**Databases:**
- Snowflake (primary production data warehouse)
  - Connection: Environment variables (SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_WAREHOUSE, SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA)
  - Client: snowflake-sdk (Node.js)
  - Authentication methods:
    - Key-pair (JWT) via SNOWFLAKE_PRIVATE_KEY or SNOWFLAKE_PRIVATE_KEY_PATH + SNOWFLAKE_PRIVATE_KEY_PASSPHRASE
    - Password via SNOWFLAKE_PASSWORD
    - Fallback: password authentication if key-pair not available
  - Database: COCO_SDLC_HOL
  - Schemas: MARTS (read queries), STAGING, INTERMEDIATE (dbt transforms)
  - Default warehouse: COMPUTE_WH (API queries)

**File Storage:**
- Local filesystem only - No cloud storage integration detected
- Generated files: Excel exports (xlsx format), PowerPoint presentations (pptxgenjs)

**Caching:**
- ioredis 5.9.3 - Redis client present in dependencies, but usage pattern not detected in codebase
- Client-side caching via React Query: TanStack React Query 5.90.21 manages server state cache, deduplication, and background refetching

## Authentication & Identity

**Auth Provider:**
- None detected - No traditional auth service (Auth0, Firebase, etc.)
- Snowflake authentication: All API calls use Snowflake SDK with JWT or password credentials
- Security model: Single client context (client_id: 'dmcl' hardcoded in dbt config)
- RLS approach: Snowflake views (AUTH_DMCL_V1, etc.) with built-in CLNT_ID filtering
- Query-level validation: SQL sanitization in `src/lib/snowflake.ts` prevents DDL/DML operations

## Monitoring & Observability

**Error Tracking:**
- None detected - No Sentry, DataDog, or similar integration

**Logs:**
- Console logging only - `console.error()` and `console.log()` calls throughout
- Snowflake query logging: `query_tag: dbt_evolv_pi` (visible in Snowflake query history)
- No centralized log aggregation detected

## CI/CD & Deployment

**Hosting:**
- Vercel - Next.js deployment platform (inferred from project structure and `.next/` build artifacts)
- Environment: Serverless Functions (Next.js API Routes)

**CI Pipeline:**
- None detected - No GitHub Actions, GitLab CI, CircleCI configuration found
- Manual deployment to Vercel

## Environment Configuration

**Required env vars:**
- **SNOWFLAKE_ACCOUNT** - Snowflake account identifier (e.g., XLB91549)
- **SNOWFLAKE_USER** - Snowflake username
- **SNOWFLAKE_WAREHOUSE** - Query warehouse (default: COMPUTE_WH)
- **SNOWFLAKE_DATABASE** - Target database (default: COCO_SDLC_HOL)
- **SNOWFLAKE_SCHEMA** - Target schema (default: MARTS)
- **SNOWFLAKE_ROLE** - User role (optional, default: SYSADMIN)
- **CORTEX_API_URL** - Cortex Agent API endpoint (optional, default: /api/cortex)

**Authentication Env Vars (choose one):**
- **SNOWFLAKE_PRIVATE_KEY** - Private key content (escaped newlines, for Vercel)
- **SNOWFLAKE_PRIVATE_KEY_PATH** - Path to private key file (local development)
- **SNOWFLAKE_PRIVATE_KEY_PASSPHRASE** - Passphrase for encrypted private key
- **SNOWFLAKE_PASSWORD** - Fallback password authentication

**Secrets location:**
- `.env.local` file (git-ignored) - Local development
- Vercel Environment Variables dashboard - Production
- Template: `apps/frontend/.env.example`

## Webhooks & Callbacks

**Incoming:**
- None detected - API is read-only

**Outgoing:**
- None detected

## Data Flow

**Analytics Query Flow:**

1. Frontend page loads (e.g., `apps/frontend/src/app/analytics/authorization/page.tsx`)
2. React Query hook calls API route (e.g., `/api/analytics/authorization/kpis`)
3. API route in `apps/frontend/src/app/api/analytics/*/route.ts`:
   - Checks Snowflake configuration (`isConfigured()`)
   - Extracts query parameters (startDate, endDate)
   - Constructs SQL query targeting COCO_SDLC_HOL.MARTS.*
   - Executes via `executeQuery()` using snowflake-sdk
   - Returns JSON response with `success`, `data`, `filters`
4. React Query caches and hydrates component state
5. Components (Ant Design, ECharts) render visualizations

**Cortex Agent Flow (future/experimental):**

1. User sends natural language query via chat interface
2. Fetch request to `/api/cortex/chat` or `/api/cortex/chat/stream`
3. Cortex Agent processes query with semantic model
4. Returns interpreted SQL and/or direct results
5. Streaming variant uses Server-Sent Events (SSE)

## Catalog of APIs

**Analytics APIs (Snowflake-backed):**
- `/api/analytics/authorization/kpis` - Authorization transaction metrics
- `/api/analytics/authorization/timeseries` - Approval/decline trends over time
- `/api/analytics/authorization/by-brand` - Breakdown by card brand
- `/api/analytics/authorization/declines` - Decline reason analysis
- `/api/analytics/authorization/details` - Detailed transaction list
- `/api/analytics/settlement/kpis` - Settlement volume metrics
- `/api/analytics/settlement/timeseries` - Settlement trends
- `/api/analytics/settlement/by-merchant` - Per-merchant breakdown
- `/api/analytics/settlement/details` - Detailed settlement records
- `/api/analytics/funding/kpis` - Deposit metrics
- `/api/analytics/funding/timeseries` - Deposit trends
- `/api/analytics/funding/details` - Funding detail records
- `/api/analytics/chargeback/kpis` - Chargeback metrics
- `/api/analytics/chargeback/by-reason` - Chargeback code breakdown
- `/api/analytics/chargeback/details` - Detailed chargeback records
- `/api/analytics/adjustment/kpis` - Credit/debit adjustment metrics
- `/api/analytics/adjustment/details` - Adjustment records
- `/api/analytics/retrieval/kpis` - Retrieval request metrics
- `/api/analytics/retrieval/details` - Detailed retrieval records

**Cortex APIs (Experimental):**
- `/api/cortex/chat` - Single-request natural language query
- `/api/cortex/chat/stream` - Streaming response (SSE format)

---

*Integration audit: 2026-02-28*
