import { NextRequest, NextResponse } from 'next/server';
import { confluence } from '@/lib/atlassian';

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const cql = searchParams.get('cql');
    const spaceKey = searchParams.get('spaceKey');
    const limit = parseInt(searchParams.get('limit') || '25', 10);

    if (cql) {
      const result = await confluence.searchContent(cql, limit);
      return NextResponse.json(result);
    }

    if (spaceKey) {
      const result = await confluence.getSpacePages(spaceKey, limit);
      return NextResponse.json(result);
    }

    return NextResponse.json(
      { error: 'Either cql or spaceKey parameter is required' },
      { status: 400 }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { spaceKey, title, content } = body;

    if (!spaceKey || !title || !content) {
      return NextResponse.json(
        { error: 'spaceKey, title, and content are required' },
        { status: 400 }
      );
    }

    const page = await confluence.createPage(spaceKey, title, content);
    return NextResponse.json(page, { status: 201 });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
