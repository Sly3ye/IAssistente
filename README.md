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
- Profilo base e privacy UX: nome, avatar URL, lingua, export dati, cloud backup, delete account
- Monetizzazione base: banner/rewarded ads, premium via store products, quota premium
- UI multilingua: italiano / inglese

## Setup rapido

1. Crea il file `.env` da `.env.example`.
2. Configura Firebase (`lib/firebase_options.dart` già incluso).
3. Avvia:

```bash
flutter pub get
flutter run
```

## Proxy backend (consigliato)

Per non esporre API key nel client, usa il provider `Proxy`:

```bash
cd proxy-server
OPENAI_API_KEY=... node server.mjs
```

Poi in `.env` dell'app:

```env
LLM_PROXY_URL=http://localhost:8787/v1/chat
LLM_PROXY_PROVIDER=openai
```

## Test

```bash
flutter analyze
flutter test
```
