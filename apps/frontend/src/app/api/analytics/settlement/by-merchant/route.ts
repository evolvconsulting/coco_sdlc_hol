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
        merchant_name,
        SUM(net_amount) as net_volume,
        SUM(sales_count) as transaction_count,
        SUM(sales_amount) as gross_sales,
        SUM(refund_amount) as refund_amount,
        SUM(discount_amount) as interchange
      FROM COCO_SDLC_HOL.MARTS.SETTLEMENTS
      WHERE settlement_date BETWEEN '${startDate}' AND '${endDate}'
      GROUP BY merchant_name
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
