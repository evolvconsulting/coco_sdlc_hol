# Codebase Structure

**Analysis Date:** 2026-02-28

## Directory Layout

```
coco_sdlc_hol/
├── apps/
│   └── frontend/               # Next.js 16 frontend application
│       ├── src/
│       │   ├── app/            # Next.js App Router pages and API routes
│       │   ├── components/     # React components organized by feature
│       │   ├── hooks/          # Custom React hooks for data fetching
│       │   ├── lib/            # Utility libraries and services
│       │   └── types/          # TypeScript type definitions
│       ├── public/             # Static assets
│       ├── package.json        # Frontend dependencies
│       └── tsconfig.json       # TypeScript configuration
├── packages/
│   ├── database/               # Database utilities (reserved)
│   │   └── utilities/
│   └── dbt/                    # dbt transformation project
│       ├── models/             # dbt models (staging → intermediate → marts)
│       ├── macros/             # dbt macros and custom logic
│       ├── dbt_project.yml     # dbt configuration
│       └── profiles.yml        # Snowflake connection configuration
├── .planning/
│   ├── codebase/              # Codebase mapping documents (you are here)
│   └── phases/                # Phase execution logs
├── .git/                       # Git repository metadata
├── package.json               # Root workspace configuration
└── README.md                  # Project overview

```

## Directory Purposes

**apps/frontend/:**
- Purpose: Single-page analytics dashboard application
- Contains: Next.js pages, components, hooks, services, types
- Key files: `package.json`, `next.config.js`, `tsconfig.json`, `tailwind.config.js`

**apps/frontend/src/app/:**
- Purpose: Next.js App Router directory with pages and API routes
- Contains: Page components and route handlers
- Structure: File-based routing where `/app/page.tsx` = route `/`, `/app/analytics/[domain]/page.tsx` = route `/analytics/{domain}`

**apps/frontend/src/app/api/:**
- Purpose: Server-side API endpoints for data operations
- Contains: Route handlers for analytics queries, metadata, and Cortex chat
- Pattern: `analytics/{domain}/{endpoint}/route.ts` maps to request `/api/analytics/{domain}/{endpoint}`

**apps/frontend/src/components/:**
- Purpose: Reusable React components
- Subdirectories:
  - `charts/`: ECharts-based visualization components (BarChart, GaugeChart, PieChart, TimeSeriesChart)
  - `chat/`: AI chat interface components (ChatWindow, SuggestedQueries)
  - `filters/`: Query filtering components (QueryBuilder)
  - `grid/`: Data table components (DataGrid with ag-Grid)
  - `layout/`: Layout components (DashboardLayout with sidebar navigation)
  - `ui/`: Generic UI components (KPICard, ConnectionError)

**apps/frontend/src/hooks/:**
- Purpose: Custom React hooks for encapsulating data-fetching logic
- Contains: `useAnalyticsData.ts` (generic analytics query hook), `useCortexAgent.ts` (AI chat hook)
- Pattern: Hooks wrap React Query and construct API URLs automatically

**apps/frontend/src/lib/:**
- Purpose: Utility libraries and service modules
- Contents:
  - `snowflake.ts`: Snowflake SDK wrapper with connection pooling, RLS, SQL sanitization
  - `cortex.ts`: Snowflake Cortex AI integration for natural language queries
  - `providers.tsx`: React Context providers (QueryClient, ConfigProvider, AntdRegistry)
  - `theme.ts`: Ant Design and Tailwind theme customization

**apps/frontend/src/types/:**
- Purpose: TypeScript type definitions for all domains
- Contains: `domain.ts` with 50+ interfaces for each payment domain and API responses

**packages/dbt/:**
- Purpose: Data transformation pipeline using medallion architecture
- Contains:
  - `models/staging/`: Views over raw CLX data
  - `models/intermediate/`: Enriched dynamic tables with 1-hour refresh
  - `models/marts/`: Business-ready analytics tables (AUTHORIZATIONS, SETTLEMENTS, DEPOSITS, etc.)
  - `dbt_project.yml`: Model materialization config and variables
  - `profiles.yml`: Snowflake connection settings

**packages/database/:**
- Purpose: Reserved for database utilities (currently minimal)
- Contains: `utilities/` subdirectory for future helper functions

## Key File Locations

**Entry Points:**
- `apps/frontend/src/app/layout.tsx`: Root layout with Providers, DashboardLayout wrapper
- `apps/frontend/src/app/page.tsx`: Home dashboard page (/route)
- `apps/frontend/src/app/analytics/[domain]/page.tsx`: Analytics domain pages (/analytics/{domain})
- `apps/frontend/src/app/chat/page.tsx`: AI chat interface (/chat route)

**Configuration:**
- `apps/frontend/package.json`: Dependencies (Next.js, React, Ant Design, ECharts, Snowflake SDK, React Query)
- `apps/frontend/tsconfig.json`: TypeScript config with path alias `@/*` → `src/*`
- `apps/frontend/tailwind.config.js`: Tailwind CSS configuration
- `apps/frontend/next.config.js`: Next.js build configuration
- `packages/dbt/dbt_project.yml`: dbt model materialization and schema configuration
- `packages/dbt/profiles.yml`: Snowflake account and authentication config

**Core Logic:**
- `apps/frontend/src/lib/snowflake.ts`: All Snowflake connectivity, 260 lines
- `apps/frontend/src/types/domain.ts`: Domain models and interfaces, 320 lines
- `apps/frontend/src/app/api/metadata/route.ts`: Metadata registry and endpoint
- `apps/frontend/src/hooks/useAnalyticsData.ts`: Generic analytics data hook

**Testing:**
- Not present in current codebase (no test files detected)

## Naming Conventions

**Files:**
- Page components: `page.tsx` (Next.js convention, e.g., `app/analytics/authorization/page.tsx`)
- API route handlers: `route.ts` (Next.js convention, e.g., `app/api/analytics/{domain}/{endpoint}/route.ts`)
- Components: PascalCase (e.g., `DashboardLayout.tsx`, `TimeSeriesChart.tsx`)
- Utilities/hooks: camelCase (e.g., `useAnalyticsData.ts`, `snowflake.ts`)
- Types: `domain.ts` or `{feature}.ts` (e.g., `types/domain.ts`)

**Directories:**
- Features: lowercase with hyphens for multi-word names (e.g., `query-builder/`, `data-grid/`)
- Grouped by type: `components/`, `hooks/`, `lib/`, `types/`, `app/`
- API routes mirror domain structure: `api/analytics/{domain}/{endpoint}/`

**Functions:**
- Event handlers: `handle{Action}` (e.g., `handleMenuClick`, `handleDateChange`)
- Data fetchers: `fetch{Entity}` or hooks like `use{Entity}Data`
- Utilities: verb-first or descriptive noun (e.g., `executeQuery`, `sanitizeSQL`, `isConfigured`)

**Variables:**
- React state: descriptive names (e.g., `selectedBrand`, `dateRange`, `activeTab`)
- Constants: UPPER_SNAKE_CASE for config (e.g., `DATABASE`, `SCHEMA`, `RLS_FILTER`)
- Data objects: camelCase (e.g., `kpiData`, `timeSeriesData`, `connectionConfig`)

**Types:**
- Interfaces: PascalCase ending in type hint (e.g., `AuthorizationKPIs`, `SettlementRecord`, `ApiResponse<T>`)
- Type aliases: PascalCase (e.g., `DomainType`)
- Enums: Not used; literals instead (e.g., `type DomainType = 'authorization' | 'settlement' | ...`)

## Where to Add New Code

**New Analytic Domain Feature:**
1. Add domain definition to `types/domain.ts` (interfaces, KPI types, record types)
2. Create API routes in `app/api/analytics/{newDomain}/{endpoints}/route.ts`
3. Create page in `app/analytics/{newDomain}/page.tsx`
4. Add navigation item to `components/layout/DashboardLayout.tsx` menu items
5. Add dbt models in `packages/dbt/models/marts/{newDomain}.sql` (dynamic table)

**New Component:**
- Shared UI component: `components/ui/{ComponentName}.tsx` with barrel export in `components/ui/index.ts`
- Feature-specific component: `components/{featureName}/{ComponentName}.tsx` with barrel export
- Always export from barrel file for consistency (e.g., `import { KPICard } from '@/components/ui'`)

**New API Endpoint (non-analytics):**
- Location: `app/api/{category}/{endpoint}/route.ts`
- Export named handler: `export async function GET(request: NextRequest)` or `POST`, `PUT`, `DELETE`
- Return: `NextResponse.json()` with typed response
- Example: `app/api/cortex/chat/route.ts` for AI chat

**New Hook:**
- Location: `hooks/{hookName}.ts`
- Export hook function: `export function use{HookName}() { ... }`
- Export from barrel: `hooks/index.ts`
- Use React Query for data fetching hooks

**New Utility/Service:**
- Location: `lib/{serviceName}.ts` (for larger services like snowflake.ts)
- Or: `lib/utils/{utilityName}.ts` (for small helper functions)
- Export functions directly (no default exports)

**New dbt Model:**
- Staging (views): `packages/dbt/models/staging/clx/{model}.sql`
- Intermediate (dynamic tables): `packages/dbt/models/intermediate/payments/{model}.sql`
- Marts (dynamic tables): `packages/dbt/models/marts/{domain}.sql`
- Add schema.yml with descriptions and tests

## Special Directories

**apps/frontend/.next/:**
- Purpose: Next.js build output
- Generated: Yes
- Committed: No (in .gitignore)

**apps/frontend/node_modules/:**
- Purpose: npm dependency installations
- Generated: Yes (via npm install)
- Committed: No (in .gitignore)

**packages/dbt/target/:**
- Purpose: dbt compiled SQL and execution artifacts
- Generated: Yes (via dbt run)
- Committed: No (in .gitignore)

**packages/dbt/logs/:**
- Purpose: dbt execution logs
- Generated: Yes (via dbt commands)
- Committed: No (in .gitignore)

**packages/dbt/dbt_packages/:**
- Purpose: dbt external packages (dbt-utils, etc.)
- Generated: Yes (via dbt deps)
- Committed: No (in .gitignore)

**.planning/codebase/:**
- Purpose: Generated codebase analysis documents
- Generated: Yes (by GSD mappers)
- Committed: Yes

**.planning/phases/:**
- Purpose: Phase execution logs and generated code
- Generated: Yes (by GSD executor)
- Committed: Yes (for audit trail)

## Important Path Aliases

**TypeScript path alias configured in `tsconfig.json`:**
- `@/*` → `src/*` (use `@/components`, `@/hooks`, `@/types`, `@/lib`)

**Always use alias paths in imports:**
```typescript
// Good
import { useAnalyticsData } from '@/hooks';
import { DashboardLayout } from '@/components/layout';
import type { AuthorizationKPIs } from '@/types/domain';
import { executeQuery } from '@/lib/snowflake';

// Avoid
import { useAnalyticsData } from '../../../hooks';
import { DashboardLayout } from '../../components/layout';
```

---

*Structure analysis: 2026-02-28*
