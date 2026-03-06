# Testing Patterns

**Analysis Date:** 2026-02-28

## Test Framework

**Runner:**
- Not detected - No test runner configuration found
- No `jest.config.js`, `vitest.config.js`, or similar test configuration files

**Assertion Library:**
- Not detected - No testing dependencies in package.json

**Run Commands:**
- Not configured - No test scripts in `apps/frontend/package.json`

## Test File Organization

**Location:**
- Not applicable - No test files found in codebase
- Expected pattern (based on Next.js conventions): Co-located alongside source files or in `__tests__` directories

**Naming:**
- No `.test.ts`, `.test.tsx`, `.spec.ts`, or `.spec.tsx` files detected in `/c/Users/TrentFoley/Source/coco_sdlc_hol/apps/frontend/src/`

**Structure:**
- Test infrastructure not implemented

## Current Testing Status

**Coverage:**
- Zero test coverage - no test files present

**Why Tests May Be Missing:**
1. Early-stage development phase focusing on feature implementation
2. Frontend-heavy application with React components and hooks that require testing setup
3. Next.js application requiring specific test runner configuration
4. May be planned for later phases

## Recommendations for Test Implementation

### Next Steps for Adding Tests

**Framework Selection:**
- **Vitest** (recommended for Next.js): Fast, Vite-native, good for unit tests
- **Jest** (traditional option): Mature, widely compatible with Next.js
- **Playwright** (for E2E): Browser automation for full application testing

**Setup Path for Vitest:**

1. **Install dependencies:**
   ```bash
   npm install -D vitest @vitest/ui @testing-library/react @testing-library/jest-dom
   ```

2. **Create `vitest.config.ts` in `apps/frontend/`:**
   ```typescript
   import { defineConfig } from 'vitest/config';
   import react from '@vitejs/plugin-react';
   import path from 'path';

   export default defineConfig({
     plugins: [react()],
     test: {
       globals: true,
       environment: 'jsdom',
       setupFiles: ['./src/test/setup.ts'],
     },
     resolve: {
       alias: {
         '@': path.resolve(__dirname, './src'),
       },
     },
   });
   ```

3. **Create test setup file `src/test/setup.ts`:**
   ```typescript
   import '@testing-library/jest-dom';
   ```

4. **Update package.json scripts:**
   ```json
   {
     "scripts": {
       "test": "vitest",
       "test:ui": "vitest --ui",
       "test:coverage": "vitest --coverage"
     }
   }
   ```

### Unit Test Patterns to Implement

**Hook Testing Pattern (for `useAnalyticsData.ts`):**

The hook is a data-fetching hook using React Query. Tests should cover:
- Query construction with parameters
- Error handling when fetch fails
- Proper TypeScript generic usage
- Query state management (loading, error, success)

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClientProvider, QueryClient } from '@tanstack/react-query';
import { useAnalyticsData } from '@/hooks/useAnalyticsData';

describe('useAnalyticsData', () => {
  let queryClient: QueryClient;

  beforeEach(() => {
    queryClient = new QueryClient();
  });

  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );

  it('constructs correct API URL with parameters', () => {
    // Test URL construction
  });

  it('handles API errors gracefully', async () => {
    // Mock fetch to return error
  });

  it('respects enabled option', () => {
    // Test that query doesn't run when enabled: false
  });
});
```

**Component Testing Pattern (for `BarChart.tsx`):**

```typescript
import { render, screen } from '@testing-library/react';
import { BarChart } from '@/components/charts/BarChart';

describe('BarChart', () => {
  const mockData = [
    { name: 'A', value: 100 },
    { name: 'B', value: 200 },
  ];

  it('renders with provided data', () => {
    render(<BarChart data={mockData} title="Test Chart" />);
    expect(screen.getByText('Test Chart')).toBeInTheDocument();
  });

  it('applies custom height prop', () => {
    const { container } = render(<BarChart data={mockData} height={500} />);
    // Assert height is applied to echarts container
  });
});
```

**API Route Testing Pattern (for `apps/frontend/src/app/api/query/route.ts`):**

```typescript
import { POST } from '@/app/api/query/route';
import { NextRequest } from 'next/server';

describe('/api/query', () => {
  it('returns error when SQL is missing', async () => {
    const request = new NextRequest('http://localhost:3000/api/query', {
      method: 'POST',
      body: JSON.stringify({}),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.success).toBe(false);
    expect(data.code).toBe('MISSING_SQL');
  });

  it('executes SQL query when Snowflake is configured', async () => {
    // Mock Snowflake connection
    // Test successful query execution
  });
});
```

### What to Test (Priority Order)

**High Priority:**

1. **Custom Hooks (`useAnalyticsData.ts`, `useCortexAgent.ts`):**
   - Query construction and parameters
   - Error handling and recovery
   - State management (loading, error, success states)
   - SSE stream parsing in `useCortexAgent`

2. **API Routes:**
   - Parameter validation (`startDate`, `endDate`, `cardBrand`)
   - Response structure (success/error format)
   - Error codes and HTTP status codes
   - SQL query generation safety

3. **Service Modules (`lib/snowflake.ts`, `lib/cortex.ts`):**
   - Configuration validation
   - Connection pooling behavior
   - SQL sanitization
   - Error handling for external services

**Medium Priority:**

4. **Data Transformation Logic:**
   - Table data rendering in `ChatWindow.tsx` (number formatting, date parsing)
   - Chart data preparation in components

5. **Components (Visual Testing):**
   - `DashboardLayout.tsx` - navigation, layout structure
   - `BarChart.tsx`, `TimeSeriesChart.tsx` - data rendering
   - `ChatWindow.tsx` - message rendering, export functionality

**Lower Priority:**

6. **UI Components (`components/ui/`)** - Mostly pass-through wrappers
7. **Type definitions** - No runtime logic to test

### What NOT to Mock

**Don't mock:**
- React Query's core functionality (use real QueryClient in tests)
- Ant Design components (use real components or shallow render)
- Next.js routing (use proper test utilities)

**Do mock:**
- Network requests (fetch/axios calls)
- Snowflake SDK
- External APIs (Cortex agent endpoint)
- Environment variables

### E2E Testing

**Recommended tool:** Playwright

**Coverage areas:**
1. Authentication flow (if implemented)
2. Navigation between domains (Authorization, Settlement, etc.)
3. Data filtering and date range selection
4. Chat interaction and SQL generation
5. Export functionality (CSV, Excel)

## Testing Best Practices for This Codebase

**For Components:**
- Render with React Query provider context
- Render with Ant Design ConfigProvider
- Test accessibility (ARIA labels)
- Mock `useAnalyticsData` hook in page component tests

**For Hooks:**
- Always wrap with providers in renderHook
- Test with different parameter combinations
- Verify React Query integration

**For API Routes:**
- Mock `executeQuery` from snowflake service
- Test all parameter combinations
- Verify error response structure matches `ApiResponse<T>` interface
- Check SQL injection prevention

**For Service Modules:**
- Mock Snowflake SDK connection
- Test configuration validation
- Verify SQL sanitization blocks dangerous operations

---

*Testing analysis: 2026-02-28*
