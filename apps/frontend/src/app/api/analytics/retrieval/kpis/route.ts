import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_RETRIEVALS } from '@/lib/config';

// GET /api/analytics/retrieval/kpis - Get retrieval KPIs
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view retrieval data.',
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
        COUNT(*) as total_retrievals,
        SUM(retrieval_amount) as total_amount,
        COUNT(CASE WHEN retrieval_status = 'OPEN' THEN 1 END) as open_count,
        COUNT(CASE WHEN retrieval_status = 'FULFILLED' THEN 1 END) as fulfilled_count,
        COUNT(CASE WHEN retrieval_status = 'EXPIRED' THEN 1 END) as expired_count,
        COUNT(CASE WHEN retrieval_status = 'CLOSED' THEN 1 END) as closed_count,
        ROUND(COUNT(CASE WHEN retrieval_status = 'FULFILLED' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as fulfillment_rate
      FROM ${FULL_TABLE_RETRIEVALS}
      WHERE retrieval_received_date BETWEEN ? AND ?
    `;

    const result = await executeQuery(sql, binds);

    if (result.rows.length === 0) {
      return NextResponse.json({
        success: true,
        data: getEmptyKPIs(),
        filters: { startDate, endDate },
      });
    }

    const row = result.rows[0];
    const kpis = {
      totalRetrievals: Number(row.TOTAL_RETRIEVALS) || 0,
      totalAmount: Number(row.TOTAL_AMOUNT) || 0,
      openCount: Number(row.OPEN_COUNT) || 0,
      fulfilledCount: Number(row.FULFILLED_COUNT) || 0,
      expiredCount: Number(row.EXPIRED_COUNT) || 0,
      closedCount: Number(row.CLOSED_COUNT) || 0,
      fulfillmentRate: Number(row.FULFILLMENT_RATE) || 0,
    };

    return NextResponse.json({
      success: true,
      data: kpis,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Retrieval KPIs error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve retrieval data. Please check your connection and try again.',
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

function getEmptyKPIs() {
  return {
    totalRetrievals: 0,
    totalAmount: 0,
    openCount: 0,
    fulfilledCount: 0,
    expiredCount: 0,
    closedCount: 0,
    fulfillmentRate: 0,
  };
}
