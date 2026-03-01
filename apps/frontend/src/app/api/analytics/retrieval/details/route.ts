import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_RETRIEVALS } from '@/lib/config';

// GET /api/analytics/retrieval/details - Get retrieval detail records
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view retrieval details.',
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
    let whereClause = 'WHERE retrieval_received_date BETWEEN ? AND ?';

    let statusFilter = '';
    if (status) {
      statusFilter = ' AND retrieval_status = ?';
      binds.push(status);
    }

    whereClause += statusFilter;

    const sql = `
      SELECT
        retrieval_key,
        original_sale_date,
        retrieval_status,
        reason_code,
        reason_description,
        response_due_date,
        merchant_name,
        card_brand,
        retrieval_amount
      FROM ${FULL_TABLE_RETRIEVALS}
      ${whereClause}
      ORDER BY original_sale_date DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql, binds);

    const data = result.rows.map(row => ({
      rtId: row.RETRIEVAL_KEY,
      saleDate: row.ORIGINAL_SALE_DATE,
      status: row.RETRIEVAL_STATUS,
      reasonCode: row.REASON_CODE,
      reasonDescription: row.REASON_DESCRIPTION,
      dueDate: row.RESPONSE_DUE_DATE,
      merchantName: row.MERCHANT_NAME,
      cardBrand: row.CARD_BRAND,
      amount: Number(row.RETRIEVAL_AMOUNT) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      rowCount: result.rowCount,
      filters: { startDate, endDate, status, limit, offset },
    });
  } catch (error) {
    console.error('Retrieval details error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve retrieval details. Please check your connection and try again.',
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
