# Proxy Server (LLM)

Server minimale per tenere le API key lato backend.

## Avvio

```bash
cd proxy-server
OPENAI_API_KEY=... node server.mjs
```

Endpoint esposto:

- `POST /v1/chat`
- `GET /v1/models`

Payload atteso (compatibile con `ProxyProvider` dell'app):

```json
{
  "provider": "openai",
  "model": "gpt-4o-mini",
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
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GEMINI_API_KEY`

Provider supportati:

- `openai`
- `anthropic`
- `gemini`
