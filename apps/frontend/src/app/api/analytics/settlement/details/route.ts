import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_SETTLEMENTS } from '@/lib/config';

// GET /api/analytics/settlement/details - Get settlement detail records
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view settlement details.',
          code: 'SNOWFLAKE_NOT_CONFIGURED'
        },
        { status: 503 }
      );
    }

    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('startDate') || getDefaultStartDate();
    const endDate = searchParams.get('endDate') || getDefaultEndDate();
    const limit = parseInt(searchParams.get('limit') || '100');
    const offset = parseInt(searchParams.get('offset') || '0');

    const binds: (string | number | null)[] = [startDate, endDate];

    const sql = `
      SELECT
        settlement_key,
        settlement_date,
        card_brand,
        merchant_name,
        sales_count,
        sales_amount,
        refund_count,
        refund_amount,
        net_amount,
        discount_amount
      FROM ${FULL_TABLE_SETTLEMENTS}
      WHERE settlement_date BETWEEN ? AND ?
      ORDER BY settlement_date DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql, binds);

    const data = result.rows.map(row => ({
      settleId: row.SETTLEMENT_KEY,
      recordDate: row.SETTLEMENT_DATE,
      cardBrand: row.CARD_BRAND,
      merchantName: row.MERCHANT_NAME,
      salesCount: Number(row.SALES_COUNT) || 0,
      salesAmount: Number(row.SALES_AMOUNT) || 0,
      refundCount: Number(row.REFUND_COUNT) || 0,
      refundAmount: Number(row.REFUND_AMOUNT) || 0,
      netAmount: Number(row.NET_AMOUNT) || 0,
      interchange: Number(row.DISCOUNT_AMOUNT) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      rowCount: result.rowCount,
      filters: { startDate, endDate, limit, offset },
    });
  } catch (error) {
    console.error('Settlement details error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve settlement details. Please check your connection and try again.',
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
