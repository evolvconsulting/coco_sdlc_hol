import { NextRequest, NextResponse } from 'next/server';
import { jira } from '@/lib/atlassian';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ key: string }> }
) {
  try {
    const { key } = await params;
    const issue = await jira.getIssue(key);
    return NextResponse.json(issue);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.includes('404') ? 404 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
