import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import 'llm_provider.dart';

class OllamaProvider implements LLMProvider {
  OllamaProvider({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl();

  final String _baseUrl;

  @override
  String get id => "ollama";

  @override
  String get label => "Ollama";

  @override
  bool get supportsStreaming => true;

  @override
  List<LLMModelOption> get models => const [
    LLMModelOption(id: "llama3", label: "Llama 3"),
    LLMModelOption(id: "mistral", label: "Mistral"),
    LLMModelOption(id: "phi3", label: "Phi-3"),
    LLMModelOption(id: "qwen2", label: "Qwen2"),
  ];

  @override
  Future<List<LLMModelOption>> loadModels() async {
    try {
      final tagsUrl = _baseUrl.replaceAll('/api/chat', '/api/tags');
      final response = await http.get(Uri.parse(tagsUrl));
      final data = jsonDecode(response.body);
      final rows = data['models'];
      if (rows is! List) return models;
      final resolved = <LLMModelOption>[];
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final name = (row['name'] ?? '').toString();
        if (name.isEmpty) continue;
        resolved.add(LLMModelOption(id: name, label: name));
      }
      if (resolved.isEmpty) return models;
      return resolved;
    } catch (_) {
      return models;
    }
  }

  static String _defaultBaseUrl() {
    if (kIsWeb) return "http://localhost:11434/api/chat";
    if (Platform.isAndroid) return "http://10.0.2.2:11434/api/chat";
    return "http://localhost:11434/api/chat";
  }

  @override
  Future<String> sendMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "model": modelId,
          "options": {
            "temperature": config.temperature,
            "top_p": config.topP,
            "num_predict": config.maxTokens,
          },
          "messages": [
            {"role": "system", "content": _systemPrompt(config)},
            ...messages.map((m) => {"role": m.role, "content": m.content}),
          ],
          "stream": false,
        }),
      );

      final data = jsonDecode(response.body);
      return data["message"]?["content"] ?? "Errore: risposta vuota da Ollama.";
    } catch (e) {
      return "Errore Ollama: $e";
    }
  }

  @override
  Stream<String> streamMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  }) async* {
    http.Client? client;
    try {
      final request = http.Request("POST", Uri.parse(_baseUrl))
        ..headers["Content-Type"] = "application/json"
        ..body = jsonEncode({
          "model": modelId,
          "options": {
            "temperature": config.temperature,
            "top_p": config.topP,
            "num_predict": config.maxTokens,
          },
          "messages": [
            {"role": "system", "content": _systemPrompt(config)},
            ...messages.map((m) => {"role": m.role, "content": m.content}),
          ],
          "stream": true,
        });

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
          if (trimmed.isEmpty) continue;
          final jsonData = jsonDecode(trimmed);
          final delta = jsonData["message"]?["content"];
          if (delta is String && delta.isNotEmpty) {
            yield delta;
          }
          if (jsonData["done"] == true) {
            return;
          }
        }
      }
    } catch (e) {
      yield "Errore Ollama: $e";
    } finally {
      client?.close();
    }
  }

  @override
  Future<String?> generateTitle({
    required String modelId,
    required String firstMessage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
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
          "stream": false,
        }),
      );

      final data = jsonDecode(response.body);
      return data["message"]?["content"]?.trim();
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
