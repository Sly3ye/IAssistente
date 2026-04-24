# Base Chatbot Test Flow

Scopo: chiudere il perimetro della versione "chatbot base" prima di aggiungere feature verticali.

Definizione di "base chatbot completa":
- login e sessione stabili
- chat LLM funzionante end-to-end
- navigazione coerente
- allegati e funzioni gia presenti senza regressioni
- settings/account/privacy consistenti
- nessun blocco P0/P1 aperto nel flusso core

Regola di test:
- esegui i test in ordine
- per ogni punto segna `PASS`, `FAIL`, `N/A`
- quando un punto fallisce, annota:
  - schermata
  - passaggi per riprodurlo
  - risultato atteso
  - risultato reale

---

## 0. Prerequisiti

- [x] App avviabile in locale senza crash all'apertura
- [x] Provider di test funzionante configurato
  - esempio attuale: `Groq`
- [x] Build aggiornata dopo le ultime patch
- [x] Account test disponibile
- [x] Connessione internet stabile

---

## 1. Smoke iniziale

- [x] Apertura app su splash/login senza freeze
  - Significa: l'app si apre e raggiunge login o home senza caricamenti infiniti, blocchi o schermata ferma.
- [x] Nessun overflow visivo evidente all'avvio
  - Significa: appena entri in app non devono esserci scritte tagliate, barre gialle/nere, widget fuori schermo o errori come `bottom overflowed`.
- [x] Tema coerente su login, chat, drawer, settings, account
- [x] Nessun testo placeholder/finto fuori posto

Esito blocco:
- `PASS` se l'app entra nel flusso core senza errori visivi o funzionali immediati

---

## 2. Login e sessione

### Email/password
- [x] Login con account valido
  - Significa: inserisci email e password corrette di un account esistente e l'app deve portarti dentro con il profilo giusto, non in guest e non con il profilo precedente.
- [x] Errore corretto con password errata
- [x] Reset password avviabile senza crash
  - Significa: dal login premi `Recover`, con email valida inserita. L'app deve mostrare conferma o errore gestito, ma non deve bloccarsi, chiudersi o rompere il layout.
- [x] Logout funzionante
- [x] Riapertura app con sessione persistente

### Provider federati
- [x] Google Sign-In funziona in ambiente locale corretto
- [ ] Apple Sign-In non rompe la UI se non disponibile

### Stato account
- [x] Email/profilo mostrati correttamente
- [x] Stato verifica email coerente

Esito blocco:
- `PASS` se login, persistenza sessione e logout sono affidabili

---

## 3. Chat core

### Invio messaggi
- [x] Creazione nuova chat
- [x] Invio messaggio semplice
- [x] Risposta del modello ricevuta correttamente
- [x] Primo messaggio non resta bloccato su `Sto scrivendo...`
- [x] Titolo chat generato o fallback stabile

### Stabilita
- [x] Nessun caricamento infinito
- [x] Retry ultimo messaggio funzionante
- [x] Cancel durante invio funzionante
- [x] Nuova chat durante sessione lunga non rompe lo stato

### Cronologia
- [x] Cronologia chat caricata correttamente dal drawer
- [x] Cambio chat senza dati corrotti
- [x] Rename chat funzionante
- [x] Delete chat funzionante

Esito blocco:
- `PASS` se la chat e usabile come prodotto reale, non solo come demo

---

## 4. Provider e modelli

### Selezione modello
- [x] Apertura model settings sheet
- [x] Cambio provider funzionante
- [x] Cambio modello funzionante
- [x] Nuova chat usa il provider/modello selezionato
- [x] Chat esistente aggiorna provider/modello quando richiesto

### Configurazioni runtime
- [x] Standard/Deep mode cambia comportamento senza rompere la chat
- [x] Memory toggle salvato correttamente
- [x] Safety toggle salvato correttamente
- [x] Auto-switch toggle salvato correttamente
- [x] Prefer offline toggle salvato correttamente
- [x] RAG toggle salvato correttamente
- [x] Analytics consent salvato correttamente
- [x] Ads consent salvato correttamente

### Persistenza
- [x] Chiudi e riapri l'app: provider e modello restano coerenti

Esito blocco:
- `PASS` se le impostazioni non sono solo grafiche ma influenzano davvero lo stato

---

## 5. Allegati

### File supportati
- [x] Allegato txt
- [x] Allegato pdf
- [x] Allegato immagine
- [x] Allegato formato non supportato gestito con messaggio corretto

### Comportamento
- [x] Allegare un file non crasha il composer
- [x] Il prompt generato dall'allegato e coerente
- [x] Le immagini non vengono OCRizzate in modo inatteso se non previsto
- [x] PDF e testo hanno fallback leggibile

Esito blocco:
- `PASS` se il flusso allegati e stabile e comprensibile
- Nota: preview e flusso UI allegati verificati. Analisi immagine end-to-end del modello rimandata ai provider a pagamento.

---

## 6. RAG locale e memoria

### Indicizzazione
- [x] Se RAG e attivo, un testo allegato viene indicizzato
- [x] Snack/message di indicizzazione coerente
- [x] Nessun crash con documenti multipli

### Uso runtime
- [x] Chat con RAG attivo non si rompe
- [x] Chat con RAG disattivo non usa fonti residue

### Gestione dati
- [x] RAG documents persistono correttamente
- [x] Delete singolo documento funziona
- [x] Clear totale documenti funziona

Esito blocco:
- `PASS` se RAG esistente e affidabile anche senza nuove feature
- Nota: schermata `Documenti RAG` aggiunta e verificata; preview allegati nel composer resa orizzontale per evitare copertura della chat.

---

## 7. Drawer e navigazione

- [x] Drawer si apre senza lag
- [x] Gerarchia pinned/recent leggibile
- [x] Selezione conversazione corretta
- [x] CTA `New Conversation` funziona sempre
- [x] Accesso a settings/account corretto
- [x] Nessun clipping, overflow o testo troncato male

Esito blocco:
- `PASS` se la navigazione mobile e affidabile e leggibile
- Nota: drawer semplificato a lista unica ordinata per utilizzo, con supporto `Fissa` via long-press.

---

## 8. Account e privacy

### Profilo
- [x] Modifica nome
- [x] Modifica avatar URL
- [x] Cambio lingua
- [x] Salvataggio profilo funzionante

### Sicurezza
- [x] Stato auth mostrato correttamente
- [x] Invio verifica email funzionante
- [x] Refresh stato verifica funzionante

### Backup e dati
- [ ] Push cloud backup
- [ ] Pull cloud backup
- [ ] Export archivio utente
- [x] Clear local chats/messages
- [x] Delete account flow apribile senza crash

### Consensi
- [x] Toggle analytics
- [x] Toggle ads

Esito blocco:
- `PASS` se account/privacy e serio e non solo presentazione
- Nota: `Push cloud backup` è bloccato da configurazione esterna Firebase/Firestore (`Cloud Firestore API disabled` sul progetto `chatbot-ce96f`).
- Nota: `Pull cloud backup` e `Export archivio utente` mostrano esito UI coerente ma non sono ancora verificati end-to-end su file/restore reale.

---

## 9. Audio e assistive features

- [x] Microfono parte correttamente
- [x] Speech-to-text inserisce testo nel composer
- [x] Stop mic funziona
- [x] Read last reply / TTS funziona
- [x] Se microfono/TTS non sono disponibili, l'app non crasha

Esito blocco:
- `PASS` se le feature audio sono stabili o degradano bene
- Nota: TTS attualmente usa voci native del device, filtrate a shortlist piu pulita nelle impostazioni.

---

## 10. Stati limite ed errori

### Error handling
- [x] Nessuna API key / provider non configurato mostra errore leggibile
- [x] Provider down mostra errore leggibile
- [x] Timeout rete mostra errore leggibile
- [x] Nessun blocco permanente su `Sto scrivendo...`

### Resilienza
- [x] Cambio provider dopo errore funziona
- [x] Riapertura app dopo errore funziona
- [x] Nessun crash su rotazione o background/foreground normale

Esito blocco:
- `PASS` se gli errori sono recuperabili e comprensibili
- Nota: il caso `provider down/quota` non e stato isolato separatamente da `provider non configurato`, ma la famiglia di errore gestita lato UX e stata verificata.

---

## 11. UI/UX quality gate

Questa sezione serve a decidere se la base e "pubblicabile come prodotto base", non solo se "funziona".

- [x] Nessun elemento grafico evidentemente vecchio o incoerente
- [x] Nessun testo che esce dai limiti
- [x] Nessun componente con spaziature sbagliate evidenti
- [x] Nessun copy placeholder, tecnico o finto
- [x] Nessuna schermata importante che sembri MVP grezzo
- [x] Chat, login, drawer, settings, account sembrano parte dello stesso prodotto

Esito blocco:
- `PASS` se la percezione generale e coerente e affidabile

---

## 12. Criteri di chiusura della base chatbot

La versione "chatbot base" si considera chiusa solo se:

- [ ] Tutti i blocchi 1-11 sono `PASS` oppure `N/A` motivato
- [ ] Nessun bug P0 aperto
- [ ] Nessun bug P1 aperto sul flusso core
- [ ] La chat risponde in modo stabile con il provider di test scelto
- [ ] UI e UX del flusso base sono abbastanza solide da evitare rework strutturali

Quando questi criteri sono soddisfatti:
- si congela la base chatbot
- si apre il blocco "feature interessanti / differenzianti"

---

## 13. Post-Base Backlog

Residui rimandati fuori dal perimetro "chatbot base":

- [ ] Modulo 8 - Push cloud backup
  - Bloccato da configurazione esterna Firebase/Firestore (`Cloud Firestore API disabled` sul progetto `chatbot-ce96f`)
- [ ] Modulo 8 - Pull cloud backup
  - Da verificare end-to-end dopo sblocco Firestore
- [ ] Modulo 8 - Export archivio utente verificabile da UI
  - Oggi il file viene generato nei documenti app, ma manca un flusso chiaro `open/share` per validarlo lato utente

---

## Template bug report rapido

```text
Titolo:
Schermata:
Passi per riprodurre:
1.
2.
3.

Atteso:

Risultato reale:

Frequenza:

Screenshot/log:
```

---

## Priorita pratica durante il test

Ordine consigliato:
1. Login/sessione
2. Chat core
3. Provider/modelli
4. Allegati
5. Drawer/navigation
6. Account/privacy
7. Audio
8. Error handling
9. Rifinitura UI

Questo e l'ordine con il miglior rapporto segnale/tempo: prima chiudi la funzionalita, poi la robustezza, poi la finitura.
