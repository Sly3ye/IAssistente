class LocalToolResult {
  const LocalToolResult(this.reply);

  final String reply;
}

LocalToolResult? runLocalTool(String message, {String languageCode = 'it'}) {
  final text = message.trim();
  if (!text.startsWith('/')) return null;
  final isEnglish = languageCode == 'en';

  if (text == '/time' || text == '/date') {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return LocalToolResult(
      isEnglish
          ? 'Local date and time: ${now.year}-$month-$day $hour:$minute:$second'
          : 'Data e ora locali: ${now.year}-$month-$day $hour:$minute:$second',
    );
  }

  if (text.startsWith('/calc ')) {
    final expr = text.substring(6).trim();
    final result = _evalBasic(expr);
    if (result == null) {
      return LocalToolResult(
        isEnglish
            ? 'Invalid format. Use /calc with simple operations, e.g. /calc 12.5 * 3'
            : 'Formato non valido. Usa /calc con operazioni semplici: es. /calc 12.5 * 3',
      );
    }
    return LocalToolResult(
      isEnglish ? 'Result: $result' : 'Risultato: $result',
    );
  }

  if (text == '/help') {
    return LocalToolResult(
      isEnglish
          ? 'Available tools: /time, /date, /calc <a op b>, /help'
          : 'Tool disponibili: /time, /date, /calc <a op b>, /help',
    );
  }

  return null;
}

double? _evalBasic(String expr) {
  final match = RegExp(
    r'^\s*(-?\d+(?:\.\d+)?)\s*([+\-*/])\s*(-?\d+(?:\.\d+)?)\s*$',
  ).firstMatch(expr);
  if (match == null) return null;

  final left = double.tryParse(match.group(1)!);
  final op = match.group(2)!;
  final right = double.tryParse(match.group(3)!);
  if (left == null || right == null) return null;

  switch (op) {
    case '+':
      return left + right;
    case '-':
      return left - right;
    case '*':
      return left * right;
    case '/':
      if (right == 0) return null;
      return left / right;
    default:
      return null;
  }
}
