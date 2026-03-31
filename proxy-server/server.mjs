import http from 'node:http';

const PORT = Number(process.env.PORT || 8787);
const RATE_LIMIT_PER_MINUTE = Number(process.env.RATE_LIMIT_PER_MINUTE || 60);
const rateMap = new Map();

function sendJson(res, code, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(code, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  });
  res.end(body);
}

function checkRateLimit(req) {
  const now = Date.now();
  const ip = req.socket.remoteAddress || 'unknown';
  const windowStart = now - 60_000;
  const entries = (rateMap.get(ip) || []).filter((ts) => ts >= windowStart);
  entries.push(now);
  rateMap.set(ip, entries);
  return entries.length <= RATE_LIMIT_PER_MINUTE;
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > 2_000_000) {
        reject(new Error('Payload too large'));
      }
    });
    req.on('end', () => {
      try {
        const parsed = raw ? JSON.parse(raw) : {};
        resolve(parsed);
      } catch (error) {
        reject(error);
      }
    });
    req.on('error', reject);
  });
}

async function callOpenAI({ model, messages, config }) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY non configurata sul server proxy.');
  }

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: model || 'gpt-4o-mini',
      temperature: Number(config?.temperature ?? 0.7),
      top_p: Number(config?.topP ?? 1.0),
      max_tokens: Number(config?.maxTokens ?? 1024),
      messages: [
        {
          role: 'system',
          content:
            (config?.systemPrompt || '').trim() ||
            'Sei un assistente AI italiano, educato e conciso.',
        },
        ...(Array.isArray(messages) ? messages : []),
      ],
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    const message = data?.error?.message || `HTTP ${response.status}`;
    throw new Error(message);
  }

  const reply = data?.choices?.[0]?.message?.content?.trim();
  if (!reply) {
    throw new Error('Risposta vuota dal provider.');
  }

  return reply;
}

async function callAnthropic({ model, messages, config }) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    throw new Error('ANTHROPIC_API_KEY non configurata sul server proxy.');
  }

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: model || 'claude-3-5-sonnet-20240620',
      system:
        (config?.systemPrompt || '').trim() ||
        'Sei un assistente AI italiano, educato e conciso.',
      max_tokens: Number(config?.maxTokens ?? 1024),
      temperature: Number(config?.temperature ?? 0.7),
      top_p: Number(config?.topP ?? 1.0),
      messages: (Array.isArray(messages) ? messages : []).map((message) => ({
        role: message.role === 'assistant' ? 'assistant' : 'user',
        content: message.content,
      })),
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    const message = data?.error?.message || `HTTP ${response.status}`;
    throw new Error(message);
  }

  const parts = Array.isArray(data?.content) ? data.content : [];
  const reply = parts
    .filter((part) => part?.type === 'text')
    .map((part) => part?.text || '')
    .join('')
    .trim();

  if (!reply) {
    throw new Error('Risposta vuota dal provider.');
  }

  return reply;
}

async function callGemini({ model, messages, config }) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY non configurata sul server proxy.');
  }

  const resolvedModel = model || 'gemini-1.5-flash';
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${resolvedModel}:generateContent`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [
            {
              text:
                (config?.systemPrompt || '').trim() ||
                'Sei un assistente AI italiano, educato e conciso.',
            },
          ],
        },
        contents: (Array.isArray(messages) ? messages : []).map((message) => ({
          role: message.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: message.content }],
        })),
        generationConfig: {
          temperature: Number(config?.temperature ?? 0.7),
          maxOutputTokens: Number(config?.maxTokens ?? 1024),
          topP: Number(config?.topP ?? 1.0),
        },
      }),
    },
  );

  const data = await response.json();
  if (!response.ok) {
    const message = data?.error?.message || `HTTP ${response.status}`;
    throw new Error(message);
  }

  const parts = data?.candidates?.[0]?.content?.parts;
  const reply = Array.isArray(parts)
    ? parts
        .map((part) => (typeof part?.text === 'string' ? part.text : ''))
        .join('')
        .trim()
    : '';

  if (!reply) {
    throw new Error('Risposta vuota dal provider.');
  }

  return reply;
}

function advertisedModels() {
  const models = [];
  if (process.env.OPENAI_API_KEY) {
    models.push(
      { id: 'gpt-4o-mini', label: 'gpt-4o-mini (OpenAI)' },
      { id: 'gpt-4o', label: 'gpt-4o (OpenAI)' },
    );
  }
  if (process.env.ANTHROPIC_API_KEY) {
    models.push(
      {
        id: 'claude-3-5-sonnet-20240620',
        label: 'claude-3-5-sonnet-20240620 (Anthropic)',
      },
      {
        id: 'claude-3-5-haiku-20241022',
        label: 'claude-3-5-haiku-20241022 (Anthropic)',
      },
    );
  }
  if (process.env.GEMINI_API_KEY) {
    models.push(
      { id: 'gemini-1.5-flash', label: 'gemini-1.5-flash (Gemini)' },
      { id: 'gemini-1.5-pro', label: 'gemini-1.5-pro (Gemini)' },
    );
  }
  return models.length > 0
    ? models
    : [
        { id: 'gpt-4o-mini', label: 'gpt-4o-mini (OpenAI)' },
        { id: 'gpt-4o', label: 'gpt-4o (OpenAI)' },
      ];
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
    });
    res.end();
    return;
  }

  if (req.method === 'GET' && req.url === '/v1/models') {
    sendJson(res, 200, {
      models: advertisedModels(),
    });
    return;
  }

  if (req.method !== 'POST' || req.url !== '/v1/chat') {
    sendJson(res, 404, { error: 'Not found' });
    return;
  }

  if (!checkRateLimit(req)) {
    sendJson(res, 429, { error: 'Rate limit superato. Riprova tra poco.' });
    return;
  }

  try {
    const body = await readJson(req);
    const provider = (body.provider || 'openai').toLowerCase();
    let reply;
    if (provider === 'openai') {
      reply = await callOpenAI(body);
    } else if (provider === 'anthropic' || provider === 'claude') {
      reply = await callAnthropic(body);
    } else if (provider === 'gemini') {
      reply = await callGemini(body);
    } else {
      sendJson(res, 400, {
        error:
          'Provider non supportato da questo proxy: usa openai, anthropic o gemini.',
      });
      return;
    }
    sendJson(res, 200, { reply });
  } catch (error) {
    sendJson(res, 500, {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(PORT, () => {
  console.log(`Proxy server listening on http://localhost:${PORT}`);
});
