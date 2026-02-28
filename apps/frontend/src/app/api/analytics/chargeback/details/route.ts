import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';

// GET /api/analytics/chargeback/details - Get chargeback detail records
export async function GET(request: NextRequest) {
  try {
    if (!isConfigured()) {
      return NextResponse.json(
        { 
          success: false, 
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view chargeback details.',
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

    let whereClause = `WHERE DSPUT_RCVD_DT BETWEEN '${startDate}' AND '${endDate}'`;
    if (status) whereClause += ` AND CBK_STATUS = '${status}'`;

    const sql = `
      SELECT 
        CBK_ID,
        DSPUT_RCVD_DT,
        DSPUT_RSN_CD,
        DSPUT_RSN_DESC,
        CBK_STATUS,
        CBK_WIN_LOSS,
        CHARGEBACK_CYCLE,
        MRCH_NM,
        CARD_BRND,
        DSPUT_AMT,
        TXN_AMT
      FROM COCO_SDLC_HOL.CLEA.CHARGEBACK_DMCL_V1
      ${whereClause}
      ORDER BY DSPUT_RCVD_DT DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql);

    const data = result.rows.map(row => ({
      cbkId: row.CBK_ID,
      disputeDate: row.DSPUT_RCVD_DT,
      reasonCode: row.DSPUT_RSN_CD,
      reasonDescription: row.DSPUT_RSN_DESC,
      status: row.CBK_STATUS,
      winLoss: row.CBK_WIN_LOSS,
      cycle: row.CHARGEBACK_CYCLE,
      merchantName: row.MRCH_NM,
      cardBrand: row.CARD_BRND,
      disputeAmount: Number(row.DSPUT_AMT) || 0,
      transactionAmount: Number(row.TXN_AMT) || 0,
    }));

    return NextResponse.json({
      success: true,
      data,
      rowCount: result.rowCount,
      filters: { startDate, endDate, status, limit, offset },
    });
  } catch (error) {
    console.error('Chargeback details error:', error);
    return NextResponse.json(
      { 
        success: false, 
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve chargeback details. Please check your connection and try again.',
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
