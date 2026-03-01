import { NextRequest, NextResponse } from 'next/server';
import * as fs from 'fs';
import * as crypto from 'crypto';
import { SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA } from '@/lib/config';

// Path where SPCS injects the rotating OAuth token for service-identity auth.
const SPCS_TOKEN_PATH = '/snowflake/session/token';

// Snowflake Cortex Agent configuration
// Note: trim() is used because Vercel env vars may have trailing newlines
const SNOWFLAKE_ACCOUNT = (process.env.SNOWFLAKE_ACCOUNT || '').trim();
const SNOWFLAKE_HOST = (process.env.SNOWFLAKE_HOST || '').trim();
const SNOWFLAKE_USER = (process.env.SNOWFLAKE_USER || '').trim();
const SNOWFLAKE_PRIVATE_KEY_PATH = (process.env.SNOWFLAKE_PRIVATE_KEY_PATH || '').trim();
const SNOWFLAKE_PRIVATE_KEY = (process.env.SNOWFLAKE_PRIVATE_KEY || '').trim();
const AGENT_NAME = (process.env.CORTEX_AGENT_NAME || 'PAYMENT_ANALYTICS_AGENT').trim();

// Generate JWT token for Snowflake authentication
function generateJWT(): string {
  if ((!SNOWFLAKE_PRIVATE_KEY && !SNOWFLAKE_PRIVATE_KEY_PATH) || !SNOWFLAKE_ACCOUNT || !SNOWFLAKE_USER) {
    throw new Error('Missing Snowflake JWT configuration');
  }

  // Load private key - prefer content over file path
  let privateKeyPem: string;
  if (SNOWFLAKE_PRIVATE_KEY) {
    // Key content provided directly (e.g., from Vercel env var)
    // Normalize line endings: convert \r\n to \n and handle escaped newlines
    privateKeyPem = SNOWFLAKE_PRIVATE_KEY
      .replace(/\\n/g, '\n')
      .replace(/\r\n/g, '\n')
      .replace(/\r/g, '\n');
  } else {
    // Key path provided (local development)
    privateKeyPem = fs.readFileSync(SNOWFLAKE_PRIVATE_KEY_PATH, 'utf8');
  }
  const passphrase = process.env.SNOWFLAKE_PRIVATE_KEY_PASSPHRASE || '';
  
  let privateKey: crypto.KeyObject;
  if (privateKeyPem.includes('ENCRYPTED')) {
    privateKey = crypto.createPrivateKey({
      key: privateKeyPem,
      format: 'pem',
      passphrase: passphrase,
    });
  } else {
    privateKey = crypto.createPrivateKey({
      key: privateKeyPem,
      format: 'pem',
    });
  }

  // Get public key fingerprint for the JWT
  const publicKey = crypto.createPublicKey(privateKey);
  const publicKeyDer = publicKey.export({ type: 'spki', format: 'der' });
  const fingerprint = crypto.createHash('sha256').update(publicKeyDer).digest('base64');

  // Account identifier for JWT (uppercase, with region if present)
  const accountId = SNOWFLAKE_ACCOUNT.toUpperCase();
  const qualifiedUsername = `${accountId}.${SNOWFLAKE_USER.toUpperCase()}`;

  // JWT claims
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: `${qualifiedUsername}.SHA256:${fingerprint}`,
    sub: qualifiedUsername,
    iat: now,
    exp: now + 3600, // 1 hour expiry
  };

  // Create JWT header
  const header = { alg: 'RS256', typ: 'JWT' };
  
  // Encode header and payload
  const encodedHeader = Buffer.from(JSON.stringify(header)).toString('base64url');
  const encodedPayload = Buffer.from(JSON.stringify(payload)).toString('base64url');
  
  // Sign the JWT
  const signatureInput = `${encodedHeader}.${encodedPayload}`;
  const signature = crypto.sign('sha256', Buffer.from(signatureInput), privateKey);
  const encodedSignature = signature.toString('base64url');

  return `${encodedHeader}.${encodedPayload}.${encodedSignature}`;
}

// Resolve the auth token and header type for the Cortex Agent REST API.
// Auth strategy (checked in order):
//   1. SPCS OAuth  — /snowflake/session/token exists (running inside SPCS container)
//   2. JWT key-pair — SNOWFLAKE_PRIVATE_KEY or SNOWFLAKE_PRIVATE_KEY_PATH is set
function getAuthToken(): { token: string; tokenType: string } {
  // Strategy 1: SPCS OAuth
  if (fs.existsSync(SPCS_TOKEN_PATH)) {
    const token = fs.readFileSync(SPCS_TOKEN_PATH, 'utf8').trim();
    return { token, tokenType: 'OAUTH' };
  }
  // Strategy 2: JWT key-pair
  return { token: generateJWT(), tokenType: 'KEYPAIR_JWT' };
}

// Check if Snowflake is properly configured for Cortex Agent auth
function isSnowflakeConfigured(): boolean {
  const hasSpcsToken = fs.existsSync(SPCS_TOKEN_PATH);
  return !!(SNOWFLAKE_ACCOUNT && SNOWFLAKE_USER && (hasSpcsToken || SNOWFLAKE_PRIVATE_KEY || SNOWFLAKE_PRIVATE_KEY_PATH));
}

interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

// POST /api/cortex/chat - Send message to Cortex Agent with streaming
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { message, history = [] } = body;

    if (!message) {
      return NextResponse.json(
        { error: 'Message is required' },
        { status: 400 }
      );
    }

    // Check if Snowflake credentials are configured
    if (!isSnowflakeConfigured()) {
      return NextResponse.json(
        { 
          success: false,
          error: 'Snowflake connection not configured',
          message: 'The AI assistant requires a connection to Snowflake. Please configure your Snowflake credentials.',
          code: 'SNOWFLAKE_NOT_CONFIGURED'
        },
        { status: 503 }
      );
    }

    // Use HOST if available, otherwise construct from account
    const baseUrl = SNOWFLAKE_HOST 
      ? `https://${SNOWFLAKE_HOST}`
      : `https://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com`;
    const agentUrl = `${baseUrl}/api/v2/databases/${SNOWFLAKE_DATABASE}/schemas/${SNOWFLAKE_SCHEMA}/agents/${AGENT_NAME}:run`;

    // Resolve auth token — uses SPCS OAuth when running in a container, JWT otherwise
    const { token: authToken, tokenType } = getAuthToken();

    // Build messages array with history
    // Cortex Agent API expects content to be an array of {type, text} objects
    const messages = [
      ...history.map((msg: ChatMessage) => ({
        role: msg.role,
        content: [{ type: 'text', text: msg.content }],
      })),
      { role: 'user', content: [{ type: 'text', text: message }] },
    ];

    const requestBody = { messages };

    // Make request to Cortex Agent
    const response = await fetch(agentUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        Authorization: `Bearer ${authToken}`,
        'X-Snowflake-Authorization-Token-Type': tokenType,
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Cortex Agent error:', response.status, errorText);
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to connect to Cortex Agent',
          message: 'Unable to reach the AI assistant. Please check your Snowflake connection and try again.',
          code: 'CORTEX_AGENT_ERROR'
        },
        { status: 503 }
      );
    }

    // Stream the response back to the client
    const encoder = new TextEncoder();
    const stream = new ReadableStream({
      async start(controller) {
        const reader = response.body?.getReader();
        if (!reader) {
          controller.close();
          return;
        }

        const decoder = new TextDecoder();
        let buffer = '';

        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            buffer += decoder.decode(value, { stream: true });
            const lines = buffer.split('\n');
            buffer = lines.pop() || '';

            for (const line of lines) {
              if (line.startsWith('event:') || line.startsWith('data:')) {
                // Forward SSE events to client
                controller.enqueue(encoder.encode(line + '\n'));
              } else if (line.trim() === '') {
                // Forward empty lines (SSE event separators)
                controller.enqueue(encoder.encode('\n'));
              }
            }
          }

          // Process any remaining buffer
          if (buffer.trim()) {
            controller.enqueue(encoder.encode(buffer + '\n'));
          }
        } catch (error) {
          console.error('Stream error:', error);
        } finally {
          controller.close();
        }
      },
    });

    return new Response(stream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    });
  } catch (error) {
    console.error('Cortex API error:', error);
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
