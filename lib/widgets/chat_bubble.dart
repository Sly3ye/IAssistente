import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onEdit;
  final VoidCallback? onRetry;
  final VoidCallback? onReadAloud;
  final String retryTooltip;
  final String editTooltip;
  final String copyTooltip;
  final String readAloudTooltip;
  final String copiedMessage;
  final String? sourcesTitle;
  final List<String> sourceNames;

  const ChatBubble({
    super.key,
    required this.message,
    this.onEdit,
    this.onRetry,
    this.onReadAloud,
    required this.retryTooltip,
    required this.editTooltip,
    required this.copyTooltip,
    required this.readAloudTooltip,
    required this.copiedMessage,
    this.sourcesTitle,
    this.sourceNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    final isUser = message.role == "user";
    final isError = message.isError;
    final isStreaming = message.isStreaming;
    final bubbleColor = isUser
        ? (isDarkTheme ? const Color(0xFF1D5A52) : const Color(0xFF0F5B52))
        : (isError
              ? (isDarkTheme
                    ? const Color(0xFF4A241C)
                    : const Color(0xFFFFE8E2))
              : theme.cardColor);
    final borderColor = isUser
        ? (isDarkTheme ? const Color(0xFF3E9A8D) : const Color(0xFF2F8D7D))
        : (isError
              ? (isDarkTheme
                    ? const Color(0xFFA55C4B)
                    : const Color(0xFFF0B7A2))
              : theme.dividerColor);
    final showActions = !isStreaming;
    final actionsAlignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final attachments = _parseAttachmentMarkers(message.content);
    final visibleContent = _stripAttachmentMarker(message.content).trim();

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
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isDarkTheme
                          ? const Color(0xFF2B5A52)
                          : const Color(0xFFE4D3B3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: isDarkTheme
                          ? const Color(0xFFE7F7F2)
                          : const Color(0xFF12322D),
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
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(22),
                          topRight: const Radius.circular(22),
                          bottomLeft: Radius.circular(isUser ? 22 : 8),
                          bottomRight: Radius.circular(isUser ? 8 : 22),
                        ),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (attachments.isNotEmpty) ...[
                            for (var i = 0; i < attachments.length; i++) ...[
                              _AttachmentPreview(
                                attachment: attachments[i],
                                isUser: isUser,
                              ),
                              if (i != attachments.length - 1 ||
                                  visibleContent.isNotEmpty)
                                const SizedBox(height: 10),
                            ],
                          ],
                          if (visibleContent.isNotEmpty)
                            Text(
                              visibleContent,
                              style: TextStyle(
                                color: isUser
                                    ? (isDarkTheme
                                          ? const Color(0xFFF6FBFA)
                                          : Colors.white)
                                    : (isError
                                          ? (isDarkTheme
                                                ? const Color(0xFFFFC4B4)
                                                : const Color(0xFF8E3720))
                                          : theme.colorScheme.onSurface),
                                fontStyle: isStreaming
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                height: 1.45,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isUser)
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12322D),
                      borderRadius: BorderRadius.circular(12),
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
                      _MessageActionButton(
                        tooltip: retryTooltip,
                        icon: Icons.refresh_rounded,
                        onPressed: onRetry!,
                      ),
                    if (onRetry != null) const SizedBox(width: 8),
                    if (onEdit != null)
                      _MessageActionButton(
                        tooltip: editTooltip,
                        icon: Icons.edit_outlined,
                        onPressed: onEdit!,
                      ),
                    if (onEdit != null) const SizedBox(width: 8),
                    if (onReadAloud != null)
                      _MessageActionButton(
                        tooltip: readAloudTooltip,
                        icon: Icons.volume_up_outlined,
                        onPressed: onReadAloud!,
                      ),
                    if (onReadAloud != null) const SizedBox(width: 8),
                    _MessageActionButton(
                      tooltip: copyTooltip,
                      icon: Icons.copy_outlined,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: message.content),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(copiedMessage)));
                      },
                    ),
                  ],
                ),
              ),
            if (!isUser && sourceNames.isNotEmpty && sourcesTitle != null)
              Padding(
                padding: const EdgeInsets.only(left: 36, top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sourcesTitle!,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: sourceNames
                          .map(
                            (name) => Chip(
                              backgroundColor: isDarkTheme
                                  ? const Color(0xFF26302D)
                                  : const Color(0xFFF4E8D2),
                              side: BorderSide(color: theme.dividerColor),
                              label: Text(name),
                            ),
                          )
                          .toList(growable: false),
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

class _MessageActionButton extends StatefulWidget {
  const _MessageActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_MessageActionButton> createState() => _MessageActionButtonState();
}

class _MessageActionButtonState extends State<_MessageActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Tooltip(
      message: widget.tooltip,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _pressed
                ? (isDark
                      ? const Color(0xFF2A3431)
                      : const Color(0xFFEDE2D0))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTapDown: (_) => _setPressed(true),
              onTapCancel: () => _setPressed(false),
              onTap: () async {
                _setPressed(true);
                widget.onPressed();
                await Future<void>.delayed(const Duration(milliseconds: 120));
                _setPressed(false);
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: theme.iconTheme.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParsedAttachment {
  const _ParsedAttachment({
    required this.kind,
    required this.path,
    required this.fileName,
  });

  final String kind;
  final String path;
  final String fileName;
}

List<_ParsedAttachment> _parseAttachmentMarkers(String content) {
  final matches = RegExp(
    r'\[\[attachment:(image|video)\|(.+?)\|(.+?)\]\]',
  ).allMatches(content);
  return matches
      .map(
        (match) => _ParsedAttachment(
          kind: match.group(1)!,
          path: match.group(2)!,
          fileName: match.group(3)!,
        ),
      )
      .toList(growable: false);
}

String _stripAttachmentMarker(String content) {
  return content
      .replaceAll(RegExp(r'\[\[attachment:(image|video)\|(.+?)\|(.+?)\]\]'), '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    required this.attachment,
    required this.isUser,
  });

  final _ParsedAttachment attachment;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    if (attachment.kind == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220, minWidth: 120),
          child: Image.file(
            File(attachment.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _FallbackAttachmentCard(
              icon: Icons.image_outlined,
              label: attachment.fileName,
              isUser: isUser,
            ),
          ),
        ),
      );
    }

    return _FallbackAttachmentCard(
      icon: Icons.videocam_outlined,
      label: attachment.fileName,
      isUser: isUser,
    );
  }
}

class _FallbackAttachmentCard extends StatelessWidget {
  const _FallbackAttachmentCard({
    required this.icon,
    required this.label,
    required this.isUser,
  });

  final IconData icon;
  final String label;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? const Color(0x1FFFFFFF)
            : (isDark ? const Color(0xFF1D2523) : const Color(0xFFF4EBDD)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser ? const Color(0x33FFFFFF) : theme.dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isUser ? Colors.white : theme.iconTheme.color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUser ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
