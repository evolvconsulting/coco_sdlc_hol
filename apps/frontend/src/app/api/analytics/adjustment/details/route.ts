import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';

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

    let whereClause = `WHERE ADJ_DT BETWEEN '${startDate}' AND '${endDate}'`;
    if (type === 'credit') whereClause += ` AND ADJ_AM >= 0`;
    if (type === 'debit') whereClause += ` AND ADJ_AM < 0`;

    const sql = `
      SELECT 
        ADJ_ID,
        ADJ_DT,
        ADJ_CD,
        ADJ_DESC_TX,
        FEE_DESC_TX,
        LCTN_DBA_NM,
        ADJ_AM
      FROM COCO_SDLC_HOL.CLEA.ADJ_DMCL_V1
      ${whereClause}
      ORDER BY ADJ_DT DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql);

    const data = result.rows.map(row => ({
      adjId: row.ADJ_ID,
      adjDate: row.ADJ_DT,
      adjCode: row.ADJ_CD,
      adjDescription: row.ADJ_DESC_TX,
      feeDescription: row.FEE_DESC_TX,
      merchantName: row.LCTN_DBA_NM,
      amount: Number(row.ADJ_AM) || 0,
      type: Number(row.ADJ_AM) >= 0 ? 'Credit' : 'Debit',
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
        details: String(error),
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
