import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onEdit;
  final VoidCallback? onRetry;
  final String retryTooltip;
  final String editTooltip;
  final String copyTooltip;
  final String copiedMessage;

  const ChatBubble({
    super.key,
    required this.message,
    this.onEdit,
    this.onRetry,
    required this.retryTooltip,
    required this.editTooltip,
    required this.copyTooltip,
    required this.copiedMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == "user";
    final isError = message.isError;
    final isStreaming = message.isStreaming;
    final bubbleColor = isUser
        ? Colors.indigo.shade200
        : (isError ? Colors.red.shade100 : Colors.grey.shade200);
    final borderColor = isUser
        ? Colors.indigo.shade300
        : (isError ? Colors.red.shade300 : Colors.grey.shade300);
    final showActions = !isStreaming;
    final actionsAlignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: actionsAlignment,
          children: [
            Row(
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser)
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      size: 16,
                      color: Colors.indigo.shade400,
                    ),
                  ),
                GestureDetector(
                  onLongPress: () async {
                    await Clipboard.setData(
                      ClipboardData(text: message.content),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(copiedMessage)));
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.74,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: isError ? Colors.red.shade900 : Colors.black87,
                          fontStyle: isStreaming
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isUser)
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            if (showActions)
              Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  left: isUser ? 0 : 36,
                  right: isUser ? 36 : 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onRetry != null)
                      IconButton(
                        tooltip: retryTooltip,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onPressed: onRetry,
                        icon: Icon(Icons.refresh, color: Colors.grey.shade600),
                      ),
                    if (onRetry != null) const SizedBox(width: 8),
                    if (onEdit != null)
                      IconButton(
                        tooltip: editTooltip,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onPressed: onEdit,
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (onEdit != null) const SizedBox(width: 8),
                    IconButton(
                      tooltip: copyTooltip,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: message.content),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(copiedMessage)));
                      },
                      icon: Icon(
                        Icons.copy_outlined,
                        color: Colors.grey.shade600,
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
}
