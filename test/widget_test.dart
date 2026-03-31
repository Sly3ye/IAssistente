import 'package:flutter_test/flutter_test.dart';

import 'package:iassistente/models/message.dart';
import 'package:iassistente/utils/token_estimator.dart';

void main() {
  test('estimateTokensFromText returns 0 for empty text', () {
    expect(estimateTokensFromText('   '), 0);
  });

  test('estimateTokensFromText scales with text length', () {
    expect(estimateTokensFromText('ciao'), 1);
    expect(estimateTokensFromText('a' * 40), 10);
  });

  test('estimateTokensFromMessages sums message token estimates', () {
    final messages = [
      Message(
        chatId: '1',
        role: 'user',
        content: 'Ciao mondo',
        createdAt: DateTime(2026, 1, 1),
      ),
      Message(
        chatId: '1',
        role: 'assistant',
        content: 'Risposta breve',
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    final expected =
        estimateTokensFromText('Ciao mondo') +
        estimateTokensFromText('Risposta breve');
    expect(estimateTokensFromMessages(messages), expected);
  });

  test('estimateUsdFromTokens returns expected cost', () {
    expect(estimateUsdFromTokens(2000), closeTo(0.004, 0.000001));
  });
}
