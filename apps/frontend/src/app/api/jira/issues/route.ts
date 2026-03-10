import { NextRequest, NextResponse } from 'next/server';
import { jira } from '@/lib/atlassian';

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const jql = searchParams.get('jql');
    const maxResults = parseInt(searchParams.get('maxResults') || '50', 10);

    if (!jql) {
      return NextResponse.json({ error: 'jql parameter is required' }, { status: 400 });
    }

    const result = await jira.searchIssues(jql, maxResults);
    return NextResponse.json(result);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { projectKey, summary, issueType, description } = body;

    if (!projectKey || !summary || !issueType) {
      return NextResponse.json(
        { error: 'projectKey, summary, and issueType are required' },
        { status: 400 }
      );
    }

    const issue = await jira.createIssue(projectKey, summary, issueType, description);
    return NextResponse.json(issue, { status: 201 });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
