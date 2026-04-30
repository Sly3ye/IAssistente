import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../models/rag_document.dart';
import '../providers/app_providers.dart';
import '../widgets/chat_drawer.dart';
import 'account_page.dart';
import 'chat_page.dart';
import 'diet_agent_page.dart';
import 'legal_agent_page.dart';
import 'memory_page.dart';
import 'medical_agent_page.dart';
import 'rag_documents_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(chatControllerProvider);
      final runtimeConfig = ref.read(appRuntimeConfigProvider);
      unawaited(
        ref
            .read(monetizationServiceProvider)
            .initialize(
              premiumEnabled: state.isPremium,
              adsEnabled: runtimeConfig.adsEnabled && state.adsConsent,
            ),
      );
      if (state.shouldShowOnboarding) {
        unawaited(
          ref.read(chatControllerProvider.notifier).dismissOnboarding(),
        );
      }
    });
  }

  Future<void> _openChat() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatPage()));
  }

  Future<void> _startNewChat() async {
    await ref.read(chatControllerProvider.notifier).newChat();
    if (!mounted) return;
    await _openChat();
  }

  Future<void> _openExistingChat(Chat chat) async {
    await ref.read(chatControllerProvider.notifier).loadChat(chat.id);
    if (!mounted) return;
    await _openChat();
  }

  Future<void> _openDiet() async {
    final started = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const DietAgentPage()));
    if (mounted && started == true) await _openChat();
  }

  Future<void> _openMedical() async {
    final started = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const MedicalAgentPage()));
    if (mounted && started == true) await _openChat();
  }

  Future<void> _openLegal() async {
    final started = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LegalAgentPage()));
    if (mounted && started == true) await _openChat();
  }

  Future<void> _openDocuments() async {
    final openedChat = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const RagDocumentsPage()));
    if (mounted && openedChat == true) await _openChat();
  }

  Future<void> _openAccount() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AccountPage()));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final strings = AppStrings.ofCode(state.preferredLanguageCode);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final recentChats = [...state.chats]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recentDocs = [...state.ragDocuments]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final firstName = _firstName(state.profileName, strings);

    return Scaffold(
      drawer: ChatDrawer(
        activeSection: ChatDrawerSection.home,
        onNewChat: _startNewChat,
      ),
      backgroundColor: isDark
          ? const Color(0xFF0E1312)
          : const Color(0xFFFCF9F2),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0E1312)
            : const Color(0xFFFCF9F2),
        toolbarHeight: 68,
        centerTitle: false,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          strings.appTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _openAccount,
              child: _Avatar(name: firstName, avatarUrl: state.avatarUrl),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.dividerColor),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              children: [
                Text(
                  strings.pick(it: 'Ciao, $firstName.', en: 'Hi, $firstName.'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.pick(
                    it: 'Scegli cosa vuoi fare adesso.',
                    en: 'Choose what you want to do now.',
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _startNewChat,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(strings.newChat),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openDocuments,
                        icon: const Icon(Icons.folder_open_outlined),
                        label: Text(
                          strings.pick(it: 'Documenti', en: 'Documents'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _HomeCard(
                  title: strings.pick(it: 'Assistenti', en: 'Assistants'),
                  trailingIcon: Icons.grid_view_rounded,
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.72,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _QuickActionTile(
                        icon: Icons.auto_awesome_rounded,
                        label: strings.pick(
                          it: 'Chat generale',
                          en: 'General chat',
                        ),
                        onTap: _startNewChat,
                      ),
                      _QuickActionTile(
                        icon: Icons.restaurant_menu_rounded,
                        label: strings.pick(it: 'Dietologo', en: 'Diet'),
                        onTap: _openDiet,
                      ),
                      _QuickActionTile(
                        icon: Icons.medical_services_outlined,
                        label: strings.pick(it: 'Medico', en: 'Medical'),
                        onTap: _openMedical,
                      ),
                      _QuickActionTile(
                        icon: Icons.gavel_rounded,
                        label: strings.pick(it: 'Avvocato', en: 'Legal'),
                        onTap: _openLegal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SystemStatusCard(
                  memoryEnabled: state.longTermMemoryEnabled,
                  memoryCount: state.memoryNotes.length,
                  documentCount: state.ragDocuments.length,
                  dailyTokensUsed: state.dailyTokensUsed,
                  dailyTokenLimit: state.dailyTokenLimit,
                  providerWarnings: state.openCircuitProviders.length,
                  strings: strings,
                  onMemoryTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MemoryPage()),
                    );
                  },
                  onDocumentsTap: _openDocuments,
                ),
                const SizedBox(height: 14),
                _HomeCard(
                  title: strings.pick(
                    it: 'Ultima attivita',
                    en: 'Recent activity',
                  ),
                  child: recentChats.isEmpty
                      ? _EmptyHomeState(
                          icon: Icons.history_rounded,
                          title: strings.pick(
                            it: 'Nessuna conversazione recente',
                            en: 'No recent conversations',
                          ),
                          body: strings.pick(
                            it: 'Crea una chat o avvia un verticale per iniziare.',
                            en: 'Create a chat or start a workflow to begin.',
                          ),
                        )
                      : Column(
                          children: [
                            for (final chat in recentChats.take(3))
                              _RecentChatRow(
                                chat: chat,
                                strings: strings,
                                onTap: () => _openExistingChat(chat),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                _HomeCard(
                  title: strings.pick(
                    it: 'Documenti personali',
                    en: 'Personal documents',
                  ),
                  trailingIcon: Icons.folder_open_outlined,
                  actionLabel: strings.pick(it: 'Gestisci', en: 'Manage'),
                  onActionTap: _openDocuments,
                  child: recentDocs.isEmpty
                      ? _EmptyHomeState(
                          icon: Icons.description_outlined,
                          title: strings.pick(
                            it: 'Nessun documento indicizzato',
                            en: 'No indexed documents',
                          ),
                          body: strings.pick(
                            it: 'Attiva Documenti personali e allega file leggibili in chat.',
                            en: 'Enable Personal documents and attach readable files in chat.',
                          ),
                        )
                      : Column(
                          children: [
                            for (final doc in recentDocs.take(3))
                              _DocumentRow(document: doc),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _firstName(String rawName, AppStrings strings) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) {
      return strings.pick(it: 'utente', en: 'there');
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.avatarUrl});

  final String name;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = avatarUrl.trim();
    return CircleAvatar(
      radius: 18,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: url.isEmpty ? null : NetworkImage(url),
      child: url.isEmpty
          ? Text(
              name.isEmpty ? 'M' : name.substring(0, 1).toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.title,
    required this.child,
    this.trailingIcon,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final Widget child;
  final IconData? trailingIcon;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.65,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (actionLabel != null && onActionTap != null)
                TextButton(onPressed: onActionTap, child: Text(actionLabel!))
              else if (trailingIcon != null)
                Icon(trailingIcon, color: theme.textTheme.bodySmall?.color),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF202927) : const Color(0xFFF0EEE7),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemStatusCard extends StatelessWidget {
  const _SystemStatusCard({
    required this.memoryEnabled,
    required this.memoryCount,
    required this.documentCount,
    required this.dailyTokensUsed,
    required this.dailyTokenLimit,
    required this.providerWarnings,
    required this.strings,
    required this.onMemoryTap,
    required this.onDocumentsTap,
  });

  final bool memoryEnabled;
  final int memoryCount;
  final int documentCount;
  final int dailyTokensUsed;
  final int dailyTokenLimit;
  final int providerWarnings;
  final AppStrings strings;
  final VoidCallback onMemoryTap;
  final VoidCallback onDocumentsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = dailyTokenLimit <= 0
        ? 0.0
        : (dailyTokensUsed / dailyTokenLimit).clamp(0.0, 1.0).toDouble();
    return _HomeCard(
      title: strings.pick(it: 'Stato', en: 'Status'),
      child: Column(
        children: [
          _StatusRow(
            icon: Icons.psychology_alt_outlined,
            label: strings.pick(it: 'Memoria', en: 'Memory'),
            value: memoryEnabled
                ? strings.pick(
                    it: '$memoryCount note',
                    en: '$memoryCount notes',
                  )
                : strings.pick(it: 'Disattiva', en: 'Off'),
            onTap: onMemoryTap,
          ),
          const SizedBox(height: 10),
          _StatusRow(
            icon: Icons.folder_open_outlined,
            label: strings.pick(it: 'Documenti', en: 'Documents'),
            value: strings.pick(
              it: '$documentCount indicizzati',
              en: '$documentCount indexed',
            ),
            onTap: onDocumentsTap,
          ),
          const SizedBox(height: 10),
          _StatusRow(
            icon: providerWarnings == 0
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            label: strings.pick(it: 'Provider', en: 'Providers'),
            value: providerWarnings == 0
                ? strings.pick(it: 'Ok', en: 'Ok')
                : strings.pick(
                    it: '$providerWarnings da controllare',
                    en: '$providerWarnings warnings',
                  ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 5),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              strings.pick(
                it: 'Token oggi: $dailyTokensUsed/$dailyTokenLimit',
                en: 'Tokens today: $dailyTokensUsed/$dailyTokenLimit',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Row(
      children: [
        Icon(icon, size: 19, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }
}

class _RecentChatRow extends StatelessWidget {
  const _RecentChatRow({
    required this.chat,
    required this.strings,
    required this.onTap,
  });

  final Chat chat;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(_iconForKind(chat.kind), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_kindLabel(chat.kind, strings)} / ${_formatDate(chat.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document});

  final RagDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text('${document.chunks.length}', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _iconForKind(String kind) {
  return switch (kind) {
    Chat.kindDiet => Icons.restaurant_menu_rounded,
    Chat.kindMedical => Icons.medical_services_outlined,
    Chat.kindLegal => Icons.gavel_rounded,
    _ => Icons.chat_bubble_outline_rounded,
  };
}

String _kindLabel(String kind, AppStrings strings) {
  return switch (kind) {
    Chat.kindDiet => strings.pick(it: 'Dieta', en: 'Diet'),
    Chat.kindMedical => strings.pick(it: 'Medico', en: 'Medical'),
    Chat.kindLegal => strings.pick(it: 'Legale', en: 'Legal'),
    _ => strings.pick(it: 'Chat', en: 'Chat'),
  };
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
