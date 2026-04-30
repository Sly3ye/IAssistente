import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
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

          // Request ATT permission on iOS 14.5+ before AdMob initializes.
          if (Platform.isIOS) {
            final status =
                await AppTrackingTransparency.trackingAuthorizationStatus;
            if (status == TrackingStatus.notDetermined) {
              await Future<void>.delayed(const Duration(milliseconds: 200));
              await AppTrackingTransparency.requestTrackingAuthorization();
            }
          }

          Object? bootstrapError;
          var configDiagnostics = const AppConfigDiagnostics.empty();
          var runtimeConfig = const AppRuntimeConfig.defaults();
          try {
            await dotenv.load(fileName: ".env");
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
            configDiagnostics = AppConfigDiagnostics.fromEnvironment(
              dotenv.env,
            );
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
              child: MimirApp(bootstrapError: bootstrapError),
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

class MimirApp extends ConsumerWidget {
  const MimirApp({super.key, this.bootstrapError});

  final Object? bootstrapError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(
      chatControllerProvider.select((state) => state.preferredLanguageCode),
    );
    final darkModeEnabled = ref.watch(
      chatControllerProvider.select((state) => state.darkModeEnabled),
    );
    final strings = AppStrings.ofCode(languageCode);

    return MaterialApp(
      title: strings.appTitle,
      themeMode: darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0F5B52),
          secondary: Color(0xFFC48A3A),
          surface: Color(0xFFF7F1E6),
          onPrimary: Colors.white,
          onSecondary: Color(0xFF1A1A1A),
          onSurface: Color(0xFF17211F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1E8DA),
        cardColor: const Color(0xFFFFFBF4),
        dividerColor: const Color(0xFFE2D4BE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF17211F),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: Color(0xFF17211F),
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFF17211F),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17211F),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17211F),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: Color(0xFF31403D),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF4A5A56),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFBF6),
          hintStyle: const TextStyle(color: Color(0xFF7D847C)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE1D4C0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE1D4C0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF0F5B52), width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F5B52),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF17211F),
            side: const BorderSide(color: Color(0xFFDBC7A7)),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF17211F),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4DB3A1),
          secondary: Color(0xFFD1A968),
          surface: Color(0xFF151B19),
          onPrimary: Color(0xFF071310),
          onSecondary: Color(0xFF1C1610),
          onSurface: Color(0xFFF1E9DB),
        ),
        scaffoldBackgroundColor: const Color(0xFF0E1312),
        cardColor: const Color(0xFF151B19),
        dividerColor: const Color(0xFF2D3A36),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFF1E9DB),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: Color(0xFFF1E9DB),
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFFF1E9DB),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF1E9DB),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF1E9DB),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: Color(0xFFD0D8D3),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFFB3BDB7),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF151B19),
          hintStyle: const TextStyle(color: Color(0xFF8C9791)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF2D3A36)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF2D3A36)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF4DB3A1), width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4DB3A1),
            foregroundColor: const Color(0xFF071310),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF1E9DB),
            side: const BorderSide(color: Color(0xFF3A4943)),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFFF1E9DB),
          contentTextStyle: const TextStyle(color: Color(0xFF0E1312)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          behavior: SnackBarBehavior.floating,
        ),
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
