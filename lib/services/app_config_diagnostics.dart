class AppConfigDiagnostics {
  const AppConfigDiagnostics({
    required this.errors,
    required this.warnings,
  });

  const AppConfigDiagnostics.empty() : errors = const [], warnings = const [];

  final List<String> errors;
  final List<String> warnings;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  static AppConfigDiagnostics fromEnvironment(
    Map<String, String?> environment,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    final appEnv = (environment['APP_ENV'] ?? 'development').trim().toLowerCase();
    final proxyUrl = (environment['LLM_PROXY_URL'] ?? '').trim();
    final proxyAuthToken = (environment['LLM_PROXY_AUTH_TOKEN'] ?? '').trim();
    final allowDirect = (environment['ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION'] ?? '')
        .trim()
        .toLowerCase();
    final directKeys = [
      'OPENAI_API_KEY',
      'ANTHROPIC_API_KEY',
      'GEMINI_API_KEY',
    ].where((key) => (environment[key] ?? '').trim().isNotEmpty).toList();

    if (proxyUrl.isEmpty && directKeys.isEmpty) {
      errors.add(
        'Missing LLM configuration: set LLM_PROXY_URL or at least one direct provider API key.',
      );
    }

    if (proxyUrl.isNotEmpty) {
      final uri = Uri.tryParse(proxyUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        errors.add('LLM_PROXY_URL is not a valid absolute URL.');
      } else {
        if (appEnv == 'production' && uri.host == 'localhost') {
          warnings.add(
            'LLM_PROXY_URL points to localhost while APP_ENV=production.',
          );
        }
        if (appEnv == 'production' &&
            uri.scheme.toLowerCase() != 'https' &&
            uri.host != 'localhost') {
          warnings.add(
            'Production proxy should use HTTPS.',
          );
        }
      }

      if (appEnv == 'production' && proxyAuthToken.isEmpty) {
        warnings.add(
          'LLM_PROXY_AUTH_TOKEN is empty in production. The proxy would be publicly callable.',
        );
      }
    }

    if (appEnv == 'production' &&
        directKeys.isNotEmpty &&
        allowDirect != 'true') {
      warnings.add(
        'Direct provider API keys are present while APP_ENV=production. They will be blocked unless ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION=true.',
      );
    }

    final iapKeys = [
      'IAP_PREMIUM_MONTHLY',
      'IAP_PREMIUM_YEARLY',
      'IAP_PREMIUM_LIFETIME',
    ];
    final configuredIapCount = iapKeys
        .where((key) => (environment[key] ?? '').trim().isNotEmpty)
        .length;
    if (configuredIapCount > 0 && configuredIapCount < iapKeys.length) {
      warnings.add(
        'Only part of the IAP product IDs are configured. Store offers may be incomplete.',
      );
    }

    final adUnitKeys = [
      'ADMOB_APP_ID_ANDROID',
      'ADMOB_APP_ID_IOS',
      'ADMOB_BANNER_ANDROID',
      'ADMOB_BANNER_IOS',
      'ADMOB_REWARDED_ANDROID',
      'ADMOB_REWARDED_IOS',
    ];
    final configuredAdKeys = adUnitKeys
        .where((key) => (environment[key] ?? '').trim().isNotEmpty)
        .length;
    if (configuredAdKeys > 0 && configuredAdKeys < adUnitKeys.length) {
      warnings.add(
        'Only part of the AdMob identifiers are configured. Ads may fail or use test IDs.',
      );
    }

    return AppConfigDiagnostics(
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
    );
  }
}
