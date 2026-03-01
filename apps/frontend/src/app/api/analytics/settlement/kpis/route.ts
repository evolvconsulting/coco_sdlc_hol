import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_SETTLEMENTS } from '@/lib/config';

// GET /api/analytics/settlement/kpis - Get settlement KPIs
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
        COUNT(*) as total_batches,
        SUM(sales_count) as total_sales_count,
        SUM(sales_amount) as total_sales_amount,
        SUM(refund_count) as total_refund_count,
        SUM(refund_amount) as total_refund_amount,
        SUM(net_amount) as net_volume,
        SUM(discount_amount) as total_interchange
      FROM ${FULL_TABLE_SETTLEMENTS}
      WHERE settlement_date BETWEEN ? AND ?
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
      totalBatches: Number(row.TOTAL_BATCHES) || 0,
      totalSalesCount: Number(row.TOTAL_SALES_COUNT) || 0,
      totalSalesAmount: Number(row.TOTAL_SALES_AMOUNT) || 0,
      totalRefundCount: Number(row.TOTAL_REFUND_COUNT) || 0,
      totalRefundAmount: Number(row.TOTAL_REFUND_AMOUNT) || 0,
      netVolume: Number(row.NET_VOLUME) || 0,
      totalInterchange: Number(row.TOTAL_INTERCHANGE) || 0,
    };

    return NextResponse.json({
      success: true,
      data: kpis,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Settlement KPIs error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve settlement data. Please check your connection and try again.',
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
    totalBatches: 0,
    totalSalesCount: 0,
    totalSalesAmount: 0,
    totalRefundCount: 0,
    totalRefundAmount: 0,
    netVolume: 0,
    totalInterchange: 0,
  };
}
