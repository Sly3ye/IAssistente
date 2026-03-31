import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudSyncService {
  CloudSyncService(this._firestore, this._auth);

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
    await _docRef(user.uid).set({
      'payloadJson': payloadJson,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': 1,
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
