import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../models/message.dart';
import '../providers/app_providers.dart';
import 'chat_bubble.dart';

class ChatList extends ConsumerWidget {
  final List<Message> messages;
  final ScrollController controller;
  final bool isSending;
  final String streamingText;
  final List<String> latestAssistantSources;
  final ValueChanged<Message>? onReadAloud;

  const ChatList({
    super.key,
    required this.messages,
    required this.controller,
    required this.isSending,
    required this.streamingText,
    required this.latestAssistantSources,
    this.onReadAloud,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.ofCode(
      ref.watch(chatControllerProvider).preferredLanguageCode,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (messages.isEmpty && !isSending && streamingText.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF12322D), Color(0xFF1D6C60)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFF7E1B5),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.startConversation,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                strings.realtimeReplyHint,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1D2523)
                      : const Color(0xFFFFFBF4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  'Chat, allegati, cronologia e impostazioni nello stesso spazio.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? const Color(0xFFDCE7E2)
                        : theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayMessages = List<Message>.from(messages);
    if (isSending && streamingText.isNotEmpty) {
      displayMessages.add(
        Message(
          chatId: messages.isNotEmpty ? messages.last.chatId : "",
          role: "assistant",
          content: streamingText,
          createdAt: DateTime.now(),
          isStreaming: true,
        ),
      );
    } else if (isSending && streamingText.isEmpty) {
      displayMessages.add(
        Message(
          chatId: messages.isNotEmpty ? messages.last.chatId : "",
          role: "assistant",
          content: strings.pick(it: 'Sto scrivendo...', en: 'Typing...'),
          createdAt: DateTime.now(),
          isStreaming: true,
        ),
      );
    }

    var latestAssistantIndex = -1;
    for (var i = displayMessages.length - 1; i >= 0; i--) {
      if (displayMessages[i].role == "assistant") {
        latestAssistantIndex = i;
        break;
      }
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: displayMessages.length,
      itemBuilder: (context, index) {
        final message = displayMessages[index];
        return ChatBubble(
          message: message,
          retryTooltip: strings.retry,
          editTooltip: strings.edit,
          copyTooltip: strings.copy,
          readAloudTooltip: strings.pick(
            it: 'Leggi risposta',
            en: 'Read reply',
          ),
          copiedMessage: strings.textCopied,
          errorLabel: strings.errorBadge,
          sourcesTitle:
              message.role == "assistant" &&
                  latestAssistantSources.isNotEmpty &&
                  index == latestAssistantIndex
              ? strings.ragSourcesTitle(latestAssistantSources.length)
              : null,
          sourceNames:
              message.role == "assistant" &&
                  latestAssistantSources.isNotEmpty &&
                  index == latestAssistantIndex
              ? latestAssistantSources
              : const [],
          onEdit:
              message.role == "user" &&
                  message.id != null &&
                  !message.isStreaming
              ? () => _showEditDialog(context, ref, message)
              : null,
          onRetry: message.role == "assistant" && !message.isStreaming
              ? () => ref
                    .read(chatControllerProvider.notifier)
                    .retryFromAssistant(message)
              : null,
          onReadAloud:
              message.role == "assistant" &&
                  !message.isStreaming &&
                  onReadAloud != null
              ? () => onReadAloud!(message)
              : null,
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Message message) {
    final controllerText = TextEditingController(text: message.content);
    final strings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.editMessage),
        content: TextField(
          controller: controllerText,
          minLines: 1,
          maxLines: 6,
          decoration: InputDecoration(labelText: strings.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () async {
              final text = controllerText.text.trim();
              if (text.isNotEmpty) {
                await ref
                    .read(chatControllerProvider.notifier)
                    .editUserMessage(message, text);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(strings.retry),
          ),
        ],
      ),
    );
  }
}
