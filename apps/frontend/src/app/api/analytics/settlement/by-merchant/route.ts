import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';

// GET /api/analytics/settlement/by-merchant - Get settlement data by merchant
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
    const limit = parseInt(searchParams.get('limit') || '10');

    const sql = `
      SELECT 
        LCTN_DBA_NM as merchant_name,
        SUM(PRCS_NET_AMT) as net_volume,
        SUM(SALES_CT) as transaction_count,
        SUM(SALES_AM) as gross_sales,
        SUM(REFUND_AM) as refund_amount,
        SUM(INTERCHANGE_AM) as interchange
      FROM COCO_SDLC_HOL.CLEA.SETTLE_DMCL_V1
      WHERE RECORD_DT BETWEEN '${startDate}' AND '${endDate}'
      GROUP BY LCTN_DBA_NM
      ORDER BY net_volume DESC
      LIMIT ${limit}
    `;

    const result = await executeQuery(sql);

    const data = result.rows.map(row => ({
      merchantName: row.MERCHANT_NAME,
      netVolume: Number(row.NET_VOLUME) || 0,
      transactionCount: Number(row.TRANSACTION_COUNT) || 0,
      grossSales: Number(row.GROSS_SALES) || 0,
      refundAmount: Number(row.REFUND_AMOUNT) || 0,
      interchange: Number(row.INTERCHANGE) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      filters: { startDate, endDate, limit },
    });
  } catch (error) {
    console.error('Settlement by-merchant error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve settlement data. Please check your connection and try again.',
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
