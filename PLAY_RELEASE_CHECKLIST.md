# Google Play Release Runbook (Checkbox + Owner)

Scope: deploy su Google Play (Android).  
Date context: 2026-04-03.

Legenda owner:
- `[TU]` task da fare da console/credenziali/release account.
- `[CODEX]` task eseguibile nel repository da Codex.
- `[TU+CODEX]` task con passaggi condivisi.

Legenda priorita:
- `P0` blocca upload/review.
- `P1` non blocca upload, ma blocca rollout sereno.
- `P2` post-release hardening.

---

## P0 - Bloccanti prima dell'upload in Play

- [x] `[TU]` Confermare package Android definitivo (es. `it.tuodominio.iassistente`).
- [x] `[TU]` Confermare versione release (`x.y.z+build`) da usare per il primo upload.
- [x] `[TU]` Creare branch release (es. `release/play-v1`) da branch stabile.
- [x] `[CODEX]` Applicare rename package in [android/app/build.gradle.kts](android/app/build.gradle.kts) (`namespace` + `applicationId`).
- [x] `[CODEX]` Aggiornare package Kotlin in [android/app/src/main/kotlin/it/dallacog/mimir/MainActivity.kt](android/app/src/main/kotlin/it/dallacog/mimir/MainActivity.kt).
- [x] `[CODEX]` Spostare il file `MainActivity.kt` nella nuova cartella package se necessario.
- [x] `[CODEX]` Verificare coerenza manifest in [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml).
- [x] `[TU]` In Firebase Console creare/aggiornare app Android con package definitivo.
- [x] `[TU]` Scaricare e sostituire [android/app/google-services.json](android/app/google-services.json).
- [x] `[TU+CODEX]` Rigenerare/allineare [lib/firebase_options.dart](lib/firebase_options.dart) (`flutterfire configure` o allineamento manuale ai nuovi app id Firebase).
- [ ] `[TU]` In `.env` impostare `APP_ENV=production`.
- [ ] `[TU]` In `.env` impostare `DEV_BYPASS_AUTH=false`.
- [ ] `[TU]` In `.env` impostare `ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION=false`.
- [ ] `[TU]` In `.env` lasciare vuote `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` lato client.
- [ ] `[TU]` Impostare `LLM_PROXY_URL` su endpoint HTTPS pubblico.
- [ ] `[TU]` Impostare `LLM_PROXY_PROVIDER` coerente con backend.
- [ ] `[TU]` Impostare `LLM_PROXY_AUTH_TOKEN` lato client se il proxy richiede bearer.
- [ ] `[TU]` Deploy proxy production con HTTPS, dominio, restart policy, monitoring.
- [ ] `[TU]` Configurare backend env: `OPENAI_API_KEY` o `ANTHROPIC_API_KEY` o `GEMINI_API_KEY`.
- [ ] `[TU]` Configurare backend env: `PROXY_AUTH_TOKEN`, `PROXY_ALLOWED_ORIGIN`, `RATE_LIMIT_PER_MINUTE`.
- [ ] `[TU]` Verificare proxy `GET /health`.
- [ ] `[TU]` Verificare proxy `GET /v1/models`.
- [ ] `[TU]` Verificare proxy `POST /v1/chat` in modalita stream e non-stream.
- [ ] `[TU]` Creare keystore release e conservarla in sicurezza.
- [ ] `[TU]` Creare file locale `keystore.properties` da [keystore.properties.example](keystore.properties.example) (non committare).
- [ ] `[TU]` Estrarre SHA-1/SHA-256 upload key con `keytool`.
- [ ] `[TU]` Inserire SHA upload key in Firebase app Android.
- [ ] `[TU]` Dopo primo upload, recuperare SHA App Signing key da Play Console.
- [ ] `[TU]` Inserire anche SHA App Signing key in Firebase.
- [ ] `[TU]` Verificare requisito target API Play corrente (nuove app: Android 15 / API 35 o successivo requisito vigente).
- [x] `[CODEX]` Verificare `flutter analyze` verde.
- [x] `[CODEX]` Verificare `flutter test -r compact` verde con `NO_PROXY=localhost,127.0.0.1,::1`.
- [ ] `[TU]` Verificare login Firebase reale su device (email/password, Google se abilitato).
- [ ] `[TU]` Build AAB release: `flutter build appbundle --release`.
- [ ] `[TU]` Verificare output AAB in `build/app/outputs/bundle/release/`.

Done criteria P0:
Upload AAB possibile senza placeholder tecnici, auth e chat funzionanti su build release firmata.

---

## P0 - Play Console obbligatorio per review

- [ ] `[TU]` Creare app su Play Console con package definitivo.
- [ ] `[TU]` Compilare store listing principale (nome, short/full description, icona, feature graphic, screenshot phone).
- [ ] `[TU]` Inserire email supporto (e sito/telefono se richiesti).
- [ ] `[TU]` Inserire URL Privacy Policy pubblico.
- [ ] `[TU]` Compilare `App access` con credenziali review valide e istruzioni precise.
- [ ] `[TU]` Compilare dichiarazione `Ads` se ads attive.
- [ ] `[TU]` Compilare `Data safety` coerente con comportamento reale app.
- [ ] `[TU]` Compilare `Target audience`.
- [ ] `[TU]` Compilare `Content rating`.
- [ ] `[TU]` Compilare eventuali dichiarazioni specifiche applicabili (News, Health, Financial, ecc.).
- [ ] `[TU]` Se l'app consente creazione account in-app, completare sezione account deletion secondo policy Play.

Done criteria Play content:
Sezione `App content` e `Store presence` senza task pendenti bloccanti.

---

## P1 - Monetizzazione e test track robusti

- [ ] `[TU]` Creare prodotti IAP su Play Console con ID finali.
- [ ] `[TU]` Allineare `.env` con `IAP_PREMIUM_MONTHLY`, `IAP_PREMIUM_YEARLY`, `IAP_PREMIUM_LIFETIME`.
- [ ] `[TU]` Configurare AdMob app ID Android reale.
- [ ] `[TU]` Configurare AdMob banner/rewarded unit ID Android reali.
- [ ] `[TU]` Caricare AAB su `Internal testing`.
- [ ] `[TU]` Invitare tester interni.
- [ ] `[TU]` Verificare acquisto e restore in ambiente test.
- [ ] `[TU]` Verificare premium entitlement in app dopo acquisto/restore.
- [ ] `[TU]` Verificare caricamento ads (banner/rewarded) in test.
- [ ] `[TU]` Eseguire smoke completo su almeno 1 device reale Android:
- [ ] `[TU]` Smoke: onboarding/auth.
- [ ] `[TU]` Smoke: chat con proxy.
- [ ] `[TU]` Smoke: fallback provider.
- [ ] `[TU]` Smoke: allegati (txt/pdf/image OCR).
- [ ] `[TU]` Smoke: local RAG.
- [ ] `[TU]` Smoke: backup locale/cloud.
- [ ] `[TU]` Smoke: export dati utente.
- [ ] `[TU]` Smoke: premium/ads.
- [ ] `[TU]` Verificare scenari rete degradata/proxy down.
- [ ] `[TU]` Verificare regressione `Prefer offline`.
- [ ] `[TU]` Risolvere issue pre-launch report Play.
- [ ] `[TU]` Se account personale nuovo, completare closed test requirement (12 tester per 14 giorni continuativi).

Done criteria P1:
Internal/closed testing stabile, nessun bug P0/P1 aperto.

---

## P1 - CI/CD e gate release

- [x] `[CODEX]` Mantenere pipeline verde in [.github/workflows/flutter-ci.yml](.github/workflows/flutter-ci.yml).
- [x] `[CODEX]` Verificare step CI: runtime check, analyze, test, build smoke.
- [x] `[CODEX]` Aggiungere/aggiornare script release gate se richiesto da te (placeholder/package/env).
- [ ] `[TU]` Eseguire pipeline verde sull'ultimo commit candidato.

Done criteria CI:
Commit release candidate con pipeline completamente verde.

---

## P0/P1 - Go live

- [ ] `[TU]` Creare release `Production` da build validata.
- [ ] `[TU]` Avviare rollout graduale (es. 5%).
- [ ] `[TU]` Monitorare per 24-72h: crash rate, ANR, login failure, chat failure, IAP/ads anomalies.
- [ ] `[TU]` Aumentare rollout progressivo (20% -> 50% -> 100%).
- [ ] `[TU]` Confermare release 100% stabile.

Done criteria go live:
Rollout 100% senza incidenti critici.

---

## P2 - Post-release operativo

- [ ] `[TU+CODEX]` Definire runbook rollback (feature flags + hotfix path).
- [ ] `[TU]` Definire policy rotazione `PROXY_AUTH_TOKEN`.
- [ ] `[TU]` Archiviare note release tecniche (versionCode, commit, env usata).
- [ ] `[TU+CODEX]` Pianificare patch release successiva (bugfix + dependency updates).

---

## Comandi utili (Windows)

Debug Android stabile:

```powershell
.\scripts\run_android_debug.ps1
```

Verifica runtime config:

```powershell
.\scripts\check_runtime_config.ps1
```

Gate pre-release (strict):

```powershell
.\scripts\release_gate.ps1 -ExpectedPackage it.dallacog.mimir
```

Smoke locale completo:

```powershell
.\scripts\smoke_local.ps1
```

Build Play release:

```powershell
flutter build appbundle --release
```

---

## Fonti policy/requisiti (da ricontrollare sempre prima del submit)

- Target API requirement: https://developer.android.com/google/play/requirements/target-sdk
- App signing and upload keys: https://developer.android.com/guide/publishing/app-signing.html
- Flutter Android deployment: https://docs.flutter.dev/deployment/android
- New personal accounts testing requirement: https://support.google.com/googleplay/android-developer/answer/14151465
- Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- User data / account deletion: https://support.google.com/googleplay/android-developer/answer/10144311
- App access and review prep: https://support.google.com/googleplay/android-developer/answer/9859455
- Create and set up app / listing: https://support.google.com/googleplay/android-developer/answer/9859152
- Testing tracks: https://support.google.com/googleplay/android-developer/answer/9845334
- Managed publishing and review timing: https://support.google.com/googleplay/android-developer/answer/9859654
