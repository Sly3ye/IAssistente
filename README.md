# iassistente

Wrapper LLM multi-provider in Flutter con chat persistenti, auth Firebase, streaming e fallback automatico.

## Feature principali

- Chat multi-provider: `Proxy`, `OpenAI`, `Claude`, `Gemini`, `Ollama`
- Streaming risposta e stop generazione
- Retry, modifica messaggio utente, rinomina/elimina chat
- Impostazioni per chat: `system prompt`, `temperature`, `topP`, `max tokens`
- Fallback automatico provider/model
- Retry/timeout/backoff + circuit breaker provider
- Persistenza locale con Drift/SQLite
- Quota token giornaliera e stima costo locale
- Ricerca chat full-text (titolo + contenuti messaggi)
- Backup locale JSON: export/import ultimo backup
- Export chat corrente in Markdown
- Prompt preset salvabili
- Tool locali: `/help`, `/time`, `/date`, `/calc`
- Memoria utente opt-in e moderazione input opt-in
- Voice mode MVP: dettatura STT + lettura risposta TTS
- Allegati completi: txt/md/json/csv/yaml + estrazione PDF + OCR immagini
- RAG locale persistito sugli allegati con gestione documenti
- Login Firebase: email/password, Google, Apple
- Reset password e invio email di verifica
- Profilo base e privacy UX: nome, avatar URL, lingua, export dati, cloud backup, delete account
- Monetizzazione base: banner/rewarded ads, premium via store products, quota premium
- UI multilingua: italiano / inglese
- Diagnostica runtime, Remote Config base, analytics/crash reporting gated da consenso

## Setup rapido

1. Crea il file `.env` da `.env.example`.
2. Configura Firebase (`lib/firebase_options.dart` già incluso).
3. Per deploy reale: compila anche gli ID AdMob e IAP nel `.env`.
4. Avvia:

```bash
flutter pub get
flutter run
```

## Proxy backend (consigliato)

Per non esporre API key nel client, usa il provider `Proxy`:

```bash
cd proxy-server
cp .env.example .env
set -a
source .env
set +a
node server.mjs
```

Poi in `.env` dell'app:

```env
LLM_PROXY_URL=http://localhost:8787/v1/chat
LLM_PROXY_PROVIDER=openai
LLM_PROXY_AUTH_TOKEN=...
```

Il proxy ora supporta:

- auth tramite bearer token opzionale
- streaming SSE
- endpoint `GET /health`
- endpoint `GET /v1/models`

## Test

```bash
./scripts/check_runtime_config.sh
flutter analyze
flutter test
./scripts/smoke_local.sh
```
