import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/chat_controller.dart';
import '../db/app_database.dart';
import '../repositories/chat_repository.dart';
import '../services/attachment_extraction_service.dart';
import '../services/app_config_diagnostics.dart';
import '../services/app_runtime_config.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/llm_provider.dart';
import '../services/local_rag_service.dart';
import '../services/monetization_service.dart';
import '../services/observability_service.dart';
import '../services/anthropic_provider.dart';
import '../services/gemini_provider.dart';
import '../services/groq_provider.dart';
import '../services/openai_provider.dart';
import '../services/proxy_provider.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(appDatabaseProvider));
});

final llmRegistryProvider = Provider<LLMRegistry>((ref) {
  return LLMRegistry([
    GroqProvider(),
    ProxyProvider(),
    OpenAIProvider(),
    AnthropicProvider(),
    GeminiProvider(),
  ]);
});

final appConfigDiagnosticsProvider = Provider<AppConfigDiagnostics>((ref) {
  return const AppConfigDiagnostics.empty();
});

final appRuntimeConfigProvider = Provider<AppRuntimeConfig>((ref) {
  return const AppRuntimeConfig.defaults();
});

final observabilityServiceProvider = Provider<ObservabilityService>((ref) {
  return ObservabilityService.noop();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final attachmentExtractionServiceProvider =
    Provider<AttachmentExtractionService>((ref) {
      return AttachmentExtractionService();
    });

final localRagServiceProvider = Provider<LocalRagService>((ref) {
  return LocalRagService();
});

final monetizationServiceProvider = ChangeNotifierProvider<MonetizationService>(
  (ref) {
    final service = MonetizationService();
    ref.onDispose(service.dispose);
    return service;
  },
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) {
    return ChatController(
      ref.watch(chatRepositoryProvider),
      ref.watch(llmRegistryProvider),
      ref.watch(authServiceProvider),
      ref.watch(cloudSyncServiceProvider),
      ref.watch(localRagServiceProvider),
      ref.watch(appRuntimeConfigProvider),
      ref.watch(observabilityServiceProvider),
    );
  },
);
