import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_strings.dart';
import 'firebase_options.dart';
import 'pages/auth_gate.dart';
import 'providers/app_providers.dart';
import 'services/app_config_diagnostics.dart';
import 'services/app_runtime_config.dart';
import 'services/observability_service.dart';

Future<void> main() async {
  var observability = ObservabilityService.noop();

  await (runZonedGuarded<Future<void>>(
        () async {
          WidgetsFlutterBinding.ensureInitialized();

          Object? bootstrapError;
          var configDiagnostics = const AppConfigDiagnostics.empty();
          var runtimeConfig = const AppRuntimeConfig.defaults();
          try {
            await dotenv.load(fileName: ".env");
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
            configDiagnostics = AppConfigDiagnostics.fromEnvironment(dotenv.env);
            runtimeConfig = await AppRuntimeConfigService.load();
            observability = await ObservabilityService.bootstrap();
            await observability.syncConsent(analyticsConsent: false);
          } catch (e) {
            bootstrapError = e;
          }

          FlutterError.onError = (details) {
            FlutterError.presentError(details);
            unawaited(
              observability.recordError(
                details.exception,
                details.stack ?? StackTrace.current,
                reason: 'flutter_error',
              ),
            );
          };

          ui.PlatformDispatcher.instance.onError = (error, stack) {
            unawaited(
              observability.recordError(error, stack, reason: 'platform_error'),
            );
            return false;
          };

          runApp(
            ProviderScope(
              overrides: [
                appConfigDiagnosticsProvider.overrideWithValue(
                  configDiagnostics,
                ),
                appRuntimeConfigProvider.overrideWithValue(runtimeConfig),
                observabilityServiceProvider.overrideWithValue(observability),
              ],
              child: AIssistenteApp(bootstrapError: bootstrapError),
            ),
          );
        },
        (error, stack) {
          unawaited(
            observability.recordError(error, stack, reason: 'zone_error'),
          );
        },
      ) ??
      Future.value());
}

class AIssistenteApp extends ConsumerWidget {
  const AIssistenteApp({super.key, this.bootstrapError});

  final Object? bootstrapError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(
      chatControllerProvider.select((state) => state.preferredLanguageCode),
    );
    final strings = AppStrings.ofCode(languageCode);

    return MaterialApp(
      title: strings.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      locale: Locale(languageCode),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: bootstrapError == null
          ? const AuthGate()
          : Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    strings.bootstrapError(bootstrapError!),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
    );
  }
}
