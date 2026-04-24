import http from 'node:http';

const PORT = Number(process.env.PORT || 8787);
const RATE_LIMIT_PER_MINUTE = Number(process.env.RATE_LIMIT_PER_MINUTE || 60);
const PROXY_AUTH_TOKEN = (process.env.PROXY_AUTH_TOKEN || '').trim();
const PROXY_ALLOWED_ORIGIN = (process.env.PROXY_ALLOWED_ORIGIN || '*').trim();
const rateMap = new Map();

function responseHeaders(extra = {}) {
  return {
    'Access-Control-Allow-Origin': PROXY_ALLOWED_ORIGIN || '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    ...extra,
  };
}

function sendJson(res, code, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(
    code,
    responseHeaders({
      'Content-Type': 'application/json; charset=utf-8',
    }),
  );
  res.end(body);
}

function startSse(res) {
  res.writeHead(
    200,
    responseHeaders({
      'Content-Type': 'text/event-stream; charset=utf-8',
      'Cache-Control': 'no-cache, no-transform',
      Connection: 'keep-alive',
      'X-Accel-Buffering': 'no',
    }),
  );
}

function sendSseData(res, payload) {
  res.write(`data: ${JSON.stringify(payload)}\n\n`);
}

function sendSseDone(res) {
  res.write('data: [DONE]\n\n');
  res.end();
}

function ensureAuthorized(req, res) {
  if (!PROXY_AUTH_TOKEN) return true;
  const header = req.headers.authorization || '';
  const expected = `Bearer ${PROXY_AUTH_TOKEN}`;
  if (header === expected) return true;
  sendJson(res, 401, { error: 'Unauthorized proxy request.' });
  return false;
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

async function readWebStream(body, onTextChunk) {
  if (!body) return;
  const reader = body.getReader();
  const decoder = new TextDecoder();
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    if (value) {
      await onTextChunk(decoder.decode(value, { stream: true }));
    }
  }
  const tail = decoder.decode();
  if (tail) {
    await onTextChunk(tail);
  }
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

async function callGroq({ model, messages, config }) {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) {
    throw new Error('GROQ_API_KEY non configurata sul server proxy.');
  }

  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: model || 'llama-3.1-8b-instant',
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

async function streamOpenAI({ model, messages, config, res }) {
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
      stream: true,
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

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(errorBody || `HTTP ${response.status}`);
  }

  let buffer = '';
  let ended = false;
  await readWebStream(response.body, async (textChunk) => {
    if (ended) return;
    buffer += textChunk;
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      const dataLine = trimmed.slice(5).trim();
      if (dataLine === '[DONE]') {
        ended = true;
        sendSseDone(res);
        return;
      }
      const json = JSON.parse(dataLine);
      const delta = json?.choices?.[0]?.delta?.content;
      if (typeof delta === 'string' && delta.length > 0) {
        sendSseData(res, { delta });
      }
    }
  });

  if (!ended) {
    sendSseDone(res);
  }
}

async function streamGroq({ model, messages, config, res }) {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) {
    throw new Error('GROQ_API_KEY non configurata sul server proxy.');
  }

  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: model || 'llama-3.1-8b-instant',
      stream: true,
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

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(errorBody || `HTTP ${response.status}`);
  }

  let buffer = '';
  let ended = false;
  await readWebStream(response.body, async (textChunk) => {
    if (ended) return;
    buffer += textChunk;
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      const dataLine = trimmed.slice(5).trim();
      if (dataLine === '[DONE]') {
        ended = true;
        sendSseDone(res);
        return;
      }
      const json = JSON.parse(dataLine);
      const delta = json?.choices?.[0]?.delta?.content;
      if (typeof delta === 'string' && delta.length > 0) {
        sendSseData(res, { delta });
      }
    }
  });

  if (!ended) {
    sendSseDone(res);
  }
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

async function streamAnthropic({ model, messages, config, res }) {
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
      stream: true,
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

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(errorBody || `HTTP ${response.status}`);
  }

  let buffer = '';
  let ended = false;
  let eventType = '';
  await readWebStream(response.body, async (textChunk) => {
    if (ended) return;
    buffer += textChunk;
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      if (trimmed.startsWith('event:')) {
        eventType = trimmed.slice(6).trim();
        continue;
      }
      if (!trimmed.startsWith('data:')) continue;
      const dataLine = trimmed.slice(5).trim();
      if (dataLine === '[DONE]') {
        ended = true;
        sendSseDone(res);
        return;
      }
      const json = JSON.parse(dataLine);
      const type = eventType || json?.type;
      if (type === 'content_block_delta') {
        const delta = json?.delta?.text;
        if (typeof delta === 'string' && delta.length > 0) {
          sendSseData(res, { delta });
        }
      }
    }
  });

  if (!ended) {
    sendSseDone(res);
  }
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

async function streamGemini({ model, messages, config, res }) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY non configurata sul server proxy.');
  }

  const resolvedModel = model || 'gemini-1.5-flash';
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${resolvedModel}:streamGenerateContent?alt=sse`,
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

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(errorBody || `HTTP ${response.status}`);
  }

  let buffer = '';
  let ended = false;
  await readWebStream(response.body, async (textChunk) => {
    if (ended) return;
    buffer += textChunk;
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      const dataLine = trimmed.slice(5).trim();
      if (dataLine === '[DONE]') {
        ended = true;
        sendSseDone(res);
        return;
      }
      const json = JSON.parse(dataLine);
      const parts = json?.candidates?.[0]?.content?.parts;
      if (!Array.isArray(parts)) continue;
      for (const part of parts) {
        if (typeof part?.text === 'string' && part.text.length > 0) {
          sendSseData(res, { delta: part.text });
        }
      }
    }
  });

  if (!ended) {
    sendSseDone(res);
  }
}

function advertisedModels() {
  const models = [];
  if (process.env.OPENAI_API_KEY) {
    models.push(
      { id: 'gpt-4o-mini', label: 'gpt-4o-mini (OpenAI)' },
      { id: 'gpt-4o', label: 'gpt-4o (OpenAI)' },
    );
  }
  if (process.env.GROQ_API_KEY) {
    models.push(
      { id: 'llama-3.1-8b-instant', label: 'llama-3.1-8b-instant (Groq)' },
      { id: 'llama-3.3-70b-versatile', label: 'llama-3.3-70b-versatile (Groq)' },
      { id: 'qwen/qwen3-32b', label: 'qwen/qwen3-32b (Groq)' },
      { id: 'openai/gpt-oss-120b', label: 'openai/gpt-oss-120b (Groq)' },
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

function logStartupStatus() {
  const availableProviders = [
    process.env.OPENAI_API_KEY ? 'openai' : null,
    process.env.GROQ_API_KEY ? 'groq' : null,
    process.env.ANTHROPIC_API_KEY ? 'anthropic' : null,
    process.env.GEMINI_API_KEY ? 'gemini' : null,
  ].filter(Boolean);

  console.log(
    `[proxy] enabled providers: ${availableProviders.join(', ') || 'none'}`,
  );
  console.log(
    `[proxy] auth token: ${PROXY_AUTH_TOKEN ? 'configured' : 'not configured'}`,
  );
  if (availableProviders.length === 0) {
    console.warn('[proxy] warning: no upstream provider API key is configured.');
  }
  if (!PROXY_AUTH_TOKEN) {
    console.warn(
      '[proxy] warning: PROXY_AUTH_TOKEN is empty, so the endpoint is public.',
    );
  }
  if (PROXY_ALLOWED_ORIGIN === '*') {
    console.warn('[proxy] warning: PROXY_ALLOWED_ORIGIN is set to "*".');
  }
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, responseHeaders());
    res.end();
    return;
  }

  if (req.method === 'GET' && req.url === '/health') {
    sendJson(res, 200, {
      ok: true,
      providers: advertisedModels(),
      authRequired: Boolean(PROXY_AUTH_TOKEN),
    });
    return;
  }

  if (req.method === 'GET' && req.url === '/v1/models') {
    if (!ensureAuthorized(req, res)) return;
    sendJson(res, 200, {
      models: advertisedModels(),
    });
    return;
  }

  if (req.method !== 'POST' || req.url !== '/v1/chat') {
    sendJson(res, 404, { error: 'Not found' });
    return;
  }

  if (!ensureAuthorized(req, res)) return;

  if (!checkRateLimit(req)) {
    sendJson(res, 429, { error: 'Rate limit superato. Riprova tra poco.' });
    return;
  }

  try {
    const body = await readJson(req);
    const provider = (body.provider || 'openai').toLowerCase();
    const wantsStream = body.stream === true;

    if (wantsStream) {
      startSse(res);
      if (provider === 'openai') {
        await streamOpenAI({ ...body, res });
      } else if (provider === 'groq') {
        await streamGroq({ ...body, res });
      } else if (provider === 'anthropic' || provider === 'claude') {
        await streamAnthropic({ ...body, res });
      } else if (provider === 'gemini') {
        await streamGemini({ ...body, res });
      } else {
        sendSseData(res, {
          error:
            'Provider non supportato da questo proxy: usa openai, groq, anthropic o gemini.',
        });
        sendSseDone(res);
      }
      return;
    }

    let reply;
    if (provider === 'openai') {
      reply = await callOpenAI(body);
    } else if (provider === 'groq') {
      reply = await callGroq(body);
    } else if (provider === 'anthropic' || provider === 'claude') {
      reply = await callAnthropic(body);
    } else if (provider === 'gemini') {
      reply = await callGemini(body);
    } else {
      sendJson(res, 400, {
        error:
          'Provider non supportato da questo proxy: usa openai, groq, anthropic o gemini.',
      });
      return;
    }
    sendJson(res, 200, { reply });
  } catch (error) {
    if (res.headersSent) {
      sendSseData(res, {
        error: error instanceof Error ? error.message : String(error),
      });
      sendSseDone(res);
      return;
    }
    sendJson(res, 500, {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(PORT, () => {
  logStartupStatus();
  console.log(`Proxy server listening on http://localhost:${PORT}`);
});
