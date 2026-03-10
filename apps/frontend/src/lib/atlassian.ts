/**
 * Atlassian Cloud API client for Jira and Confluence integration.
 * Uses Basic Auth with email + API token.
 */

const ATLASSIAN_DOMAIN = process.env.ATLASSIAN_DOMAIN;
const ATLASSIAN_EMAIL = process.env.ATLASSIAN_EMAIL;
const ATLASSIAN_API_TOKEN = process.env.ATLASSIAN_API_TOKEN;

function getAuthHeader(): string {
  if (!ATLASSIAN_EMAIL || !ATLASSIAN_API_TOKEN) {
    throw new Error('Atlassian credentials not configured. Set ATLASSIAN_EMAIL and ATLASSIAN_API_TOKEN.');
  }
  const credentials = Buffer.from(`${ATLASSIAN_EMAIL}:${ATLASSIAN_API_TOKEN}`).toString('base64');
  return `Basic ${credentials}`;
}

function getBaseUrl(service: 'jira' | 'confluence'): string {
  if (!ATLASSIAN_DOMAIN) {
    throw new Error('ATLASSIAN_DOMAIN not configured.');
  }
  const domain = ATLASSIAN_DOMAIN.replace(/^https?:\/\//, '').replace(/\/$/, '');
  if (service === 'jira') {
    return `https://${domain}/rest/api/3`;
  }
  return `https://${domain}/wiki/rest/api`;
}

async function atlassianFetch<T>(
  service: 'jira' | 'confluence',
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const url = `${getBaseUrl(service)}${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Authorization': getAuthHeader(),
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Atlassian API error (${response.status}): ${error}`);
  }

  return response.json();
}

// ============================================================================
// Jira API
// ============================================================================

export interface JiraIssue {
  id: string;
  key: string;
  fields: {
    summary: string;
    description?: unknown;
    status: { name: string };
    issuetype: { name: string };
    priority?: { name: string };
    assignee?: { displayName: string; emailAddress: string };
    reporter?: { displayName: string; emailAddress: string };
    created: string;
    updated: string;
  };
}

export interface JiraSearchResult {
  startAt: number;
  maxResults: number;
  total: number;
  issues: JiraIssue[];
}

export const jira = {
  async getIssue(issueKey: string): Promise<JiraIssue> {
    return atlassianFetch<JiraIssue>('jira', `/issue/${issueKey}`);
  },

  async searchIssues(jql: string, maxResults = 50): Promise<JiraSearchResult> {
    return atlassianFetch<JiraSearchResult>('jira', '/search', {
      method: 'POST',
      body: JSON.stringify({ jql, maxResults }),
    });
  },

  async createIssue(projectKey: string, summary: string, issueType: string, description?: string): Promise<JiraIssue> {
    const body = {
      fields: {
        project: { key: projectKey },
        summary,
        issuetype: { name: issueType },
        ...(description && { description: { type: 'doc', version: 1, content: [{ type: 'paragraph', content: [{ type: 'text', text: description }] }] } }),
      },
    };
    return atlassianFetch<JiraIssue>('jira', '/issue', {
      method: 'POST',
      body: JSON.stringify(body),
    });
  },

  async getProjects(): Promise<{ id: string; key: string; name: string }[]> {
    return atlassianFetch('jira', '/project');
  },
};

// ============================================================================
// Confluence API
// ============================================================================

export interface ConfluencePage {
  id: string;
  title: string;
  type: string;
  status: string;
  _links: {
    webui: string;
    self: string;
  };
}

export interface ConfluenceSearchResult {
  results: ConfluencePage[];
  start: number;
  limit: number;
  size: number;
}

export const confluence = {
  async getPage(pageId: string): Promise<ConfluencePage> {
    return atlassianFetch<ConfluencePage>('confluence', `/content/${pageId}`);
  },

  async searchContent(cql: string, limit = 25): Promise<ConfluenceSearchResult> {
    const params = new URLSearchParams({ cql, limit: String(limit) });
    return atlassianFetch<ConfluenceSearchResult>('confluence', `/content/search?${params}`);
  },

  async getSpacePages(spaceKey: string, limit = 25): Promise<ConfluenceSearchResult> {
    const params = new URLSearchParams({ spaceKey, limit: String(limit) });
    return atlassianFetch<ConfluenceSearchResult>('confluence', `/content?${params}`);
  },

  async createPage(spaceKey: string, title: string, body: string): Promise<ConfluencePage> {
    const payload = {
      type: 'page',
      title,
      space: { key: spaceKey },
      body: {
        storage: {
          value: body,
          representation: 'storage',
        },
      },
    };
    return atlassianFetch<ConfluencePage>('confluence', '/content', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async getSpaces(): Promise<{ results: { id: string; key: string; name: string }[] }> {
    return atlassianFetch('confluence', '/space');
  },
};
