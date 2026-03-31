import 'package:flutter_dotenv/flutter_dotenv.dart';

bool isClientSideProviderBlockedInProduction() {
  final appEnv = (dotenv.env['APP_ENV'] ?? 'development').trim().toLowerCase();
  final allowDirect = (dotenv.env['ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION'] ?? '')
      .trim()
      .toLowerCase();

  return appEnv == 'production' && allowDirect != 'true';
}

String blockedClientProviderMessage(String providerLabel) {
  return 'Error $providerLabel: direct client usage is disabled in production. Configure the proxy backend or set ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION=true only for intentional testing.';
}
