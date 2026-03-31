import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import 'llm_provider.dart';
import 'provider_runtime_guard.dart';

class OpenAIProvider implements LLMProvider {
  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";
  static const String _modelsUrl = "https://api.openai.com/v1/models";

  @override
  String get id => "openai";

  @override
  String get label => "OpenAI";

  @override
  bool get supportsStreaming => true;

  @override
  List<LLMModelOption> get models => const [
    LLMModelOption(id: "gpt-4o-mini", label: "GPT-4o mini"),
    LLMModelOption(id: "gpt-4o", label: "GPT-4o"),
  ];

  @override
  Future<List<LLMModelOption>> loadModels() async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return models;
    if (isClientSideProviderBlockedInProduction()) return models;

    try {
      final response = await http.get(
        Uri.parse(_modelsUrl),
        headers: {"Authorization": "Bearer $apiKey"},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data is! Map<String, dynamic>) {
        return models;
      }

      final rows = data['data'];
      if (rows is! List) return models;

      final allowed = <LLMModelOption>[];
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final id = (row['id'] ?? '').toString();
        if (id.startsWith('gpt-') ||
            id.startsWith('o1') ||
            id.startsWith('o3')) {
          allowed.add(LLMModelOption(id: id, label: id));
        }
      }
      if (allowed.isEmpty) return models;
      allowed.sort((a, b) => a.id.compareTo(b.id));
      return allowed;
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
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return "Nessuna API key trovata. Aggiungila nel file .env.";
    }
    if (isClientSideProviderBlockedInProduction()) {
      return blockedClientProviderMessage(label);
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": modelId,
          "temperature": config.temperature,
          "top_p": config.topP,
          "max_tokens": config.maxTokens,
          "messages": [
            {"role": "system", "content": _systemPrompt(config)},
            ...messages.map((m) => {"role": m.role, "content": m.content}),
          ],
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        return "Errore OpenAI: ${data['error']?['message'] ?? response.statusCode}";
      }

      return data['choices']?[0]?['message']?['content'] ??
          "Errore: risposta vuota da OpenAI.";
    } catch (e) {
      return "Errore di rete: $e";
    }
  }

  @override
  Stream<String> streamMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  }) async* {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      yield "Nessuna API key trovata. Aggiungila nel file .env.";
      return;
    }
    if (isClientSideProviderBlockedInProduction()) {
      yield blockedClientProviderMessage(label);
      return;
    }

    final request = http.Request("POST", Uri.parse(_baseUrl))
      ..headers.addAll({
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      })
      ..body = jsonEncode({
        "model": modelId,
        "stream": true,
        "temperature": config.temperature,
        "top_p": config.topP,
        "max_tokens": config.maxTokens,
        "messages": [
          {"role": "system", "content": _systemPrompt(config)},
          ...messages.map((m) => {"role": m.role, "content": m.content}),
        ],
      });

    http.Client? client;
    try {
      client = http.Client();
      final streamed = await client.send(request);
      final buffer = StringBuffer();
      await for (final chunk in streamed.stream) {
        buffer.write(utf8.decode(chunk));
        final text = buffer.toString();
        final lines = text.split('\n');
        buffer.clear();
        if (!text.endsWith('\n')) {
          buffer.write(lines.removeLast());
        }
        for (final line in lines) {
          final trimmed = line.trim();
          if (!trimmed.startsWith("data:")) continue;
          final data = trimmed.substring(5).trim();
          if (data == "[DONE]") return;
          final jsonData = jsonDecode(data);
          final delta = jsonData["choices"]?[0]?["delta"]?["content"];
          if (delta is String && delta.isNotEmpty) {
            yield delta;
          }
        }
      }
    } catch (e) {
      yield "Errore di rete: $e";
    } finally {
      client?.close();
    }
  }

  @override
  Future<String?> generateTitle({
    required String modelId,
    required String firstMessage,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;
    if (isClientSideProviderBlockedInProduction()) return null;

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": modelId,
          "messages": [
            {
              "role": "system",
              "content":
                  "Genera un titolo molto breve (max 4 parole) per questo contenuto.",
            },
            {"role": "user", "content": firstMessage},
          ],
          "max_tokens": 20,
        }),
      );

      final data = jsonDecode(response.body);
      return data["choices"]?[0]?["message"]?["content"]?.trim();
    } catch (e) {
      return null;
    }
  }

  String _systemPrompt(LLMRequestConfig config) {
    final prompt = config.systemPrompt.trim();
    if (prompt.isEmpty) return LLMRequestConfig.defaults.systemPrompt;
    return prompt;
  }
}
