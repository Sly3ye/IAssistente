import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart' as db;
import '../models/chat.dart' as chat_model;
import '../models/message.dart' as message_model;

class ChatRepository {
  ChatRepository(this._db);

  final db.AppDatabase _db;

  Future<List<chat_model.Chat>> loadChats() async {
    final rows = await (_db.select(
      _db.chats,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    return rows.map(_mapChat).toList();
  }

  Future<List<message_model.Message>> loadMessages(String chatId) async {
    final rows =
        await (_db.select(_db.messages)
              ..where((t) => t.chatId.equals(chatId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows
        .map(
          (row) => message_model.Message(
            id: row.id,
            chatId: row.chatId,
            role: row.role,
            content: row.content,
            createdAt: row.createdAt,
            isError: row.isError,
          ),
        )
        .toList();
  }

  Future<chat_model.Chat> createChat({
    required String title,
    required String providerId,
    required String modelId,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    required double topP,
  }) async {
    final now = DateTime.now();
    final id = now.toIso8601String();
    await _db
        .into(_db.chats)
        .insert(
          db.ChatsCompanion.insert(
            id: id,
            title: title,
            createdAt: now,
            updatedAt: now,
            providerId: providerId,
            modelId: modelId,
            systemPrompt: Value(systemPrompt),
            temperature: Value(temperature),
            maxTokens: Value(maxTokens),
            topP: Value(topP),
          ),
        );
    return chat_model.Chat(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      providerId: providerId,
      modelId: modelId,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
    );
  }

  Future<void> updateChatTitle(String chatId, String title) async {
    await (_db.update(_db.chats)..where((t) => t.id.equals(chatId))).write(
      db.ChatsCompanion(title: Value(title), updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> updateChatModel({
    required String chatId,
    required String providerId,
    required String modelId,
  }) async {
    await (_db.update(_db.chats)..where((t) => t.id.equals(chatId))).write(
      db.ChatsCompanion(
        providerId: Value(providerId),
        modelId: Value(modelId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateChatSettings({
    required String chatId,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    required double topP,
  }) async {
    await (_db.update(_db.chats)..where((t) => t.id.equals(chatId))).write(
      db.ChatsCompanion(
        systemPrompt: Value(systemPrompt),
        temperature: Value(temperature),
        maxTokens: Value(maxTokens),
        topP: Value(topP),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> touchChat(String chatId) async {
    await (_db.update(_db.chats)..where((t) => t.id.equals(chatId))).write(
      db.ChatsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> deleteChat(String chatId) async {
    await (_db.delete(
      _db.messages,
    )..where((t) => t.chatId.equals(chatId))).go();
    await (_db.delete(_db.chats)..where((t) => t.id.equals(chatId))).go();
  }

  Future<void> deleteMessageById(int id) async {
    await (_db.delete(_db.messages)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateMessageContent(int id, String content) async {
    await (_db.update(_db.messages)..where((t) => t.id.equals(id))).write(
      db.MessagesCompanion(content: Value(content)),
    );
  }

  Future<void> deleteMessagesAfter({
    required String chatId,
    required DateTime createdAt,
  }) async {
    await (_db.delete(_db.messages)..where(
          (t) =>
              t.chatId.equals(chatId) &
              t.createdAt.isBiggerThanValue(createdAt),
        ))
        .go();
  }

  Future<message_model.Message?> getLastUserMessage(String chatId) async {
    final rows =
        await (_db.select(_db.messages)
              ..where((t) => t.chatId.equals(chatId) & t.role.equals("user"))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .get();
    if (rows.isEmpty) return null;
    final row = rows.first;
    return message_model.Message(
      id: row.id,
      chatId: row.chatId,
      role: row.role,
      content: row.content,
      createdAt: row.createdAt,
      isError: row.isError,
    );
  }

  Future<int> addMessage({
    required String chatId,
    required String role,
    required String content,
    bool isError = false,
  }) async {
    final id = await _db
        .into(_db.messages)
        .insert(
          db.MessagesCompanion.insert(
            chatId: chatId,
            role: role,
            content: content,
            createdAt: DateTime.now(),
            isError: Value(isError),
          ),
        );
    await touchChat(chatId);
    return id;
  }

  Future<void> setAppState(String key, String value) async {
    await _db
        .into(_db.appState)
        .insertOnConflictUpdate(
          db.AppStateCompanion.insert(key: key, value: value),
        );
  }

  Future<String?> getAppState(String key) async {
    final row = await (_db.select(
      _db.appState,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<Map<String, dynamic>> exportAppPayload({
    bool includeAppState = false,
  }) async {
    final chats = await loadChats();
    final messages = await (_db.select(
      _db.messages,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    final appStateRows = includeAppState
        ? await (_db.select(_db.appState)).get()
        : const [];

    return {
      "version": 1,
      "exportedAt": DateTime.now().toIso8601String(),
      "chats": chats
          .map(
            (chat) => {
              "id": chat.id,
              "title": chat.title,
              "createdAt": chat.createdAt.toIso8601String(),
              "updatedAt": chat.updatedAt.toIso8601String(),
              "providerId": chat.providerId,
              "modelId": chat.modelId,
              "systemPrompt": chat.systemPrompt,
              "temperature": chat.temperature,
              "maxTokens": chat.maxTokens,
              "topP": chat.topP,
            },
          )
          .toList(),
      "messages": messages
          .map(
            (m) => {
              "chatId": m.chatId,
              "role": m.role,
              "content": m.content,
              "createdAt": m.createdAt.toIso8601String(),
              "isError": m.isError,
            },
          )
          .toList(),
      if (includeAppState)
        "appState": appStateRows
            .map((row) => {"key": row.key, "value": row.value})
            .toList(),
    };
  }

  Future<String> exportPayloadToJsonFile({
    required String prefix,
    required Map<String, dynamic> payload,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeTimestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(
      '${dir.path}/${_safeFilePart(prefix)}_$safeTimestamp.json',
    );
    final formatted = const JsonEncoder.withIndent('  ').convert(payload);
    await file.writeAsString(formatted);
    return file.path;
  }

  Future<String> exportChatsToJsonFile() async {
    final payload = await exportAppPayload();
    return exportPayloadToJsonFile(
      prefix: 'iassistente_backup',
      payload: payload,
    );
  }

  Future<String> exportUserDataToJsonFile({
    required Map<String, dynamic> accountPayload,
  }) async {
    final payload = await exportAppPayload(includeAppState: true);
    payload['account'] = accountPayload;

    return exportPayloadToJsonFile(
      prefix: 'iassistente_userdata',
      payload: payload,
    );
  }

  Future<String?> latestBackupPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final entities = await dir.list().toList();
    final backups = entities
        .whereType<File>()
        .where(
          (f) =>
              f.path.contains('iassistente_backup_') &&
              f.path.endsWith('.json'),
        )
        .toList();

    if (backups.isEmpty) return null;

    backups.sort((a, b) {
      final aTime = a.statSync().modified;
      final bTime = b.statSync().modified;
      return bTime.compareTo(aTime);
    });

    return backups.first.path;
  }

  Future<void> importChatsFromJsonFile({
    required String path,
    bool replaceLocalData = true,
  }) async {
    final raw = await File(path).readAsString();
    final parsed = jsonDecode(raw);

    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Backup non valido.');
    }

    await importAppPayload(
      payload: parsed,
      replaceLocalData: replaceLocalData,
      replaceAppState: false,
    );
  }

  Future<void> importAppPayload({
    required Map<String, dynamic> payload,
    bool replaceLocalData = true,
    bool replaceAppState = false,
  }) async {
    final chatsRaw = payload['chats'];
    final messagesRaw = payload['messages'];
    final appStateRaw = payload['appState'];

    if (chatsRaw is! List || messagesRaw is! List) {
      throw const FormatException('Backup incompleto.');
    }

    await _db.transaction(() async {
      if (replaceLocalData) {
        await _db.delete(_db.messages).go();
        await _db.delete(_db.chats).go();
      }
      if (replaceAppState) {
        await _db.delete(_db.appState).go();
      }

      for (final rawChat in chatsRaw) {
        if (rawChat is! Map<String, dynamic>) continue;
        final id = (rawChat['id'] ?? '').toString();
        if (id.isEmpty) continue;

        await _db
            .into(_db.chats)
            .insertOnConflictUpdate(
              db.ChatsCompanion.insert(
                id: id,
                title: (rawChat['title'] ?? 'Chat importata').toString(),
                createdAt: _parseDate(rawChat['createdAt']) ?? DateTime.now(),
                updatedAt: _parseDate(rawChat['updatedAt']) ?? DateTime.now(),
                providerId: (rawChat['providerId'] ?? 'openai').toString(),
                modelId: (rawChat['modelId'] ?? 'gpt-4o-mini').toString(),
                systemPrompt: Value((rawChat['systemPrompt'] ?? '').toString()),
                temperature: Value(_parseDouble(rawChat['temperature']) ?? 0.7),
                maxTokens: Value(_parseInt(rawChat['maxTokens']) ?? 1024),
                topP: Value(_parseDouble(rawChat['topP']) ?? 1.0),
              ),
            );
      }

      for (final rawMessage in messagesRaw) {
        if (rawMessage is! Map<String, dynamic>) continue;
        final chatId = (rawMessage['chatId'] ?? '').toString();
        if (chatId.isEmpty) continue;

        await _db
            .into(_db.messages)
            .insert(
              db.MessagesCompanion.insert(
                chatId: chatId,
                role: (rawMessage['role'] ?? 'user').toString(),
                content: (rawMessage['content'] ?? '').toString(),
                createdAt:
                    _parseDate(rawMessage['createdAt']) ?? DateTime.now(),
                isError: Value(rawMessage['isError'] == true),
              ),
            );
      }

      if (appStateRaw is List) {
        for (final rawState in appStateRaw) {
          if (rawState is! Map<String, dynamic>) continue;
          final key = (rawState['key'] ?? '').toString();
          if (key.isEmpty) continue;
          await _db
              .into(_db.appState)
              .insertOnConflictUpdate(
                db.AppStateCompanion.insert(
                  key: key,
                  value: (rawState['value'] ?? '').toString(),
                ),
              );
        }
      }
    });
  }

  Future<Set<String>> searchChatIdsByMessage(String query) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return <String>{};

    final rows =
        await (_db.selectOnly(_db.messages)
              ..addColumns([_db.messages.chatId])
              ..where(_db.messages.content.like('%$cleaned%'))
              ..groupBy([_db.messages.chatId]))
            .get();

    return rows
        .map((row) => row.read(_db.messages.chatId))
        .whereType<String>()
        .toSet();
  }

  Future<String?> exportChatToMarkdown(String chatId) async {
    final chatRow = await (_db.select(
      _db.chats,
    )..where((t) => t.id.equals(chatId))).getSingleOrNull();
    if (chatRow == null) return null;

    final messages = await loadMessages(chatId);
    final buffer = StringBuffer()
      ..writeln('# ${chatRow.title}')
      ..writeln()
      ..writeln('- Provider: ${chatRow.providerId}')
      ..writeln('- Modello: ${chatRow.modelId}')
      ..writeln('- Creata: ${chatRow.createdAt.toIso8601String()}')
      ..writeln('- Aggiornata: ${chatRow.updatedAt.toIso8601String()}')
      ..writeln()
      ..writeln('---')
      ..writeln();

    for (final message in messages) {
      final role = message.role == 'user' ? 'Utente' : 'Assistente';
      buffer.writeln('## $role (${message.createdAt.toIso8601String()})');
      buffer.writeln();
      buffer.writeln(message.content);
      buffer.writeln();
    }

    final dir = await getApplicationDocumentsDirectory();
    final safeTitle = _safeFilePart(chatRow.title);
    final safeTimestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/chat_${safeTitle}_$safeTimestamp.md');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<void> clearLocalData({bool clearAppState = false}) async {
    await _db.transaction(() async {
      await _db.delete(_db.messages).go();
      await _db.delete(_db.chats).go();
      if (clearAppState) {
        await _db.delete(_db.appState).go();
      }
    });
  }

  chat_model.Chat _mapChat(db.Chat row) {
    return chat_model.Chat(
      id: row.id,
      title: row.title,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      providerId: row.providerId,
      modelId: row.modelId,
      systemPrompt: row.systemPrompt,
      temperature: row.temperature,
      maxTokens: row.maxTokens,
      topP: row.topP,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _safeFilePart(String value) {
    final cleaned = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    if (cleaned.isEmpty) return 'chat';
    return cleaned;
  }
}
