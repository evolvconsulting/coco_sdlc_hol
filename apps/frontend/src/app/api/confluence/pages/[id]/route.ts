import { NextRequest, NextResponse } from 'next/server';
import { confluence } from '@/lib/atlassian';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const page = await confluence.getPage(id);
    return NextResponse.json(page);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.includes('404') ? 404 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
