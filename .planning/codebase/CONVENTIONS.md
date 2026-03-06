# Coding Conventions

**Analysis Date:** 2026-02-28

## Naming Patterns

**Files:**
- React components (TSX): PascalCase (e.g., `ChatWindow.tsx`, `BarChart.tsx`, `DashboardLayout.tsx`)
- API route handlers: lowercase with hyphens in nested paths (e.g., `/api/analytics/authorization/kpis/route.ts`, `/api/cortex/chat/route.ts`)
- Utility/library files: camelCase (e.g., `snowflake.ts`, `cortex.ts`, `providers.tsx`)
- Type definition files: descriptive camelCase (e.g., `domain.ts`)
- Hooks: camelCase with `use` prefix (e.g., `useAnalyticsData.ts`, `useCortexAgent.ts`)

**Functions:**
- React components: PascalCase (exported functions that return JSX)
- Custom hooks: camelCase with `use` prefix (e.g., `useAnalyticsData()`, `useCortexAgent()`)
- Utility functions: camelCase (e.g., `executeQuery()`, `formatSQL()`, `exportToCSV()`)
- Async functions: camelCase, no special prefix (e.g., `sendMessage()`, `getConnection()`)
- Helper functions in components: camelCase (e.g., `getStatusIcon()`, `handleKeyPress()`)

**Variables:**
- State variables: camelCase (e.g., `inputValue`, `isTyping`, `agentStatus`, `messages`)
- Constants: camelCase (e.g., `defaultColors`, `evolvTheme`) or UPPER_SNAKE_CASE for global constants
- Component props interfaces: descriptive PascalCase + `Props` suffix (e.g., `ChatWindowProps`, `BarChartProps`, `UseAnalyticsDataOptions`)
- Types and interfaces: PascalCase (e.g., `Message`, `ContentItem`, `ApiResponse<T>`, `DomainType`)

**Types:**
- Interfaces: PascalCase, semantic names (e.g., `AuthorizationRecord`, `SettlementKPIs`, `QueryResult`)
- Type aliases: PascalCase (e.g., `DomainType`, `VegaLiteSpec`)
- Union types: PascalCase with specific values (e.g., `type DomainType = 'authorization' | 'settlement' | 'funding'`)
- Generic parameters: Single letter or semantic names (e.g., `T` for generic, `K` for keys)

## Code Style

**Formatting:**
- Automatic formatting via Tailwind and Ant Design integration
- Tab indentation: 2 spaces (inferred from codebase)
- Line length: No hard enforced limit observed, but keep readable
- Semicolons: Required at end of statements
- Quotes: Single quotes for strings (`'use client';`), except JSX attribute values
- Trailing commas: Used in multi-line arrays/objects

**Linting:**
- ESLint: `^9` with flat config (`eslint.config.mjs`)
- Extends: `eslint-config-next/core-web-vitals` and `eslint-config-next/typescript`
- Lint command: `npm run lint` in frontend app
- Ignore patterns defined in `eslint.config.mjs`:
  - `.next/**`
  - `out/**`
  - `build/**`
  - `next-env.d.ts`

**TypeScript Configuration:**
- Strict mode: Enabled (`strict: true`)
- Target: ES2017
- Module: ESNext
- Path aliases: `@/*` maps to `./src/*`
- JSX mode: `react-jsx` (automatic runtime)
- Module resolution: `bundler`
- ESModule interop enabled

## Import Organization

**Order:**
1. React imports (`import React from 'react';` or `import type { Metadata } from 'next';`)
2. Next.js core imports (`import { useState } from 'react';`, `import { useRouter } from 'next/navigation';`)
3. Third-party UI library imports (Ant Design, echarts, etc.)
4. Type imports (marked with `import type`)
5. Local/internal imports using path aliases (`@/components`, `@/lib`, `@/hooks`, `@/types`)
6. Style imports (CSS, if present)

**Pattern observed in `src/app/layout.tsx`:**
```typescript
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "@/lib/providers";
import { DashboardLayout } from "@/components/layout";
```

**Path Aliases:**
- `@/app` - Next.js app directory
- `@/components` - Reusable React components
- `@/hooks` - Custom React hooks
- `@/lib` - Utility functions and service modules
- `@/types` - Type definitions and interfaces

**Barrel Files:**
- Used in hooks: `src/hooks/index.ts` re-exports all custom hooks
- Allows importing as: `import { useAnalyticsData, useCortexAgent } from '@/hooks';`

## Error Handling

**Patterns:**
- API routes use structured error responses with `NextResponse.json()`:
  ```typescript
  return NextResponse.json(
    {
      success: false,
      error: 'Error title',
      message: 'User-friendly description',
      code: 'ERROR_CODE',
      details: String(error)
    },
    { status: HTTP_STATUS }
  );
  ```
- Success responses always include `success: true` flag
- Custom error objects extend Error type (e.g., `const err = new Error(msg) as Error & { code?: string };`)
- Try-catch blocks in async operations, especially for external service calls (Snowflake, API routes)
- Error codes are semantic uppercase with underscores (e.g., `SNOWFLAKE_NOT_CONFIGURED`, `QUERY_EXECUTION_ERROR`)
- HTTP status codes used appropriately: 400 (bad request), 503 (service unavailable), 500 (server error)

**Hook error patterns:**
- React Query errors passed through and enriched with custom code property
- Error names checked for specific handling (e.g., `if ((error as Error).name === 'AbortError')`)

## Logging

**Framework:** `console` object (no centralized logging framework)

**Patterns:**
- `console.error()`: For errors in catch blocks, e.g., `console.error('Query execution error:', error)`
- `console.log()`: For debugging SSE streams, parsing results
- Log prefixes: `[SSE]`, `[Query]` style tags in debug logs for context
- Debugging logs include structured data: `console.log('[SSE] Extracted columns from rowType:', columns)`
- No logging in production paths - all logs are for development debugging

## Comments

**When to Comment:**
- Complex logic requires explanation (e.g., RLS (Row-Level Security) enforcement patterns)
- Non-obvious React patterns (e.g., `useImperativeHandle` with refs)
- Section headers for major code blocks
- Security-relevant code always documented
- Limitations and caveats documented (e.g., "simplified for demo - use proper pooling in production")

**JSDoc/TSDoc:**
- Minimal usage observed
- Function signatures use TypeScript types instead of JSDoc type annotations
- No @param, @return tags found in codebase
- Types defined via interfaces for parameters

**Style:**
- Single-line comments: `// Comment`
- Block comments: `/* Multi-line comment */`
- Inline comments sparingly used

## Function Design

**Size:**
- Small, focused functions (10-50 lines typical)
- Larger functions for component rendering (ChatWindow: ~600 lines) justified by JSX content
- Utility functions kept minimal (5-20 lines)

**Parameters:**
- Destructured object parameters for components: `function BarChart({ data, title, height = 300, ...rest })`
- Named parameters over positional: Options objects for functions with multiple optional parameters
- Type annotations required for all parameters
- Default parameter values used: `height = 300`, `enabled: options?.enabled ?? true`

**Return Values:**
- Consistent typing: Generics used for reusable hooks (`useAnalyticsData<T>()`)
- API responses wrapped in `ApiResponse<T>` interface
- Promises explicitly typed: `async function getConnection(): Promise<snowflake.Connection>`
- React components return `JSX.Element` or void
- Hooks return objects with methods/state: `{ messages, isTyping, sendMessage, clearMessages }`

## Module Design

**Exports:**
- Named exports preferred: `export { useCortexAgent } from './useCortexAgent';`
- Default exports for page components: `export default function AuthorizationPage() {}`
- Barrel files (index.ts) re-export from multiple modules for convenience

**Common Patterns:**
- Service modules (snowflake.ts, cortex.ts) export multiple utility functions
- Custom hooks are exported as named exports, usable immediately
- Component files export single default component or multiple named components
- Type definitions exported from dedicated type files (`types/domain.ts`)

**Organization:**
- Related functionality grouped in directories: `components/charts/`, `components/ui/`, `components/layout/`
- API routes organized by domain: `app/api/analytics/{domain}/{endpoint}/route.ts`
- Each route handler is a separate file

## Client vs Server Components

**Client Components:**
- Marked with `'use client';` directive at top of file
- Used for: Interactive components, hooks, event handlers, browser APIs
- Examples: `ChatWindow.tsx`, `DashboardLayout.tsx`, `BarChart.tsx`

**Server Components:**
- Default in Next.js 13+ app directory
- Used for: Page components that don't need interactivity, API route handlers
- Examples: Page components in `app/analytics/*/page.tsx`

## Component Props Pattern

**Interfaces Pattern:**
```typescript
interface BarChartProps {
  data: BarChartDataPoint[];
  title?: string;
  height?: number;
  horizontal?: boolean;
  showLegend?: boolean;
  stacked?: boolean;
  formatValue?: (value: number) => string;
  colors?: string[];
  xAxisLabel?: string;
  yAxisLabel?: string;
}
```

- Optional props marked with `?`
- Callback functions typed: `formatValue?: (value: number) => string`
- Arrays of objects for complex data: `data: BarChartDataPoint[]`
- String unions for enums: Instead of separate boolean flags, use string literals
- Default values provided at function call site

## API Response Wrapper

**Standard pattern across all API routes:**
```typescript
interface ApiResponse<T> {
  success: boolean;
  data: T;
  filters?: Record<string, unknown>;
  rowCount?: number;
  error?: string;
  message?: string;
  code?: string;
}
```

- All successful responses have `success: true`
- All error responses have `success: false`
- Data is always in `data` field for successful responses
- Optional metadata fields for filtering context

---

*Convention analysis: 2026-02-28*
