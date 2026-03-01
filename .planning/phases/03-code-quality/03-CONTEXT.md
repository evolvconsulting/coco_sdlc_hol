# Phase 3: Code Quality - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Harden backend API routes against security vulnerabilities and reliability failures before production. Specifically: centralize DB/schema/table name config, fix HTTP status codes and sanitize error responses, replace SQL string interpolation with parameterized queries, and enforce per-request Snowflake connection lifecycle. No new features, no UI changes.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
User deferred all implementation decisions to Claude. The following apply:

- **Error response sanitization:** Log full error server-side (`console.error`); return only safe structured info to client (error code + generic message, no credentials, no stack traces, no Snowflake connection details). Remove `details: String(error)` from all API route error responses.

- **Config file organization:** Create `apps/frontend/src/lib/config.ts` as the single source of truth for all DB, schema, and table name references. No hardcoded strings in route files — all must import from config. Env vars remain in `.env.local`; config.ts reads from `process.env` where values should be configurable, uses string constants for names that are fixed per environment.

- **Connection lifecycle:** Per-request connections — each API request creates a new Snowflake connection and destroys it after the query completes. No shared global `connectionPool` variable. Simpler and safer for this phase; pooling is a performance optimization for a later phase.

- **`sanitizeSQL()` disposition:** Remove `sanitizeSQL()` entirely. Parameterized queries eliminate the need for it, and keeping it gives false security confidence. The function's regex approach is documented in CONCERNS.md as bypassable.

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. The ROADMAP.md success criteria are the acceptance tests:
1. All DB/schema/table references resolve to single config file
2. API error responses return correct HTTP status codes and no Snowflake credentials
3. User-supplied query params use parameterized queries (no string interpolation in SQL)
4. Each API request creates and closes its own Snowflake connection

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `apps/frontend/src/lib/snowflake.ts` — Contains `executeQuery()`, `getConnection()`, `sanitizeSQL()`, and global `connectionPool`. This is the primary file to refactor for CODE-03 and CODE-04.
- `apps/frontend/src/types/domain.ts` — Existing type pattern; new config types can follow same pattern.

### Established Patterns
- All API routes use `NextResponse.json({ success: false, error, message, code }, { status })` for errors — this pattern is correct, just needs `details: String(error)` removed and status codes verified.
- Path alias `@/lib` — config.ts should live here and be imported via `@/lib/config`.

### Integration Points
- All files under `apps/frontend/src/app/api/analytics/*/route.ts` — will need SQL refactor and error response cleanup.
- `apps/frontend/src/app/api/query/route.ts` — custom query endpoint, also needs parameterized query treatment.
- `apps/frontend/src/lib/snowflake.ts` — central point for connection management and query execution changes.

### Problem Inventory (from CONCERNS.md)
- SQL injection: All analytics routes use string interpolation (e.g., `card_brand = '${cardBrand}'`)
- Hardcoded names: `FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS` in all routes
- Credential exposure: `details: String(error)` in all error responses
- Global connection: `connectionPool` in snowflake.ts shared across all requests
- sanitizeSQL(): Lines 180-205 in snowflake.ts — bypassable, creates false security

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-code-quality*
*Context gathered: 2026-02-28*
