import { NextResponse } from 'next/server';
import { confluence } from '@/lib/atlassian';

export async function GET() {
  try {
    const spaces = await confluence.getSpaces();
    return NextResponse.json(spaces);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
