import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_CHARGEBACKS } from '@/lib/config';

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

    const binds: (string | number | null)[] = [startDate, endDate];
    let whereClause = 'WHERE dispute_received_date BETWEEN ? AND ?';

    let statusFilter = '';
    if (status) {
      statusFilter = ' AND chargeback_status = ?';
      binds.push(status);
    }

    whereClause += statusFilter;

    const sql = `
      SELECT
        chargeback_key,
        dispute_received_date,
        reason_code,
        reason_description,
        chargeback_status,
        outcome,
        lifecycle_stage,
        merchant_name,
        card_brand,
        dispute_amount,
        transaction_amount
      FROM ${FULL_TABLE_CHARGEBACKS}
      ${whereClause}
      ORDER BY dispute_received_date DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql, binds);

    const data = result.rows.map(row => ({
      cbkId: row.CHARGEBACK_KEY,
      disputeDate: row.DISPUTE_RECEIVED_DATE,
      reasonCode: row.REASON_CODE,
      reasonDescription: row.REASON_DESCRIPTION,
      status: row.CHARGEBACK_STATUS,
      winLoss: row.OUTCOME,
      cycle: row.LIFECYCLE_STAGE,
      merchantName: row.MERCHANT_NAME,
      cardBrand: row.CARD_BRAND,
      disputeAmount: Number(row.DISPUTE_AMOUNT) || 0,
      transactionAmount: Number(row.TRANSACTION_AMOUNT) || 0,
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
