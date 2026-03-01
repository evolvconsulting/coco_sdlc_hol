import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_ADJUSTMENTS } from '@/lib/config';

// GET /api/analytics/adjustment/kpis - Get adjustment KPIs
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view adjustment data.',
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
        COUNT(*) as total_adjustments,
        SUM(CASE WHEN adjustment_amount >= 0 THEN adjustment_amount ELSE 0 END) as total_credits,
        SUM(CASE WHEN adjustment_amount < 0 THEN ABS(adjustment_amount) ELSE 0 END) as total_debits,
        SUM(adjustment_amount) as net_adjustment,
        COUNT(CASE WHEN adjustment_amount >= 0 THEN 1 END) as credit_count,
        COUNT(CASE WHEN adjustment_amount < 0 THEN 1 END) as debit_count
      FROM ${FULL_TABLE_ADJUSTMENTS}
      WHERE adjustment_date BETWEEN ? AND ?
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
      totalAdjustments: Number(row.TOTAL_ADJUSTMENTS) || 0,
      totalCredits: Number(row.TOTAL_CREDITS) || 0,
      totalDebits: Number(row.TOTAL_DEBITS) || 0,
      netAdjustment: Number(row.NET_ADJUSTMENT) || 0,
      creditCount: Number(row.CREDIT_COUNT) || 0,
      debitCount: Number(row.DEBIT_COUNT) || 0,
    };

    return NextResponse.json({
      success: true,
      data: kpis,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Adjustment KPIs error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve adjustment data. Please check your connection and try again.',
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
    totalAdjustments: 0,
    totalCredits: 0,
    totalDebits: 0,
    netAdjustment: 0,
    creditCount: 0,
    debitCount: 0,
  };
}
