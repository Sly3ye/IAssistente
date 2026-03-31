import '../models/message.dart';

class LLMModelOption {
  final String id;
  final String label;

  const LLMModelOption({required this.id, required this.label});
}

class LLMRequestConfig {
  final String systemPrompt;
  final double temperature;
  final int maxTokens;
  final double topP;

  const LLMRequestConfig({
    required this.systemPrompt,
    required this.temperature,
    required this.maxTokens,
    required this.topP,
  });

  static const defaults = LLMRequestConfig(
    systemPrompt: "Sei un assistente AI italiano, educato e conciso.",
    temperature: 0.7,
    maxTokens: 1024,
    topP: 1.0,
  );
}

abstract class LLMProvider {
  String get id;
  String get label;
  List<LLMModelOption> get models;
  bool get supportsStreaming;

  Future<List<LLMModelOption>> loadModels() async {
    return models;
  }

  Future<String> sendMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  });

  Stream<String> streamMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  });

  Future<String?> generateTitle({
    required String modelId,
    required String firstMessage,
  });
}

class LLMRegistry {
  final List<LLMProvider> providers;

  LLMRegistry(this.providers);

  LLMProvider byId(String id) {
    return providers.firstWhere((p) => p.id == id);
  }

  LLMProvider get defaultProvider => providers.first;
}
