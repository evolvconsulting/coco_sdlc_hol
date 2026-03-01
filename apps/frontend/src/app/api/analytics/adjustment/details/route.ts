import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_ADJUSTMENTS } from '@/lib/config';

// GET /api/analytics/adjustment/details - Get adjustment detail records
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view adjustment details.',
          code: 'SNOWFLAKE_NOT_CONFIGURED'
        },
        { status: 503 }
      );
    }

    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('startDate') || getDefaultStartDate();
    const endDate = searchParams.get('endDate') || getDefaultEndDate();
    const type = searchParams.get('type'); // 'credit' or 'debit'
    const limit = parseInt(searchParams.get('limit') || '100');
    const offset = parseInt(searchParams.get('offset') || '0');

    const binds: (string | number | null)[] = [startDate, endDate];
    let whereClause = 'WHERE adjustment_date BETWEEN ? AND ?';

    // type filter uses numeric comparison — no user string interpolated into SQL
    if (type === 'credit') whereClause += ' AND adjustment_amount >= 0';
    if (type === 'debit') whereClause += ' AND adjustment_amount < 0';

    const sql = `
      SELECT
        adjustment_key,
        adjustment_date,
        adjustment_code,
        adjustment_description,
        adjustment_category,
        merchant_name,
        adjustment_amount
      FROM ${FULL_TABLE_ADJUSTMENTS}
      ${whereClause}
      ORDER BY adjustment_date DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql, binds);

    const data = result.rows.map(row => ({
      adjId: row.ADJUSTMENT_KEY,
      adjDate: row.ADJUSTMENT_DATE,
      adjCode: row.ADJUSTMENT_CODE,
      adjDescription: row.ADJUSTMENT_DESCRIPTION,
      adjCategory: row.ADJUSTMENT_CATEGORY,
      merchantName: row.MERCHANT_NAME,
      amount: Number(row.ADJUSTMENT_AMOUNT) || 0,
      type: Number(row.ADJUSTMENT_AMOUNT) >= 0 ? 'Credit' : 'Debit',
    }));

    return NextResponse.json({
      success: true,
      data,
      rowCount: result.rowCount,
      filters: { startDate, endDate, type, limit, offset },
    });
  } catch (error) {
    console.error('Adjustment details error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve adjustment details. Please check your connection and try again.',
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
