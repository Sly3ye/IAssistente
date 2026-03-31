import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/chat_controller.dart';
import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../pages/account_page.dart';
import '../pages/premium_page.dart';
import '../providers/app_providers.dart';
import '../services/llm_provider.dart';

class ChatDrawer extends ConsumerStatefulWidget {
  const ChatDrawer({super.key});

  @override
  ConsumerState<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<ChatDrawer> {
  Offset? _tapPosition;
  String _query = '';
  Set<String> _messageMatchChatIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final registry = ref.watch(llmRegistryProvider);
    final strings = AppStrings.ofCode(state.preferredLanguageCode);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IAssistente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          state.profileName.isNotEmpty
                              ? state.profileName
                              : (state.profileEmail.isNotEmpty
                                    ? state.profileEmail
                                    : strings.accountSection),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${_providerLabel(registry, state.selectedProviderId)} · ${state.selectedModelId}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          strings.tokenCostStats(
                            state.dailyTokensUsed,
                            state.dailyTokenLimit,
                            state.estimatedCostUsd,
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          strings.requestStats(
                            state.successRequests,
                            state.failedRequests,
                            state.averageLatencyMs,
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        ref.read(chatControllerProvider.notifier).newChat(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: strings.searchChats,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                strings.drawerChats,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            if (_filteredChats(state.chats).isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(strings.noChatsYet)),
              ),
            for (final chat in _filteredChats(state.chats))
              GestureDetector(
                onTapDown: (details) {
                  _tapPosition = details.globalPosition;
                },
                child: ListTile(
                  title: Text(
                    chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: _buildSubtitle(chat, registry),
                  selected: state.currentChat?.id == chat.id,
                  onTap: () {
                    ref.read(chatControllerProvider.notifier).loadChat(chat.id);
                    Navigator.pop(context);
                  },
                  onLongPress: () async {
                    if (_tapPosition == null) return;
                    final overlay = Overlay.of(context);
                    final overlayBox =
                        overlay.context.findRenderObject() as RenderBox;
                    final position = RelativeRect.fromRect(
                      Rect.fromLTWH(_tapPosition!.dx, _tapPosition!.dy, 0, 0),
                      Offset.zero & overlayBox.size,
                    );

                    final action = await showMenu(
                      context: context,
                      position: position,
                      items: [
                        PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Text(strings.rename),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                strings.delete,
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (!context.mounted) return;
                    if (action == 'rename') {
                      _showRenameDialog(context, chat, ref);
                    } else if (action == 'delete') {
                      ref
                          .read(chatControllerProvider.notifier)
                          .deleteChat(chat);
                    }
                  },
                ),
              ),
            const SizedBox(height: 12),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(strings.exportFullBackup),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final path = await ref
                    .read(chatControllerProvider.notifier)
                    .exportChatsBackup();
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(strings.backupExported(path))),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(strings.exportCurrentChat),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final path = await ref
                    .read(chatControllerProvider.notifier)
                    .exportCurrentChatMarkdown();
                if (!context.mounted) return;
                final text = path == null
                    ? strings.noCurrentChatToExport
                    : strings.chatExported(path);
                messenger.showSnackBar(SnackBar(content: Text(text)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(strings.importLatestBackup),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final path = await ref
                    .read(chatControllerProvider.notifier)
                    .importChatsBackupFromLatest();
                if (!context.mounted) return;
                final message = path == null
                    ? strings.noBackupFound('locale')
                    : strings.backupImported(path);
                messenger.showSnackBar(SnackBar(content: Text(message)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: Text(strings.clearLocalChatData),
              onTap: () async {
                final shouldClear = await showDialog<bool>(
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
                if (shouldClear != true) return;
                await ref
                    .read(chatControllerProvider.notifier)
                    .clearLocalChatsAndMessages();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.localDataRemoved)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: Text(strings.manageDocuments),
              onTap: () => _showDocumentsDialog(context, strings, state),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(strings.accountAndPrivacy),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AccountPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(strings.premium),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const PremiumPage()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(strings.signOut),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSearchChanged(String value) async {
    final trimmed = value.trim();
    setState(() {
      _query = trimmed;
      if (trimmed.isEmpty) {
        _messageMatchChatIds = <String>{};
      }
    });

    if (trimmed.isEmpty) return;

    final ids = await ref
        .read(chatControllerProvider.notifier)
        .searchChatIdsByMessage(trimmed);
    if (!mounted) return;

    setState(() {
      _messageMatchChatIds = ids;
    });
  }

  List<Chat> _filteredChats(List<Chat> chats) {
    if (_query.isEmpty) return chats;
    final q = _query.toLowerCase();
    return chats.where((chat) {
      final titleMatch = chat.title.toLowerCase().contains(q);
      final messageMatch = _messageMatchChatIds.contains(chat.id);
      return titleMatch || messageMatch;
    }).toList();
  }

  Widget _buildSubtitle(Chat chat, LLMRegistry registry) {
    final providerLabel = _providerLabel(registry, chat.providerId);
    return Text(
      '$providerLabel · ${chat.modelId} · ${_formatDate(chat.updatedAt)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _providerLabel(LLMRegistry registry, String providerId) {
    try {
      return registry.byId(providerId).label;
    } catch (_) {
      return providerId;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  void _showRenameDialog(BuildContext context, Chat chat, WidgetRef ref) {
    final controllerText = TextEditingController(text: chat.title);
    final strings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
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

  void _showDocumentsDialog(
    BuildContext context,
    AppStrings strings,
    ChatState state,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            Text(
              strings.manageDocuments,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (state.ragDocuments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(strings.noIndexedDocuments),
              ),
            for (final doc in state.ragDocuments)
              ListTile(
                title: Text(doc.name),
                subtitle: Text(_formatDate(doc.createdAt)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref
                        .read(chatControllerProvider.notifier)
                        .deleteRagDocument(doc.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.documentDeleted(doc.name)),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            if (state.ragDocuments.isNotEmpty)
              FilledButton.tonal(
                onPressed: () async {
                  await ref
                      .read(chatControllerProvider.notifier)
                      .clearRagDocuments();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.documentsCleared)),
                  );
                  Navigator.pop(context);
                },
                child: Text(strings.clearAllDocuments),
              ),
          ],
        ),
      ),
    );
  }
}
