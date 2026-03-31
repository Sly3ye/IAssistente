import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class ObservabilityService {
  ObservabilityService._({
    required FirebaseAnalytics? analytics,
    required FirebaseCrashlytics? crashlytics,
  }) : _analytics = analytics,
       _crashlytics = crashlytics;

  final FirebaseAnalytics? _analytics;
  final FirebaseCrashlytics? _crashlytics;

  factory ObservabilityService.noop() {
    return ObservabilityService._(analytics: null, crashlytics: null);
  }

  static Future<ObservabilityService> bootstrap() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return ObservabilityService.noop();
    }

    try {
      return ObservabilityService._(
        analytics: FirebaseAnalytics.instance,
        crashlytics: FirebaseCrashlytics.instance,
      );
    } catch (_) {
      return ObservabilityService.noop();
    }
  }

  Future<void> syncConsent({required bool analyticsConsent}) async {
    if (_analytics != null) {
      await _analytics.setAnalyticsCollectionEnabled(analyticsConsent);
    }
    if (_crashlytics != null) {
      await _crashlytics.setCrashlyticsCollectionEnabled(analyticsConsent);
    }
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object> parameters = const {},
  }) async {
    if (_analytics == null) return;
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> recordProviderResult({
    required String providerId,
    required bool success,
    required int latencyMs,
  }) async {
    await logEvent(
      'provider_request',
      parameters: {
        'provider_id': providerId,
        'success': success,
        'latency_ms': latencyMs,
      },
    );
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String reason = 'unhandled',
    bool fatal = false,
  }) async {
    if (_crashlytics == null) return;
    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }
}
