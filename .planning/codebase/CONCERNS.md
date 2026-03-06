# Codebase Concerns

**Analysis Date:** 2026-02-28

## Tech Debt

**SQL Injection Risk in Query Parameters:**
- Issue: String interpolation used directly in SQL queries with user-provided parameters like card brand and dates
- Files: `apps/frontend/src/app/api/analytics/authorization/kpis/route.ts`, `apps/frontend/src/app/api/analytics/settlement/details/route.ts`, and all other analytics routes
- Impact: Direct SQL injection vulnerability. Malicious input in query parameters could compromise database
- Example: Line 26 in authorization/kpis route: `const cardBrandFilter = cardBrand ? `AND card_brand = '${cardBrand}'` : '';`
- Fix approach: Use parameterized queries/prepared statements in Snowflake SDK instead of string interpolation

**Connection Pool Management is Simplified:**
- Issue: Comment on line 82 of `apps/frontend/src/lib/snowflake.ts` notes "simplified for demo - use proper pooling in production"
- Files: `apps/frontend/src/lib/snowflake.ts` (line 82-88)
- Impact: Single connection reused for all requests; no connection pooling, recycling, or cleanup between requests. Will fail under concurrent load
- Fix approach: Implement proper connection pooling with configurable pool size, timeout, and idle connection cleanup

**Missing Error Response Status Codes:**
- Issue: API routes return success=false in response body but don't always set correct HTTP status codes
- Files: Multiple analytics route handlers (e.g., `apps/frontend/src/app/api/analytics/authorization/timeseries/route.ts`)
- Impact: Client code checking HTTP status may miss actual errors if status is 200 with success=false in body
- Fix approach: Ensure failed queries return appropriate 4xx/5xx HTTP status codes, not 200

**Hardcoded SQL Table Names:**
- Issue: Database and schema names hardcoded in SQL queries throughout analytics routes
- Files: All analytics route files under `apps/frontend/src/app/api/analytics/*/`
- Example: `FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS` (line 37 in authorization/kpis)
- Impact: Difficult to switch environments or databases without code changes
- Fix approach: Move table names to configuration constants in `apps/frontend/src/lib/snowflake.ts`

## Security Considerations

**SQL Sanitization is Incomplete:**
- Risk: `sanitizeSQL()` function in `apps/frontend/src/lib/snowflake.ts` (lines 180-205) blocks DDL/DML statements, but comment-removal regex can be bypassed
- Files: `apps/frontend/src/lib/snowflake.ts` (lines 180-205)
- Current mitigation: Basic regex patterns for dangerous keywords
- Recommendations: Never use string concatenation for SQL. Always use parameterized queries. Remove `sanitizeSQL()` as it provides false security

**JWT Token Generation Missing Expiry Validation:**
- Risk: JWT tokens generated in `apps/frontend/src/app/api/cortex/chat/route.ts` expire in 1 hour (line 66), but no refresh mechanism exists
- Files: `apps/frontend/src/app/api/cortex/chat/route.ts`
- Current mitigation: New token generated per API request
- Recommendations: Implement token refresh for long-running chat sessions; cache tokens with proper TTL

**Private Key Handling Lacks Validation:**
- Risk: Private keys loaded from environment variables without format validation
- Files: `apps/frontend/src/app/api/cortex/chat/route.ts` (lines 24-34), `apps/frontend/src/lib/snowflake.ts` (lines 103-112)
- Current mitigation: Try/catch on key loading, passphrase handling for encrypted keys
- Recommendations: Add schema validation for loaded keys; test passphrase decryption early in startup

**Snowflake Credentials in Error Messages:**
- Risk: Error details exposed to clients may contain Snowflake connection strings or sensitive query information
- Files: All API route files return `details: String(error)` in error responses
- Example: Lines 53, 161 in `apps/frontend/src/app/api/query/route.ts`, line 227 in `apps/frontend/src/app/api/cortex/chat/route.ts`
- Impact: Stack traces and error details sent to frontend could expose schema information, connection details, or query structure
- Recommendations: Log full errors server-side; return generic error messages to clients

**Missing CORS/CSP Headers:**
- Risk: No explicit security headers configured in API responses
- Files: All Next.js API routes
- Current mitigation: Next.js defaults apply
- Recommendations: Add explicit `Access-Control-Allow-Origin`, CSP headers in API responses

## Performance Bottlenecks

**No Result Caching for Repeated Queries:**
- Problem: Analytics endpoints re-query Snowflake for identical parameters on every request
- Files: All files under `apps/frontend/src/app/api/analytics/*/`
- Cause: useAnalyticsData hook (line 22-35 in `apps/frontend/src/hooks/useAnalyticsData.ts`) relies on React Query but API has no caching
- Improvement path: Add caching headers (ETag, Cache-Control) to API responses; implement server-side result caching for common queries

**Large Components Lack Code Splitting:**
- Problem: ChatWindow component is 597 lines (line 1 in `apps/frontend/src/components/chat/ChatWindow.tsx`)
- Files: `apps/frontend/src/components/chat/ChatWindow.tsx`
- Cause: All UI logic, export utilities, rendering, and state management in single file
- Improvement path: Extract export utilities to separate file, split message rendering to sub-components, consider lazy loading large interactive sections

**VegaEmbed Dynamic Import Without Proper Fallback:**
- Problem: Dynamic import of VegaEmbed (line 33-36 in ChatWindow.tsx) shows spinner but no error handling if module fails to load
- Files: `apps/frontend/src/components/chat/ChatWindow.tsx`
- Cause: Dynamic import only has loading state, no error boundary
- Improvement path: Add error state component for failed module loads; add timeout handling

**Inefficient Data Processing in Large Result Sets:**
- Problem: Analytics pages fetch full result sets then render all rows without pagination
- Files: Chart components like `apps/frontend/src/components/charts/BarChart.tsx` (line 43-44)
- Cause: Set operations and data grouping done in memory without limits
- Improvement path: Implement server-side pagination and filtering before returning results

## Fragile Areas

**Hardcoded Configuration in Multiple Places:**
- Files: `apps/frontend/src/app/api/cortex/chat/route.ts` (lines 7-14)
- Why fragile: Database, schema, and agent names repeated across multiple files with no centralized config
- Safe modification: Extract all config to `apps/frontend/src/lib/config.ts`
- Test coverage: Minimal - no tests verify config values match across files

**Date Parameter Parsing Without Validation:**
- Files: `apps/frontend/src/app/api/analytics/authorization/kpis/route.ts` (lines 21-22)
- Why fragile: `searchParams.get()` returns string|null without format validation; passed directly to SQL
- Safe modification: Create date validation utility that checks ISO format before using in queries
- Test coverage: No validation tests exist

**Manual Message History Management:**
- Files: `apps/frontend/src/hooks/useCortexAgent.ts` (lines 94-97)
- Why fragile: Message history passed as array of plain objects; no validation of message structure
- Safe modification: Create MessageHistory type with validation; add guards before accessing message properties
- Test coverage: No tests for message history edge cases (missing role, null content, etc)

**Snowflake Connection State Shared Across Requests:**
- Files: `apps/frontend/src/lib/snowflake.ts` (lines 83-129)
- Why fragile: Global `connectionPool` variable shared across all concurrent requests; connection.destroy() callback doesn't guarantee cleanup
- Safe modification: Use per-request connections or implement proper pool lifecycle management with connection validation on reuse
- Test coverage: No concurrent request tests

## Missing Critical Features

**No Authentication/Authorization:**
- Problem: API endpoints lack user authentication. Anyone with access to the URL can query all data
- Blocks: Row-level security, multi-tenant data isolation, audit logging of data access
- Impacts: `apps/frontend/src/app/api/analytics/*`, `apps/frontend/src/app/api/query/route.ts`, `apps/frontend/src/app/api/cortex/chat/route.ts`

**No Rate Limiting:**
- Problem: No rate limiting on API endpoints; users could flood Snowflake with requests
- Blocks: Protection against abuse, DDoS mitigation
- Impact: All API route files

**No Structured Logging:**
- Problem: Console.error/log calls sprinkled throughout; no correlation IDs, request tracing, or log aggregation
- Blocks: Production debugging, performance monitoring, audit trails
- Impact: 24 files with console statements; see grep output above

**No Data Validation Schema:**
- Problem: No schema validation for API responses from Snowflake; assumes query always returns expected columns
- Blocks: Type safety at runtime, clear contract between frontend and API
- Impact: All analytics route files assuming specific column names without validation

## Test Coverage Gaps

**No Unit Tests:**
- What's not tested: None of the lib utilities have test coverage
- Files: `apps/frontend/src/lib/snowflake.ts`, `apps/frontend/src/lib/cortex.ts`, `apps/frontend/src/hooks/*`
- Risk: Changes to connection handling, JWT generation, or data transformation break silently
- Priority: High - connection and auth code is critical

**No Integration Tests:**
- What's not tested: End-to-end flows like: user sends query → Cortex Agent → executes SQL → returns results
- Files: No test files found in entire codebase
- Risk: Integration issues between components only caught in production
- Priority: High - Cortex Agent integration is complex

**No E2E Tests:**
- What's not tested: User workflows like navigating to dashboard, selecting filters, viewing charts
- Files: Testing framework not configured (no jest.config.js, vitest.config.ts, playwright.config.ts)
- Risk: UI regressions and component interaction bugs
- Priority: Medium - caught during manual testing

**No SQL Query Validation Tests:**
- What's not tested: SQL string generation and parameter interpolation
- Files: All analytics route files
- Risk: SQL injection and syntax errors from bad parameters
- Priority: High - security and correctness critical

---

*Concerns audit: 2026-02-28*
