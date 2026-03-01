import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_DEPOSITS } from '@/lib/config';

// GET /api/analytics/funding/details - Get funding detail records
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view funding details.',
          code: 'SNOWFLAKE_NOT_CONFIGURED'
        },
        { status: 503 }
      );
    }

    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('startDate') || getDefaultStartDate();
    const endDate = searchParams.get('endDate') || getDefaultEndDate();
    const status = searchParams.get('status');
    const limit = parseInt(searchParams.get('limit') || '100');
    const offset = parseInt(searchParams.get('offset') || '0');

    const binds: (string | number | null)[] = [startDate, endDate];
    let whereClause = 'WHERE deposit_date BETWEEN ? AND ?';

    let statusFilter = '';
    if (status) {
      statusFilter = ' AND payment_status = ?';
      binds.push(status);
    }

    whereClause += statusFilter;

    const sql = `
      SELECT
        deposit_key,
        deposit_date,
        payment_status,
        merchant_name,
        deposit_amount,
        net_sales_amount,
        total_fees_amount,
        chargeback_amount
      FROM ${FULL_TABLE_DEPOSITS}
      ${whereClause}
      ORDER BY deposit_date DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql, binds);

    const data = result.rows.map(row => ({
      fundId: row.DEPOSIT_KEY,
      fundedDate: row.DEPOSIT_DATE,
      status: row.PAYMENT_STATUS,
      merchantName: row.MERCHANT_NAME,
      depositAmount: Number(row.DEPOSIT_AMOUNT) || 0,
      netSales: Number(row.NET_SALES_AMOUNT) || 0,
      fees: Number(row.TOTAL_FEES_AMOUNT) || 0,
      chargebacks: Number(row.CHARGEBACK_AMOUNT) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      rowCount: result.rowCount,
      filters: { startDate, endDate, status, limit, offset },
    });
  } catch (error) {
    console.error('Funding details error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve funding details. Please check your connection and try again.',
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
