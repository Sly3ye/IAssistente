class RagChunk {
  const RagChunk({
    required this.id,
    required this.documentId,
    required this.content,
  });

  final String id;
  final String documentId;
  final String content;

  Map<String, Object> toJson() {
    return {'id': id, 'documentId': documentId, 'content': content};
  }

  factory RagChunk.fromJson(Map<String, dynamic> json) {
    return RagChunk(
      id: (json['id'] ?? '').toString(),
      documentId: (json['documentId'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
    );
  }
}

class RagDocument {
  const RagDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.chunks,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<RagChunk> chunks;

  Map<String, Object> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'chunks': chunks.map((c) => c.toJson()).toList(),
    };
  }

  factory RagDocument.fromJson(Map<String, dynamic> json) {
    final chunkRows = json['chunks'];
    final parsedChunks = <RagChunk>[];
    if (chunkRows is List) {
      for (final row in chunkRows) {
        if (row is Map<String, dynamic>) {
          parsedChunks.add(RagChunk.fromJson(row));
        }
      }
    }

    return RagDocument(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Documento').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      chunks: parsedChunks,
    );
  }
}
