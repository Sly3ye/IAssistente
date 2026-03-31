import '../models/message.dart';

int estimateTokensFromText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return ((trimmed.length / 4).ceil()).clamp(1, 1000000);
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
