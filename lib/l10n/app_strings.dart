import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings._(this.languageCode);

  final String languageCode;

  static const supportedLanguageCodes = <String>['it', 'en'];
  static const supportedLocales = <Locale>[Locale('it'), Locale('en')];

  static AppStrings ofCode(String code) {
    final normalized = supportedLanguageCodes.contains(code) ? code : 'it';
    return AppStrings._(normalized);
  }

  bool get isEnglish => languageCode == 'en';

  String pick({required String it, required String en}) {
    return isEnglish ? en : it;
  }

  String languageLabel(String code) {
    switch (code) {
      case 'en':
        return pick(it: 'Inglese', en: 'English');
      case 'it':
      default:
        return pick(it: 'Italiano', en: 'Italian');
    }
  }

  String modelLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'it':
      default:
        return 'Italian';
    }
  }

  String get appTitle => pick(it: 'Mimir', en: 'Mimir');
  String get configureFirebase => pick(
    it: 'Configura Firebase e riprova.',
    en: 'Configure Firebase and try again.',
  );
  String bootstrapError(Object error) => pick(
    it: 'Errore bootstrap: $error\n$configureFirebase',
    en: 'Bootstrap error: $error\n$configureFirebase',
  );
  String authError(Object error) => pick(
    it: 'Errore autenticazione: $error\n$configureFirebase',
    en: 'Authentication error: $error\n$configureFirebase',
  );

  String get login => pick(it: 'Accedi', en: 'Sign in');
  String get createAccount => pick(it: 'Crea un account', en: 'Create account');
  String get email => pick(it: 'Email', en: 'Email');
  String get password => pick(it: 'Password', en: 'Password');
  String get register => pick(it: 'Registrati', en: 'Register');
  String get forgotPassword =>
      pick(it: 'Password dimenticata?', en: 'Forgot password?');
  String get sendResetEmail =>
      pick(it: 'Invia reset password', en: 'Send password reset');
  String resetEmailSent(String email) => pick(
    it: 'Email di reset inviata a $email.',
    en: 'Password reset email sent to $email.',
  );
  String get continueWithGoogle =>
      pick(it: 'Continua con Google', en: 'Continue with Google');
  String get continueWithApple =>
      pick(it: 'Continua con Apple', en: 'Continue with Apple');
  String get alreadyHaveAccount => pick(
    it: 'Hai gia un account? Accedi',
    en: 'Already have an account? Sign in',
  );
  String get noAccount => pick(
    it: 'Non hai un account? Registrati',
    en: 'No account yet? Register',
  );
  String get guestMode => pick(it: 'Modalita guest', en: 'Guest mode');
  String get enterEmailAndPassword =>
      pick(it: 'Inserisci email e password.', en: 'Enter email and password.');

  String get chooseModel => pick(it: 'Scegli modello', en: 'Choose model');
  String providerModels(String provider) =>
      pick(it: 'Modelli $provider', en: '$provider models');
  String get refresh => pick(it: 'Aggiorna', en: 'Refresh');
  String get promptPresets => pick(it: 'Preset prompt', en: 'Prompt presets');
  String get save => pick(it: 'Salva', en: 'Save');
  String get noSavedPresets =>
      pick(it: 'Nessun preset salvato.', en: 'No saved presets.');
  String get systemPrompt => pick(it: 'System Prompt', en: 'System Prompt');
  String get systemPromptHint => pick(
    it: 'Istruzioni base per il modello',
    en: 'Base instructions for the model',
  );
  String temperatureLabel(double value) => pick(
    it: 'Temperature: ${value.toStringAsFixed(2)}',
    en: 'Temperature: ${value.toStringAsFixed(2)}',
  );
  String topPLabel(double value) => pick(
    it: 'Top P: ${value.toStringAsFixed(2)}',
    en: 'Top P: ${value.toStringAsFixed(2)}',
  );
  String maxTokensLabel(int value) =>
      pick(it: 'Max tokens: $value', en: 'Max tokens: $value');
  String get autoFallback => pick(
    it: 'Fallback automatico provider',
    en: 'Automatic provider fallback',
  );
  String get inputSafety =>
      pick(it: 'Moderazione input (safety)', en: 'Input safety moderation');
  String get preferOffline =>
      pick(it: 'Preferisci offline (Ollama)', en: 'Prefer offline (Ollama)');
  String get longTermMemory =>
      pick(it: 'Memoria utente a lungo termine', en: 'Long-term user memory');
  String get analyticsConsent =>
      pick(it: 'Consenso analytics', en: 'Analytics consent');
  String get adsConsent => pick(it: 'Consenso ads', en: 'Ads consent');
  String get localRag =>
      pick(it: 'RAG locale sugli allegati', en: 'Local RAG on attachments');
  String ragSourcesTitle(int count) =>
      pick(it: 'Fonti locali usate: $count', en: 'Local sources used: $count');
  String ragDocumentsLabel(int count) => pick(
    it: 'Documenti indicizzati: $count',
    en: 'Indexed documents: $count',
  );
  String circuitBreakerActive(List<String> providers) => pick(
    it: 'Circuit breaker attivo: ${providers.join(', ')}',
    en: 'Circuit breaker active: ${providers.join(', ')}',
  );
  String get saveSettings =>
      pick(it: 'Salva impostazioni', en: 'Save settings');

  String get readLastReply =>
      pick(it: 'Leggi ultima risposta', en: 'Read last reply');
  String get regenerate => pick(it: 'Rigenera', en: 'Regenerate');
  String get modelSettings =>
      pick(it: 'Impostazioni modello', en: 'Model settings');
  String get newChat => pick(it: 'Nuova chat', en: 'New chat');
  String providerAndModel(String provider, String model) =>
      '$provider · $model';
  String tokensToday(int used, int limit) =>
      pick(it: 'Token oggi: $used/$limit', en: 'Tokens today: $used/$limit');
  String get startConversation => pick(
    it: 'Inizia una nuova conversazione',
    en: 'Start a new conversation',
  );
  String get realtimeReplyHint => pick(
    it: 'Scrivi un messaggio per vedere la risposta in tempo reale.',
    en: 'Write a message to see the reply in real time.',
  );
  String get chooseModelAndWrite => pick(
    it: 'Scegli un modello e inizia a scrivere. Usa /help per i tool locali.',
    en: 'Choose a model and start typing. Use /help for local tools.',
  );

  String get attach => pick(it: 'Allega', en: 'Attach');
  String get writeMessage =>
      pick(it: 'Scrivi un messaggio...', en: 'Write a message...');
  String get stopMic => pick(it: 'Ferma microfono', en: 'Stop microphone');
  String get microphone => pick(it: 'Microfono', en: 'Microphone');
  String get textCopied => pick(it: 'Testo copiato.', en: 'Text copied.');
  String get retry => pick(it: 'Rigenera', en: 'Retry');
  String get editMessage => pick(it: 'Modifica messaggio', en: 'Edit message');
  String get text => pick(it: 'Testo', en: 'Text');
  String get cancel => pick(it: 'Annulla', en: 'Cancel');
  String get copy => pick(it: 'Copia', en: 'Copy');
  String get edit => pick(it: 'Modifica', en: 'Edit');

  String get localTimeUnavailable =>
      pick(it: 'Microfono non disponibile.', en: 'Microphone not available.');
  String emptyTextAttachment(String fileName) => pick(
    it: 'Allegato testo `$fileName` vuoto o non leggibile.',
    en: 'Text attachment `$fileName` is empty or unreadable.',
  );
  String analyzeAttachment(String fileName, String text) => pick(
    it: 'Analizza questo allegato `$fileName`:\n$text',
    en: 'Analyze this attachment `$fileName`:\n$text',
  );
  String pdfManualFallback(String fileName) => pick(
    it: 'Ho allegato un PDF `$fileName`, ma non sono riuscito a estrarne il testo automaticamente. Guidami per riassumerlo manualmente.',
    en: 'I attached a PDF `$fileName`, but automatic text extraction failed. Guide me to summarize it manually.',
  );
  String imageManualFallback(String fileName) => pick(
    it: 'Ho allegato un\'immagine `$fileName`, ma non sono riuscito a estrarre testo automaticamente. Dammi i passaggi per analizzarla manualmente.',
    en: 'I attached an image `$fileName`, but automatic text extraction failed. Give me the steps to analyze it manually.',
  );
  String attachmentType(String fileName, String type) => pick(
    it: 'Allegato `$fileName` (tipo `$type`)',
    en: 'Attachment `$fileName` (type `$type`)',
  );
  String ragIndexed(String fileName) => pick(
    it: 'Documento indicizzato per RAG locale: $fileName',
    en: 'Document indexed for local RAG: $fileName',
  );
  String attachmentProcessed(String note) => pick(it: note, en: note);
  String get failedAttachmentExtraction => pick(
    it: 'Impossibile leggere l\'allegato selezionato.',
    en: 'Unable to read the selected attachment.',
  );

  String get drawerChats => pick(it: 'Le tue chat', en: 'Your chats');
  String get noChatsYet =>
      pick(it: 'Nessuna chat ancora.', en: 'No chats yet.');
  String get searchChats => pick(
    it: 'Cerca chat o testo messaggi...',
    en: 'Search chats or message text...',
  );
  String tokenCostStats(int used, int limit, double cost) => pick(
    it: 'Token: $used/$limit · \$${cost.toStringAsFixed(3)}',
    en: 'Tokens: $used/$limit · \$${cost.toStringAsFixed(3)}',
  );
  String requestStats(int ok, int fail, double avgMs) => pick(
    it: 'Req ok/fail: $ok/$fail · avg ${avgMs.toStringAsFixed(0)} ms',
    en: 'Req ok/fail: $ok/$fail · avg ${avgMs.toStringAsFixed(0)} ms',
  );
  String get rename => pick(it: 'Rinomina', en: 'Rename');
  String get newName => pick(it: 'Nuovo nome', en: 'New name');
  String get delete => pick(it: 'Elimina', en: 'Delete');
  String get exportFullBackup =>
      pick(it: 'Esporta backup completo', en: 'Export full backup');
  String get exportCurrentChat =>
      pick(it: 'Esporta chat corrente (.md)', en: 'Export current chat (.md)');
  String get importLatestBackup =>
      pick(it: 'Importa ultimo backup', en: 'Import latest backup');
  String get clearLocalChatData =>
      pick(it: 'Pulisci dati locali chat', en: 'Clear local chat data');
  String get cloudBackupPush => pick(it: 'Backup cloud', en: 'Cloud backup');
  String get cloudBackupPull =>
      pick(it: 'Ripristina da cloud', en: 'Restore from cloud');
  String get accountAndPrivacy =>
      pick(it: 'Profilo e privacy', en: 'Profile and privacy');
  String get premium => pick(it: 'Premium', en: 'Premium');
  String get signOut => pick(it: 'Esci', en: 'Sign out');
  String backupExported(String path) =>
      pick(it: 'Backup esportato: $path', en: 'Backup exported: $path');
  String chatExported(String path) =>
      pick(it: 'Chat esportata: $path', en: 'Chat exported: $path');
  String get noCurrentChatToExport => pick(
    it: 'Nessuna chat corrente da esportare.',
    en: 'No current chat to export.',
  );
  String noBackupFound(String location) => pick(
    it: 'Nessun backup trovato da $location.',
    en: 'No backup found from $location.',
  );
  String backupImported(String path) =>
      pick(it: 'Backup importato: $path', en: 'Backup imported: $path');
  String get deleteLocalDataConfirmTitle => pick(it: 'Conferma', en: 'Confirm');
  String get deleteLocalDataConfirmBody => pick(
    it: 'Questa azione elimina tutte le chat e i messaggi locali.',
    en: 'This action deletes all local chats and messages.',
  );
  String get localDataRemoved =>
      pick(it: 'Dati locali rimossi.', en: 'Local data removed.');
  String get cloudBackupUploaded =>
      pick(it: 'Backup cloud completato.', en: 'Cloud backup completed.');
  String get cloudBackupRestored =>
      pick(it: 'Backup cloud ripristinato.', en: 'Cloud backup restored.');

  String get presetName => pick(it: 'Nome preset', en: 'Preset name');
  String get presetNameHint =>
      pick(it: 'Es. Scrittura tecnica', en: 'E.g. Technical writing');

  String get onboardingTitleA =>
      pick(it: 'Benvenuto in AIssistente', en: 'Welcome to AIssistente');
  String get onboardingTitleB => pick(it: 'Partenza rapida', en: 'Quick start');
  String get onboardingBodyA => pick(
    it: 'Suggerimento: usa /help per tool locali, salva preset prompt e attiva fallback automatico per maggiore affidabilita.',
    en: 'Tip: use /help for local tools, save prompt presets, and enable automatic fallback for better reliability.',
  );
  String get onboardingBodyB => pick(
    it: 'Suggerimento: allega documenti per indicizzarli in locale, usa il microfono per dettare e aggiorna la lista modelli dal pannello impostazioni.',
    en: 'Tip: attach documents to index them locally, use the microphone to dictate, and refresh the model list from settings.',
  );
  String get start => pick(it: 'Inizia', en: 'Start');

  String get accountPrivacyTitle =>
      pick(it: 'Profilo e privacy', en: 'Profile and privacy');
  String get displayName => pick(it: 'Nome', en: 'Name');
  String get avatarUrl => pick(it: 'URL avatar', en: 'Avatar URL');
  String get preferredLanguage =>
      pick(it: 'Lingua preferita', en: 'Preferred language');
  String get emailAddress => pick(it: 'Email', en: 'Email');
  String get accountSection => pick(it: 'Account', en: 'Account');
  String get authBypassTitle => pick(
    it: 'Accesso saltato per sviluppo',
    en: 'Auth bypass enabled for development',
  );
  String get authBypassBody => pick(
    it: 'Stai usando l\'app senza login Firebase. Le funzioni esterne come account, backup cloud, ads e autenticazione reale restano escluse da questo test.',
    en: 'You are using the app without Firebase sign-in. External features such as account, cloud backup, ads, and real authentication stay out of this test run.',
  );
  String get runtimeDiagnostics =>
      pick(it: 'Diagnostica runtime', en: 'Runtime diagnostics');
  String get noRuntimeWarnings => pick(
    it: 'Nessun warning di configurazione rilevato.',
    en: 'No runtime configuration warnings detected.',
  );
  String get emailVerified =>
      pick(it: 'Email verificata', en: 'Email verified');
  String get emailNotVerified =>
      pick(it: 'Email non verificata', en: 'Email not verified');
  String get sendVerificationEmail =>
      pick(it: 'Invia email di verifica', en: 'Send verification email');
  String get verificationEmailSent =>
      pick(it: 'Email di verifica inviata.', en: 'Verification email sent.');
  String get refreshVerificationStatus =>
      pick(it: 'Aggiorna stato verifica', en: 'Refresh verification status');
  String get privacySection => pick(it: 'Privacy', en: 'Privacy');
  String get dataSection => pick(it: 'Dati e backup', en: 'Data and backups');
  String get dataPolicyTitle =>
      pick(it: 'Policy tecnica dati', en: 'Technical data policy');
  String get dataPolicyBody => pick(
    it: 'Locale: chat, messaggi, impostazioni, preset prompt, memoria utente, indice RAG e metriche locali. Cloud backup: un payload JSON esportato manualmente con chat, messaggi, stato app e profilo base; nessun embedding cloud dedicato. Analytics e crash reporting restano spenti finche non dai consenso.',
    en: 'Local: chats, messages, settings, prompt presets, user memory, RAG index, and local metrics. Cloud backup: a manually exported JSON payload with chats, messages, app state, and basic profile; no dedicated cloud embeddings. Analytics and crash reporting stay off until you grant consent.',
  );
  String get premiumSection => pick(it: 'Premium', en: 'Premium');
  String get saveProfile => pick(it: 'Salva profilo', en: 'Save profile');
  String get profileSaved =>
      pick(it: 'Profilo aggiornato.', en: 'Profile updated.');
  String get privacyPolicyTitle =>
      pick(it: 'Informativa privacy', en: 'Privacy policy');
  String get privacyPolicyBody => pick(
    it: 'I dati delle chat vengono salvati in locale. Se abiliti il backup cloud, l\'app salva un payload JSON nel tuo spazio Firestore. Analytics e ads restano disattivati fino al consenso esplicito. Puoi esportare i tuoi dati o cancellare account e dati locali da questa schermata.',
    en: 'Chat data is stored locally. If you enable cloud backup, the app stores a JSON payload in your Firestore space. Analytics and ads stay disabled until you explicitly consent. You can export your data or delete your account and local data from this screen.',
  );
  String get exportUserData =>
      pick(it: 'Esporta tutti i dati utente', en: 'Export all user data');
  String userDataExported(String path) =>
      pick(it: 'Dati utente esportati: $path', en: 'User data exported: $path');
  String get deleteAccount =>
      pick(it: 'Cancella account', en: 'Delete account');
  String get deleteAccountBody => pick(
    it: 'Questa azione elimina i dati locali, rimuove il backup cloud e prova a cancellare il tuo account Firebase.',
    en: 'This action deletes local data, removes the cloud backup, and attempts to delete your Firebase account.',
  );
  String get deleteAccountPasswordHint => pick(
    it: 'Password (solo email/password)',
    en: 'Password (email/password only)',
  );
  String get deleteAccountConfirm =>
      pick(it: 'Cancella account', en: 'Delete account');
  String get accountDeleted =>
      pick(it: 'Account cancellato.', en: 'Account deleted.');

  String get premiumActive => pick(it: 'Premium attivo', en: 'Premium active');
  String get premiumInactive =>
      pick(it: 'Premium non attivo', en: 'Premium not active');
  String premiumQuota(int limit) => pick(
    it: 'Quota token giornaliera: $limit',
    en: 'Daily token quota: $limit',
  );
  String get premiumBody => pick(
    it: 'Premium rimuove banner ads, alza il limite token giornaliero e mantiene attivi backup e strumenti avanzati senza interruzioni.',
    en: 'Premium removes banner ads, raises the daily token limit, and keeps backups and advanced tools available without interruptions.',
  );
  String get restorePurchases =>
      pick(it: 'Ripristina acquisti', en: 'Restore purchases');
  String get noProductsConfigured => pick(
    it: 'Nessun prodotto store configurato. Imposta gli ID in .env per abilitare gli acquisti reali.',
    en: 'No store product is configured. Set product IDs in .env to enable real purchases.',
  );
  String get storeUnavailable => pick(
    it: 'Store non disponibile su questo device/build.',
    en: 'Store is unavailable on this device/build.',
  );
  String get premiumTemporarilyUnavailable => pick(
    it: 'Paywall disabilitato da configurazione runtime.',
    en: 'Paywall disabled by runtime configuration.',
  );
  String get purchaseUnavailable =>
      pick(it: 'Acquisto non disponibile.', en: 'Purchase not available.');
  String purchaseSuccess(String name) =>
      pick(it: 'Acquisto completato: $name', en: 'Purchase completed: $name');
  String get purchasesRestored =>
      pick(it: 'Acquisti ripristinati.', en: 'Purchases restored.');

  String rewardedAdTitle(int bonusTokens) =>
      pick(it: 'Continua con un ad', en: 'Continue with an ad');
  String rewardedAdBody(int bonusTokens) => pick(
    it: 'Hai consumato molta quota oggi. Guarda un rewarded ad per ottenere $bonusTokens token extra.',
    en: 'You have consumed a lot of quota today. Watch a rewarded ad to get $bonusTokens extra tokens.',
  );
  String get watchAd => pick(it: 'Guarda ad', en: 'Watch ad');
  String get notNow => pick(it: 'Non ora', en: 'Not now');
  String rewardedTokensGranted(int tokens) => pick(
    it: 'Ricompensa ottenuta: +$tokens token.',
    en: 'Reward granted: +$tokens tokens.',
  );
  String get rewardedAdUnavailable => pick(
    it: 'Rewarded ad non disponibile al momento.',
    en: 'Rewarded ad is currently unavailable.',
  );

  String get manageDocuments =>
      pick(it: 'Documenti locali', en: 'Local documents');
  String get noIndexedDocuments =>
      pick(it: 'Nessun documento indicizzato.', en: 'No indexed documents.');
  String get clearAllDocuments => pick(it: 'Svuota indice', en: 'Clear index');
  String get documentsCleared =>
      pick(it: 'Indice documenti svuotato.', en: 'Document index cleared.');
  String documentDeleted(String name) =>
      pick(it: 'Documento rimosso: $name', en: 'Document removed: $name');

  String get storeLoading =>
      pick(it: 'Caricamento offerte...', en: 'Loading offers...');
  String get genericError =>
      pick(it: 'Si e verificato un errore.', en: 'An error occurred.');
  String get cloudUnavailable => pick(
    it: 'Backup cloud disponibile solo con utente autenticato.',
    en: 'Cloud backup is available only for authenticated users.',
  );
  String get deleteAccountNeedsLogin => pick(
    it: 'Firebase richiede un login recente prima di cancellare l\'account.',
    en: 'Firebase requires a recent login before deleting the account.',
  );
  String get dailyLimitLabel =>
      pick(it: 'Limite giornaliero raggiunto', en: 'Daily limit reached');
}
