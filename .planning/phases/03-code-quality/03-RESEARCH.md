# Phase 3: Code Quality - Research

**Researched:** 2026-02-28
**Domain:** Next.js API route hardening — SQL injection, credential exposure, config centralization, connection lifecycle
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Error response sanitization:** Log full error server-side (`console.error`); return only safe structured info to client (error code + generic message, no credentials, no stack traces, no Snowflake connection details). Remove `details: String(error)` from all API route error responses.

- **Config file organization:** Create `apps/frontend/src/lib/config.ts` as the single source of truth for all DB, schema, and table name references. No hardcoded strings in route files — all must import from config. Env vars remain in `.env.local`; config.ts reads from `process.env` where values should be configurable, uses string constants for names that are fixed per environment.

- **Connection lifecycle:** Per-request connections — each API request creates a new Snowflake connection and destroys it after the query completes. No shared global `connectionPool` variable. Simpler and safer for this phase; pooling is a performance optimization for a later phase.

- **`sanitizeSQL()` disposition:** Remove `sanitizeSQL()` entirely. Parameterized queries eliminate the need for it, and keeping it gives false security confidence. The function's regex approach is documented in CONCERNS.md as bypassable.

### Claude's Discretion

User deferred all implementation decisions to Claude beyond the above locked choices.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CODE-01 | Database, schema, and table names centralized in a single configuration file (not scattered across route files) | Config pattern in Architecture Patterns section; full file inventory in Scope section |
| CODE-02 | API routes return correct HTTP status codes (4xx/5xx) on errors — not 200 with success=false in body | Status code audit in Code Examples; all catch blocks presently return 503 with the right status field but `details` must be removed |
| CODE-03 | Error responses do not expose Snowflake credentials, connection strings, or sensitive query details | `details: String(error)` removal pattern in Code Examples; 21 affected files listed in Scope |
| CODE-04 | SQL queries for user-provided parameters use parameterized queries instead of string interpolation | Snowflake SDK bind syntax verified via Context7; `executeQuery` signature change pattern in Code Examples |
| CODE-05 | Snowflake connection lifecycle properly managed — no shared global connection across concurrent requests | Per-request connection pattern in Architecture Patterns; `connectionPool` global removal plan documented |
</phase_requirements>

---

## Summary

Phase 3 is a targeted hardening pass — no new features, no UI changes. All work is confined to `apps/frontend/src/lib/snowflake.ts`, a new `apps/frontend/src/lib/config.ts`, and 19 analytics API route files. The problems are well-understood, the code is consistent, and the fixes follow straightforward patterns.

The four work streams map cleanly onto the requirements: (1) create config.ts and replace all 19 hardcoded `COCO_SDLC_HOL.MARTS.*` references; (2) audit HTTP status codes across all catch blocks; (3) strip `details: String(error)` from all 21 error-returning files; (4) change `executeQuery` to accept bind parameters and rewrite every route that interpolates user-supplied values into SQL; (5) remove the global `connectionPool` singleton, rewrite `getConnection()` to create-and-destroy per request, and remove the unused `closeConnection()` export.

The Snowflake Node.js SDK natively supports parameterized queries via the `binds` array on `connection.execute()` — confirmed against official docs. No new dependencies are required for any of the five CODE requirements. The biggest complexity risk is the `executeQuery` signature change propagating across 19 call sites; the plan should handle this as a single coordinated wave.

**Primary recommendation:** Implement in this order — config.ts first (CODE-01), then error sanitization (CODE-02/03), then parameterized queries (CODE-04), then connection lifecycle (CODE-05). Each step is independent of the next, so failures are isolated.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| snowflake-sdk | 2.3.4 (already installed) | Parameterized query execution via `binds` array | Official Snowflake Node.js connector — already in use, binds are native |
| TypeScript | 5.x (already installed) | Typed config constants, typed bind arrays | Already in use with strict mode |
| Next.js | 16.1.6 (already installed) | API route hosting | Already in use |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none new) | — | — | All requirements are satisfied with existing dependencies |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native `binds` in snowflake-sdk | A query-builder library (e.g., Knex) | Knex adds a new dep and learning curve; native binds are sufficient and already documented in the SDK |
| Per-request connection destroy | Connection pooling library | Pooling is a Phase 4 performance optimization; per-request is simpler and correct for this milestone |

**Installation:**
```bash
# No new packages required
```

---

## Architecture Patterns

### Recommended Project Structure

After Phase 3, the relevant files are:

```
apps/frontend/src/lib/
├── config.ts          # NEW — single source of truth for DB/schema/table names
├── snowflake.ts       # MODIFIED — no global pool, parameterized executeQuery, no sanitizeSQL
└── providers.tsx      # unchanged

apps/frontend/src/app/api/
├── analytics/         # 19 route files — MODIFIED for config import + parameterized queries + error cleanup
│   ├── authorization/{kpis,timeseries,by-brand,declines,details}/route.ts
│   ├── settlement/{kpis,timeseries,by-merchant,details}/route.ts
│   ├── funding/{kpis,timeseries,details}/route.ts
│   ├── chargeback/{kpis,by-reason,details}/route.ts
│   ├── retrieval/{kpis,details}/route.ts
│   └── adjustment/{kpis,details}/route.ts
├── query/route.ts     # MODIFIED — error sanitization only (SQL comes from trusted AI agent, not user form fields)
└── metadata/route.ts  # MODIFIED — import from config.ts instead of inline DATABASE/SCHEMA constants
```

### Pattern 1: Config Module (CODE-01)

**What:** A single TypeScript module that exports all database, schema, and table name constants, reading from environment variables where appropriate.

**When to use:** Any file that needs to reference Snowflake object names.

**Example:**
```typescript
// apps/frontend/src/lib/config.ts
// Source: Project convention + CONTEXT.md locked decision

// Configurable via environment — different values per environment
export const SNOWFLAKE_DATABASE = process.env.SNOWFLAKE_DATABASE || 'COCO_SDLC_HOL';
export const SNOWFLAKE_SCHEMA = process.env.SNOWFLAKE_SCHEMA || 'MARTS';

// Fixed table names — same in all environments for this project
export const TABLE_AUTHORIZATIONS = 'AUTHORIZATIONS';
export const TABLE_SETTLEMENTS = 'SETTLEMENTS';
export const TABLE_DEPOSITS = 'DEPOSITS';
export const TABLE_CHARGEBACKS = 'CHARGEBACKS';
export const TABLE_RETRIEVALS = 'RETRIEVALS';
export const TABLE_ADJUSTMENTS = 'ADJUSTMENTS';

// Computed full references — use these in SQL queries
export const FULL_TABLE_AUTHORIZATIONS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_AUTHORIZATIONS}`;
export const FULL_TABLE_SETTLEMENTS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_SETTLEMENTS}`;
export const FULL_TABLE_DEPOSITS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_DEPOSITS}`;
export const FULL_TABLE_CHARGEBACKS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_CHARGEBACKS}`;
export const FULL_TABLE_RETRIEVALS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_RETRIEVALS}`;
export const FULL_TABLE_ADJUSTMENTS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_ADJUSTMENTS}`;
```

Usage in a route file:
```typescript
// Before (hardcoded):
FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS

// After (config import):
import { FULL_TABLE_AUTHORIZATIONS } from '@/lib/config';
// ...
FROM ${FULL_TABLE_AUTHORIZATIONS}
```

**Note:** `metadata/route.ts` already has a local DATABASE/SCHEMA pattern at the top using `process.env` — it should be refactored to import from `@/lib/config` and drop its own local constants.

### Pattern 2: Parameterized Queries via Snowflake SDK Binds (CODE-04)

**What:** Replace SQL string interpolation for user-supplied values with `?` placeholders and a `binds` array passed to `connection.execute()`.

**Verified:** Official Snowflake Node.js driver docs confirm two syntaxes — question-mark (`?`) and numeric (`:1`, `:2`). The question-mark style is simpler for sequential parameters.

```javascript
// Source: https://docs.snowflake.com/en/developer-guide/node-js/nodejs-driver-execute
connection.execute({
  sqlText: 'SELECT c1 FROM t WHERE c1 = ? AND c2 = ?',
  binds: [value1, value2]
});
```

**Updated `executeQuery` signature in snowflake.ts:**
```typescript
// Before:
export async function executeQuery(sql: string): Promise<QueryResult>

// After:
export async function executeQuery(sql: string, binds?: (string | number | null)[]): Promise<QueryResult>
```

**Inside `executeQuery`, pass binds to execute:**
```typescript
connection.execute({
  sqlText: sql,
  binds: binds || [],
  complete: (err, stmt, rows) => { /* existing handler */ },
});
```

**Route file — before (string interpolation):**
```typescript
const cardBrandFilter = cardBrand ? `AND card_brand = '${cardBrand}'` : '';
const sql = `
  SELECT ...
  FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS
  WHERE transaction_date BETWEEN '${startDate}' AND '${endDate}'
    ${cardBrandFilter}
`;
const result = await executeQuery(sql);
```

**Route file — after (parameterized):**
```typescript
import { FULL_TABLE_AUTHORIZATIONS } from '@/lib/config';

const binds: (string | null)[] = [startDate, endDate];
const cardBrandFilter = cardBrand ? 'AND card_brand = ?' : '';
if (cardBrand) binds.push(cardBrand);

const sql = `
  SELECT ...
  FROM ${FULL_TABLE_AUTHORIZATIONS}
  WHERE transaction_date BETWEEN ? AND ?
    ${cardBrandFilter}
`;
const result = await executeQuery(sql, binds);
```

**Critical detail:** Table names and column names cannot be parameterized in SQL — only values can. The hardcoded `FULL_TABLE_*` constants in SQL templates are correct and safe because they come from the trusted config module, not user input.

### Pattern 3: Per-Request Connection Lifecycle (CODE-05)

**What:** Remove the global `connectionPool` variable. `getConnection()` becomes a private helper that always creates a new connection. After `executeQuery` completes (success or error), the connection is destroyed.

**Updated snowflake.ts connection flow:**
```typescript
// REMOVE: let connectionPool: snowflake.Connection | null = null;

// getConnection() — always creates a fresh connection, not exported
async function createConnection(): Promise<snowflake.Connection> {
  const config = getConfig();
  // ... existing connection options building logic unchanged ...
  return new Promise((resolve, reject) => {
    const connection = snowflake.createConnection(connectionOptions);
    connection.connect((err, conn) => {
      if (err) {
        console.error('Failed to connect to Snowflake:', err);
        reject(err);
      } else {
        resolve(conn);
      }
    });
  });
}

// executeQuery — creates connection, runs query, destroys connection
export async function executeQuery(sql: string, binds?: (string | number | null)[]): Promise<QueryResult> {
  const startTime = Date.now();
  const connection = await createConnection();

  return new Promise((resolve, reject) => {
    connection.execute({
      sqlText: sql,
      binds: binds || [],
      complete: (err, stmt, rows) => {
        const executionTime = Date.now() - startTime;
        // Destroy connection regardless of outcome
        connection.destroy((destroyErr) => {
          if (destroyErr) console.error('Error closing Snowflake connection:', destroyErr);
        });

        if (err) {
          console.error('Query execution error:', err);
          reject(err);
          return;
        }

        const columns = stmt.getColumns()?.map((col) => col.getName()) || [];
        resolve({
          columns,
          rows: (rows as Record<string, unknown>[]) || [],
          rowCount: rows?.length || 0,
          executionTime,
        });
      },
    });
  });
}
```

**Also remove:** The `closeConnection()` export is no longer needed — connections clean up after themselves. Remove it from `snowflake.ts`. Check that nothing imports `closeConnection` before removing.

**Also remove:** `executeQueryWithRLS()` — it only called `sanitizeSQL()` then `executeQuery()`. Since `sanitizeSQL()` is being removed, `executeQueryWithRLS()` becomes a trivial passthrough and can be deleted. Verify no route files import it.

### Pattern 4: Error Response Sanitization (CODE-02 / CODE-03)

**What:** Remove `details: String(error)` from every API error response. The full error is already logged server-side with `console.error()`.

**Before:**
```typescript
catch (error) {
  console.error('Authorization KPIs error:', error);
  return NextResponse.json(
    {
      success: false,
      error: 'Failed to connect to Snowflake',
      message: 'Unable to retrieve authorization data. Please check your connection and try again.',
      details: String(error),        // <-- REMOVE THIS LINE
      code: 'SNOWFLAKE_CONNECTION_ERROR'
    },
    { status: 503 }
  );
}
```

**After:**
```typescript
catch (error) {
  console.error('Authorization KPIs error:', error);
  return NextResponse.json(
    {
      success: false,
      error: 'Failed to connect to Snowflake',
      message: 'Unable to retrieve authorization data. Please check your connection and try again.',
      code: 'SNOWFLAKE_CONNECTION_ERROR'
    },
    { status: 503 }
  );
}
```

**HTTP status code audit (CODE-02):** The existing routes already set `{ status: 503 }` on Snowflake errors and `{ status: 503 }` for not-configured. This is technically correct (service unavailable). The pattern is consistent across all 19 analytics routes. The only place returning 500 is `query/route.ts` for `QUERY_EXECUTION_ERROR` and `INTERNAL_ERROR` — those are also correct. **No status code changes are required beyond the error sanitization.** The "200 with success=false" concern in CONCERNS.md was a general risk description; the actual code already sets non-200 status codes on errors.

**Files with `details: String(error)` that need cleanup (21 files):**
```
apps/frontend/src/app/api/analytics/retrieval/details/route.ts
apps/frontend/src/app/api/analytics/retrieval/kpis/route.ts
apps/frontend/src/app/api/analytics/adjustment/details/route.ts
apps/frontend/src/app/api/analytics/chargeback/details/route.ts
apps/frontend/src/app/api/analytics/funding/details/route.ts
apps/frontend/src/app/api/analytics/settlement/details/route.ts
apps/frontend/src/app/api/analytics/authorization/details/route.ts
apps/frontend/src/app/api/cortex/chat/route.ts
apps/frontend/src/app/api/analytics/authorization/by-brand/route.ts
apps/frontend/src/app/api/analytics/authorization/declines/route.ts
apps/frontend/src/app/api/analytics/authorization/kpis/route.ts
apps/frontend/src/app/api/analytics/authorization/timeseries/route.ts
apps/frontend/src/app/api/analytics/chargeback/by-reason/route.ts
apps/frontend/src/app/api/analytics/chargeback/kpis/route.ts
apps/frontend/src/app/api/analytics/funding/kpis/route.ts
apps/frontend/src/app/api/analytics/funding/timeseries/route.ts
apps/frontend/src/app/api/analytics/settlement/by-merchant/route.ts
apps/frontend/src/app/api/analytics/settlement/kpis/route.ts
apps/frontend/src/app/api/analytics/settlement/timeseries/route.ts
apps/frontend/src/app/api/analytics/adjustment/kpis/route.ts
apps/frontend/src/app/api/query/route.ts
```

### Anti-Patterns to Avoid

- **Parameterizing table names:** Table/schema/column names cannot be bound as parameters in SQL — only literal values can. The `FULL_TABLE_*` constants in SQL templates are correct; they are trusted config, not user input.
- **Partial parameterization:** If a route has 3 user-supplied values and only 2 are parameterized, the remaining one is still a vector. All `searchParams.get()` values used in SQL must be bound.
- **Leaving `sanitizeSQL()` as a "belt-and-suspenders" measure:** The CONTEXT.md is explicit — remove it. Keeping it creates false confidence and the regex is bypassable.
- **Destroying connection before query completes:** Connection destroy must happen inside the `complete` callback, not after the Promise resolves, or the connection may be destroyed while the query is still streaming.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SQL injection prevention | Custom sanitizer regex | Snowflake SDK `binds` array | Parameterized queries are the only reliable protection; regex can be bypassed (documented in CONCERNS.md) |
| Connection management | Custom pool/singleton | Per-request create+destroy via snowflake-sdk | The SDK handles connect/disconnect lifecycle correctly; a custom singleton is what created the bug |
| Config management | Dynamic config loading or environment schema validation | Simple TypeScript constants that read `process.env` | No runtime config schema validation needed for this milestone; keep it simple |

**Key insight:** Every "custom solution" in this codebase (sanitizeSQL, connectionPool singleton) created the exact vulnerabilities being fixed in Phase 3. The SDK's built-in parameterized query support is the right tool.

---

## Common Pitfalls

### Pitfall 1: `binds` Array Order Must Match `?` Placeholder Order

**What goes wrong:** The `binds` array is positional — the first `?` gets `binds[0]`, the second gets `binds[1]`. If a route conditionally adds a filter (e.g., `cardBrand` is optional), the bind array must be built to match the exact number and order of `?` placeholders in the final SQL string.

**Why it happens:** Routes build WHERE clauses dynamically by concatenating optional filter strings. When a filter is absent, its `?` is not in the SQL, but if the bind was already pushed to the array, the positions shift.

**How to avoid:** Build the SQL fragment and push to the binds array in the same conditional block:
```typescript
const binds: (string | number | null)[] = [startDate, endDate]; // always present
let cardBrandFilter = '';
if (cardBrand) {
  cardBrandFilter = 'AND card_brand = ?';
  binds.push(cardBrand);
}
```
Never push to binds unconditionally when the SQL placeholder is conditional.

**Warning signs:** Query returns no results when a filter is applied, or Snowflake returns a "wrong number of binds" error.

### Pitfall 2: `limit` and `offset` Are Numbers, Not Strings

**What goes wrong:** `parseInt(searchParams.get('limit') || '100')` returns a number. The Snowflake SDK `binds` array accepts numbers and strings. However, LIMIT and OFFSET in SQL cannot be parameterized in all contexts — Snowflake may require literal integers for LIMIT/OFFSET.

**Why it happens:** LIMIT and OFFSET are structural SQL clauses, not data values. Some SQL engines reject parameterized LIMIT/OFFSET.

**How to avoid:** Keep `LIMIT` and `OFFSET` as validated integer literals in the SQL string, not as bind parameters. Since they come from trusted query params parsed with `parseInt()`, they are numbers, not arbitrary strings. Validate they are non-negative integers before injecting:
```typescript
const limit = Math.max(1, Math.min(1000, parseInt(searchParams.get('limit') || '100')));
const offset = Math.max(0, parseInt(searchParams.get('offset') || '0'));
// Then in SQL: LIMIT ${limit} OFFSET ${offset}  — safe because limit/offset are validated integers
```

**Warning signs:** Snowflake error on queries with parameterized LIMIT.

### Pitfall 3: Forgetting `details` in `cortex/chat/route.ts`

**What goes wrong:** The grep found `details: String(error)` in `apps/frontend/src/app/api/cortex/chat/route.ts`. This file is not an analytics route — it is the AI chat route. It is easy to miss when updating only the "analytics" routes.

**Why it happens:** The cortex route lives outside the `analytics/` directory and has a different structure. Mechanical updates to analytics routes may skip it.

**How to avoid:** The file list above includes it explicitly. The plan should treat cortex/chat/route.ts as a distinct task item, not assume it is covered by the analytics route sweep.

### Pitfall 4: `executeQueryWithRLS` May Still Be Referenced

**What goes wrong:** `executeQueryWithRLS` wraps `sanitizeSQL` + `executeQuery`. After removing `sanitizeSQL`, this function is a trivial passthrough. Removing it requires confirming nothing imports it.

**Why it happens:** It is exported from snowflake.ts and could be imported by any route.

**How to avoid:**
```bash
grep -r "executeQueryWithRLS" apps/frontend/src/
```
If no files import it, remove it safely. If any do, change those imports to `executeQuery` first.

### Pitfall 5: `closeConnection` Export Still Referenced Somewhere

**What goes wrong:** The global `connectionPool` singleton was managed by the exported `closeConnection()`. Removing both means any caller of `closeConnection()` will have a compile error.

**Why it happens:** The function is exported and could be used in application shutdown logic or test files.

**How to avoid:** Grep for `closeConnection` imports before removing:
```bash
grep -r "closeConnection" apps/frontend/src/
```
If nothing imports it, remove safely.

### Pitfall 6: `getTableMetadata` in snowflake.ts Has Its Own Hardcoded References

**What goes wrong:** `getTableMetadata()` (lines 210-236 of snowflake.ts) reads `process.env.SNOWFLAKE_DATABASE` and `process.env.SNOWFLAKE_SCHEMA` inline, and interpolates `tableName` directly into SQL. This function is technically outside the analytics route scope but is in the file being refactored.

**Why it happens:** It was written with the same "inline env reads" pattern as the rest.

**How to avoid:** As part of the snowflake.ts refactor, update `getTableMetadata` to import from `@/lib/config` and use string interpolation (since `tableName` is a trusted internal value, not user input — but validate it is one of the known table names if desired).

---

## Code Examples

Verified patterns from official sources:

### Snowflake SDK Parameterized Query — Question-Mark Style
```javascript
// Source: https://docs.snowflake.com/en/developer-guide/node-js/nodejs-driver-execute
connection.execute({
  sqlText: 'SELECT c1 FROM (SELECT ? AS c1 UNION ALL SELECT ? AS c1) WHERE c1 = ?',
  binds: [1, 2, 1],
  complete: (err, stmt, rows) => { /* ... */ }
});
```

### Full executeQuery Signature After Refactor
```typescript
// apps/frontend/src/lib/snowflake.ts — after CODE-04 + CODE-05 changes
export async function executeQuery(
  sql: string,
  binds?: (string | number | null)[]
): Promise<QueryResult> {
  const startTime = Date.now();
  const connection = await createConnection(); // no longer reads global pool

  return new Promise((resolve, reject) => {
    connection.execute({
      sqlText: sql,
      binds: binds || [],
      complete: (err, stmt, rows) => {
        const executionTime = Date.now() - startTime;
        // Destroy connection before resolving/rejecting
        connection.destroy((destroyErr) => {
          if (destroyErr) console.error('Error closing Snowflake connection:', destroyErr);
        });

        if (err) {
          console.error('Query execution error:', err);
          reject(err);
          return;
        }

        const columns = stmt.getColumns()?.map((col) => col.getName()) || [];
        resolve({
          columns,
          rows: (rows as Record<string, unknown>[]) || [],
          rowCount: rows?.length || 0,
          executionTime,
        });
      },
    });
  });
}
```

### Config Import Pattern in Route File
```typescript
// apps/frontend/src/app/api/analytics/authorization/kpis/route.ts — after CODE-01 + CODE-04
import { FULL_TABLE_AUTHORIZATIONS } from '@/lib/config';

// Build binds array matching ? placeholders in order
const binds: (string | null)[] = [startDate, endDate];
const cardBrandFilter = cardBrand ? 'AND card_brand = ?' : '';
if (cardBrand) binds.push(cardBrand);

const sql = `
  SELECT
    COUNT(*) as total_transactions,
    ...
  FROM ${FULL_TABLE_AUTHORIZATIONS}
  WHERE transaction_date BETWEEN ? AND ?
    ${cardBrandFilter}
`;
const result = await executeQuery(sql, binds);
```

---

## Scope Inventory

### Files Requiring Changes

**New file (CODE-01):**
- `apps/frontend/src/lib/config.ts` — create

**Heavy refactor (CODE-04 + CODE-05, plus CODE-01 + CODE-03):**
- `apps/frontend/src/lib/snowflake.ts` — remove global pool, add binds param, remove sanitizeSQL/executeQueryWithRLS/closeConnection

**Config import only (CODE-01):**
- `apps/frontend/src/app/api/metadata/route.ts` — replace local DATABASE/SCHEMA constants with config import

**Full route treatment (CODE-01 + CODE-03 + CODE-04) — 19 files:**
```
authorization/kpis, timeseries, by-brand, declines, details  (5 files)
settlement/kpis, timeseries, by-merchant, details            (4 files)
funding/kpis, timeseries, details                            (3 files)
chargeback/kpis, by-reason, details                         (3 files)
retrieval/kpis, details                                      (2 files)
adjustment/kpis, details                                     (2 files)
```

**Error sanitization only (CODE-03) — outside analytics:**
- `apps/frontend/src/app/api/cortex/chat/route.ts` — remove `details: String(error)` only
- `apps/frontend/src/app/api/query/route.ts` — remove `details: String(error)` (SQL from trusted AI agent, not raw user form input, so parameterized query refactor is lower priority here; confirm with codebase review)

### User-Supplied Parameters by Route Type

Every analytics route has `startDate` and `endDate` from `searchParams.get()`. These are always parameterized.

Optional user-supplied filters (also parameterize):
- `cardBrand` — authorization routes
- `status` — authorization/details, chargeback/details
- `limit`, `offset` — details routes (use validated integer literals in SQL, not binds — see Pitfall 2)

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| SQL string interpolation | Snowflake SDK `binds` array | SDK has supported binds since initial Node.js driver release |
| Global connection singleton | Per-request create+destroy | Appropriate for low-concurrency server; pool is a Phase 4 optimization |
| `sanitizeSQL()` regex | Parameterized queries (eliminates need) | Regex sanitizers are universally considered insufficient — parameterization is the correct solution |
| Inline `process.env` reads scattered across routes | Centralized `config.ts` | Standard Next.js pattern: centralize config, import where needed |

---

## Open Questions

1. **Does `query/route.ts` need parameterized query treatment?**
   - What we know: The SQL in this route comes from the AI agent (Cortex), not directly from a user-typed form field. The AI constructs the SQL.
   - What's unclear: Whether the AI-generated SQL could contain injection vectors if the AI was prompted adversarially.
   - Recommendation: Apply error sanitization (remove `details: String(error)`) as required for CODE-03. For CODE-04, the Cortex AI generates the SQL — it is arguably more analogous to a trusted query builder than user input. The plan should at minimum remove `details: String(error)` from this file. Parameterized query treatment is secondary and can be noted as a future improvement.

2. **`connection.destroy()` callback timing — does it affect returned Promise?**
   - What we know: The `complete` callback fires when query finishes. Calling `connection.destroy()` inside `complete` starts async destruction. The Promise resolves/rejects immediately after.
   - What's unclear: Whether the destroy callback being async creates any edge cases (e.g., the next request tries to create a connection while destroy is still in flight).
   - Recommendation: Per-request connections are independent — there is no shared pool, so concurrent destroy-and-create operations on different connection objects do not interfere. This is safe.

---

## Sources

### Primary (HIGH confidence)
- `/websites/snowflake_en` (Context7) — Snowflake Node.js driver execute with binds, question-mark syntax confirmed at https://docs.snowflake.com/en/developer-guide/node-js/nodejs-driver-execute
- Direct code inspection of `apps/frontend/src/lib/snowflake.ts` — global connectionPool pattern confirmed on lines 83, 85-132
- Direct code inspection of all 19 analytics route files — hardcoded `COCO_SDLC_HOL.MARTS.*` and string interpolation confirmed
- `.planning/codebase/CONCERNS.md` — problem inventory, sanitizeSQL bypass documentation

### Secondary (MEDIUM confidence)
- `.planning/codebase/ARCHITECTURE.md` — data flow, layer descriptions
- `.planning/codebase/CONVENTIONS.md` — naming, error pattern, import order
- `.planning/codebase/STACK.md` — snowflake-sdk 2.3.4 confirmed in use

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps needed; snowflake-sdk binds confirmed via official docs
- Architecture: HIGH — code directly inspected, all 19 + 2 files identified
- Pitfalls: HIGH — based on direct inspection of actual code patterns; pitfalls are specific to this codebase

**Research date:** 2026-02-28
**Valid until:** 2026-03-30 (stable domain; no fast-moving libraries)
