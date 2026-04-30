import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _passwordFocus = FocusNode();
  bool isRegister = false;
  bool isLoading = false;
  bool passwordVisible = false;
  String? errorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _withLoading(Future<void> Function() action) async {
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => errorText = error.toString());
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
    final chatController = ref.read(chatControllerProvider.notifier);
    await _withLoading(() async {
      if (isRegister) {
        await auth.registerWithEmail(email: email, password: password);
        await auth.sendCurrentEmailVerification();
        await chatController.handleAuthStateChanged();
        await ref
            .read(observabilityServiceProvider)
            .logEvent('auth_register_email');
      } else {
        await auth.signInWithEmail(email: email, password: password);
        await chatController.handleAuthStateChanged();
        await ref
            .read(observabilityServiceProvider)
            .logEvent('auth_login_email');
      }
    });
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    final strings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
    if (email.isEmpty) {
      setState(() => errorText = strings.enterEmailAndPassword);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    await _withLoading(() async {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email: email);
      await ref
          .read(observabilityServiceProvider)
          .logEvent('auth_password_reset_requested');
    });

    if (!mounted || errorText != null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(strings.resetEmailSent(email))),
    );
  }

  Future<void> _signInGoogle() async {
    final auth = ref.read(authServiceProvider);
    final chatController = ref.read(chatControllerProvider.notifier);
    await _withLoading(() async {
      await auth.signInWithGoogle();
      await chatController.handleAuthStateChanged();
      await ref
          .read(observabilityServiceProvider)
          .logEvent('auth_login_google');
    });
  }

  Future<void> _signInApple() async {
    final auth = ref.read(authServiceProvider);
    final chatController = ref.read(chatControllerProvider.notifier);
    await _withLoading(() async {
      await auth.signInWithApple();
      await chatController.handleAuthStateChanged();
      await ref.read(observabilityServiceProvider).logEvent('auth_login_apple');
    });
  }

  Future<void> _showAlternativeAccess() async {
    final strings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D2C7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.pick(
                    it: 'Accesso alternativo',
                    en: 'Alternative access',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.pick(
                    it: 'Usa Google o Apple se preferisci non accedere con email e password.',
                    en: 'Use Google or Apple if you prefer not to sign in with email and password.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                            _signInGoogle();
                          },
                    icon: const Icon(Icons.g_mobiledata, size: 26),
                    label: Text(strings.continueWithGoogle),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                            _signInApple();
                          },
                    icon: const Icon(Icons.apple, size: 18),
                    label: Text(strings.continueWithApple),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ofCode(
      ref.watch(chatControllerProvider).preferredLanguageCode,
    );
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = viewInsets > 0;

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(28, 32, 28, 24 + viewInsets),
            children: [
              SizedBox(height: keyboardOpen ? 16 : 72),
              Text(
                'Mimir.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  color: const Color(0xFF182119),
                ),
              ),
              SizedBox(height: keyboardOpen ? 24 : 44),
              Text(
                isRegister
                    ? strings.createAccount
                    : strings.pick(
                        it: 'Accedi a Mimir',
                        en: 'Sign in to Mimir',
                      ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF232920),
                ),
              ),
              if (!isRegister && !keyboardOpen) ...[
                const SizedBox(height: 8),
                Text(
                  strings.pick(
                    it: 'Accedi per ritrovare profilo, cronologia, documenti e impostazioni.',
                    en: 'Sign in to access profile, history, documents, and settings.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF666A63),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              _LedgerField(
                label: strings.emailFieldLabel,
                controller: emailController,
                icon: Icons.mail_outline_rounded,
                hintText: 'architect@domain.com',
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
              ),
              const SizedBox(height: 20),
              _LedgerField(
                label: strings.passwordFieldLabel,
                controller: passwordController,
                focusNode: _passwordFocus,
                icon: Icons.key_rounded,
                hintText: '........',
                obscureText: !passwordVisible,
                textInputAction: TextInputAction.done,
                onEditingComplete: isLoading ? null : _submitEmail,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isRegister)
                      TextButton(
                        onPressed: isLoading ? null : _resetPassword,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          strings.pick(it: 'Recupera', en: 'Recover'),
                        ),
                      ),
                    IconButton(
                      onPressed: () =>
                          setState(() => passwordVisible = !passwordVisible),
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorText!,
                  style: const TextStyle(
                    color: Color(0xFF8E3720),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : _submitEmail,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E2D1D),
                    shadowColor: const Color(0x33000000),
                    elevation: 6,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isRegister ? strings.register : strings.login),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => setState(() => isRegister = !isRegister),
                  child: Text(
                    isRegister
                        ? strings.alreadyHaveAccount
                        : strings.createAccount,
                    style: const TextStyle(
                      color: Color(0xFF595D57),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (!isRegister && !keyboardOpen)
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : _showAlternativeAccess,
                    child: Text(
                      strings.pick(
                        it: 'Altri metodi di accesso',
                        en: 'Alternative sign-in methods',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF767A73),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: keyboardOpen ? 28 : 88),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${strings.bySigningIn} ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF8F928B),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse('https://mimir.app/privacy'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      strings.privacyPolicyLink,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8F928B),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    ' ${strings.and} ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF8F928B),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse('https://mimir.app/terms'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      strings.termsLink,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8F928B),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerField extends StatelessWidget {
  const _LedgerField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hintText,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.textInputAction,
    this.onEditingComplete,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final IconData icon;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF666A63),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE0DCCF))),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(icon, size: 18, color: const Color(0xFF91958D)),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  autofocus: autofocus,
                  textInputAction: textInputAction,
                  onEditingComplete: onEditingComplete,
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ).copyWith(hintText: hintText),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}
