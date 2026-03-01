import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_DEPOSITS } from '@/lib/config';

// GET /api/analytics/funding/kpis - Get funding KPIs
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
        COUNT(*) as total_funding_records,
        SUM(deposit_amount) as total_deposits,
        SUM(net_sales_amount) as total_net_sales,
        SUM(total_fees_amount) as total_fees,
        SUM(chargeback_amount) as total_chargebacks,
        COUNT(CASE WHEN payment_status = 'COMPLETED' THEN 1 END) as completed_count,
        COUNT(CASE WHEN payment_status = 'PENDING' THEN 1 END) as pending_count,
        COUNT(CASE WHEN payment_status = 'HELD' THEN 1 END) as held_count
      FROM ${FULL_TABLE_DEPOSITS}
      WHERE deposit_date BETWEEN ? AND ?
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
      totalFundingRecords: Number(row.TOTAL_FUNDING_RECORDS) || 0,
      totalDeposits: Number(row.TOTAL_DEPOSITS) || 0,
      totalNetSales: Number(row.TOTAL_NET_SALES) || 0,
      totalFees: Number(row.TOTAL_FEES) || 0,
      totalChargebacks: Number(row.TOTAL_CHARGEBACKS) || 0,
      completedCount: Number(row.COMPLETED_COUNT) || 0,
      pendingCount: Number(row.PENDING_COUNT) || 0,
      heldCount: Number(row.HELD_COUNT) || 0,
    };

    return NextResponse.json({
      success: true,
      data: kpis,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Funding KPIs error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve funding data. Please check your connection and try again.',
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
    totalFundingRecords: 0,
    totalDeposits: 0,
    totalNetSales: 0,
    totalFees: 0,
    totalChargebacks: 0,
    completedCount: 0,
    pendingCount: 0,
    heldCount: 0,
  };
}
