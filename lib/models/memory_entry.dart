enum MemoryCategory { profile, preference, constraint, goal, note }

class MemoryEntry {
  const MemoryEntry({required this.category, required this.content});

  final MemoryCategory category;
  final String content;

  String serialize() => '${category.name}::$content';

  static MemoryEntry parse(String raw) {
    final separator = raw.indexOf('::');
    if (separator <= 0 || separator >= raw.length - 2) {
      return MemoryEntry(category: MemoryCategory.note, content: raw.trim());
    }
    final categoryName = raw.substring(0, separator).trim();
    final content = raw.substring(separator + 2).trim();
    MemoryCategory? category;
    for (final item in MemoryCategory.values) {
      if (item.name == categoryName) {
        category = item;
        break;
      }
    }
    return MemoryEntry(
      category: category ?? MemoryCategory.note,
      content: content,
    );
  }
}

extension MemoryCategoryX on MemoryCategory {
  String label(String languageCode) {
    final isItalian = languageCode == 'it';
    return switch (this) {
      MemoryCategory.profile => isItalian ? 'Profilo' : 'Profile',
      MemoryCategory.preference => isItalian ? 'Preferenze' : 'Preferences',
      MemoryCategory.constraint => isItalian ? 'Vincoli' : 'Constraints',
      MemoryCategory.goal => isItalian ? 'Obiettivi' : 'Goals',
      MemoryCategory.note => isItalian ? 'Note' : 'Notes',
    };
  }
}
