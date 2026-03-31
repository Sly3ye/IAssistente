import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onAttach;
  final VoidCallback onMic;
  final bool isSending;
  final bool isListening;
  final String attachTooltip;
  final String micTooltip;
  final String stopMicTooltip;
  final String hintText;

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
    required this.attachTooltip,
    required this.micTooltip,
    required this.stopMicTooltip,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: attachTooltip,
              onPressed: isSending ? null : onAttach,
              icon: const Icon(Icons.attach_file),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => isSending ? null : onSend(),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hintText,
                ),
              ),
            ),
            IconButton(
              tooltip: isListening ? stopMicTooltip : micTooltip,
              onPressed: isSending ? null : onMic,
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none_outlined,
                color: isListening ? Colors.red : Colors.grey.shade700,
              ),
            ),
            CircleAvatar(
              backgroundColor: isSending ? Colors.grey : Colors.blueAccent,
              child: IconButton(
                icon: isSending
                    ? const Icon(Icons.stop, color: Colors.white)
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: isSending ? onCancel : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
