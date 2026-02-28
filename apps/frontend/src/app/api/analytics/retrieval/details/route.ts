import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';

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

    let whereClause = `WHERE RT_SALE_DT BETWEEN '${startDate}' AND '${endDate}'`;
    if (status) whereClause += ` AND RV_CB_STATUS = '${status}'`;

    const sql = `
      SELECT 
        RT_ID,
        RT_SALE_DT,
        RV_CB_STATUS,
        RT_RSN_CD,
        RT_RSN_DESC,
        RT_RTRVL_DUE_DT,
        LCTN_DBA_NM,
        CARD_BRND,
        RT_DOLLAR_AM
      FROM COCO_SDLC_HOL.CLEA.RETRIEVAL_DMCL_V1
      ${whereClause}
      ORDER BY RT_SALE_DT DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql);

    const data = result.rows.map(row => ({
      rtId: row.RT_ID,
      saleDate: row.RT_SALE_DT,
      status: row.RV_CB_STATUS,
      reasonCode: row.RT_RSN_CD,
      reasonDescription: row.RT_RSN_DESC,
      dueDate: row.RT_RTRVL_DUE_DT,
      merchantName: row.LCTN_DBA_NM,
      cardBrand: row.CARD_BRND,
      amount: Number(row.RT_DOLLAR_AM) || 0,
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
