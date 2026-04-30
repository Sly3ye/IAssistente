import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import 'llm_provider.dart';

class OllamaProvider implements LLMProvider {
  OllamaProvider({String? baseUrl})
    : _baseUrl = _resolveBaseUrl(baseUrl: baseUrl);

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
      final response = await http
          .get(Uri.parse(tagsUrl))
          .timeout(const Duration(seconds: 10));
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

  static String _resolveBaseUrl({String? baseUrl}) {
    final explicit = (baseUrl ?? '').trim();
    if (explicit.isNotEmpty) return explicit;

    final envValue = (dotenv.env['OLLAMA_BASE_URL'] ?? '').trim();
    if (envValue.isNotEmpty) return envValue;

    return _defaultBaseUrl();
  }

  @override
  Future<String> sendMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  }) async {
    try {
      final response = await http
          .post(
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
                ...messages.map(
                    (m) => {"role": m.role, "content": m.content}),
              ],
              "stream": false,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode >= 400) {
        return _errorMessage(response.statusCode);
      }

      final data = jsonDecode(response.body);
      return data["message"]?["content"] ?? "Errore: risposta vuota da Ollama.";
    } catch (_) {
      return _connectionErrorMessage();
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
      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (streamed.statusCode >= 400) {
        yield _errorMessage(streamed.statusCode);
        return;
      }
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
    } catch (_) {
      yield _connectionErrorMessage();
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
      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 15));

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

  String _errorMessage(int statusCode) {
    return 'Errore Ollama ($statusCode). Controlla che il server locale sia attivo e che OLLAMA_BASE_URL punti all\'host corretto.';
  }

  String _connectionErrorMessage() {
    return 'Errore Ollama: server non raggiungibile. Su emulatore Android usa 10.0.2.2; su telefono fisico imposta OLLAMA_BASE_URL con l\'IP locale del PC, ad esempio http://192.168.1.10:11434/api/chat.';
  }
}
