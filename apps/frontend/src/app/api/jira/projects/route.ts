import { NextResponse } from 'next/server';
import { jira } from '@/lib/atlassian';

export async function GET() {
  try {
    const projects = await jira.getProjects();
    return NextResponse.json(projects);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
