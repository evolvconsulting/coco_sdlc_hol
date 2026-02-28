import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';

// GET /api/analytics/chargeback/by-reason - Get chargeback breakdown by reason
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        { 
          success: false, 
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view chargeback data.',
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
        reason_code,
        reason_description,
        COUNT(*) as count,
        SUM(dispute_amount) as amount,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
      FROM COCO_SDLC_HOL.MARTS.CHARGEBACKS
      WHERE dispute_received_date BETWEEN '${startDate}' AND '${endDate}'
      GROUP BY reason_code, reason_description
      ORDER BY count DESC
      LIMIT 10
    `;

    const result = await executeQuery(sql);

    const data = result.rows.map(row => ({
      reasonCode: row.REASON_CODE,
      reasonDescription: row.REASON_DESCRIPTION,
      count: Number(row.COUNT) || 0,
      amount: Number(row.AMOUNT) || 0,
      percentage: Number(row.PERCENTAGE) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      filters: { startDate, endDate },
    });
  } catch (error) {
    console.error('Chargeback by-reason error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve chargeback data. Please check your connection and try again.',
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
