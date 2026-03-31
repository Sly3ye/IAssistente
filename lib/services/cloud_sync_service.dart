import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudSyncService {
  CloudSyncService(this._firestore, this._auth);

  static const int _maxPayloadBytes = 900000;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _docRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('app_sync')
        .doc('main');
  }

  Future<bool> canSync() async {
    return _auth.currentUser != null;
  }

  Future<void> pushPayload(Map<String, dynamic> payload) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utente non autenticato.');
    }

    final payloadJson = jsonEncode(payload);
    final bytes = utf8.encode(payloadJson);
    if (bytes.length > _maxPayloadBytes) {
      throw StateError(
        'Backup cloud troppo grande (${bytes.length} byte). Riduci i dati locali prima del sync.',
      );
    }

    final checksum = sha256.convert(bytes).toString();
    await _docRef(user.uid).set({
      'payloadJson': payloadJson,
      'payloadChecksum': checksum,
      'payloadSizeBytes': bytes.length,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': 2,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> pullPayload() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utente non autenticato.');
    }

    final snapshot = await _docRef(user.uid).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    final payloadJson = data?['payloadJson'];
    if (payloadJson is! String || payloadJson.trim().isEmpty) {
      return null;
    }
    final payloadSizeBytes = data?['payloadSizeBytes'];
    if (payloadSizeBytes is int && payloadSizeBytes > _maxPayloadBytes) {
      throw StateError('Backup cloud non valido: payload oltre il limite.');
    }

    final checksum = data?['payloadChecksum'];
    final bytes = utf8.encode(payloadJson);
    if (checksum is String && checksum.isNotEmpty) {
      final currentChecksum = sha256.convert(bytes).toString();
      if (currentChecksum != checksum) {
        throw StateError('Backup cloud corrotto: checksum non valido.');
      }
    }

    final decoded = jsonDecode(payloadJson);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  }

  Future<void> deletePayload() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utente non autenticato.');
    }

    await _docRef(user.uid).delete();
  }
}
