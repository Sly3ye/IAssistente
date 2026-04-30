import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import 'llm_provider.dart';
import 'provider_runtime_guard.dart';

class AnthropicProvider implements LLMProvider {
  static const String _baseUrl = "https://api.anthropic.com/v1/messages";

  @override
  String get id => "anthropic";

  @override
  String get label => "Claude";

  @override
  bool get supportsStreaming => true;

  @override
  List<LLMModelOption> get models => const [
    LLMModelOption(
      id: "claude-3-5-sonnet-20240620",
      label: "Claude 3.5 Sonnet",
    ),
    LLMModelOption(id: "claude-3-5-haiku-20241022", label: "Claude 3.5 Haiku"),
    LLMModelOption(id: "claude-3-opus-20240229", label: "Claude 3 Opus"),
  ];

  @override
  Future<List<LLMModelOption>> loadModels() async {
    return models;
  }

  Map<String, String> _headers(String apiKey) => {
    "Content-Type": "application/json",
    "x-api-key": apiKey,
    "anthropic-version": "2023-06-01",
  };

  List<Map<String, String>> _mapMessages(List<Message> messages) {
    return messages
        .map(
          (m) => {
            "role": m.role == "assistant" ? "assistant" : "user",
            "content": m.content,
          },
        )
        .toList();
  }

  @override
  Future<String> sendMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  }) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return "Nessuna API key trovata. Aggiungila nel file .env.";
    }
    if (isClientSideProviderBlockedInProduction()) {
      return blockedClientProviderMessage(label);
    }

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers(apiKey),
            body: jsonEncode({
              "model": modelId,
              "system": _systemPrompt(config),
              "max_tokens": config.maxTokens,
              "temperature": config.temperature,
              "top_p": config.topP,
              "messages": _mapMessages(messages),
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = jsonDecode(response.body);
      if (response.statusCode == 429) {
        final retryAfter = response.headers['retry-after'];
        final wait = retryAfter != null ? ' (riprova tra ${retryAfter}s)' : '';
        return "Limite richieste raggiunto$wait. Aspetta un momento e riprova.";
      }
      if (response.statusCode != 200) {
        return "Errore Anthropic: ${data['error']?['message'] ?? response.statusCode}";
      }

      final content = data["content"];
      if (content is List) {
        final buffer = StringBuffer();
        for (final part in content) {
          if (part is Map && part["type"] == "text") {
            buffer.write(part["text"] ?? "");
          }
        }
        final text = buffer.toString().trim();
        return text.isEmpty ? "Errore: risposta vuota da Claude." : text;
      }
      return "Errore: risposta vuota da Claude.";
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
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      yield "Nessuna API key trovata. Aggiungila nel file .env.";
      return;
    }
    if (isClientSideProviderBlockedInProduction()) {
      yield blockedClientProviderMessage(label);
      return;
    }

    final request = http.Request("POST", Uri.parse(_baseUrl))
      ..headers.addAll(_headers(apiKey))
      ..body = jsonEncode({
        "model": modelId,
        "system": _systemPrompt(config),
        "max_tokens": config.maxTokens,
        "temperature": config.temperature,
        "top_p": config.topP,
        "stream": true,
        "messages": _mapMessages(messages),
      });

    http.Client? client;
    String? eventType;
    try {
      client = http.Client();
      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (streamed.statusCode == 429) {
        final retryAfter = streamed.headers['retry-after'];
        final wait = retryAfter != null ? ' (riprova tra ${retryAfter}s)' : '';
        yield "Limite richieste raggiunto$wait. Aspetta un momento e riprova.";
        return;
      }
      if (streamed.statusCode >= 400) {
        final errorBody = await streamed.stream.bytesToString();
        try {
          final data = jsonDecode(errorBody);
          yield "Errore Anthropic: ${data['error']?['message'] ?? streamed.statusCode}";
        } catch (_) {
          yield "Errore Anthropic: ${errorBody.isEmpty ? streamed.statusCode : errorBody}";
        }
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
          if (trimmed.startsWith("event:")) {
            eventType = trimmed.substring(6).trim();
            continue;
          }
          if (!trimmed.startsWith("data:")) continue;
          final dataLine = trimmed.substring(5).trim();
          if (dataLine == "[DONE]") return;
          final jsonData = jsonDecode(dataLine);
          final type = eventType ?? jsonData["type"];
          if (type == "content_block_delta") {
            final delta = jsonData["delta"];
            final textDelta = delta is Map ? delta["text"] : null;
            if (textDelta is String && textDelta.isNotEmpty) {
              yield textDelta;
            }
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
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;
    if (isClientSideProviderBlockedInProduction()) return null;

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers(apiKey),
            body: jsonEncode({
              "model": modelId,
              "system":
                  "Genera un titolo molto breve (max 4 parole) per questo contenuto.",
              "max_tokens": 20,
              "messages": [
                {"role": "user", "content": firstMessage},
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      final content = data["content"];
      if (content is List) {
        for (final part in content) {
          if (part is Map && part["type"] == "text") {
            final text = (part["text"] ?? "").toString().trim();
            if (text.isNotEmpty) return text;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _systemPrompt(LLMRequestConfig config) {
    final prompt = config.systemPrompt.trim();
    if (prompt.isEmpty) return LLMRequestConfig.defaults.systemPrompt;
    return prompt;
  }
}
