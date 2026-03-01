import { NextRequest, NextResponse } from 'next/server';
import { executeQuery, isConfigured } from '@/lib/snowflake';

// POST /api/query - Execute a query against Snowflake
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { sql } = body;

    if (!sql) {
      return NextResponse.json(
        { 
          success: false,
          error: 'SQL query is required',
          message: 'Please provide a SQL query to execute.',
          code: 'MISSING_SQL'
        },
        { status: 400 }
      );
    }

    // Check if Snowflake is configured
    if (!isConfigured()) {
      return NextResponse.json(
        { 
          success: false,
          error: 'Snowflake connection not configured',
          message: 'Please configure your Snowflake credentials to execute queries.',
          code: 'SNOWFLAKE_NOT_CONFIGURED'
        },
        { status: 503 }
      );
    }

    try {
      const startTime = Date.now();
      const result = await executeQuery(sql);
      return NextResponse.json({
        success: true,
        columns: result.columns,
        rows: result.rows,
        rowCount: result.rowCount,
        executionTime: Date.now() - startTime,
        sql,
      });
    } catch (snowflakeError) {
      console.error('Snowflake query error:', snowflakeError);
      return NextResponse.json(
        {
          success: false,
          error: 'Query execution failed',
          message: 'Unable to execute query against Snowflake. Please check your query syntax and try again.',
          code: 'QUERY_EXECUTION_ERROR'
        },
        { status: 500 }
      );
    }
  } catch (error) {
    console.error('Query API error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Internal server error',
        message: 'An unexpected error occurred. Please try again.',
        code: 'INTERNAL_ERROR'
      },
      { status: 500 }
    );
  }
}
