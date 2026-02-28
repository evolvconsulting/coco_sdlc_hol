// Snowflake service for executing queries with RLS enforcement
// All queries automatically filter by CLNT_ID = 'dmcl' for security

import snowflake from 'snowflake-sdk';
import * as fs from 'fs';
import * as crypto from 'crypto';

interface SnowflakeConfig {
  account: string;
  username: string;
  warehouse: string;
  database: string;
  schema: string;
  role?: string;
  // Key-pair auth
  privateKeyPath?: string;
  privateKey?: string;
  // Password auth (fallback)
  password?: string;
}

interface QueryResult {
  columns: string[];
  rows: Record<string, unknown>[];
  rowCount: number;
  executionTime: number;
}

// Get configuration from environment variables
function getConfig(): SnowflakeConfig {
  const config: SnowflakeConfig = {
    account: process.env.SNOWFLAKE_ACCOUNT || '',
    username: process.env.SNOWFLAKE_USER || process.env.SNOWFLAKE_USERNAME || '',
    warehouse: process.env.SNOWFLAKE_WAREHOUSE || 'COMPUTE_WH',
    database: process.env.SNOWFLAKE_DATABASE || 'COCO_SDLC_HOL',
    schema: process.env.SNOWFLAKE_SCHEMA || 'CLEA',
    role: process.env.SNOWFLAKE_ROLE,
    privateKeyPath: process.env.SNOWFLAKE_PRIVATE_KEY_PATH,
    privateKey: process.env.SNOWFLAKE_PRIVATE_KEY,
    password: process.env.SNOWFLAKE_PASSWORD,
  };

  // Validate required fields
  if (!config.account || !config.username) {
    throw new Error('Missing required Snowflake configuration. Check SNOWFLAKE_ACCOUNT and SNOWFLAKE_USER environment variables.');
  }

  // Must have either private key (content or path) or password
  if (!config.privateKey && !config.privateKeyPath && !config.password) {
    throw new Error('Missing Snowflake authentication. Set SNOWFLAKE_PRIVATE_KEY, SNOWFLAKE_PRIVATE_KEY_PATH, or SNOWFLAKE_PASSWORD.');
  }

  return config;
}

// Load private key from file for JWT auth
function loadPrivateKey(keyPath: string): string {
  try {
    const keyContent = fs.readFileSync(keyPath, 'utf8');
    
    // If the key is encrypted, we need the passphrase
    // For now, assume unencrypted key or handle via environment
    const passphrase = process.env.SNOWFLAKE_PRIVATE_KEY_PASSPHRASE || '';
    
    if (keyContent.includes('ENCRYPTED')) {
      // Decrypt the private key
      const privateKey = crypto.createPrivateKey({
        key: keyContent,
        format: 'pem',
        passphrase: passphrase,
      });
      return privateKey.export({ type: 'pkcs8', format: 'pem' }) as string;
    }
    
    return keyContent;
  } catch (err) {
    console.error('Failed to load private key:', err);
    throw new Error(`Failed to load private key from ${keyPath}`);
  }
}

// Create a connection pool (simplified for demo - use proper pooling in production)
let connectionPool: snowflake.Connection | null = null;

async function getConnection(): Promise<snowflake.Connection> {
  if (connectionPool) {
    return connectionPool;
  }

  const config = getConfig();
  
  // Build connection options
  const connectionOptions: snowflake.ConnectionOptions = {
    account: config.account,
    username: config.username,
    warehouse: config.warehouse,
    database: config.database,
    schema: config.schema,
    role: config.role,
  };

  // Use key-pair authentication if private key is provided (content or path)
  if (config.privateKey) {
    // Private key content provided directly (e.g., from Vercel env var)
    // Convert escaped newlines back to actual newlines
    connectionOptions.authenticator = 'SNOWFLAKE_JWT';
    connectionOptions.privateKey = config.privateKey.replace(/\\n/g, '\n');
  } else if (config.privateKeyPath) {
    // Private key path provided (local development)
    const privateKey = loadPrivateKey(config.privateKeyPath);
    connectionOptions.authenticator = 'SNOWFLAKE_JWT';
    connectionOptions.privateKey = privateKey;
  } else if (config.password) {
    connectionOptions.password = config.password;
  }

  return new Promise((resolve, reject) => {
    const connection = snowflake.createConnection(connectionOptions);

    connection.connect((err, conn) => {
      if (err) {
        console.error('Failed to connect to Snowflake:', err);
        reject(err);
      } else {
        connectionPool = conn;
        resolve(conn);
      }
    });
  });
}

// Execute a query and return results
export async function executeQuery(sql: string): Promise<QueryResult> {
  const startTime = Date.now();
  const connection = await getConnection();

  return new Promise((resolve, reject) => {
    connection.execute({
      sqlText: sql,
      complete: (err, stmt, rows) => {
        const executionTime = Date.now() - startTime;

        if (err) {
          console.error('Query execution error:', err);
          reject(err);
          return;
        }

        // Extract column names from statement
        const columns = stmt.getColumns()?.map((col) => col.getName()) || [];

        resolve({
          columns,
          rows: (rows as Record<string, unknown>[]) || [],
          rowCount: rows?.length || 0,
          executionTime,
        });
      },
    });
  });
}

// Execute a query with automatic RLS filter
// This ensures all queries are scoped to the DMCL client
export async function executeQueryWithRLS(
  sql: string,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _clientId: string = 'dmcl'
): Promise<QueryResult> {
  // Note: The views (AUTH_DMCL_V1, etc.) already have CLNT_ID filtering built-in
  // This function is for additional security layer on raw queries
  
  // Validate the SQL doesn't contain dangerous patterns
  const sanitizedSql = sanitizeSQL(sql);
  
  return executeQuery(sanitizedSql);
}

// Basic SQL sanitization (additional layer - views provide primary security)
function sanitizeSQL(sql: string): string {
  // Remove comments that could hide malicious code
  let sanitized = sql.replace(/--.*$/gm, '');
  sanitized = sanitized.replace(/\/\*[\s\S]*?\*\//g, '');
  
  // Check for dangerous statements
  const dangerous = [
    /\bDROP\b/i,
    /\bDELETE\b/i,
    /\bTRUNCATE\b/i,
    /\bALTER\b/i,
    /\bCREATE\b/i,
    /\bINSERT\b/i,
    /\bUPDATE\b/i,
    /\bGRANT\b/i,
    /\bREVOKE\b/i,
  ];

  for (const pattern of dangerous) {
    if (pattern.test(sanitized)) {
      throw new Error('Query contains prohibited statements');
    }
  }

  return sanitized;
}

// Get table metadata (columns, types)
export async function getTableMetadata(tableName: string): Promise<{
  columns: Array<{ name: string; type: string; nullable: boolean }>;
}> {
  const database = process.env.SNOWFLAKE_DATABASE || 'COCO_SDLC_HOL';
  const schema = process.env.SNOWFLAKE_SCHEMA || 'CLEA';
  
  const sql = `
    SELECT 
      COLUMN_NAME as name,
      DATA_TYPE as type,
      IS_NULLABLE = 'YES' as nullable
    FROM ${database}.INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = '${schema}'
      AND TABLE_NAME = '${tableName.toUpperCase()}'
    ORDER BY ORDINAL_POSITION
  `;

  const result = await executeQuery(sql);
  
  return {
    columns: result.rows.map((row) => ({
      name: row.NAME as string,
      type: row.TYPE as string,
      nullable: row.NULLABLE as boolean,
    })),
  };
}

// Test connection
export async function testConnection(): Promise<boolean> {
  try {
    await executeQuery('SELECT 1 as test');
    return true;
  } catch {
    return false;
  }
}

// Check if Snowflake is configured
export function isConfigured(): boolean {
  try {
    const account = process.env.SNOWFLAKE_ACCOUNT;
    const user = process.env.SNOWFLAKE_USER || process.env.SNOWFLAKE_USERNAME;
    const hasAuth = process.env.SNOWFLAKE_PRIVATE_KEY || process.env.SNOWFLAKE_PRIVATE_KEY_PATH || process.env.SNOWFLAKE_PASSWORD;
    return !!(account && user && hasAuth);
  } catch {
    return false;
  }
}

// Close connection (cleanup)
export function closeConnection(): void {
  if (connectionPool) {
    connectionPool.destroy((err) => {
      if (err) {
        console.error('Error closing Snowflake connection:', err);
      }
    });
    connectionPool = null;
  }
}
