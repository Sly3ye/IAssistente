import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../services/dev_options.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _avatarController;
  String? _languageCode;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _avatarController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final authService = ref.watch(authServiceProvider);
    final diagnostics = ref.watch(appConfigDiagnosticsProvider);
    final strings = AppStrings.ofCode(state.preferredLanguageCode);
    final authBypassEnabled = DevOptions.authBypassEnabled;
    final hasAuthenticatedUser = authService.currentUser != null;
    final isEmailVerified = !authBypassEnabled && authService.isEmailVerified;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_initialized) {
      _initialized = true;
      _nameController.text = state.profileName;
      _avatarController.text = state.avatarUrl;
      _languageCode = state.preferredLanguageCode;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF274B44), Color(0xFF3C6B62)]
                      : const [Color(0xFF0E2D1D), Color(0xFF214536)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFFE8D5AC),
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
        children: [
          Text(
            'Account & Privacy',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your identity, workspace permissions, and how account data interacts with intelligence features.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Profile Identity',
            subtitle: 'Your public identity and account metadata.',
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF274B44), Color(0xFF3C6B62)]
                              : const [Color(0xFF192821), Color(0xFF31453C)],
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFFE8D5AC),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MiniLabel('FULL NAME'),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                _MiniLabel('PRIMARY EMAIL'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.profileEmail.isEmpty
                            ? strings.emailAddress
                            : state.profileEmail,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Icon(
                      isEmailVerified ? Icons.lock : Icons.lock_open,
                      color: theme.iconTheme.color,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  authBypassEnabled
                      ? strings.authBypassTitle
                      : (isEmailVerified
                            ? strings.emailVerified
                            : strings.emailNotVerified),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const Divider(height: 28),
                _MiniLabel('PREFERRED LANGUAGE'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _languageCode,
                  decoration: const InputDecoration(
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  items: AppStrings.supportedLanguageCodes
                      .map(
                        (code) => DropdownMenuItem(
                          value: code,
                          child: Text(strings.languageLabel(code)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(
                      () => _languageCode = value ?? state.preferredLanguageCode,
                    );
                  },
                ),
                const Divider(height: 28),
                _MiniLabel('AVATAR URL'),
                const SizedBox(height: 4),
                TextField(
                  controller: _avatarController,
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref
                          .read(chatControllerProvider.notifier)
                          .updateProfile(
                            name: _nameController.text.trim(),
                            avatarUrl: _avatarController.text.trim(),
                          );
                      await ref
                          .read(chatControllerProvider.notifier)
                          .setPreferredLanguage(
                            _languageCode ?? state.preferredLanguageCode,
                          );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(strings.profileSaved)),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? theme.colorScheme.primary
                          : const Color(0xFFEEE8DC),
                      foregroundColor: isDark
                          ? theme.colorScheme.onPrimary
                          : const Color(0xFF1F2A20),
                      elevation: 0,
                    ),
                    child: const Text('Modify Details'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Security Integrity',
            child: Column(
              children: [
                _LineItem(
                  title: 'Authentication Status',
                  value: isEmailVerified
                      ? strings.emailVerified
                      : strings.emailNotVerified,
                  subtitle: authBypassEnabled
                      ? strings.authBypassBody
                      : 'Last updated automatically from Firebase.',
                ),
                const SizedBox(height: 14),
                if (!authBypassEnabled &&
                    !isEmailVerified &&
                    state.profileEmail.trim().isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await ref
                                  .read(authServiceProvider)
                                  .sendCurrentEmailVerification();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(strings.verificationEmailSent),
                                ),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                          child: Text(strings.sendVerificationEmail),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await ref.read(authServiceProvider).reloadCurrentUser();
                              if (!mounted) return;
                              setState(() {});
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    strings.refreshVerificationStatus,
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                          child: Text(strings.refreshVerificationStatus),
                        ),
                      ),
                    ],
                  ),
                if (!authBypassEnabled && hasAuthenticatedUser) ...[
                  const SizedBox(height: 12),
                  _LineItem(
                    title: 'Cloud Backup',
                    value: 'Connected',
                    subtitle: 'Push or restore encrypted archives from cloud storage.',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await ref
                                  .read(chatControllerProvider.notifier)
                                  .pushCloudBackup();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(strings.cloudBackupUploaded),
                                ),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: Text(strings.cloudBackupPush),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final restored = await ref
                                  .read(chatControllerProvider.notifier)
                                  .pullCloudBackup();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    restored
                                        ? strings.cloudBackupRestored
                                        : strings.noBackupFound('cloud'),
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                          icon: const Icon(Icons.cloud_download_outlined),
                          label: Text(strings.cloudBackupPull),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Intelligence Training',
            subtitle:
                'Control diagnostics, personalization, and consent-sensitive behavior.',
            accentColor: isDark ? const Color(0xFF1B2321) : const Color(0xFFF3E0D6),
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Contribute to global training',
                  value: state.analyticsConsent,
                  onChanged: (value) => ref
                      .read(chatControllerProvider.notifier)
                      .setAnalyticsConsent(value),
                ),
                const SizedBox(height: 12),
                _ToggleRow(
                  label: 'Advertising personalization',
                  value: state.adsConsent,
                  onChanged: (value) async {
                    await ref
                        .read(chatControllerProvider.notifier)
                        .setAdsConsent(value);
                    await ref
                        .read(monetizationServiceProvider)
                        .updateAdsConsent(
                          ref.read(appRuntimeConfigProvider).adsEnabled && value,
                        );
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  strings.privacyPolicyBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Data Archive',
            subtitle:
                'Download or remove local and cloud-linked conversation data.',
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final path = await ref
                          .read(chatControllerProvider.notifier)
                          .exportUserDataBundle();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(strings.userDataExported(path))),
                      );
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Generate Archive'),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: Text(strings.clearLocalChatData),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(strings.deleteLocalDataConfirmTitle),
                        content: Text(strings.deleteLocalDataConfirmBody),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(strings.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(strings.delete),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    await ref
                        .read(chatControllerProvider.notifier)
                        .clearLocalChatsAndMessages();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(strings.localDataRemoved)),
                    );
                  },
                ),
                if (!authBypassEnabled && hasAuthenticatedUser)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_forever_outlined),
                    title: Text(strings.deleteAccount),
                    onTap: () => _confirmDeleteAccount(context, strings),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!diagnostics.hasErrors && !diagnostics.hasWarnings)
            _SectionCard(
              title: strings.runtimeDiagnostics,
              child: Text(strings.noRuntimeWarnings),
            ),
          for (final error in diagnostics.errors)
            _SectionCard(
              title: strings.runtimeDiagnostics,
              accentColor: isDark ? const Color(0xFF3A211C) : const Color(0xFFFFEFE8),
              child: Text(
                error,
                style: TextStyle(
                  color: isDark ? const Color(0xFFFFC4B4) : const Color(0xFF8E3720),
                ),
              ),
            ),
          for (final warning in diagnostics.warnings)
            _SectionCard(
              title: strings.runtimeDiagnostics,
              accentColor: isDark ? const Color(0xFF332A1A) : const Color(0xFFFFF4DF),
              child: Text(warning),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AppStrings strings,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final providers = ref.read(authServiceProvider).currentProviderIds;
    final needsPassword = providers.contains('password');
    final passwordController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.deleteAccountBody),
            if (needsPassword) ...[
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: strings.deleteAccountPasswordHint,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.deleteAccountConfirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await ref
          .read(chatControllerProvider.notifier)
          .deleteAccountAndData(password: passwordController.text.trim());
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(strings.accountDeleted)));
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      passwordController.dispose();
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.accentColor = Colors.white,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor == Colors.white ? theme.cardColor : accentColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x55000000) : const Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 0.8,
        color: Theme.of(context).textTheme.bodySmall?.color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
