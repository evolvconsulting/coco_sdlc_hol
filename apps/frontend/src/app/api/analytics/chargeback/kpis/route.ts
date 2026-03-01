import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_CHARGEBACKS } from '@/lib/config';

// GET /api/analytics/chargeback/kpis - Get chargeback KPIs
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view chargeback data.',
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
        COUNT(*) as total_chargebacks,
        SUM(dispute_amount) as total_dispute_amount,
        SUM(transaction_amount) as total_transaction_amount,
        COUNT(CASE WHEN chargeback_status = 'OPEN' THEN 1 END) as open_count,
        COUNT(CASE WHEN chargeback_status = 'CLOSED' THEN 1 END) as closed_count,
        COUNT(CASE WHEN outcome = 'WIN' THEN 1 END) as won_count,
        COUNT(CASE WHEN outcome = 'LOSS' THEN 1 END) as lost_count,
        ROUND(COUNT(CASE WHEN outcome = 'WIN' THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN outcome IS NOT NULL THEN 1 END), 0), 2) as win_rate
      FROM ${FULL_TABLE_CHARGEBACKS}
      WHERE dispute_received_date BETWEEN ? AND ?
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
      totalChargebacks: Number(row.TOTAL_CHARGEBACKS) || 0,
      totalDisputeAmount: Number(row.TOTAL_DISPUTE_AMOUNT) || 0,
      totalTransactionAmount: Number(row.TOTAL_TRANSACTION_AMOUNT) || 0,
      openCount: Number(row.OPEN_COUNT) || 0,
      closedCount: Number(row.CLOSED_COUNT) || 0,
      wonCount: Number(row.WON_COUNT) || 0,
      lostCount: Number(row.LOST_COUNT) || 0,
      winRate: Number(row.WIN_RATE) || 0,
    };

    return NextResponse.json({
      success: true,
      data: kpis,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Chargeback KPIs error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve chargeback data. Please check your connection and try again.',
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
    totalChargebacks: 0,
    totalDisputeAmount: 0,
    totalTransactionAmount: 0,
    openCount: 0,
    closedCount: 0,
    wonCount: 0,
    lostCount: 0,
    winRate: 0,
  };
}
