import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_SETTLEMENTS } from '@/lib/config';

// GET /api/analytics/settlement/timeseries - Get settlement timeseries data
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view settlement data.',
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
        settlement_date as date,
        SUM(sales_count) as sales_count,
        SUM(sales_amount) as sales_amount,
        SUM(refund_count) as refund_count,
        SUM(refund_amount) as refund_amount,
        SUM(net_amount) as net_amount,
        SUM(discount_amount) as interchange
      FROM ${FULL_TABLE_SETTLEMENTS}
      WHERE settlement_date BETWEEN ? AND ?
      GROUP BY settlement_date
      ORDER BY settlement_date
    `;

    const result = await executeQuery(sql, binds);

    const data = result.rows.map(row => ({
      date: row.DATE,
      salesCount: Number(row.SALES_COUNT) || 0,
      salesAmount: Number(row.SALES_AMOUNT) || 0,
      refundCount: Number(row.REFUND_COUNT) || 0,
      refundAmount: Number(row.REFUND_AMOUNT) || 0,
      netAmount: Number(row.NET_AMOUNT) || 0,
      interchange: Number(row.INTERCHANGE) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Settlement timeseries error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve settlement timeseries. Please check your connection and try again.',
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
