import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/message.dart';
import 'llm_provider.dart';
import 'provider_runtime_guard.dart';

class GroqProvider implements LLMProvider {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _modelsUrl = 'https://api.groq.com/openai/v1/models';

  @override
  String get id => 'groq';

  @override
  String get label => 'Groq';

  @override
  bool get supportsStreaming => false;

  @override
  List<LLMModelOption> get models => const [
    LLMModelOption(
      id: 'llama-3.1-8b-instant',
      label: 'Llama 3.1 8B Instant',
    ),
    LLMModelOption(
      id: 'llama-3.3-70b-versatile',
      label: 'Llama 3.3 70B Versatile',
    ),
    LLMModelOption(
      id: 'qwen/qwen3-32b',
      label: 'Qwen3 32B',
    ),
    LLMModelOption(
      id: 'openai/gpt-oss-120b',
      label: 'GPT-OSS 120B',
    ),
  ];

  @override
  Future<List<LLMModelOption>> loadModels() async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return models;
    if (isClientSideProviderBlockedInProduction()) return models;

    try {
      final response = await http.get(
        Uri.parse(_modelsUrl),
        headers: {'Authorization': 'Bearer $apiKey'},
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
        if (id.isEmpty) continue;
        if (id.contains('llama') ||
            id.contains('qwen') ||
            id.contains('gpt-oss')) {
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
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Nessuna API key Groq trovata. Aggiungila nel file .env.';
    }
    if (isClientSideProviderBlockedInProduction()) {
      return blockedClientProviderMessage(label);
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': modelId,
          'temperature': config.temperature,
          'top_p': config.topP,
          'max_tokens': config.maxTokens,
          'messages': [
            {'role': 'system', 'content': _systemPrompt(config)},
            ...messages.map((m) => {'role': m.role, 'content': m.content}),
          ],
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        return 'Errore Groq: ${data['error']?['message'] ?? response.statusCode}';
      }

      return data['choices']?[0]?['message']?['content'] ??
          'Errore: risposta vuota da Groq.';
    } catch (e) {
      return 'Errore di rete: $e';
    }
  }

  @override
  Stream<String> streamMessage({
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
  }) async* {
    yield await sendMessage(
      modelId: modelId,
      messages: messages,
      config: config,
    );
  }

  @override
  Future<String?> generateTitle({
    required String modelId,
    required String firstMessage,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;
    if (isClientSideProviderBlockedInProduction()) return null;

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': modelId,
          'messages': [
            {
              'role': 'system',
              'content':
                  'Genera solo un titolo naturale di 3-5 parole per una chat. Usa il tema concreto emerso nella prima risposta, non riformulare la richiesta generica dell’utente. Evita titoli vaghi come "dimmi qualcosa interessante". Niente virgolette, niente emoji, niente punteggiatura finale.',
            },
            {'role': 'user', 'content': firstMessage},
          ],
          'max_tokens': 20,
        }),
      );

      final data = jsonDecode(response.body);
      return data['choices']?[0]?['message']?['content']?.trim();
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
