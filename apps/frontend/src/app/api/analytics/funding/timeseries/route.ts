import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';

// GET /api/analytics/funding/timeseries - Get funding timeseries data
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        { 
          success: false, 
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view funding data.',
          code: 'SNOWFLAKE_NOT_CONFIGURED'
        },
        { status: 503 }
      );
    }

    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('startDate') || getDefaultStartDate();
    const endDate = searchParams.get('endDate') || getDefaultEndDate();

    const sql = `
      SELECT 
        FUNDED_DT as date,
        SUM(DEPOSIT_AM) as deposits,
        SUM(NET_SALES_AM) as net_sales,
        SUM(FEES_AM) as fees,
        SUM(CHARGEBACK_AM) as chargebacks,
        COUNT(*) as funding_count
      FROM COCO_SDLC_HOL.CLEA.FUND_DMCL_V1
      WHERE FUNDED_DT BETWEEN '${startDate}' AND '${endDate}'
      GROUP BY FUNDED_DT
      ORDER BY FUNDED_DT
    `;

    const result = await executeQuery(sql);

    const data = result.rows.map(row => ({
      date: row.DATE,
      deposits: Number(row.DEPOSITS) || 0,
      netSales: Number(row.NET_SALES) || 0,
      fees: Number(row.FEES) || 0,
      chargebacks: Number(row.CHARGEBACKS) || 0,
      fundingCount: Number(row.FUNDING_COUNT) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Funding timeseries error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve funding timeseries. Please check your connection and try again.',
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
