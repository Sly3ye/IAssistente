import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_strings.dart';
import 'firebase_options.dart';
import 'pages/auth_gate.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? bootstrapError;
  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    bootstrapError = e;
  }

  runApp(ProviderScope(child: AIssistenteApp(bootstrapError: bootstrapError)));
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
