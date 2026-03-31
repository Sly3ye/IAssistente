import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';

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
    final isEmailVerified = authService.isEmailVerified;

    if (!_initialized) {
      _initialized = true;
      _nameController.text = state.profileName;
      _avatarController.text = state.avatarUrl;
      _languageCode = state.preferredLanguageCode;
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.accountPrivacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            strings.accountSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: strings.displayName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: state.profileEmail,
            readOnly: true,
            decoration: InputDecoration(
              labelText: strings.emailAddress,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isEmailVerified ? Icons.verified_user : Icons.mark_email_unread,
            ),
            title: Text(
              isEmailVerified
                  ? strings.emailVerified
                  : strings.emailNotVerified,
            ),
          ),
          if (!isEmailVerified && state.profileEmail.trim().isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.tonal(
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
                OutlinedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref.read(authServiceProvider).reloadCurrentUser();
                      if (!mounted) return;
                      setState(() {});
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(strings.refreshVerificationStatus),
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
              ],
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _avatarController,
            decoration: InputDecoration(
              labelText: strings.avatarUrl,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _languageCode,
            decoration: InputDecoration(
              labelText: strings.preferredLanguage,
              border: const OutlineInputBorder(),
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
          const SizedBox(height: 12),
          FilledButton(
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
            child: Text(strings.saveProfile),
          ),
          const SizedBox(height: 24),
          Text(
            strings.runtimeDiagnostics,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (!diagnostics.hasErrors && !diagnostics.hasWarnings)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(strings.noRuntimeWarnings),
              ),
            ),
          for (final error in diagnostics.errors)
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: Icon(Icons.error_outline, color: Colors.red.shade700),
                title: Text(error),
              ),
            ),
          for (final warning in diagnostics.warnings)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.orange.shade800,
                ),
                title: Text(warning),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            strings.privacySection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(strings.privacyPolicyBody),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.analyticsConsent),
            value: state.analyticsConsent,
            onChanged: (value) => ref
                .read(chatControllerProvider.notifier)
                .setAnalyticsConsent(value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.adsConsent),
            value: state.adsConsent,
            onChanged: (value) async {
              await ref.read(chatControllerProvider.notifier).setAdsConsent(
                value,
              );
              await ref
                  .read(monetizationServiceProvider)
                  .updateAdsConsent(
                    ref.read(appRuntimeConfigProvider).adsEnabled && value,
                  );
            },
          ),
          const SizedBox(height: 24),
          Text(
            strings.dataSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.dataPolicyTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(strings.dataPolicyBody),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(strings.exportUserData),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final path = await ref
                  .read(chatControllerProvider.notifier)
                  .exportUserDataBundle();
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text(strings.userDataExported(path))),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: Text(strings.cloudBackupPush),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(chatControllerProvider.notifier)
                    .pushCloudBackup();
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(strings.cloudBackupUploaded)),
                );
              } catch (error) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: Text(strings.cloudBackupPull),
            onTap: () async {
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
          ),
          ListTile(
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
          const SizedBox(height: 24),
          Text(
            strings.privacyPolicyTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _confirmDeleteAccount(context, strings),
            style: FilledButton.styleFrom(foregroundColor: Colors.red.shade900),
            child: Text(strings.deleteAccount),
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
                  border: const OutlineInputBorder(),
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
