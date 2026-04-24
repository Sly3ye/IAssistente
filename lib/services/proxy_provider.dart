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
  bool get supportsStreaming => true;

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
      final response = await http.get(
        Uri.parse(modelsUrl),
        headers: _requestHeaders(),
      );
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
        headers: _requestHeaders(),
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
    final baseUrl = dotenv.env['LLM_PROXY_URL'];
    final provider = dotenv.env['LLM_PROXY_PROVIDER'] ?? 'openai';
    if (baseUrl == null || baseUrl.isEmpty) {
      yield "Configura LLM_PROXY_URL nel file .env per usare il proxy backend.";
      return;
    }

    final request = http.Request("POST", Uri.parse(baseUrl))
      ..headers.addAll({
        ..._requestHeaders(),
        "Accept": "text/event-stream",
      })
      ..body = jsonEncode({
        "provider": provider,
        "model": modelId,
        "stream": true,
        "messages": messages
            .map((m) => {"role": m.role, "content": m.content})
            .toList(),
        "config": {
          "systemPrompt": config.systemPrompt,
          "temperature": config.temperature,
          "maxTokens": config.maxTokens,
          "topP": config.topP,
        },
      });

    http.Client? client;
    try {
      client = http.Client();
      final streamed = await client.send(request);
      if (streamed.statusCode >= 400) {
        final errorBody = await streamed.stream.bytesToString();
        try {
          final data = jsonDecode(errorBody);
          yield "Errore Proxy: ${data['error'] ?? streamed.statusCode}";
        } catch (_) {
          yield "Errore Proxy: ${errorBody.isEmpty ? streamed.statusCode : errorBody}";
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
          if (!trimmed.startsWith("data:")) continue;
          final dataLine = trimmed.substring(5).trim();
          if (dataLine == "[DONE]") return;
          final jsonData = jsonDecode(dataLine);
          final error = jsonData["error"];
          if (error is String && error.isNotEmpty) {
            yield "Errore Proxy: $error";
            return;
          }
          final delta = jsonData["delta"];
          if (delta is String && delta.isNotEmpty) {
            yield delta;
          }
        }
      }
    } catch (e) {
      yield "Errore Proxy: $e";
    } finally {
      client?.close();
    }
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
              "Genera solo un titolo naturale di 3-5 parole per una chat. Usa il tema concreto emerso nella prima risposta, non riformulare la richiesta generica dell’utente. Evita titoli vaghi come dimmi qualcosa interessante. Niente virgolette, niente emoji, niente punteggiatura finale. Contenuto: $firstMessage",
          createdAt: DateTime.now(),
        ),
      ],
      config: const LLMRequestConfig(
        systemPrompt:
            "Genera solo titoli brevi e concreti, senza punteggiatura finale.",
        temperature: 0.2,
        maxTokens: 20,
        topP: 1.0,
      ),
    );

    if (title.startsWith("Errore")) return null;
    return title;
  }

  Map<String, String> _requestHeaders() {
    final token = (dotenv.env['LLM_PROXY_AUTH_TOKEN'] ?? '').trim();
    return {
      "Content-Type": "application/json",
      if (token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }
}
