import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/memory_entry.dart';
import '../providers/app_providers.dart';

class MemoryPage extends ConsumerWidget {
  const MemoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider);
    final theme = Theme.of(context);
    final languageCode = state.preferredLanguageCode;
    final entries = state.memoryNotes
        .map(MemoryEntry.parse)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageCode == 'it' ? 'Memoria utente' : 'User memory'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(languageCode == 'it' ? 'Aggiungi' : 'Add'),
      ),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  languageCode == 'it'
                      ? 'Salva preferenze, vincoli, obiettivi e fatti utili. Verranno usati solo quando rilevanti.'
                      : 'Save preferences, constraints, goals, and useful facts. They will be used only when relevant.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final raw = state.memoryNotes[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                    title: Text(
                      entry.category.label(languageCode),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(entry.content),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showEditor(
                            context,
                            ref,
                            initial: entry,
                            rawValue: raw,
                          );
                        } else if (value == 'delete') {
                          await ref
                              .read(chatControllerProvider.notifier)
                              .deleteMemoryEntry(raw);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(languageCode == 'it' ? 'Modifica' : 'Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(languageCode == 'it' ? 'Elimina' : 'Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    MemoryEntry? initial,
    String? rawValue,
  }) async {
    final languageCode = ref.read(chatControllerProvider).preferredLanguageCode;
    final controller = TextEditingController(text: initial?.content ?? '');
    var category = initial?.category ?? MemoryCategory.note;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: EdgeInsets.only(
                left: 8,
                right: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageCode == 'it'
                          ? (initial == null ? 'Nuova memoria' : 'Modifica memoria')
                          : (initial == null ? 'New memory entry' : 'Edit memory entry'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<MemoryCategory>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: languageCode == 'it' ? 'Categoria' : 'Category',
                      ),
                      items: MemoryCategory.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label(languageCode)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => category = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: languageCode == 'it'
                            ? 'Contenuto da ricordare'
                            : 'Content to remember',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(languageCode == 'it' ? 'Annulla' : 'Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;
                              if (initial == null || rawValue == null) {
                                await ref
                                    .read(chatControllerProvider.notifier)
                                    .addMemoryEntry(
                                      category: category,
                                      content: text,
                                    );
                              } else {
                                await ref
                                    .read(chatControllerProvider.notifier)
                                    .updateMemoryEntry(
                                      previousValue: rawValue,
                                      category: category,
                                      content: text,
                                    );
                              }
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Text(languageCode == 'it' ? 'Salva' : 'Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
