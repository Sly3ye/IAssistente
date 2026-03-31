import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
  String? get currentEmail => _auth.currentUser?.email;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
  String get currentDisplayName => _auth.currentUser?.displayName ?? '';
  String get currentPhotoUrl => _auth.currentUser?.photoURL ?? '';
  List<String> get currentProviderIds =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
      const [];

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw StateError("Accesso Google annullato.");
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    final oauthCredential = OAuthProvider(
      "apple.com",
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);
    return _auth.signInWithCredential(oauthCredential);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendCurrentEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utente non autenticato.');
    }
    await user.sendEmailVerification();
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> updateProfile({
    required String displayName,
    required String photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utente non autenticato.');
    }

    await user.updateDisplayName(
      displayName.trim().isEmpty ? null : displayName.trim(),
    );
    await user.updatePhotoURL(photoUrl.trim().isEmpty ? null : photoUrl.trim());
    await user.reload();
  }

  Future<void> deleteCurrentUser({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utente non autenticato.');
    }

    final providers = currentProviderIds.toSet();
    final email = user.email;
    final trimmedPassword = password?.trim() ?? '';

    if (providers.contains('password') &&
        email != null &&
        trimmedPassword.isNotEmpty) {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: trimmedPassword,
      );
      await user.reauthenticateWithCredential(credential);
    }

    await user.delete();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
