import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
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
        actions: [
          Tooltip(
            message: languageCode == 'it'
                ? 'Usa la memoria nelle risposte'
                : 'Use memory in replies',
            child: Switch(
              value: state.longTermMemoryEnabled,
              onChanged: (value) => ref
                  .read(chatControllerProvider.notifier)
                  .setLongTermMemory(value),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(languageCode == 'it' ? 'Aggiungi' : 'Add'),
      ),
      body: entries.isEmpty
          ? _EmptyMemoryState(
              languageCode: languageCode,
              theme: theme,
              onAdd: () => _showEditor(context, ref),
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
                          final strings = AppStrings.ofCode(languageCode);
                          if (!context.mounted) return;
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(strings.deleteMemoryConfirmTitle),
                              content: Text(strings.deleteMemoryConfirmBody),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(strings.cancel),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(strings.delete),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref
                                .read(chatControllerProvider.notifier)
                                .deleteMemoryEntry(raw);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            languageCode == 'it' ? 'Modifica' : 'Edit',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            languageCode == 'it' ? 'Elimina' : 'Delete',
                          ),
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
                          ? (initial == null
                                ? 'Nuova memoria'
                                : 'Modifica memoria')
                          : (initial == null
                                ? 'New memory entry'
                                : 'Edit memory entry'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<MemoryCategory>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: languageCode == 'it'
                            ? 'Categoria'
                            : 'Category',
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
                            child: Text(
                              languageCode == 'it' ? 'Annulla' : 'Cancel',
                            ),
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
                            child: Text(
                              languageCode == 'it' ? 'Salva' : 'Save',
                            ),
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

class _EmptyMemoryState extends StatelessWidget {
  const _EmptyMemoryState({
    required this.languageCode,
    required this.theme,
    required this.onAdd,
  });

  final String languageCode;
  final ThemeData theme;
  final VoidCallback onAdd;

  bool get _isItalian => languageCode == 'it';

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark
        ? const Color(0xFF9FD9CB)
        : const Color(0xFF0F5B52);
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
                Icons.psychology_outlined,
                size: 36,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isItalian ? 'Nessuna memoria salvata' : 'No memory saved yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _isItalian
                  ? 'Salva preferenze, vincoli, obiettivi e fatti utili su di te. Verranno inclusi automaticamente nelle risposte quando la memoria è attiva.'
                  : 'Save preferences, constraints, goals, and useful facts about you. They are automatically included in replies when memory is enabled.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1D2523)
                    : const Color(0xFFF4EBDD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _isItalian
                          ? 'Scrivi «ricorda che …» in chat per salvare qualcosa al volo'
                          : 'Write «remember that …» in chat to save on the fly',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _isItalian ? 'Aggiungi prima voce' : 'Add first entry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
