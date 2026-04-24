import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

class AttachmentPreviewItem {
  const AttachmentPreviewItem({
    required this.label,
    this.kind,
    this.subtitle,
    this.previewPath,
    this.previewBytes,
    this.onRemove,
  });

  final String? kind;
  final String label;
  final String? subtitle;
  final String? previewPath;
  final Uint8List? previewBytes;
  final VoidCallback? onRemove;
}

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onAttach;
  final VoidCallback onMic;
  final bool isSending;
  final bool isListening;
  final double micLevel;
  final String attachTooltip;
  final String micTooltip;
  final String stopMicTooltip;
  final String hintText;
  final List<AttachmentPreviewItem> attachments;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onCancel,
    required this.onAttach,
    required this.onMic,
    required this.isSending,
    required this.isListening,
    required this.micLevel,
    required this.attachTooltip,
    required this.micTooltip,
    required this.stopMicTooltip,
    required this.hintText,
    this.attachments = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final dockSize = keyboardOpen ? 40.0 : 42.0;
    final sendButtonSize = keyboardOpen ? 44.0 : 48.0;

    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: keyboardOpen ? 12 : 14,
          vertical: keyboardOpen ? 6 : 12,
        ),
        margin: EdgeInsets.fromLTRB(
          10,
          keyboardOpen ? 2 : 8,
          10,
          keyboardOpen ? 2 : 12,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x66000000)
                  : const Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: attachments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = attachments[index];
                      return SizedBox(
                        width: 220,
                        child: _AttachmentChip(
                          kind: item.kind,
                          label: item.label,
                          subtitle: item.subtitle,
                          previewPath: item.previewPath,
                          previewBytes: item.previewBytes,
                          onRemove: item.onRemove,
                        ),
                      );
                    },
                  ),
                ),
              ),
            Row(
              children: [
                _ActionDock(
                  tooltip: attachTooltip,
                  onPressed: isSending ? null : onAttach,
                  icon: Icons.add_rounded,
                  size: dockSize,
                ),
                SizedBox(width: keyboardOpen ? 8 : 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: keyboardOpen ? 3 : 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => isSending ? null : onSend(),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: keyboardOpen ? 8 : 12,
                      ),
                    ).copyWith(
                      hintText: hintText,
                    ),
                  ),
                ),
                SizedBox(width: keyboardOpen ? 6 : 8),
                _MicActionDock(
                  tooltip: isListening ? stopMicTooltip : micTooltip,
                  onPressed: isSending ? null : onMic,
                  icon:
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  foregroundColor: isListening
                      ? (isDark
                            ? const Color(0xFF9FD9CB)
                            : const Color(0xFF0F5B52))
                      : theme.iconTheme.color ?? colorScheme.onSurface,
                  backgroundColor: isListening
                      ? (isDark
                            ? const Color(0xFF18322D)
                            : const Color(0xFFDCEDE7))
                      : (isDark
                            ? const Color(0xFF202927)
                            : const Color(0xFFF3ECE0)),
                  size: dockSize,
                  isListening: isListening,
                  level: micLevel,
                ),
                SizedBox(width: keyboardOpen ? 6 : 8),
                Container(
                  width: sendButtonSize,
                  height: sendButtonSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF3A8F80), Color(0xFF58B5A4)]
                          : const [Color(0xFF0F5B52), Color(0xFF1A7A6C)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isSending ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                      color: isDark ? const Color(0xFF071310) : Colors.white,
                    ),
                    onPressed: isSending ? onCancel : onSend,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MicActionDock extends StatelessWidget {
  const _MicActionDock({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.size,
    required this.isListening,
    required this.level,
    this.foregroundColor,
    this.backgroundColor,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final bool isListening;
  final double level;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedLevel = level.clamp(0.0, 1.0);
    final ringScale = 1 + (normalizedLevel * 0.12);
    final ringOpacity = 0.10 + (normalizedLevel * 0.16);
    final accentColor = foregroundColor ?? theme.colorScheme.primary;
    final outerGlowColor = accentColor.withValues(alpha: ringOpacity * 0.75);
    final innerGlowColor = accentColor.withValues(alpha: ringOpacity);

    return Tooltip(
      message: tooltip,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isListening)
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  scale: ringScale + 0.05,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  child: Container(
                    width: size + 16,
                    height: size + 16,
                    decoration: BoxDecoration(
                      color: outerGlowColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: ringScale,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  child: Container(
                    width: size + 8,
                    height: size + 8,
                    decoration: BoxDecoration(
                      color: innerGlowColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          _ActionDock(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: icon,
            size: size,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
          ),
          if (isListening)
            Positioned(
              bottom: 6,
              child: IgnorePointer(
                child: Row(
                  children: List.generate(3, (index) {
                    final barLevel = (normalizedLevel - (index * 0.08)).clamp(
                      0.16,
                      1.0,
                    );
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      width: 2.8,
                      height: 3 + (barLevel * 6),
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 2.5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    this.kind,
    required this.label,
    this.subtitle,
    this.previewPath,
    this.previewBytes,
    this.onRemove,
  });

  final String? kind;
  final String label;
  final String? subtitle;
  final String? previewPath;
  final Uint8List? previewBytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2523) : const Color(0xFFF4EBDD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          if (kind == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 46,
                height: 46,
                child: previewBytes != null
                    ? Image.memory(previewBytes!, fit: BoxFit.cover)
                    : (previewPath != null
                          ? Image.file(File(previewPath!), fit: BoxFit.cover)
                          : Container(
                              color: isDark
                                  ? const Color(0xFF2A3431)
                                  : const Color(0xFFE8DFD2),
                              child: Icon(
                                Icons.image_outlined,
                                size: 18,
                                color: theme.iconTheme.color,
                              ),
                            )),
              ),
            )
          else
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A3431)
                    : const Color(0xFFE8DFD2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                kind == 'video'
                    ? Icons.videocam_outlined
                    : Icons.attach_file_rounded,
                size: 20,
                color: theme.iconTheme.color,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Remove attachment',
            ),
        ],
      ),
    );
  }
}

class _ActionDock extends StatelessWidget {
  const _ActionDock({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.size,
    this.foregroundColor,
    this.backgroundColor,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor ??
            (isDark ? const Color(0xFF202927) : const Color(0xFFF3ECE0)),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              color: foregroundColor ?? theme.iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }
}
