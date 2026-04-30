class Chat {
  static const String kindGeneral = 'general';
  static const String kindDiet = 'diet';
  static const String kindMedical = 'medical';
  static const String kindLegal = 'legal';

  final String id;
  final String title;
  final String kind;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String providerId;
  final String modelId;
  final String systemPrompt;
  final double temperature;
  final int maxTokens;
  final double topP;

  Chat({
    required this.id,
    required this.title,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    required this.providerId,
    required this.modelId,
    required this.systemPrompt,
    required this.temperature,
    required this.maxTokens,
    required this.topP,
  });

  Chat copyWith({
    String? id,
    String? title,
    String? kind,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? providerId,
    String? modelId,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    double? topP,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
    );
  }
}
