import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_AUTHORIZATIONS } from '@/lib/config';

// GET /api/analytics/authorization/declines - Get decline reason breakdown
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view decline data.',
          code: 'SNOWFLAKE_NOT_CONFIGURED'
        },
        { status: 503 }
      );
    }

    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('startDate') || getDefaultStartDate();
    const endDate = searchParams.get('endDate') || getDefaultEndDate();

    const binds: (string | number | null)[] = [startDate, endDate];

    const sql = `
      SELECT
        COALESCE(decline_reason, 'Unknown') as reason,
        COUNT(*) as count,
        SUM(transaction_amount) as amount,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
      FROM ${FULL_TABLE_AUTHORIZATIONS}
      WHERE transaction_date BETWEEN ? AND ?
        AND approval_status = 'Declined'
      GROUP BY decline_reason
      ORDER BY count DESC
      LIMIT 10
    `;

    const result = await executeQuery(sql, binds);

    const data = result.rows.map(row => ({
      reason: row.REASON,
      count: Number(row.COUNT) || 0,
      amount: Number(row.AMOUNT) || 0,
      percentage: Number(row.PERCENTAGE) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Authorization declines error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve decline data. Please check your connection and try again.',
        code: 'SNOWFLAKE_CONNECTION_ERROR'
      },
      { status: 503 }
    );
  }
}

function getDefaultStartDate(): string {
  const date = new Date();
  date.setDate(date.getDate() - 30);
  return date.toISOString().split('T')[0];
}

function getDefaultEndDate(): string {
  return new Date().toISOString().split('T')[0];
}
