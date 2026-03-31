class PromptPreset {
  const PromptPreset({
    required this.id,
    required this.name,
    required this.systemPrompt,
    required this.temperature,
    required this.maxTokens,
    required this.topP,
  });

  final String id;
  final String name;
  final String systemPrompt;
  final double temperature;
  final int maxTokens;
  final double topP;

  Map<String, Object> toJson() {
    return {
      'id': id,
      'name': name,
      'systemPrompt': systemPrompt,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'topP': topP,
    };
  }

  factory PromptPreset.fromJson(Map<String, dynamic> json) {
    return PromptPreset(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Preset').toString(),
      systemPrompt: (json['systemPrompt'] ?? '').toString(),
      temperature: _parseDouble(json['temperature'], fallback: 0.7),
      maxTokens: _parseInt(json['maxTokens'], fallback: 1024),
      topP: _parseDouble(json['topP'], fallback: 1.0),
    );
  }

  static double _parseDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _parseInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
