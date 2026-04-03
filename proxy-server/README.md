# Proxy Server (LLM)

Server minimale per tenere le API key lato backend.

## Avvio

```bash
cd proxy-server
cp .env.example .env
node server.mjs
```

PowerShell:

```powershell
cd proxy-server
Copy-Item .env.example .env -Force
$env:OPENAI_API_KEY = "..."
node server.mjs
```

Endpoint esposto:

- `POST /v1/chat`
- `GET /v1/models`
- `GET /health`

Payload atteso (compatibile con `ProxyProvider` dell'app):

```json
{
  "provider": "openai",
  "model": "gpt-4o-mini",
  "stream": false,
  "messages": [{"role":"user","content":"Ciao"}],
  "config": {
    "systemPrompt": "Sei un assistente AI italiano, educato e conciso.",
    "temperature": 0.7,
    "maxTokens": 1024,
    "topP": 1.0
  }
}
```

Risposta:

```json
{ "reply": "..." }
```

Variabili utili:

- `PORT` (default `8787`)
- `RATE_LIMIT_PER_MINUTE` (default `60`)
- `PROXY_ALLOWED_ORIGIN` (default `*`)
- `PROXY_AUTH_TOKEN` (richiesto dal client se impostato)
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GEMINI_API_KEY`

Provider supportati:

- `openai`
- `anthropic`
- `gemini`

## Streaming

Se il body contiene `"stream": true`, il proxy risponde in `text/event-stream`
con messaggi del tipo:

```text
data: {"delta":"..."}

data: [DONE]
```
