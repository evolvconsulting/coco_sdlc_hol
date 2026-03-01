import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_AUTHORIZATIONS } from '@/lib/config';

// GET /api/analytics/authorization/timeseries - Get authorization timeseries data
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view authorization data.',
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
        transaction_date as date,
        COUNT(*) as transactions,
        SUM(CASE WHEN approval_status = 'Approved' THEN 1 ELSE 0 END) as approved,
        SUM(CASE WHEN approval_status = 'Declined' THEN 1 ELSE 0 END) as declined,
        ROUND(SUM(CASE WHEN approval_status = 'Approved' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as approval_rate,
        SUM(transaction_amount) as amount
      FROM ${FULL_TABLE_AUTHORIZATIONS}
      WHERE transaction_date BETWEEN ? AND ?
      GROUP BY transaction_date
      ORDER BY transaction_date
    `;

    const result = await executeQuery(sql, binds);

    const data = result.rows.map(row => ({
      date: row.DATE,
      transactions: Number(row.TRANSACTIONS) || 0,
      approved: Number(row.APPROVED) || 0,
      declined: Number(row.DECLINED) || 0,
      approvalRate: Number(row.APPROVAL_RATE) || 0,
      amount: Number(row.AMOUNT) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Authorization timeseries error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve authorization timeseries. Please check your connection and try again.',
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
