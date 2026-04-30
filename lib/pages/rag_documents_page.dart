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
        title: Text(
          strings.pick(it: 'Documenti personali', en: 'Personal documents'),
        ),
        actions: [
          if (docs.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(
                      strings.pick(it: 'Svuotare indice?', en: 'Clear index?'),
                    ),
                    content: Text(
                      strings.pick(
                        it: 'Tutti i documenti personali verranno rimossi.',
                        en: 'All personal documents will be removed.',
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
      floatingActionButton: docs.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await controller.setRagEnabled(true);
                await controller.newChat();
                if (context.mounted) Navigator.pop(context, true);
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(
                strings.pick(
                  it: 'Chiedi sui documenti',
                  en: 'Ask about documents',
                ),
              ),
            ),
      body: docs.isEmpty
          ? _EmptyRagState(
              strings: strings,
              onStartChat: () async {
                await controller.setRagEnabled(true);
                await controller.newChat();
                if (context.mounted) Navigator.pop(context, true);
              },
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
  const _RagDocumentCard({required this.document, required this.onDelete});

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

class _EmptyRagState extends StatelessWidget {
  const _EmptyRagState({required this.strings, required this.onStartChat});

  final AppStrings strings;
  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFF9FD9CB) : const Color(0xFF0F5B52);

    final steps = [
      strings.pick(
        it: '1. Apri le impostazioni modello e attiva Documenti personali',
        en: '1. Open model settings and enable Personal Documents',
      ),
      strings.pick(
        it: '2. Avvia una chat e allega un file PDF, TXT o immagine',
        en: '2. Start a chat and attach a PDF, TXT, or image file',
      ),
      strings.pick(
        it: '3. Il file viene indicizzato e appare qui, pronto per le domande',
        en: '3. The file gets indexed and appears here, ready to query',
      ),
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF18322D)
                    : const Color(0xFFDCEDE7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dataset_linked_outlined,
                size: 36,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.pick(
                it: 'Nessun documento indicizzato',
                en: 'No documents indexed yet',
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              strings.pick(
                it: 'Indicizza i tuoi file per poter fare domande specifiche sul loro contenuto direttamente in chat.',
                en: 'Index your files to ask specific questions about their content directly in chat.',
              ),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1D2523) : const Color(0xFFF4EBDD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: steps
                    .map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          step,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(height: 1.4),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onStartChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(
                strings.pick(
                  it: 'Vai in chat',
                  en: 'Go to chat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
