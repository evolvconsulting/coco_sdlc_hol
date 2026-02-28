// Cortex Agent API service for natural language queries
// Integrates with Snowflake Cortex Agent REST API

interface CortexMessage {
  role: 'user' | 'assistant';
  content: string;
}

interface CortexResponse {
  message: string;
  sql?: string;
  data?: Record<string, unknown>[];
  error?: string;
}

interface CortexStreamChunk {
  type: 'text' | 'sql' | 'data' | 'error' | 'done';
  content: string;
}

// Cortex Agent API configuration
const CORTEX_API_BASE = process.env.CORTEX_API_URL || '/api/cortex';

// Send a message to Cortex Agent
export async function sendCortexMessage(
  message: string,
  conversationHistory: CortexMessage[] = []
): Promise<CortexResponse> {
  try {
    const response = await fetch(`${CORTEX_API_BASE}/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message,
        history: conversationHistory,
        semantic_model: 'performance_intelligence',
      }),
    });

    if (!response.ok) {
      throw new Error(`Cortex API error: ${response.status}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Cortex Agent error:', error);
    return {
      message: 'Sorry, I encountered an error processing your request.',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

// Stream response from Cortex Agent (for real-time updates)
export async function* streamCortexMessage(
  message: string,
  conversationHistory: CortexMessage[] = []
): AsyncGenerator<CortexStreamChunk> {
  try {
    const response = await fetch(`${CORTEX_API_BASE}/chat/stream`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message,
        history: conversationHistory,
        semantic_model: 'performance_intelligence',
      }),
    });

    if (!response.ok) {
      throw new Error(`Cortex API error: ${response.status}`);
    }

    const reader = response.body?.getReader();
    if (!reader) {
      throw new Error('No response body');
    }

    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      
      if (done) {
        yield { type: 'done', content: '' };
        break;
      }

      buffer += decoder.decode(value, { stream: true });
      
      // Parse SSE events
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6);
          if (data === '[DONE]') {
            yield { type: 'done', content: '' };
            return;
          }
          try {
            const parsed = JSON.parse(data);
            yield parsed as CortexStreamChunk;
          } catch {
            // Skip invalid JSON
          }
        }
      }
    }
  } catch (error) {
    yield {
      type: 'error',
      content: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

// Suggested queries for the chat interface
export const suggestedQueries = {
  authorization: [
    'What is my approval rate by card brand this month?',
    'Show me authorization trends for the last 7 days',
    'Which merchants have the lowest approval rates?',
    'What are the top decline reasons today?',
  ],
  settlement: [
    'What is my net settlement volume this month?',
    'Show me top 10 merchants by settlement volume',
    'How much did I pay in interchange fees last week?',
    'Compare sales vs refunds by card brand',
  ],
  funding: [
    'How much was deposited today?',
    'Show me funding breakdown by fee type',
    'What are my total fees this month?',
    'List deposits for the last 7 days',
  ],
  chargeback: [
    'What are my chargeback trends over the last 12 months?',
    'What is my chargeback win rate?',
    'Show chargebacks by reason code',
    'Which merchants have the most chargebacks?',
  ],
  retrieval: [
    'How many retrievals are due this week?',
    'What is my retrieval fulfillment rate?',
    'Show open retrievals by merchant',
    'List expired retrievals from last month',
  ],
  adjustment: [
    'Show me credit vs debit adjustments this month',
    'What are the total adjustments by type?',
    'List adjustments over $1,000',
    'What fees were adjusted this week?',
  ],
};

// Format SQL for display
export function formatSQL(sql: string): string {
  // Basic SQL formatting
  let formatted = sql;
  
  // Add newlines before major keywords
  const majorKeywords = ['FROM', 'WHERE', 'GROUP BY', 'ORDER BY', 'HAVING', 'LIMIT'];
  for (const keyword of majorKeywords) {
    const regex = new RegExp(`\\s+${keyword}\\s+`, 'gi');
    formatted = formatted.replace(regex, `\n${keyword} `);
  }

  // Indent subqueries and CASE statements
  formatted = formatted.replace(/\(\s*SELECT/gi, '(\n  SELECT');
  formatted = formatted.replace(/\s+WHEN\s+/gi, '\n    WHEN ');
  formatted = formatted.replace(/\s+ELSE\s+/gi, '\n    ELSE ');
  formatted = formatted.replace(/\s+END\s*/gi, '\n  END');

  return formatted.trim();
}
