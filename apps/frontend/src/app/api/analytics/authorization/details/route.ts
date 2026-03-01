import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_AUTHORIZATIONS } from '@/lib/config';

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

    const binds: (string | number | null)[] = [startDate, endDate];
    let whereClause = 'WHERE transaction_date BETWEEN ? AND ?';

    let cardBrandFilter = '';
    if (cardBrand) {
      cardBrandFilter = ' AND card_brand = ?';
      binds.push(cardBrand);
    }

    let statusFilter = '';
    if (status === 'approved') {
      statusFilter = ' AND approval_status = ?';
      binds.push('Approved');
    } else if (status === 'declined') {
      statusFilter = ' AND approval_status = ?';
      binds.push('Declined');
    }

    whereClause += cardBrandFilter + statusFilter;

    const sql = `
      SELECT
        authorization_key,
        transaction_date,
        card_brand,
        transaction_amount,
        approval_status,
        decline_reason,
        merchant_name,
        payment_method,
        processing_network
      FROM ${FULL_TABLE_AUTHORIZATIONS}
      ${whereClause}
      ORDER BY transaction_date DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

    const result = await executeQuery(sql, binds);

    const data = result.rows.map(row => ({
      authId: row.AUTHORIZATION_KEY,
      txnDate: row.TRANSACTION_DATE,
      cardBrand: row.CARD_BRAND,
      amount: Number(row.TRANSACTION_AMOUNT) || 0,
      status: row.APPROVAL_STATUS,
      declineReason: row.DECLINE_REASON,
      merchantName: row.MERCHANT_NAME,
      paymentMethod: row.PAYMENT_METHOD,
      network: row.PROCESSING_NETWORK,
      riskScore: null,
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
