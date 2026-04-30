import '../models/message.dart';

int estimateTokensFromText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  // Word-based estimate: ~1.3 tokens/word for Italian/English prose.
  // Penalize non-ASCII characters (accents, special chars) that BPE splits.
  final words = trimmed.split(RegExp(r'\s+'));
  final wordTokens = (words.length * 1.3).ceil();
  final nonAscii = trimmed.runes.where((r) => r > 127).length;
  final extraTokens = (nonAscii * 0.3).ceil();
  return (wordTokens + extraTokens).clamp(1, 1000000);
}

int estimateTokensFromMessages(List<Message> messages) {
  var total = 0;
  for (final message in messages) {
    total += estimateTokensFromText(message.content);
  }
  return total;
}

double estimateUsdFromTokens(int tokens, {double usdPer1kTokens = 0.002}) {
  if (tokens <= 0) return 0;
  return (tokens / 1000.0) * usdPer1kTokens;
}
