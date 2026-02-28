'use client';

import { useQuery } from '@tanstack/react-query';
import type { ApiResponse } from '@/types/domain';

interface UseAnalyticsDataOptions {
  enabled?: boolean;
}

export function useAnalyticsData<T>(
  domain: string,
  endpoint: string,
  params: Record<string, string | undefined>,
  options?: UseAnalyticsDataOptions,
) {
  const filteredParams = Object.fromEntries(
    Object.entries(params).filter(([, v]) => v !== undefined && v !== null),
  );
  const queryString = new URLSearchParams(filteredParams as Record<string, string>).toString();
  const url = `/api/analytics/${domain}/${endpoint}${queryString ? `?${queryString}` : ''}`;

  return useQuery<T, Error>({
    queryKey: [domain, endpoint, filteredParams],
    queryFn: async () => {
      const res = await fetch(url);
      const json: ApiResponse<T> = await res.json();
      if (!json.success) {
        const err = new Error(json.message || json.error || 'API request failed') as Error & { code?: string };
        err.code = json.code;
        throw err;
      }
      return json.data;
    },
    enabled: options?.enabled ?? true,
  });
}
