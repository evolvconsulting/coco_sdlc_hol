# Architecture

**Analysis Date:** 2026-02-28

## Pattern Overview

**Overall:** Client-Server Architecture with Multi-Layer Data Processing

**Key Characteristics:**
- Server-Side Rendering (SSR) enabled via Next.js with API routes for data operations
- Domain-driven analytics with 6 distinct payment processing domains
- Real-time Snowflake integration for data querying
- Medical medallion architecture (staging → intermediate → marts) for data transformation
- Client-side state management via TanStack React Query for efficient data fetching

## Layers

**Presentation Layer:**
- Purpose: User interface rendering and client-side interactions
- Location: `apps/frontend/src/app/` and `apps/frontend/src/components/`
- Contains: Next.js pages, React components, UI elements, charts, and layouts
- Depends on: Backend API routes, hooks for data fetching, type definitions
- Used by: End users accessing the payment analytics dashboard

**API Layer:**
- Purpose: Server-side request handling and data transformation
- Location: `apps/frontend/src/app/api/`
- Contains: Route handlers for analytics endpoints, metadata endpoints, Cortex AI endpoints
- Depends on: Snowflake library (`lib/snowflake.ts`), domain metadata, query builders
- Used by: Frontend pages and components via fetch requests

**Data Access Layer:**
- Purpose: Database connectivity and query execution with security enforcement
- Location: `apps/frontend/src/lib/snowflake.ts`
- Contains: Snowflake SDK wrapper, connection pooling, RLS (Row-Level Security) enforcement, SQL sanitization
- Depends on: Snowflake SDK, environment configuration, file system for key handling
- Used by: API routes to execute domain-specific queries

**Type & Metadata Layer:**
- Purpose: Type definitions and domain configuration
- Location: `apps/frontend/src/types/domain.ts`
- Contains: TypeScript interfaces for all 6 payment domains, KPI types, API response wrappers
- Depends on: Nothing
- Used by: All layers for type safety and consistency

**Data Transformation Layer:**
- Purpose: Transform raw payment data into business-ready analytics
- Location: `packages/dbt/models/`
- Contains: Staging views, intermediate dynamic tables, marts dynamic tables
- Depends on: Snowflake warehouse, CLX raw data
- Used by: Frontend queries via MARTS schema

## Data Flow

**Analytics Data Request Flow:**

1. User navigates to analytics page (e.g., `/analytics/authorization`)
2. Page component renders with `useAnalyticsData` hook
3. Hook constructs URL: `/api/analytics/{domain}/{endpoint}?params=...`
4. API route handler (e.g., `route.ts` in `authorization/kpis/`) receives request
5. Route handler calls `executeQuery()` from `lib/snowflake.ts`
6. Snowflake connection established with JWT or password auth
7. SQL query executed against `COCO_SDLC_HOL.MARTS.{TABLE}` with RLS filter for `CLNT_ID = 'dmcl'`
8. Results transformed to domain-specific type (e.g., `AuthorizationKPIs`)
9. Response wrapped in `ApiResponse<T>` and returned to client
10. React Query caches result (5-minute stale time)
11. Component re-renders with typed data

**Supported Analytics Endpoints:**

| Domain | Endpoints | Tables |
|--------|-----------|--------|
| Authorization | kpis, timeseries, by-brand, declines, details | AUTHORIZATIONS |
| Settlement | kpis, by-merchant, timeseries, details | SETTLEMENTS |
| Funding | kpis, timeseries, details | DEPOSITS |
| Chargeback | kpis, by-reason, details | CHARGEBACKS |
| Retrieval | kpis, details | RETRIEVALS |
| Adjustment | kpis, details | ADJUSTMENTS |

**State Management:**
- Client-side caching via TanStack React Query (`QueryClient` configured in `lib/providers.tsx`)
- Stale time: 5 minutes; gc time: 10 minutes
- Automatic retry on failure (1 attempt)
- No refetch on window focus (optimized for dashboard usage)
- Manual refetch triggers via `refetch()` methods

## Key Abstractions

**Domain Configuration:**
- Purpose: Centralized definition of payment analytics domains
- Examples: `types/domain.ts` defines `DOMAINS` record with configuration for all 6 domains
- Pattern: Record-based lookup for type-safe domain access (e.g., `DOMAINS['authorization']`)

**useAnalyticsData Hook:**
- Purpose: Reusable data fetching pattern for all analytics endpoints
- Location: `hooks/useAnalyticsData.ts`
- Pattern: Generic TypeScript hook wrapping React Query with automatic URL construction and error handling
- Usage: `const data = useAnalyticsData<AuthorizationKPIs>('authorization', 'kpis', params)`

**Snowflake Service:**
- Purpose: Encapsulate all Snowflake interactions with security enforcement
- Location: `lib/snowflake.ts`
- Abstractions:
  - `getConnection()`: Manages connection pooling
  - `executeQuery()`: Executes SELECT queries with error handling
  - `executeQueryWithRLS()`: Adds RLS enforcement layer
  - `sanitizeSQL()`: Prevents SQL injection
  - `isConfigured()`: Runtime configuration validation

**Domain Metadata Registry:**
- Purpose: Single source of truth for domain dimensions, measures, and table mappings
- Location: `app/api/metadata/route.ts`
- Pattern: Static metadata object defining for each domain: tableName, fullTableName, dimensions[], measures[]
- Used by: Metadata endpoint and query builders

## Entry Points

**Home Dashboard:**
- Location: `app/page.tsx`
- Triggers: User navigates to `/` or application loads
- Responsibilities: Display KPI overview, domain cards, alerts, quick questions

**Analytics Domain Pages:**
- Location: `app/analytics/{domain}/page.tsx` (e.g., `authorization/page.tsx`)
- Triggers: User clicks domain card or navigates directly
- Responsibilities: Display domain-specific analytics with filters, tabs, charts, and data grids

**API Routes:**
- Location: `app/api/analytics/{domain}/{endpoint}/route.ts`
- Triggers: Frontend components call `fetch()` to these routes
- Responsibilities: Execute domain-specific queries and return typed results

**Chat/Cortex Page:**
- Location: `app/chat/page.tsx`
- Triggers: User clicks "Ask Your Data" button
- Responsibilities: Enable AI-powered natural language queries against data

**Metadata Endpoint:**
- Location: `app/api/metadata/route.ts`
- Triggers: Application needs domain structure or connection info
- Responsibilities: Return domain metadata, table schemas, connection status

## Error Handling

**Strategy:** Multi-layer error handling with user-facing fallback UI

**Patterns:**

**Connection Errors:**
- Captured at `snowflake.ts` - `isConfigured()` checks at route handler entry
- Error code: `SNOWFLAKE_NOT_CONFIGURED`
- User sees: `<ConnectionError />` component with "Snowflake connection not configured" message
- Recovery: Retry button triggers `refetchAll()` to check if configuration was added

**Query Execution Errors:**
- Captured at Snowflake SDK error callbacks in `executeQuery()`
- Error code: `SNOWFLAKE_CONNECTION_ERROR`
- Wrapped in `ApiResponse` with `success: false`, error message, and code
- React Query treats as error, hook's `error` property populated
- User sees: Component checks `hasError && errorCode` and displays appropriate message

**Validation Errors:**
- SQL sanitization in `sanitizeSQL()` throws on dangerous patterns
- Returns 400 with error message if detected
- Prevents DROP, DELETE, INSERT, UPDATE, ALTER, etc.

**Client-Side Error Handling:**
- Hooks use React Query's error boundary
- Components check `error` property and display fallback UI
- Example: `{hasError && errorCode === 'SNOWFLAKE_NOT_CONFIGURED' ? <ConnectionError /> : null}`

## Cross-Cutting Concerns

**Logging:** Console logging at key points in `lib/snowflake.ts` and route handlers - errors logged with context

**Validation:**
- Type validation via TypeScript (compile-time)
- URL parameter validation in route handlers (runtime)
- SQL sanitization in `lib/snowflake.ts` (runtime)

**Authentication:**
- Snowflake JWT authentication via private key or password
- Configured via environment variables (no embedded credentials)
- Account, user, database, schema, and warehouse determined at connection time

**Row-Level Security:**
- Hard-coded filter for `CLNT_ID = 'dmcl'` in all queries
- Snowflake views enforce additional RLS (e.g., `AUTH_DMCL_V1`)
- Double-layer security: application query filter + view security

**Rate Limiting:** Not implemented - relies on Snowflake connection pooling

**Caching:**
- Server-side: Snowflake dynamic tables refresh on 1-hour lag
- Client-side: React Query 5-minute stale time
- Manual refresh buttons allow immediate data reload

---

*Architecture analysis: 2026-02-28*
