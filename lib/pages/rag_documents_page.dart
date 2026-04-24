import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/rag_document.dart';
import '../providers/app_providers.dart';

class RagDocumentsPage extends ConsumerWidget {
  const RagDocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final strings = AppStrings.ofCode(state.preferredLanguageCode);
    final docs = state.ragDocuments;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.pick(it: 'Documenti RAG', en: 'RAG documents')),
        actions: [
          if (docs.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(
                      strings.pick(
                        it: 'Svuotare indice?',
                        en: 'Clear index?',
                      ),
                    ),
                    content: Text(
                      strings.pick(
                        it: 'Tutti i documenti RAG verranno rimossi.',
                        en: 'All RAG documents will be removed.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(strings.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(strings.pick(it: 'Svuota', en: 'Clear')),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await controller.clearRagDocuments();
                }
              },
              child: Text(strings.pick(it: 'Svuota', en: 'Clear')),
            ),
        ],
      ),
      body: docs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  strings.noIndexedDocuments,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                return _RagDocumentCard(
                  document: doc,
                  onDelete: () async {
                    await controller.deleteRagDocument(doc.id);
                  },
                );
              },
            ),
    );
  }
}

class _RagDocumentCard extends StatelessWidget {
  const _RagDocumentCard({
    required this.document,
    required this.onDelete,
  });

  final RagDocument document;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.description_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${document.chunks.length} chunk • ${document.createdAt.day.toString().padLeft(2, '0')}/${document.createdAt.month.toString().padLeft(2, '0')}/${document.createdAt.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
