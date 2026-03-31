# VDeploy — Obiettivo Prodotto (App Chatbot GPT-like)

Data: 2026-02-02
Stato: Definito
Piattaforma: Mobile (Flutter). Estensione Web dopo deploy.

## Stato implementazione (agg. 2026-03-05)
- Completato: Multi-provider LLM (OpenAI, Claude, Gemini, Ollama + Proxy backend), streaming, login obbligatorio (Apple/Google/email), fallback automatico provider, impostazioni per chat (system prompt/temperature/max tokens/topP), ricerca chat full-text, export/import backup locale JSON, export chat markdown, quota token giornaliera con stima costi, retry/timeout/backoff con circuit-breaker, preset prompt, moderazione input, memoria utente opt-in, onboarding A/B base, voice mode MVP (STT/TTS), allegati con estrazione testo PDF/OCR immagini, RAG locale persistito con gestione documenti, monetizzazione base ads+premium, UI multilingua it/en, privacy UX con consensi/export/backup cloud/cancellazione account, profilo base (nome/avatar/lingua).
- Note di configurazione esterna: per acquisti reali servono product ID store in `.env`; per ads reali servono unit ID AdMob; per il proxy multi-provider servono le relative API key lato server.

## 1) Visione sintetica
Un’app mobile chatbot GPT-like, multi-provider (GPT, Claude, Gemini), con login obbligatorio, streaming in tempo reale, supporto allegati, RAG locale, monetizzazione tramite ads + abbonamenti, multilingua. VDeploy include ciò che serve per competere con app simili sul mercato.

## 2) Obiettivi chiave (VDeploy)
- Esperienza chat fluida e competitiva (UI moderna, streaming, qualità risposta).
- Multi-provider per vantaggio competitivo e continuità servizio.
- Allegati e RAG locale per valore aggiunto immediato.
- Monetizzazione sostenibile senza perdita economica.
- Privacy e trasparenza adeguate per app pubblica.

## 3) Scope funzionale (obbligatorio)
### 3.1 Chat e UI
- Lista chat + dettaglio chat con messaggi e streaming obbligatorio.
- Stato “sta scrivendo”, errori, retry, rate limit lato client.
- Input con supporto per testo + allegati.
- Ricerca nelle chat e gestione (rinomina, elimina).

### 3.2 Autenticazione
- Login obbligatorio.
- Provider: Apple, Google, email/password.
- Gestione profilo base (nome, avatar, lingua).

### 3.3 Multi-provider LLM
- Integrazione GPT, Claude, Gemini.
- Selezione provider per chat e fallback manuale.
- Parametri modello per chat: temperature, max tokens, system prompt.

### 3.4 Allegati (minimo competitivo)
Se “tutto” è troppo complesso per VDeploy, il minimo competitivo è:
- Immagini (upload + analisi).
- PDF (lettura + estrazione testo).
- Documenti di testo (txt, md).
Audio/video restano fuori scope VDeploy se complessità elevata.

### 3.5 RAG locale
- Indicizzazione locale degli allegati.
- Retrieval per chat con controllo esplicito (toggle on/off).
- No cloud RAG in VDeploy.

### 3.6 Multilingua
- UI multilingua.
- Risposte modello in lingua selezionata.

### 3.7 Monetizzazione
- Ads: trigger basato su token consumati.
- Abbonamenti: sblocco quota token + feature premium (es. generazione immagini).
- Logica ads/token progettata per non andare in perdita.

## 4) Privacy e conformità (definita dal prodotto)
Per competere e pubblicare in store, includere:
- Informativa privacy chiara in-app.
- Consenso analytics/ads (opt-in/opt-out).
- Esportazione dati utente (locale).
- Cancellazione account + rimozione dati locali.
- Policy conservazione dati locali.

## 5) Requisiti non funzionali
- Performance: streaming fluido, UI responsiva.
- Affidabilità: retry, fallback provider manuale.
- Sicurezza: gestione sicura token/provider e chiavi.
- Scalabilità: architettura pronta a supporto web post-deploy.

## 6) Requisiti tecnici minimi
- Flutter + Riverpod per stato e DI.
- Persistenza locale con Drift/SQLite.
- Networking con http (streaming SSE).
- Gestione chiavi API tramite .env.
- Modulo RAG locale con indicizzazione base (embedding locale o on-device).

## 6) Fuori scope VDeploy
- RAG cloud.
- Estensione web/desktop.
- Audio e video avanzati (se non essenziali per competere).
- Automazioni complesse o agenti multi-step.

## 7) Backlog iniziale (ordine consigliato)
1. Multi-provider LLM (OpenAI, Claude, Gemini).
2. Streaming robusto per tutti i provider.
3. Login obbligatorio (Apple/Google/email).
4. Allegati base + RAG locale.
5. Monetizzazione (ads/token + abbonamenti).
6. Privacy UX (consensi, esportazione, cancellazione).

## 8) Decisioni aperte (da chiudere prima sviluppo)
- Provider predefinito e criteri di fallback.
- Policy ads/token (valori precisi in base a CPM/ricavi).
- Priorità allegati avanzati (audio/video).
- Pricing e tier degli abbonamenti.

## 9) Deliverable attesi
- App mobile Flutter pronta al deploy.
- Integrazione multi-provider LLM funzionante.
- Streaming obbligatorio attivo.
- Allegati + RAG locale.
- Login con Apple/Google/email.
- Ads + abbonamenti con limiti token.
- Documento privacy e schermate consenso.

## 10) Roadmap post-deploy (non VDeploy)
- RAG cloud.
- Web app.
- Miglioramenti advanced attachments (audio/video).
- Funzioni avanzate (memory a lungo termine, agenti).
