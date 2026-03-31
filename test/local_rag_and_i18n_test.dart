import 'package:flutter_test/flutter_test.dart';
import 'package:iassistente/l10n/app_strings.dart';
import 'package:iassistente/services/local_rag_service.dart';

void main() {
  test('AppStrings falls back to italian for unknown language', () {
    final strings = AppStrings.ofCode('fr');
    expect(strings.languageCode, 'it');
    expect(strings.login, 'Accedi');
  });

  test('AppStrings returns english labels', () {
    final strings = AppStrings.ofCode('en');
    expect(strings.login, 'Sign in');
    expect(strings.languageLabel('it'), 'Italian');
  });

  test('LocalRagService indexes and retrieves matching context', () {
    final service = LocalRagService();
    final docs = service.indexDocuments(
      existing: const [],
      documentName: 'Roadmap',
      text:
          'The deploy checklist includes Firebase setup, premium subscriptions, and local retrieval augmented generation for attachments.',
    );

    final result = service.retrieve(
      query: 'How do subscriptions work?',
      documents: docs,
    );

    expect(docs, isNotEmpty);
    expect(result.context, contains('subscriptions'));
    expect(result.matchedChunks, isNotEmpty);
  });
}
