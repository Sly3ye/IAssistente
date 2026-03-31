import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isRegister = false;
  bool isLoading = false;
  String? errorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _withLoading(Future<void> Function() action) async {
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => errorText = e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _submitEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final strings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
    if (email.isEmpty || password.isEmpty) {
      setState(() => errorText = strings.enterEmailAndPassword);
      return;
    }
    final auth = ref.read(authServiceProvider);
    await _withLoading(() async {
      if (isRegister) {
        await auth.registerWithEmail(email: email, password: password);
      } else {
        await auth.signInWithEmail(email: email, password: password);
      }
    });
  }

  Future<void> _signInGoogle() async {
    final auth = ref.read(authServiceProvider);
    await _withLoading(() async {
      await auth.signInWithGoogle();
    });
  }

  Future<void> _signInApple() async {
    final auth = ref.read(authServiceProvider);
    await _withLoading(() async {
      await auth.signInWithApple();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ofCode(
      ref.watch(chatControllerProvider).preferredLanguageCode,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.chat_bubble_outline, size: 56),
            const SizedBox(height: 12),
            Text(
              strings.appTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text(
              isRegister ? strings.createAccount : strings.login,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: strings.email,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: strings.password,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isLoading ? null : _submitEmail,
              child: Text(isRegister ? strings.register : strings.login),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => setState(() => isRegister = !isRegister),
              child: Text(
                isRegister ? strings.alreadyHaveAccount : strings.noAccount,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _signInGoogle,
              icon: const Icon(Icons.g_mobiledata),
              label: Text(strings.continueWithGoogle),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _signInApple,
              icon: const Icon(Icons.apple),
              label: Text(strings.continueWithApple),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 16),
              Text(errorText!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
