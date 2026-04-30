class SafetyCheckResult {
  const SafetyCheckResult({required this.isBlocked, required this.reason});

  final bool isBlocked;
  final String reason;

  static const ok = SafetyCheckResult(isBlocked: false, reason: '');
}

SafetyCheckResult checkSafety(
  String text, {
  String languageCode = 'it',
  String chatKind = 'general',
}) {
  final lower = text.toLowerCase();
  final isEnglish = languageCode == 'en';

  const blockedPatterns = [
    // Italian
    'come costruire una bomba',
    'come fare una bomba',
    'uccidere qualcuno',
    'rubare password',
    'bypassare 2fa',
    'malware',
    'ransomware',
    'carding',
    'deepfake porn',
    // English
    'how to build a bomb',
    'how to make a bomb',
    'how to make a weapon',
    'kill someone',
    'how to kill',
    'steal password',
    'bypass 2fa',
    'create malware',
    'write malware',
    'make ransomware',
    'create ransomware',
  ];

  for (final pattern in blockedPatterns) {
    if (lower.contains(pattern)) {
      return SafetyCheckResult(
        isBlocked: true,
        reason: isEnglish
            ? 'Request blocked for safety: high-risk content.'
            : 'Richiesta bloccata per sicurezza: contenuto ad alto rischio.',
      );
    }
  }

  const jailbreakPatterns = [
    'ignore previous instructions',
    'disregard all above',
    'act as developer mode',
    'jailbreak',
  ];

  for (final pattern in jailbreakPatterns) {
    if (lower.contains(pattern)) {
      return SafetyCheckResult(
        isBlocked: true,
        reason: isEnglish
            ? 'Request blocked: attempt to bypass safety instructions.'
            : 'Richiesta bloccata: tentativo di bypass istruzioni di sicurezza.',
      );
    }
  }

  if (chatKind == 'medical') {
    const medicalEmergencyPatterns = [
      // Italian
      'dolore al petto',
      'non respiro',
      'difficolta a respirare',
      'difficoltà a respirare',
      'svenimento',
      'ictus',
      'overdose',
      'suicid',
      // English
      'chest pain',
      "can't breathe",
      'cannot breathe',
      'difficulty breathing',
      'trouble breathing',
      'fainting',
      'stroke',
      'heart attack',
      'suicide',
      'kill myself',
      'end my life',
    ];
    if (medicalEmergencyPatterns.any(lower.contains)) {
      return SafetyCheckResult(
        isBlocked: true,
        reason: isEnglish
            ? 'This sounds potentially urgent. I cannot handle it as a chat diagnosis. Contact emergency services or urgent medical care now. I can help prepare a short summary for a clinician once you are safe.'
            : 'Questo puo essere urgente. Non posso gestirlo come diagnosi via chat. Contatta subito emergenza, pronto soccorso o guardia medica. Quando sei al sicuro posso aiutarti a preparare un riepilogo breve per un professionista.',
      );
    }

    const medicalRiskPatterns = [
      // Italian
      'che dose',
      'dosaggio',
      'prescrivimi',
      'smetto il farmaco',
      'interrompo il farmaco',
      // English
      'what dose',
      'what dosage',
      'prescribe me',
      'stop taking my medication',
      'stop my medication',
      'can i stop taking',
      'change my dosage',
      'increase my dose',
      'double my dose',
    ];
    if (medicalRiskPatterns.any(lower.contains)) {
      return SafetyCheckResult(
        isBlocked: true,
        reason: isEnglish
            ? 'I cannot prescribe, change dosages, or tell you to stop medication. I can help you organize symptoms, current medication, questions, and information to discuss with a qualified clinician.'
            : 'Non posso prescrivere, modificare dosaggi o dirti di interrompere farmaci. Posso aiutarti a organizzare sintomi, farmaci attuali, domande e informazioni da discutere con un professionista sanitario.',
      );
    }
  }

  if (chatKind == 'diet') {
    const dietRiskPatterns = [
      // Italian
      '500 calorie',
      '400 calorie',
      '300 calorie',
      'perdere 10 kg',
      'dimagrire 10 kg',
      'vomitare',
      'anoressia',
      'bulimia',
      'saltare tutti i pasti',
      // English
      '500 calories',
      '400 calories',
      '300 calories',
      'lose 10 kg',
      'lose 10 lb',
      'lose 10 pound',
      'vomit',
      'purge',
      'anorexia',
      'bulimia',
      'skip all meals',
      'starvation diet',
      'not eating',
    ];
    if (dietRiskPatterns.any(lower.contains)) {
      return SafetyCheckResult(
        isBlocked: true,
        reason: isEnglish
            ? 'I cannot help build extreme or unsafe eating plans. I can help create a safer, realistic plan, or a summary to discuss with a dietitian or doctor if weight, eating distress, pregnancy, minors, or medical conditions are involved.'
            : 'Non posso aiutarti a costruire piani alimentari estremi o non sicuri. Posso aiutarti a creare un piano piu realistico e prudente, oppure un riepilogo da discutere con dietista o medico se ci sono peso, disagio alimentare, gravidanza, minori o condizioni mediche.',
      );
    }
  }

  if (chatKind == 'legal') {
    const legalRiskPatterns = [
      // Italian
      'falsificare',
      'firma falsa',
      'mentire al giudice',
      'nascondere prove',
      'evadere le tasse',
      'truffare',
      // English
      'forge',
      'forged document',
      'fake signature',
      'lie to the judge',
      'lie in court',
      'hide evidence',
      'destroy evidence',
      'evade taxes',
      'tax evasion',
      'defraud',
      'money laundering',
      'falsify',
    ];
    if (legalRiskPatterns.any(lower.contains)) {
      return SafetyCheckResult(
        isBlocked: true,
        reason: isEnglish
            ? 'I cannot help with illegal or deceptive actions. I can help you organize the facts, identify lawful options in general terms, and prepare questions for a qualified professional.'
            : 'Non posso aiutarti con azioni illegali o ingannevoli. Posso aiutarti a ordinare i fatti, individuare opzioni lecite in termini generali e preparare domande per un professionista qualificato.',
      );
    }
  }

  return SafetyCheckResult.ok;
}
