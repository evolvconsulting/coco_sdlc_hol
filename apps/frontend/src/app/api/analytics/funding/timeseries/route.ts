import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_DEPOSITS } from '@/lib/config';

// GET /api/analytics/funding/timeseries - Get funding timeseries data
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view funding data.',
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
        deposit_date as date,
        SUM(deposit_amount) as deposits,
        SUM(net_sales_amount) as net_sales,
        SUM(total_fees_amount) as fees,
        SUM(chargeback_amount) as chargebacks,
        COUNT(*) as funding_count
      FROM ${FULL_TABLE_DEPOSITS}
      WHERE deposit_date BETWEEN ? AND ?
      GROUP BY deposit_date
      ORDER BY deposit_date
    `;

    const result = await executeQuery(sql, binds);

    const data = result.rows.map(row => ({
      date: row.DATE,
      deposits: Number(row.DEPOSITS) || 0,
      netSales: Number(row.NET_SALES) || 0,
      fees: Number(row.FEES) || 0,
      chargebacks: Number(row.CHARGEBACKS) || 0,
      fundingCount: Number(row.FUNDING_COUNT) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Funding timeseries error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve funding timeseries. Please check your connection and try again.',
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
