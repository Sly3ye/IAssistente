import 'package:flutter/material.dart';

class AgentDisclaimerBanner extends StatelessWidget {
  const AgentDisclaimerBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: isDark ? const Color(0xFF172320) : const Color(0xFFF0E9DC),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: isDark ? const Color(0xFF9FD9CB) : const Color(0xFF0F5B52),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? const Color(0xFFB8D8D3)
                    : const Color(0xFF3A5E57),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
