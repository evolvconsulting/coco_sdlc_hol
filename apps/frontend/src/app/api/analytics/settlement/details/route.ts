import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';

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

    const sql = `
      SELECT 
        SETTLE_ID,
        RECORD_DT,
        CARD_BRND,
        LCTN_DBA_NM,
        SALES_CT,
        SALES_AM,
        REFUND_CNT,
        REFUND_AM,
        PRCS_NET_AMT,
        INTERCHANGE_AM
      FROM COCO_SDLC_HOL.CLEA.SETTLE_DMCL_V1
      WHERE RECORD_DT BETWEEN '${startDate}' AND '${endDate}'
      ORDER BY RECORD_DT DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql);

    const data = result.rows.map(row => ({
      settleId: row.SETTLE_ID,
      recordDate: row.RECORD_DT,
      cardBrand: row.CARD_BRND,
      merchantName: row.LCTN_DBA_NM,
      salesCount: Number(row.SALES_CT) || 0,
      salesAmount: Number(row.SALES_AM) || 0,
      refundCount: Number(row.REFUND_CNT) || 0,
      refundAmount: Number(row.REFUND_AM) || 0,
      netAmount: Number(row.PRCS_NET_AMT) || 0,
      interchange: Number(row.INTERCHANGE_AM) || 0,
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
