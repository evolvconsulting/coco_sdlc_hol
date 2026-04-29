import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';
import { FULL_TABLE_AUTHORIZATIONS } from '@/lib/config';

// GET /api/analytics/authorization/kpis - Get authorization KPIs
export async function GET(request: NextRequest) {
  try {
    // Check if Snowflake is configured
    if (!isConfigured()) {
      return NextResponse.json(
        {
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to view authorization data.',
          code: 'SNOWFLAKE_NOT_CONFIGURED'
        },
        { status: 503 }
      );
    }

    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get('startDate') || getDefaultStartDate();
    const endDate = searchParams.get('endDate') || getDefaultEndDate();
    const cardBrand = searchParams.get('cardBrand');

    // Build the SQL query
    const binds: (string | number | null)[] = [startDate, endDate];
    let cardBrandFilter = '';
    if (cardBrand) {
      cardBrandFilter = 'AND card_brand = ?';
      binds.push(cardBrand);
    }

    const sql = `
      SELECT
        COUNT(*) as total_transactions,
        SUM(CASE WHEN approval_status = 'Approved' THEN 1 ELSE 0 END) as approved_count,
        SUM(CASE WHEN approval_status = 'Declined' THEN 1 ELSE 0 END) as declined_count,
        ROUND(SUM(CASE WHEN approval_status = 'Approved' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as approval_rate,
        SUM(transaction_amount) as total_amount,
        SUM(CASE WHEN approval_status = 'Approved' THEN transaction_amount ELSE 0 END) as approved_amount,
        ROUND(AVG(transaction_amount), 2) as avg_ticket_size
      FROM ${FULL_TABLE_AUTHORIZATIONS}
      WHERE transaction_date BETWEEN ? AND ?
        ${cardBrandFilter}
    `;

    const result = await executeQuery(sql, binds);

    if (result.rows.length === 0) {
      return NextResponse.json({
        success: true,
        data: getEmptyKPIs(),
        filters: { startDate, endDate, cardBrand },
      });
    }

    const row = result.rows[0];
    const kpis = {
      totalTransactions: Number(row.TOTAL_TRANSACTIONS) || 0,
      approvedCount: Number(row.APPROVED_COUNT) || 0,
      declinedCount: Number(row.DECLINED_COUNT) || 0,
      approvalRate: Number(row.APPROVAL_RATE) || 0,
      totalAmount: Number(row.TOTAL_AMOUNT) || 0,
      approvedAmount: Number(row.APPROVED_AMOUNT) || 0,
      avgTicketSize: Number(row.AVG_TICKET_SIZE) || 0,
      trends: {
        transactions: 0,
        approvalRate: 0,
        amount: 0,
      },
    };

    return NextResponse.json({
      success: true,
      data: kpis,
      filters: { startDate, endDate, cardBrand },
    });
  } catch (error) {
    console.error('Authorization KPIs error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Failed to connect to Snowflake',
        message: 'Unable to retrieve authorization data. Please check your connection and try again.',
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

function getEmptyKPIs() {
  return {
    totalTransactions: 0,
    approvedCount: 0,
    declinedCount: 0,
    approvalRate: 0,
    totalAmount: 0,
    approvedAmount: 0,
    avgTicketSize: 0,
    trends: {
      transactions: 0,
      approvalRate: 0,
      amount: 0,
    },
  };
}
