import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppRuntimeConfig {
  const AppRuntimeConfig({
    required this.baseDailyTokenLimit,
    required this.premiumDailyTokenLimit,
    required this.adTriggerStep,
    required this.rewardedTokenBonus,
    required this.defaultProviderId,
    required this.onboardingEnabled,
    required this.paywallEnabled,
    required this.adsEnabled,
  });

  const AppRuntimeConfig.defaults()
    : baseDailyTokenLimit = 20000,
      premiumDailyTokenLimit = 100000,
      adTriggerStep = 5000,
      rewardedTokenBonus = 2500,
      defaultProviderId = 'groq',
      onboardingEnabled = true,
      paywallEnabled = true,
      adsEnabled = true;

  final int baseDailyTokenLimit;
  final int premiumDailyTokenLimit;
  final int adTriggerStep;
  final int rewardedTokenBonus;
  final String defaultProviderId;
  final bool onboardingEnabled;
  final bool paywallEnabled;
  final bool adsEnabled;
}

class AppRuntimeConfigService {
  static Future<AppRuntimeConfig> load() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const AppRuntimeConfig.defaults();
    }

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults({
        'base_daily_token_limit': 20000,
        'premium_daily_token_limit': 100000,
        'rewarded_ad_trigger_step': 5000,
        'rewarded_token_bonus': 2500,
        'default_provider_id': 'groq',
        'onboarding_enabled': true,
        'paywall_enabled': true,
        'ads_enabled': true,
      });
      await remoteConfig.fetchAndActivate();

      final remoteProviderId = remoteConfig.getString('default_provider_id').trim();
      return AppRuntimeConfig(
        baseDailyTokenLimit: remoteConfig.getInt('base_daily_token_limit'),
        premiumDailyTokenLimit: remoteConfig.getInt(
          'premium_daily_token_limit',
        ),
        adTriggerStep: remoteConfig.getInt('rewarded_ad_trigger_step'),
        rewardedTokenBonus: remoteConfig.getInt('rewarded_token_bonus'),
        defaultProviderId: _resolveDefaultProvider(remoteProviderId),
        onboardingEnabled: remoteConfig.getBool('onboarding_enabled'),
        paywallEnabled: remoteConfig.getBool('paywall_enabled'),
        adsEnabled: remoteConfig.getBool('ads_enabled'),
      );
    } catch (_) {
      return AppRuntimeConfig(
        baseDailyTokenLimit: 20000,
        premiumDailyTokenLimit: 100000,
        adTriggerStep: 5000,
        rewardedTokenBonus: 2500,
        defaultProviderId: _resolveDefaultProvider('groq'),
        onboardingEnabled: true,
        paywallEnabled: true,
        adsEnabled: true,
      );
    }
  }

  /// If direct client-side LLM usage is blocked in production and a proxy is
  /// configured, transparently switch the default provider to 'proxy' so fresh
  /// installs work out of the box without a manual provider change.
  static String _resolveDefaultProvider(String preferred) {
    final appEnv = (dotenv.env['APP_ENV'] ?? '').trim().toLowerCase();
    final allowDirect =
        (dotenv.env['ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION'] ?? '')
            .trim()
            .toLowerCase();
    final proxyUrl = (dotenv.env['LLM_PROXY_URL'] ?? '').trim();
    final blocked = appEnv == 'production' && allowDirect != 'true';
    if (blocked && proxyUrl.isNotEmpty && preferred != 'proxy') return 'proxy';
    return preferred;
  }
}
