import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../controllers/chat_controller.dart';
import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../pages/account_page.dart';
import '../pages/chat_page.dart';
import '../pages/diet_agent_page.dart';
import '../pages/legal_agent_page.dart';
import '../pages/memory_page.dart';
import '../pages/medical_agent_page.dart';
import '../pages/premium_page.dart';
import '../pages/rag_documents_page.dart';
import '../providers/app_providers.dart';
import '../services/dev_options.dart';

enum ChatDrawerSection { home, chat }

class ChatDrawer extends ConsumerStatefulWidget {
  const ChatDrawer({
    super.key,
    this.activeSection = ChatDrawerSection.chat,
    this.onNewChat,
  });

  final ChatDrawerSection activeSection;
  final Future<void> Function()? onNewChat;

  @override
  ConsumerState<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<ChatDrawer> {
  Offset? _tapPosition;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final strings = AppStrings.ofCode(state.preferredLanguageCode);
    final authBypassEnabled = DevOptions.authBypassEnabled;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final chats = _sortedChats(state.chats, state.pinnedChatIds);

    final screenWidth = MediaQuery.of(context).size.width;
    return Drawer(
      width: screenWidth < 400 ? screenWidth * 0.88 : 318,
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? const Color(0x55000000)
                              : const Color(0x14000000),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0E2D1D), Color(0xFF214536)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFE9D2A3),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.profileName.isNotEmpty
                                    ? state.profileName
                                    : 'Mimir',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.isPremium
                                    ? strings.pick(
                                        it: 'Piano Pro',
                                        en: 'Pro plan',
                                      )
                                    : strings.pick(
                                        it: 'Piano base',
                                        en: 'Base plan',
                                      ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DrawerNavTile(
                    icon: Icons.home_outlined,
                    label: strings.pick(it: 'Home', en: 'Home'),
                    isSelected: widget.activeSection == ChatDrawerSection.home,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      if (widget.onNewChat != null) {
                        await widget.onNewChat!();
                        return;
                      }
                      await ref.read(chatControllerProvider.notifier).newChat();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(strings.newChat),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      minimumSize: const Size.fromHeight(52),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DrawerNavTile(
                    icon: Icons.history_rounded,
                    label: strings.pick(it: 'Cronologia', en: 'History'),
                    isSelected: widget.activeSection == ChatDrawerSection.chat,
                    onTap: () {},
                  ),
                  _DrawerNavTile(
                    icon: Icons.restaurant_menu_rounded,
                    label: strings.pick(it: 'Dieta', en: 'Diet'),
                    onTap: () async {
                      Navigator.pop(context);
                      final started = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const DietAgentPage(),
                        ),
                      );
                      if (!context.mounted ||
                          started != true ||
                          widget.activeSection != ChatDrawerSection.home) {
                        return;
                      }
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatPage()),
                      );
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.medical_services_outlined,
                    label: strings.pick(
                      it: 'Medico di base',
                      en: 'General practitioner',
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final started = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const MedicalAgentPage(),
                        ),
                      );
                      if (!context.mounted ||
                          started != true ||
                          widget.activeSection != ChatDrawerSection.home) {
                        return;
                      }
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatPage()),
                      );
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.gavel_rounded,
                    label: strings.pick(it: 'Avvocato', en: 'Lawyer'),
                    onTap: () async {
                      Navigator.pop(context);
                      final started = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const LegalAgentPage(),
                        ),
                      );
                      if (!context.mounted ||
                          started != true ||
                          widget.activeSection != ChatDrawerSection.home) {
                        return;
                      }
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatPage()),
                      );
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.psychology_alt_outlined,
                    label: strings.pick(it: 'Memoria', en: 'Memory'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MemoryPage()),
                      );
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.dataset_linked_outlined,
                    label: strings.pick(
                      it: 'Documenti personali',
                      en: 'Personal documents',
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final openedChat = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const RagDocumentsPage(),
                        ),
                      );
                      if (!context.mounted ||
                          openedChat != true ||
                          widget.activeSection != ChatDrawerSection.home) {
                        return;
                      }
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                children: [
                  if (chats.isNotEmpty)
                    for (final chat in chats)
                      _ChatTile(
                        chat: chat,
                        isSelected: state.currentChat?.id == chat.id,
                        isPinned: state.pinnedChatIds.contains(chat.id),
                        subtitle:
                            '${_chatKindLabel(chat.kind, strings)} / ${_formatDate(chat.updatedAt)}',
                        onTap: () {
                          ref
                              .read(chatControllerProvider.notifier)
                              .loadChat(chat.id);
                          Navigator.pop(context);
                        },
                        onTapDown: (details) =>
                            _tapPosition = details.globalPosition,
                        onLongPress: () =>
                            _showChatMenu(context, chat, strings),
                      )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        strings.noChatsYet,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF121816)
                    : const Color(0xFFF7F3EA),
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AccountPage()),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF4A4331)
                                : const Color(0xFFE7D7AE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initialsFromState(state),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? theme.colorScheme.onSurface
                                  : const Color(0xFF445145),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.profileName.isNotEmpty
                                    ? state.profileName
                                    : (state.profileEmail.isNotEmpty
                                          ? state.profileEmail
                                          : strings.guestMode),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                state.isPremium
                                    ? strings.pick(
                                        it: 'Piano Pro',
                                        en: 'Pro plan',
                                      )
                                    : strings.pick(
                                        it: 'Piano base',
                                        en: 'Base plan',
                                      ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (!authBypassEnabled)
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'premium') {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PremiumPage(),
                                  ),
                                );
                              } else if (value == 'logout') {
                                await ref.read(authServiceProvider).signOut();
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'premium',
                                child: Text('Premium'),
                              ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Text(strings.signOut),
                              ),
                            ],
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.more_horiz_rounded),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _version.isEmpty ? 'Mimir' : 'Mimir v$_version',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChatMenu(
    BuildContext context,
    Chat chat,
    AppStrings strings,
  ) async {
    if (_tapPosition == null) return;
    final state = ref.read(chatControllerProvider);
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(_tapPosition!.dx, _tapPosition!.dy, 0, 0),
      Offset.zero & overlayBox.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'pin',
          child: Text(
            state.pinnedChatIds.contains(chat.id)
                ? strings.unpinChat
                : strings.pinChat,
          ),
        ),
        PopupMenuItem(value: 'rename', child: Text(strings.rename)),
        PopupMenuItem(value: 'delete', child: Text(strings.delete)),
      ],
    );

    if (!context.mounted) return;
    if (action == 'pin') {
      await ref.read(chatControllerProvider.notifier).togglePinnedChat(chat);
    } else if (action == 'rename') {
      _showRenameDialog(context, chat, strings);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(strings.deleteChatConfirmTitle),
          content: Text(strings.deleteChatConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text(strings.delete),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        ref.read(chatControllerProvider.notifier).deleteChat(chat);
      }
    }
  }

  List<Chat> _sortedChats(List<Chat> chats, List<String> pinnedChatIds) {
    final pinned = pinnedChatIds.toSet();
    final sorted = [...chats];
    sorted.sort((a, b) {
      final aPinned = pinned.contains(a.id);
      final bPinned = pinned.contains(b.id);
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sorted;
  }

  void _showRenameDialog(BuildContext context, Chat chat, AppStrings strings) {
    final controllerText = TextEditingController(text: chat.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.rename),
          content: TextField(
            controller: controllerText,
            decoration: InputDecoration(labelText: strings.newName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel),
            ),
            TextButton(
              onPressed: () {
                final name = controllerText.text.trim();
                if (name.isNotEmpty) {
                  ref
                      .read(chatControllerProvider.notifier)
                      .renameChat(chat, name);
                }
                Navigator.pop(context);
              },
              child: Text(strings.save),
            ),
          ],
        );
      },
    );
  }

  String _initialsFromState(ChatState state) {
    final raw = state.profileName.trim().isNotEmpty
        ? state.profileName.trim()
        : state.profileEmail.trim();
    if (raw.isEmpty) return 'M';
    final parts = raw.split(RegExp(r'\s+'));
    String firstChar(String value) {
      return value.isEmpty ? '' : value.substring(0, 1).toUpperCase();
    }

    if (parts.length == 1) return firstChar(parts.first);
    return '${firstChar(parts.first)}${firstChar(parts.last)}';
  }

  String _formatDate(DateTime date) {
    final state = ref.read(chatControllerProvider);
    final strings = AppStrings.ofCode(state.preferredLanguageCode);
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return strings.pick(it: 'Oggi', en: 'Today');
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _chatKindLabel(String kind, AppStrings strings) {
    return switch (kind) {
      Chat.kindDiet => strings.pick(it: 'Dieta', en: 'Diet'),
      Chat.kindMedical => strings.pick(it: 'Medico', en: 'Medical'),
      Chat.kindLegal => strings.pick(it: 'Legale', en: 'Legal'),
      _ => strings.pick(it: 'Chat', en: 'Chat'),
    };
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: isSelected ? theme.colorScheme.surfaceContainerHighest : null,
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? theme.colorScheme.onSurface : theme.iconTheme.color,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected
              ? theme.colorScheme.onSurface
              : theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.isSelected,
    required this.isPinned,
    required this.subtitle,
    required this.onTap,
    required this.onTapDown,
    required this.onLongPress,
  });

  final Chat chat;
  final bool isSelected;
  final bool isPinned;
  final String subtitle;
  final VoidCallback onTap;
  final GestureTapDownCallback onTapDown;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: onTapDown,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: isSelected
            ? theme.colorScheme.surfaceContainerHighest
            : null,
        leading: Icon(
          isPinned ? Icons.push_pin_rounded : _iconForKind(chat.kind),
          size: 16,
          color: isPinned ? const Color(0xFFC69A46) : theme.disabledColor,
        ),
        title: Text(
          chat.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  IconData _iconForKind(String kind) {
    return switch (kind) {
      Chat.kindDiet => Icons.restaurant_menu_rounded,
      Chat.kindMedical => Icons.medical_services_outlined,
      Chat.kindLegal => Icons.gavel_rounded,
      _ => Icons.chat_bubble_outline_rounded,
    };
  }
}
