import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import 'llm_provider.dart';

class GeminiProvider implements LLMProvider {
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/";

  @override
  String get id => "gemini";

  @override
  String get label => "Gemini";

  @override
  bool get supportsStreaming => true;

  @override
  List<LLMModelOption> get models => const [
    LLMModelOption(id: "gemini-1.5-flash", label: "Gemini 1.5 Flash"),
    LLMModelOption(id: "gemini-1.5-pro", label: "Gemini 1.5 Pro"),
  ];

  @override
  Future<List<LLMModelOption>> loadModels() async {
    return models;
  }

  List<Map<String, Object>> _mapMessages(List<Message> messages) {
    return messages
        .map(
          (m) => {
            "role": m.role == "assistant" ? "model" : "user",
            "parts": [
              {"text": m.content},
            ],
          },
        )
        .toList();
  }

  Map<String, Object> _requestBody(
    List<Message> messages,
    LLMRequestConfig config,
  ) {
    return {
      "systemInstruction": {
        "parts": [
          {"text": _systemPrompt(config)},
        ],
      },
      "contents": _mapMessages(messages),
      "generationConfig": {
        "temperature": config.temperature,
        "maxOutputTokens": config.maxTokens,
        "topP": config.topP,
      },
    };
  }

  Map<String, String> _headers(String apiKey) => {
    "Content-Type": "application/json",
    "x-goog-api-key": apiKey,
  };

  @override
  Future<String> sendMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return "Nessuna API key trovata. Aggiungila nel file .env.";
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl$modelId:generateContent"),
        headers: _headers(apiKey),
        body: jsonEncode(_requestBody(messages, config)),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        return "Errore Gemini: ${data['error']?['message'] ?? response.statusCode}";
      }
      final candidates = data["candidates"];
      if (candidates is List && candidates.isNotEmpty) {
        final parts = candidates[0]?["content"]?["parts"];
        if (parts is List) {
          final buffer = StringBuffer();
          for (final part in parts) {
            if (part is Map && part["text"] is String) {
              buffer.write(part["text"]);
            }
          }
          final text = buffer.toString().trim();
          return text.isEmpty ? "Errore: risposta vuota da Gemini." : text;
        }
      }
      return "Errore: risposta vuota da Gemini.";
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
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      yield "Nessuna API key trovata. Aggiungila nel file .env.";
      return;
    }

    final request =
        http.Request(
            "POST",
            Uri.parse("$_baseUrl$modelId:streamGenerateContent?alt=sse"),
          )
          ..headers.addAll(_headers(apiKey))
          ..body = jsonEncode(_requestBody(messages, config));

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
          final dataLine = trimmed.substring(5).trim();
          if (dataLine == "[DONE]") return;
          final jsonData = jsonDecode(dataLine);
          final candidates = jsonData["candidates"];
          if (candidates is List && candidates.isNotEmpty) {
            final parts = candidates[0]?["content"]?["parts"];
            if (parts is List) {
              for (final part in parts) {
                final textPart = part is Map ? part["text"] : null;
                if (textPart is String && textPart.isNotEmpty) {
                  yield textPart;
                }
              }
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
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl$modelId:generateContent"),
        headers: _headers(apiKey),
        body: jsonEncode({
          "systemInstruction": {
            "parts": [
              {
                "text":
                    "Genera un titolo molto breve (max 4 parole) per questo contenuto.",
              },
            ],
          },
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": firstMessage},
              ],
            },
          ],
          "generationConfig": {"maxOutputTokens": 20},
        }),
      );
      final data = jsonDecode(response.body);
      final candidates = data["candidates"];
      if (candidates is List && candidates.isNotEmpty) {
        final parts = candidates[0]?["content"]?["parts"];
        if (parts is List && parts.isNotEmpty) {
          final text = (parts[0]?["text"] ?? "").toString().trim();
          return text.isEmpty ? null : text;
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
