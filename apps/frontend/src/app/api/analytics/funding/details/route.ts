import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';

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

    let whereClause = `WHERE FUNDED_DT BETWEEN '${startDate}' AND '${endDate}'`;
    if (status) whereClause += ` AND PAYMENT_STATUS = '${status}'`;

    const sql = `
      SELECT 
        FUND_ID,
        FUNDED_DT,
        PAYMENT_STATUS,
        LCTN_DBA_NM,
        DEPOSIT_AM,
        NET_SALES_AM,
        FEES_AM,
        CHARGEBACK_AM
      FROM COCO_SDLC_HOL.CLEA.FUND_DMCL_V1
      ${whereClause}
      ORDER BY FUNDED_DT DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql);

    const data = result.rows.map(row => ({
      fundId: row.FUND_ID,
      fundedDate: row.FUNDED_DT,
      status: row.PAYMENT_STATUS,
      merchantName: row.LCTN_DBA_NM,
      depositAmount: Number(row.DEPOSIT_AM) || 0,
      netSales: Number(row.NET_SALES_AM) || 0,
      fees: Number(row.FEES_AM) || 0,
      chargebacks: Number(row.CHARGEBACK_AM) || 0,
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
