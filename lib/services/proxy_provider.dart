import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/message.dart';
import 'llm_provider.dart';

class ProxyProvider implements LLMProvider {
  @override
  String get id => "proxy";

  @override
  String get label => "Proxy";

  @override
  bool get supportsStreaming => false;

  @override
  List<LLMModelOption> get models => const [
    LLMModelOption(id: "default", label: "Default"),
  ];

  @override
  Future<List<LLMModelOption>> loadModels() async {
    final baseUrl = dotenv.env['LLM_PROXY_URL'];
    if (baseUrl == null || baseUrl.isEmpty) return models;

    final modelsUrl = baseUrl.replaceAll('/v1/chat', '/v1/models');
    try {
      final response = await http.get(Uri.parse(modelsUrl));
      final data = jsonDecode(response.body);
      final rows = data['models'];
      if (rows is! List) return models;
      final loaded = <LLMModelOption>[];
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          final id = (row['id'] ?? '').toString();
          final label = (row['label'] ?? id).toString();
          if (id.isNotEmpty) {
            loaded.add(LLMModelOption(id: id, label: label));
          }
          continue;
        }
        final id = row.toString();
        if (id.isNotEmpty) {
          loaded.add(LLMModelOption(id: id, label: id));
        }
      }
      return loaded.isEmpty ? models : loaded;
    } catch (_) {
      return models;
    }
  }

  @override
  Future<String> sendMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  }) async {
    final baseUrl = dotenv.env['LLM_PROXY_URL'];
    final provider = dotenv.env['LLM_PROXY_PROVIDER'] ?? 'openai';
    if (baseUrl == null || baseUrl.isEmpty) {
      return "Configura LLM_PROXY_URL nel file .env per usare il proxy backend.";
    }

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "provider": provider,
          "model": modelId,
          "messages": messages
              .map((m) => {"role": m.role, "content": m.content})
              .toList(),
          "config": {
            "systemPrompt": config.systemPrompt,
            "temperature": config.temperature,
            "maxTokens": config.maxTokens,
            "topP": config.topP,
          },
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 400) {
        return "Errore Proxy: ${data['error'] ?? response.statusCode}";
      }

      final reply =
          data['reply'] ??
          data['message']?['content'] ??
          data['choices']?[0]?['message']?['content'];
      if (reply is String && reply.trim().isNotEmpty) {
        return reply.trim();
      }
      return "Errore Proxy: risposta vuota.";
    } catch (e) {
      return "Errore Proxy: $e";
    }
  }

  @override
  Stream<String> streamMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  }) async* {
    final reply = await sendMessage(
      modelId: modelId,
      messages: messages,
      config: config,
    );
    yield reply;
  }

  @override
  Future<String?> generateTitle({
    required String modelId,
    required String firstMessage,
  }) async {
    final title = await sendMessage(
      modelId: modelId,
      messages: [
        Message(
          chatId: "title",
          role: "user",
          content:
              "Genera un titolo molto breve (max 4 parole) per questo contenuto: $firstMessage",
          createdAt: DateTime.now(),
        ),
      ],
      config: const LLMRequestConfig(
        systemPrompt: "Genera solo titoli brevi, senza punteggiatura finale.",
        temperature: 0.2,
        maxTokens: 20,
        topP: 1.0,
      ),
    );

    if (title.startsWith("Errore")) return null;
    return title;
  }
}
