import 'dart:math';

import '../models/rag_document.dart';

class RagRetrievalResult {
  const RagRetrievalResult({
    required this.context,
    required this.matchedChunks,
    required this.sourceNames,
  });

  final String context;
  final List<RagChunk> matchedChunks;
  final List<String> sourceNames;
}

class LocalRagService {
  List<RagDocument> indexDocuments({
    required List<RagDocument> existing,
    required String documentName,
    required String text,
  }) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return existing;

    final documentId = DateTime.now().microsecondsSinceEpoch.toString();
    final chunks = _chunkText(cleaned, documentId);
    if (chunks.isEmpty) return existing;

    final next = [
      ...existing,
      RagDocument(
        id: documentId,
        name: documentName,
        createdAt: DateTime.now(),
        chunks: chunks,
      ),
    ];

    // Keep index bounded for mobile memory.
    if (next.length > 50) {
      next.removeAt(0);
    }

    return next;
  }

  RagRetrievalResult retrieve({
    required String query,
    required List<RagDocument> documents,
    int maxChunks = 4,
  }) {
    final cleanedQuery = query.trim();
    if (cleanedQuery.isEmpty || documents.isEmpty) {
      return const RagRetrievalResult(
        context: '',
        matchedChunks: [],
        sourceNames: [],
      );
    }

    final queryTokens = _tokenize(cleanedQuery);
    if (queryTokens.isEmpty) {
      return const RagRetrievalResult(
        context: '',
        matchedChunks: [],
        sourceNames: [],
      );
    }

    final scored = <_ScoredChunk>[];
    for (final doc in documents) {
      for (final chunk in doc.chunks) {
        final score = _scoreChunk(chunk.content, queryTokens);
        if (score > 0) {
          scored.add(
            _ScoredChunk(chunk: chunk, score: score, docName: doc.name),
          );
        }
      }
    }

    if (scored.isEmpty) {
      return const RagRetrievalResult(
        context: '',
        matchedChunks: [],
        sourceNames: [],
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final selected = scored.take(max(1, maxChunks)).toList();

    final buffer = StringBuffer();
    for (final item in selected) {
      buffer.writeln('Fonte: ${item.docName}');
      buffer.writeln(item.chunk.content);
      buffer.writeln();
    }

    return RagRetrievalResult(
      context: buffer.toString().trim(),
      matchedChunks: selected.map((e) => e.chunk).toList(growable: false),
      sourceNames: selected
          .map((e) => e.docName)
          .toSet()
          .toList(growable: false),
    );
  }

  List<RagChunk> _chunkText(String text, String documentId) {
    const maxChunkChars = 900;
    const minChunkChars = 80;

    final normalized = text.replaceAll('\r\n', '\n');
    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final chunks = <RagChunk>[];
    var index = 0;

    for (final paragraph in paragraphs) {
      if (paragraph.length <= maxChunkChars) {
        if (paragraph.length >= minChunkChars) {
          chunks.add(
            RagChunk(
              id: '$documentId-$index',
              documentId: documentId,
              content: paragraph,
            ),
          );
          index++;
        }
        continue;
      }

      var start = 0;
      while (start < paragraph.length) {
        final end = min(start + maxChunkChars, paragraph.length);
        final piece = paragraph.substring(start, end).trim();
        if (piece.length >= minChunkChars) {
          chunks.add(
            RagChunk(
              id: '$documentId-$index',
              documentId: documentId,
              content: piece,
            ),
          );
          index++;
        }
        if (end == paragraph.length) break;
        start = end - 120; // overlap for context continuity
        if (start < 0) start = 0;
      }
    }

    return chunks;
  }

  int _scoreChunk(String chunk, Set<String> queryTokens) {
    final chunkTokens = _tokenize(chunk);
    if (chunkTokens.isEmpty) return 0;

    var score = 0;
    for (final token in queryTokens) {
      if (chunkTokens.contains(token)) {
        score += 10;
      }
    }

    final queryJoined = queryTokens.join(' ');
    if (queryJoined.isNotEmpty && chunk.toLowerCase().contains(queryJoined)) {
      score += 15;
    }

    return score;
  }

  Set<String> _tokenize(String text) {
    final lower = text.toLowerCase();
    final tokens = lower
        .split(RegExp(r'[^a-z0-9àèéìòù]+'))
        .where((t) => t.length >= 3)
        .toSet();

    const stopWords = {
      'che',
      'con',
      'per',
      'una',
      'del',
      'della',
      'sono',
      'this',
      'that',
      'from',
      'into',
    };

    tokens.removeWhere(stopWords.contains);
    return tokens;
  }
}

class _ScoredChunk {
  const _ScoredChunk({
    required this.chunk,
    required this.score,
    required this.docName,
  });

  final RagChunk chunk;
  final int score;
  final String docName;
}
