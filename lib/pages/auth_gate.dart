import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import 'chat_page.dart';
import 'login_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final languageCode = ref.watch(
      chatControllerProvider.select((state) => state.preferredLanguageCode),
    );
    final strings = AppStrings.ofCode(languageCode);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginPage();
        return const ChatPage();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(strings.authError(error), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
