class SafetyCheckResult {
  const SafetyCheckResult({required this.isBlocked, required this.reason});

  final bool isBlocked;
  final String reason;

  static const ok = SafetyCheckResult(isBlocked: false, reason: '');
}

SafetyCheckResult checkSafety(String text, {String languageCode = 'it'}) {
  final lower = text.toLowerCase();
  final isEnglish = languageCode == 'en';

  const blockedPatterns = [
    'come costruire una bomba',
    'come fare una bomba',
    'uccidere qualcuno',
    'rubare password',
    'bypassare 2fa',
    'malware',
    'ransomware',
    'carding',
    'deepfake porn',
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

  return SafetyCheckResult.ok;
}
