import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';

// GET /api/analytics/authorization/details - Get authorization detail records
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        { 
          success: false, 
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view authorization details.',
          code: 'SNOWFLAKE_NOT_CONFIGURED'
        },
        { status: 503 }
      );
    }

    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('startDate') || getDefaultStartDate();
    const endDate = searchParams.get('endDate') || getDefaultEndDate();
    const cardBrand = searchParams.get('cardBrand');
    const status = searchParams.get('status');
    const limit = parseInt(searchParams.get('limit') || '100');
    const offset = parseInt(searchParams.get('offset') || '0');

    let whereClause = `WHERE TXNDATE BETWEEN '${startDate}' AND '${endDate}'`;
    if (cardBrand) whereClause += ` AND CARD_BRND = '${cardBrand}'`;
    if (status === 'approved') whereClause += ` AND APPROVALCODE = 1`;
    if (status === 'declined') whereClause += ` AND APPROVALCODE = 0`;

    const sql = `
      SELECT 
        AUTH_ID,
        TXNDATE,
        CARD_BRND,
        AMOUNT,
        APPROVALCODE,
        DECLINEREASON,
        LCTN_DBA_NM,
        PAYMENTMETHOD,
        NETWORK,
        RISK_SCORE
      FROM COCO_SDLC_HOL.CLEA.AUTH_DMCL_V1
      ${whereClause}
      ORDER BY TXNDATE DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql);

    const data = result.rows.map(row => ({
      authId: row.AUTH_ID,
      txnDate: row.TXNDATE,
      cardBrand: row.CARD_BRND,
      amount: Number(row.AMOUNT) || 0,
      status: row.APPROVALCODE === 1 ? 'Approved' : 'Declined',
      declineReason: row.DECLINEREASON,
      merchantName: row.LCTN_DBA_NM,
      paymentMethod: row.PAYMENTMETHOD,
      network: row.NETWORK,
      riskScore: Number(row.RISK_SCORE) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      rowCount: result.rowCount,
      filters: { startDate, endDate, cardBrand, status, limit, offset },
    });
  } catch (error) {
    console.error('Authorization details error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve authorization details. Please check your connection and try again.',
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
