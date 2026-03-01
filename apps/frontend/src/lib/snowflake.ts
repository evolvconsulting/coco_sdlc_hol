// Snowflake service for executing queries with per-request connection lifecycle.
// Each executeQuery call creates a fresh connection and destroys it after completion.

import snowflake from 'snowflake-sdk';
import * as fs from 'fs';
import * as crypto from 'crypto';
import { SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA } from '@/lib/config';

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
    schema: process.env.SNOWFLAKE_SCHEMA || 'MARTS',
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

// Create a fresh connection for each request — no global singleton
async function createConnection(): Promise<snowflake.Connection> {
  const config = getConfig();

  // Build connection options
  const connectionOptions: snowflake.ConnectionOptions = {
    account: config.account,
    username: config.username,
    warehouse: config.warehouse,
    database: config.database,
    schema: config.schema,
    role: config.role,
    ...(process.env.SNOWFLAKE_HOST ? { host: process.env.SNOWFLAKE_HOST } : {}),
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
        resolve(conn);
      }
    });
  });
}

// Execute a query and return results
export async function executeQuery(
  sql: string,
  binds?: (string | number | null)[]
): Promise<QueryResult> {
  const startTime = Date.now();
  const connection = await createConnection();

  return new Promise((resolve, reject) => {
    connection.execute({
      sqlText: sql,
      binds: binds || [],
      complete: (err, stmt, rows) => {
        const executionTime = Date.now() - startTime;

        connection.destroy((destroyErr) => {
          if (destroyErr) console.error('Error closing Snowflake connection:', destroyErr);
        });

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

// Get table metadata (columns, types)
export async function getTableMetadata(tableName: string): Promise<{
  columns: Array<{ name: string; type: string; nullable: boolean }>;
}> {
  const sql = `
    SELECT
      COLUMN_NAME as name,
      DATA_TYPE as type,
      IS_NULLABLE = 'YES' as nullable
    FROM ${SNOWFLAKE_DATABASE}.INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = '${SNOWFLAKE_SCHEMA}'
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
