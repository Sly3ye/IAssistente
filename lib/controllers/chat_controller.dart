import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../models/diet_profile.dart';
import '../models/legal_profile.dart';
import '../models/memory_entry.dart';
import '../models/medical_profile.dart';
import '../models/message.dart';
import '../models/prompt_preset.dart';
import '../models/rag_document.dart';
import '../repositories/chat_repository.dart';
import '../services/app_runtime_config.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/llm_provider.dart';
import '../services/local_rag_service.dart';
import '../services/observability_service.dart';
import '../utils/content_safety.dart';
import '../utils/local_tools.dart';
import '../utils/token_estimator.dart';

class ChatState {
  static const Object _noChange = Object();

  final List<Chat> chats;
  final Chat? currentChat;
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final String selectedProviderId;
  final String selectedModelId;
  final String selectedSystemPrompt;
  final double selectedTemperature;
  final int selectedMaxTokens;
  final double selectedTopP;
  final bool autoFallback;
  final bool strictSafety;
  final bool preferOffline;
  final bool longTermMemoryEnabled;
  final bool ragEnabled;
  final bool analyticsConsent;
  final bool adsConsent;
  final bool darkModeEnabled;
  final String preferredLanguageCode;
  final String ttsVoiceName;
  final String ttsVoiceLocale;
  final double ttsSpeechRate;
  final double ttsPitch;
  final String profileName;
  final String profileEmail;
  final String avatarUrl;
  final DietProfile dietProfile;
  final MedicalProfile medicalProfile;
  final LegalProfile legalProfile;
  final bool isPremium;
  final String streamingText;
  final String? sendingChatId;
  final int dailyTokensUsed;
  final int dailyTokenLimit;
  final int nextAdTriggerTokens;
  final int rewardedTokenBonus;
  final List<String> latestRagSourceNames;
  final bool shouldOfferRewardedAd;
  final double estimatedCostUsd;
  final List<PromptPreset> promptPresets;
  final List<String> memoryNotes;
  final List<RagDocument> ragDocuments;
  final List<String> pinnedChatIds;
  final Map<String, List<LLMModelOption>> providerModels;
  final int successRequests;
  final int failedRequests;
  final double averageLatencyMs;
  final List<String> openCircuitProviders;
  final bool shouldShowOnboarding;
  final String onboardingVariant;

  const ChatState({
    required this.chats,
    required this.currentChat,
    required this.messages,
    required this.isLoading,
    required this.isSending,
    required this.errorMessage,
    required this.selectedProviderId,
    required this.selectedModelId,
    required this.selectedSystemPrompt,
    required this.selectedTemperature,
    required this.selectedMaxTokens,
    required this.selectedTopP,
    required this.autoFallback,
    required this.strictSafety,
    required this.preferOffline,
    required this.longTermMemoryEnabled,
    required this.ragEnabled,
    required this.analyticsConsent,
    required this.adsConsent,
    required this.darkModeEnabled,
    required this.preferredLanguageCode,
    required this.ttsVoiceName,
    required this.ttsVoiceLocale,
    required this.ttsSpeechRate,
    required this.ttsPitch,
    required this.profileName,
    required this.profileEmail,
    required this.avatarUrl,
    required this.dietProfile,
    required this.medicalProfile,
    required this.legalProfile,
    required this.isPremium,
    required this.streamingText,
    required this.sendingChatId,
    required this.dailyTokensUsed,
    required this.dailyTokenLimit,
    required this.nextAdTriggerTokens,
    required this.rewardedTokenBonus,
    required this.latestRagSourceNames,
    required this.shouldOfferRewardedAd,
    required this.estimatedCostUsd,
    required this.promptPresets,
    required this.memoryNotes,
    required this.ragDocuments,
    required this.pinnedChatIds,
    required this.providerModels,
    required this.successRequests,
    required this.failedRequests,
    required this.averageLatencyMs,
    required this.openCircuitProviders,
    required this.shouldShowOnboarding,
    required this.onboardingVariant,
  });

  ChatState copyWith({
    List<Chat>? chats,
    Object? currentChat = _noChange,
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    String? selectedProviderId,
    String? selectedModelId,
    String? selectedSystemPrompt,
    double? selectedTemperature,
    int? selectedMaxTokens,
    double? selectedTopP,
    bool? autoFallback,
    bool? strictSafety,
    bool? preferOffline,
    bool? longTermMemoryEnabled,
    bool? ragEnabled,
    bool? analyticsConsent,
    bool? adsConsent,
    bool? darkModeEnabled,
    String? preferredLanguageCode,
    String? ttsVoiceName,
    String? ttsVoiceLocale,
    double? ttsSpeechRate,
    double? ttsPitch,
    String? profileName,
    String? profileEmail,
    String? avatarUrl,
    DietProfile? dietProfile,
    MedicalProfile? medicalProfile,
    LegalProfile? legalProfile,
    bool? isPremium,
    String? streamingText,
    Object? sendingChatId = _noChange,
    int? dailyTokensUsed,
    int? dailyTokenLimit,
    int? nextAdTriggerTokens,
    int? rewardedTokenBonus,
    List<String>? latestRagSourceNames,
    bool? shouldOfferRewardedAd,
    double? estimatedCostUsd,
    List<PromptPreset>? promptPresets,
    List<String>? memoryNotes,
    List<RagDocument>? ragDocuments,
    List<String>? pinnedChatIds,
    Map<String, List<LLMModelOption>>? providerModels,
    int? successRequests,
    int? failedRequests,
    double? averageLatencyMs,
    List<String>? openCircuitProviders,
    bool? shouldShowOnboarding,
    String? onboardingVariant,
    bool clearError = false,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      currentChat: identical(currentChat, _noChange)
          ? this.currentChat
          : currentChat as Chat?,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      selectedSystemPrompt: selectedSystemPrompt ?? this.selectedSystemPrompt,
      selectedTemperature: selectedTemperature ?? this.selectedTemperature,
      selectedMaxTokens: selectedMaxTokens ?? this.selectedMaxTokens,
      selectedTopP: selectedTopP ?? this.selectedTopP,
      autoFallback: autoFallback ?? this.autoFallback,
      strictSafety: strictSafety ?? this.strictSafety,
      preferOffline: preferOffline ?? this.preferOffline,
      longTermMemoryEnabled:
          longTermMemoryEnabled ?? this.longTermMemoryEnabled,
      ragEnabled: ragEnabled ?? this.ragEnabled,
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      adsConsent: adsConsent ?? this.adsConsent,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      preferredLanguageCode:
          preferredLanguageCode ?? this.preferredLanguageCode,
      ttsVoiceName: ttsVoiceName ?? this.ttsVoiceName,
      ttsVoiceLocale: ttsVoiceLocale ?? this.ttsVoiceLocale,
      ttsSpeechRate: ttsSpeechRate ?? this.ttsSpeechRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      profileName: profileName ?? this.profileName,
      profileEmail: profileEmail ?? this.profileEmail,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dietProfile: dietProfile ?? this.dietProfile,
      medicalProfile: medicalProfile ?? this.medicalProfile,
      legalProfile: legalProfile ?? this.legalProfile,
      isPremium: isPremium ?? this.isPremium,
      streamingText: streamingText ?? this.streamingText,
      sendingChatId: identical(sendingChatId, _noChange)
          ? this.sendingChatId
          : sendingChatId as String?,
      dailyTokensUsed: dailyTokensUsed ?? this.dailyTokensUsed,
      dailyTokenLimit: dailyTokenLimit ?? this.dailyTokenLimit,
      nextAdTriggerTokens: nextAdTriggerTokens ?? this.nextAdTriggerTokens,
      rewardedTokenBonus: rewardedTokenBonus ?? this.rewardedTokenBonus,
      latestRagSourceNames: latestRagSourceNames ?? this.latestRagSourceNames,
      shouldOfferRewardedAd:
          shouldOfferRewardedAd ?? this.shouldOfferRewardedAd,
      estimatedCostUsd: estimatedCostUsd ?? this.estimatedCostUsd,
      promptPresets: promptPresets ?? this.promptPresets,
      memoryNotes: memoryNotes ?? this.memoryNotes,
      ragDocuments: ragDocuments ?? this.ragDocuments,
      pinnedChatIds: pinnedChatIds ?? this.pinnedChatIds,
      providerModels: providerModels ?? this.providerModels,
      successRequests: successRequests ?? this.successRequests,
      failedRequests: failedRequests ?? this.failedRequests,
      averageLatencyMs: averageLatencyMs ?? this.averageLatencyMs,
      openCircuitProviders: openCircuitProviders ?? this.openCircuitProviders,
      shouldShowOnboarding: shouldShowOnboarding ?? this.shouldShowOnboarding,
      onboardingVariant: onboardingVariant ?? this.onboardingVariant,
    );
  }

  factory ChatState.initial({
    required LLMProvider defaultProvider,
    required int dailyTokenLimit,
    required int nextAdTriggerTokens,
    required int rewardedTokenBonus,
    required Map<String, List<LLMModelOption>> providerModels,
    required String defaultLanguageCode,
  }) {
    return ChatState(
      chats: const [],
      currentChat: null,
      messages: const [],
      isLoading: true,
      isSending: false,
      errorMessage: null,
      selectedProviderId: defaultProvider.id,
      selectedModelId: defaultProvider.models.first.id,
      selectedSystemPrompt: LLMRequestConfig.defaults.systemPrompt,
      selectedTemperature: LLMRequestConfig.defaults.temperature,
      selectedMaxTokens: LLMRequestConfig.defaults.maxTokens,
      selectedTopP: LLMRequestConfig.defaults.topP,
      autoFallback: true,
      strictSafety: true,
      preferOffline: false,
      longTermMemoryEnabled: false,
      ragEnabled: false,
      analyticsConsent: false,
      adsConsent: false,
      darkModeEnabled: false,
      preferredLanguageCode: defaultLanguageCode,
      ttsVoiceName: '',
      ttsVoiceLocale: '',
      ttsSpeechRate: 0.5,
      ttsPitch: 1.0,
      profileName: '',
      profileEmail: '',
      avatarUrl: '',
      dietProfile: DietProfile.empty,
      medicalProfile: MedicalProfile.empty,
      legalProfile: LegalProfile.empty,
      isPremium: false,
      streamingText: '',
      sendingChatId: null,
      dailyTokensUsed: 0,
      dailyTokenLimit: dailyTokenLimit,
      nextAdTriggerTokens: nextAdTriggerTokens,
      rewardedTokenBonus: rewardedTokenBonus,
      latestRagSourceNames: const [],
      shouldOfferRewardedAd: false,
      estimatedCostUsd: 0,
      promptPresets: const [],
      memoryNotes: const [],
      ragDocuments: const [],
      pinnedChatIds: const [],
      providerModels: providerModels,
      successRequests: 0,
      failedRequests: 0,
      averageLatencyMs: 0,
      openCircuitProviders: const [],
      shouldShowOnboarding: false,
      onboardingVariant: 'A',
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(
    this._repo,
    this._registry,
    this._authService,
    this._cloudSync,
    this._localRag,
    this._runtimeConfig,
    this._observability,
  ) : super(
        ChatState.initial(
          defaultProvider: _initialDefaultProvider(_registry, _runtimeConfig),
          dailyTokenLimit: _runtimeConfig.baseDailyTokenLimit,
          nextAdTriggerTokens: _runtimeConfig.adTriggerStep,
          rewardedTokenBonus: _runtimeConfig.rewardedTokenBonus,
          providerModels: _initialProviderModels(_registry),
          defaultLanguageCode: _deviceLanguageCode(),
        ),
      ) {
    _init();
  }

  final ChatRepository _repo;
  final LLMRegistry _registry;
  final AuthService _authService;
  final CloudSyncService _cloudSync;
  final LocalRagService _localRag;
  final AppRuntimeConfig _runtimeConfig;
  final ObservabilityService _observability;

  static const String _currentChatKey = 'currentChatId';
  static const String _providerKey = 'defaultProviderId';
  static const String _modelKey = 'defaultModelId';
  static const String _systemPromptKey = 'defaultSystemPrompt';
  static const String _temperatureKey = 'defaultTemperature';
  static const String _maxTokensKey = 'defaultMaxTokens';
  static const String _topPKey = 'defaultTopP';
  static const String _autoFallbackKey = 'autoFallbackEnabled';
  static const String _strictSafetyKey = 'strictSafetyEnabled';
  static const String _preferOfflineKey = 'preferOfflineEnabled';
  static const String _memoryEnabledKey = 'longTermMemoryEnabled';
  static const String _ragEnabledKey = 'localRagEnabled';
  static const String _ragDocumentsKey = 'localRagDocuments';
  static const String _memoryNotesKey = 'longTermMemoryNotes';
  static const String _promptPresetsKey = 'promptPresets';
  static const String _pinnedChatIdsKey = 'pinnedChatIds';
  static const String _analyticsConsentKey = 'analyticsConsent';
  static const String _adsConsentKey = 'adsConsent';
  static const String _darkModeEnabledKey = 'darkModeEnabled';
  static const String _languageKey = 'preferredLanguageCode';
  static const String _ttsVoiceNameKey = 'ttsVoiceName';
  static const String _ttsVoiceLocaleKey = 'ttsVoiceLocale';
  static const String _ttsSpeechRateKey = 'ttsSpeechRate';
  static const String _ttsPitchKey = 'ttsPitch';
  static const String _profileNameKey = 'profileName';
  static const String _dietProfileKey = 'dietProfile';
  static const String _medicalProfileKey = 'medicalProfile';
  static const String _legalProfileKey = 'legalProfile';
  static const String _avatarUrlKey = 'avatarUrl';
  static const String _premiumEnabledKey = 'premiumEnabled';
  static const String _nextAdTriggerKey = 'nextRewardedAdTriggerTokens';
  static const String _activeAuthUidKey = 'activeAuthUid';

  static const String _dailyUsageDateKey = 'dailyUsageDate';
  static const String _dailyUsageTokensKey = 'dailyUsageTokens';

  static const String _metricsSuccessKey = 'metricsSuccessRequests';
  static const String _metricsFailedKey = 'metricsFailedRequests';
  static const String _metricsLatencyTotalKey = 'metricsLatencyTotalMs';

  static const String _onboardingSeenKey = 'onboardingSeen';
  static const String _onboardingVariantKey = 'onboardingVariant';

  bool _cancelRequested = false;
  final Map<String, int> _providerFailureCounts = <String, int>{};
  final Map<String, DateTime> _providerBlockedUntil = <String, DateTime>{};

  Future<void> _init() async {
    final providerId = await _repo.getAppState(_providerKey);
    final modelId = await _repo.getAppState(_modelKey);
    final systemPrompt =
        await _repo.getAppState(_systemPromptKey) ??
        LLMRequestConfig.defaults.systemPrompt;
    final temperature = _parseDouble(
      await _repo.getAppState(_temperatureKey),
      fallback: LLMRequestConfig.defaults.temperature,
    );
    final maxTokens = _parseInt(
      await _repo.getAppState(_maxTokensKey),
      fallback: LLMRequestConfig.defaults.maxTokens,
    );
    final topP = _parseDouble(
      await _repo.getAppState(_topPKey),
      fallback: LLMRequestConfig.defaults.topP,
    );

    final autoFallback = _parseBool(
      await _repo.getAppState(_autoFallbackKey),
      fallback: true,
    );
    final strictSafety = _parseBool(
      await _repo.getAppState(_strictSafetyKey),
      fallback: true,
    );
    final preferOffline = _parseBool(
      await _repo.getAppState(_preferOfflineKey),
      fallback: false,
    );
    final memoryEnabled = _parseBool(
      await _repo.getAppState(_memoryEnabledKey),
      fallback: false,
    );
    final ragEnabled = _parseBool(
      await _repo.getAppState(_ragEnabledKey),
      fallback: false,
    );
    final analyticsConsent = _parseBool(
      await _repo.getAppState(_analyticsConsentKey),
      fallback: false,
    );
    final adsConsent = _parseBool(
      await _repo.getAppState(_adsConsentKey),
      fallback: false,
    );
    final darkModeEnabled = _parseBool(
      await _repo.getAppState(_darkModeEnabledKey),
      fallback: false,
    );
    final preferredLanguageCode = _normalizeLanguageCode(
      await _repo.getAppState(_languageKey) ?? _deviceLanguageCode(),
    );
    final ttsVoiceName = await _repo.getAppState(_ttsVoiceNameKey) ?? '';
    final ttsVoiceLocale = await _repo.getAppState(_ttsVoiceLocaleKey) ?? '';
    final ttsSpeechRate = _parseDouble(
      await _repo.getAppState(_ttsSpeechRateKey),
      fallback: 0.5,
    );
    final ttsPitch = _parseDouble(
      await _repo.getAppState(_ttsPitchKey),
      fallback: 1.0,
    );
    final profileName =
        await _repo.getAppState(_profileNameKey) ??
        _authService.currentDisplayName;
    final dietProfile = _parseDietProfile(
      await _repo.getAppState(_dietProfileKey),
    );
    final medicalProfile = _parseMedicalProfile(
      await _repo.getAppState(_medicalProfileKey),
    );
    final legalProfile = _parseLegalProfile(
      await _repo.getAppState(_legalProfileKey),
    );
    final avatarUrl =
        await _repo.getAppState(_avatarUrlKey) ?? _authService.currentPhotoUrl;
    final premiumEnabled = _parseBool(
      await _repo.getAppState(_premiumEnabledKey),
      fallback: false,
    );
    final nextAdTriggerTokens = _parseInt(
      await _repo.getAppState(_nextAdTriggerKey),
      fallback: _runtimeConfig.adTriggerStep,
    );

    final memoryNotes = _parseStringList(
      await _repo.getAppState(_memoryNotesKey),
    );
    final promptPresets = _parsePromptPresets(
      await _repo.getAppState(_promptPresetsKey),
    );
    final ragDocuments = _parseRagDocuments(
      await _repo.getAppState(_ragDocumentsKey),
    );
    final pinnedChatIds = _parseStringList(
      await _repo.getAppState(_pinnedChatIdsKey),
    );

    final metricsSuccess = _parseInt(
      await _repo.getAppState(_metricsSuccessKey),
      fallback: 0,
    );
    final metricsFailed = _parseInt(
      await _repo.getAppState(_metricsFailedKey),
      fallback: 0,
    );
    final metricsLatencyTotal = _parseDouble(
      await _repo.getAppState(_metricsLatencyTotalKey),
      fallback: 0,
    );
    final averageLatency = metricsSuccess == 0
        ? 0.0
        : metricsLatencyTotal / metricsSuccess;

    final onboardingSeen = _parseBool(
      await _repo.getAppState(_onboardingSeenKey),
      fallback: false,
    );
    final onboardingVariant = await _resolveOnboardingVariant();

    await _observability.syncConsent(analyticsConsent: analyticsConsent);

    final fallbackProvider = _runtimeDefaultProvider();
    final selectedProvider = providerId == null
        ? fallbackProvider
        : _safeProviderById(providerId);
    final selectedModelId = modelId ?? _firstModelIdFor(selectedProvider.id);

    final chats = await _loadNormalizedChats();
    final currentId = await _repo.getAppState(_currentChatKey);
    Chat? current;
    if (currentId != null) {
      for (final chat in chats) {
        if (chat.id == currentId) {
          current = chat;
          break;
        }
      }
    }
    current ??= chats.isNotEmpty ? chats.first : null;
    final messages = current == null
        ? const <Message>[]
        : await _repo.loadMessages(current.id);

    final usageTokens = await _loadDailyUsage();
    final dailyTokenLimit = _dailyLimitForPremium(premiumEnabled);

    state = state.copyWith(
      chats: chats,
      currentChat: current,
      messages: messages,
      isLoading: false,
      selectedProviderId: current?.providerId ?? selectedProvider.id,
      selectedModelId: current?.modelId ?? selectedModelId,
      selectedSystemPrompt: current?.systemPrompt ?? systemPrompt,
      selectedTemperature: current?.temperature ?? temperature,
      selectedMaxTokens: current?.maxTokens ?? maxTokens,
      selectedTopP: current?.topP ?? topP,
      autoFallback: autoFallback,
      strictSafety: strictSafety,
      preferOffline: preferOffline,
      longTermMemoryEnabled: memoryEnabled,
      ragEnabled: ragEnabled,
      analyticsConsent: analyticsConsent,
      adsConsent: adsConsent,
      darkModeEnabled: darkModeEnabled,
      preferredLanguageCode: preferredLanguageCode,
      ttsVoiceName: ttsVoiceName,
      ttsVoiceLocale: ttsVoiceLocale,
      ttsSpeechRate: ttsSpeechRate,
      ttsPitch: ttsPitch,
      profileName: profileName,
      profileEmail: _authService.currentEmail ?? '',
      avatarUrl: avatarUrl,
      dietProfile: dietProfile,
      medicalProfile: medicalProfile,
      legalProfile: legalProfile,
      isPremium: premiumEnabled,
      dailyTokensUsed: usageTokens,
      dailyTokenLimit: dailyTokenLimit,
      nextAdTriggerTokens: nextAdTriggerTokens,
      rewardedTokenBonus: _runtimeConfig.rewardedTokenBonus,
      latestRagSourceNames: const [],
      shouldOfferRewardedAd: false,
      estimatedCostUsd: estimateUsdFromTokens(usageTokens),
      promptPresets: promptPresets,
      memoryNotes: memoryNotes,
      ragDocuments: ragDocuments,
      pinnedChatIds: pinnedChatIds,
      successRequests: metricsSuccess,
      failedRequests: metricsFailed,
      averageLatencyMs: averageLatency,
      openCircuitProviders: _currentOpenCircuits(),
      shouldShowOnboarding: _runtimeConfig.onboardingEnabled && !onboardingSeen,
      onboardingVariant: onboardingVariant,
      clearError: true,
    );

    // ignore: unawaited_futures
    refreshProviderModels();
  }

  static Map<String, List<LLMModelOption>> _initialProviderModels(
    LLMRegistry registry,
  ) {
    final map = <String, List<LLMModelOption>>{};
    for (final provider in registry.providers) {
      map[provider.id] = provider.models;
    }
    return map;
  }

  Future<void> refreshProviderModels([String? providerId]) async {
    final updated = <String, List<LLMModelOption>>{...state.providerModels};

    Future<void> loadProvider(LLMProvider provider) async {
      final models = await provider.loadModels();
      if (models.isNotEmpty) {
        updated[provider.id] = models;
      }
    }

    if (providerId != null) {
      final provider = _safeProviderById(providerId);
      await loadProvider(provider);
    } else {
      for (final provider in _registry.providers) {
        await loadProvider(provider);
      }
    }

    state = state.copyWith(providerModels: updated);

    final selectedProviderModels =
        updated[state.selectedProviderId] ?? const [];
    final selectedStillValid = selectedProviderModels.any(
      (m) => m.id == state.selectedModelId,
    );
    if (!selectedStillValid && selectedProviderModels.isNotEmpty) {
      final replacement = selectedProviderModels.first.id;
      await updateCurrentChatModel(
        providerId: state.selectedProviderId,
        modelId: replacement,
      );
      await updateDefaultModel(
        providerId: state.selectedProviderId,
        modelId: replacement,
      );
    }
  }

  Future<void> refreshChats() async {
    final chats = await _loadNormalizedChats();
    Chat? refreshedCurrent = state.currentChat;
    final currentId = state.currentChat?.id;
    if (currentId != null) {
      for (final chat in chats) {
        if (chat.id == currentId) {
          refreshedCurrent = chat;
          break;
        }
      }
    }
    state = state.copyWith(chats: chats, currentChat: refreshedCurrent);
  }

  Future<void> updateSearchWarmup(String query) async {
    await _repo.searchChatIdsByMessage(query);
  }

  Future<Set<String>> searchChatIdsByMessage(String query) {
    return _repo.searchChatIdsByMessage(query);
  }

  Future<void> newChat() async {
    final chat = await _repo.createChat(
      title: _strings.newChat,
      providerId: state.selectedProviderId,
      modelId: state.selectedModelId,
      systemPrompt: state.selectedSystemPrompt,
      temperature: state.selectedTemperature,
      maxTokens: state.selectedMaxTokens,
      topP: state.selectedTopP,
    );
    await _repo.setAppState(_currentChatKey, chat.id);
    final chats = await _loadNormalizedChats();
    state = state.copyWith(
      chats: chats,
      currentChat: chat,
      messages: const <Message>[],
      streamingText: '',
      latestRagSourceNames: const [],
      clearError: true,
    );
    await _observability.logEvent(
      'chat_created',
      parameters: {'provider_id': chat.providerId, 'model_id': chat.modelId},
    );
  }

  Future<void> startDietAgent({
    required DietProfile profile,
  }) async {
    await saveDietProfile(profile);
    final sections = _dietProfileSections(profile);
    final systemPrompt = _buildDietAgentPrompt(sections);
    final chat = await _repo.createChat(
      title: 'Agente dieta',
      providerId: state.selectedProviderId,
      modelId: state.selectedModelId,
      systemPrompt: systemPrompt,
      temperature: 0.25,
      maxTokens: state.selectedMaxTokens < 1600 ? 1600 : state.selectedMaxTokens,
      topP: 0.9,
    );
    final welcome = _buildDietAgentWelcome(sections);
    await _repo.addMessage(
      chatId: chat.id,
      role: 'assistant',
      content: welcome,
    );
    await _repo.setAppState(_currentChatKey, chat.id);
    final chats = await _loadNormalizedChats();
    state = state.copyWith(
      chats: chats,
      currentChat: chat,
      messages: [
        Message(
          chatId: chat.id,
          role: 'assistant',
          content: welcome,
          createdAt: DateTime.now(),
        ),
      ],
      selectedSystemPrompt: systemPrompt,
      selectedTemperature: chat.temperature,
      selectedMaxTokens: chat.maxTokens,
      selectedTopP: chat.topP,
      streamingText: '',
      latestRagSourceNames: const [],
      clearError: true,
    );
    await _observability.logEvent(
      'diet_agent_started',
      parameters: {
        'provider_id': chat.providerId,
        'model_id': chat.modelId,
        'diet_profile_saved': profile.isEmpty ? 0 : 1,
      },
    );
  }

  Future<void> startMedicalAgent({
    required MedicalProfile profile,
  }) async {
    await saveMedicalProfile(profile);
    final sections = _medicalProfileSections(profile);
    final systemPrompt = _buildMedicalAgentPrompt(sections);
    final chat = await _repo.createChat(
      title: 'Medico di base',
      providerId: state.selectedProviderId,
      modelId: state.selectedModelId,
      systemPrompt: systemPrompt,
      temperature: 0.2,
      maxTokens: state.selectedMaxTokens < 1800 ? 1800 : state.selectedMaxTokens,
      topP: 0.9,
    );
    final welcome = _buildMedicalAgentWelcome(sections);
    await _repo.addMessage(
      chatId: chat.id,
      role: 'assistant',
      content: welcome,
    );
    await _repo.setAppState(_currentChatKey, chat.id);
    final chats = await _loadNormalizedChats();
    state = state.copyWith(
      chats: chats,
      currentChat: chat,
      messages: [
        Message(
          chatId: chat.id,
          role: 'assistant',
          content: welcome,
          createdAt: DateTime.now(),
        ),
      ],
      selectedSystemPrompt: systemPrompt,
      selectedTemperature: chat.temperature,
      selectedMaxTokens: chat.maxTokens,
      selectedTopP: chat.topP,
      streamingText: '',
      latestRagSourceNames: const [],
      clearError: true,
    );
    await _observability.logEvent(
      'medical_agent_started',
      parameters: {
        'provider_id': chat.providerId,
        'model_id': chat.modelId,
        'medical_profile_saved': profile.isEmpty ? 0 : 1,
      },
    );
  }

  Future<void> startLegalAgent({
    required LegalProfile profile,
  }) async {
    await saveLegalProfile(profile);
    final sections = _legalProfileSections(profile);
    final systemPrompt = _buildLegalAgentPrompt(sections);
    final chat = await _repo.createChat(
      title: 'Avvocato',
      providerId: state.selectedProviderId,
      modelId: state.selectedModelId,
      systemPrompt: systemPrompt,
      temperature: 0.15,
      maxTokens: state.selectedMaxTokens < 1800 ? 1800 : state.selectedMaxTokens,
      topP: 0.9,
    );
    final welcome = _buildLegalAgentWelcome(sections);
    await _repo.addMessage(
      chatId: chat.id,
      role: 'assistant',
      content: welcome,
    );
    await _repo.setAppState(_currentChatKey, chat.id);
    final chats = await _loadNormalizedChats();
    state = state.copyWith(
      chats: chats,
      currentChat: chat,
      messages: [
        Message(
          chatId: chat.id,
          role: 'assistant',
          content: welcome,
          createdAt: DateTime.now(),
        ),
      ],
      selectedSystemPrompt: systemPrompt,
      selectedTemperature: chat.temperature,
      selectedMaxTokens: chat.maxTokens,
      selectedTopP: chat.topP,
      streamingText: '',
      latestRagSourceNames: const [],
      clearError: true,
    );
    await _observability.logEvent(
      'legal_agent_started',
      parameters: {
        'provider_id': chat.providerId,
        'model_id': chat.modelId,
        'legal_profile_saved': profile.isEmpty ? 0 : 1,
      },
    );
  }

  Future<void> loadChat(String id) async {
    final chats = await _loadNormalizedChats();
    final current = chats.firstWhere((c) => c.id == id);
    final messages = await _repo.loadMessages(id);
    await _repo.setAppState(_currentChatKey, id);
    state = state.copyWith(
      chats: chats,
      currentChat: current,
      messages: messages,
      selectedSystemPrompt: current.systemPrompt,
      selectedTemperature: current.temperature,
      selectedMaxTokens: current.maxTokens,
      selectedTopP: current.topP,
      streamingText: '',
      latestRagSourceNames: const [],
      clearError: true,
    );
  }

  Future<void> renameChat(Chat chat, String newTitle) async {
    await _repo.updateChatTitle(chat.id, newTitle);
    await refreshChats();
    if (state.currentChat?.id == chat.id) {
      state = state.copyWith(
        currentChat: state.currentChat?.copyWith(title: newTitle),
      );
    }
  }

  Future<void> deleteChat(Chat chat) async {
    await _repo.deleteChat(chat.id);
    if (state.pinnedChatIds.contains(chat.id)) {
      final nextPinned = [...state.pinnedChatIds]..remove(chat.id);
      await _repo.setAppState(_pinnedChatIdsKey, jsonEncode(nextPinned));
      state = state.copyWith(pinnedChatIds: nextPinned);
    }
    final chats = await _loadNormalizedChats();

    Chat? current = state.currentChat;
    if (current?.id == chat.id) {
      current = chats.isNotEmpty ? chats.first : null;
      if (current != null) {
        await _repo.setAppState(_currentChatKey, current.id);
      }
    }

    final messages = current == null
        ? const <Message>[]
        : await _repo.loadMessages(current.id);
    state = state.copyWith(
      chats: chats,
      currentChat: current,
      messages: messages,
      latestRagSourceNames: const [],
      selectedSystemPrompt: current?.systemPrompt ?? state.selectedSystemPrompt,
      selectedTemperature: current?.temperature ?? state.selectedTemperature,
      selectedMaxTokens: current?.maxTokens ?? state.selectedMaxTokens,
      selectedTopP: current?.topP ?? state.selectedTopP,
      streamingText: '',
      clearError: true,
    );
  }

  Future<void> togglePinnedChat(Chat chat) async {
    final nextPinned = [...state.pinnedChatIds];
    if (nextPinned.contains(chat.id)) {
      nextPinned.remove(chat.id);
    } else {
      nextPinned.add(chat.id);
    }
    await _repo.setAppState(_pinnedChatIdsKey, jsonEncode(nextPinned));
    state = state.copyWith(pinnedChatIds: nextPinned);
  }

  Future<void> updateDefaultModel({
    required String providerId,
    required String modelId,
  }) async {
    await _repo.setAppState(_providerKey, providerId);
    await _repo.setAppState(_modelKey, modelId);
    state = state.copyWith(
      selectedProviderId: providerId,
      selectedModelId: modelId,
    );
  }

  Future<void> updateCurrentChatModel({
    required String providerId,
    required String modelId,
  }) async {
    final current = state.currentChat;
    if (current == null) {
      await updateDefaultModel(providerId: providerId, modelId: modelId);
      return;
    }

    await _repo.updateChatModel(
      chatId: current.id,
      providerId: providerId,
      modelId: modelId,
    );
    await refreshChats();
    state = state.copyWith(
      currentChat: current.copyWith(providerId: providerId, modelId: modelId),
      selectedProviderId: providerId,
      selectedModelId: modelId,
    );
  }

  Future<void> updateCurrentChatSettings({
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    required double topP,
  }) async {
    final current = state.currentChat;
    await _persistDefaultSettings(
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
    );

    if (current != null) {
      await _repo.updateChatSettings(
        chatId: current.id,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
        topP: topP,
      );
      await refreshChats();
      state = state.copyWith(
        currentChat: current.copyWith(
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
          topP: topP,
        ),
        selectedSystemPrompt: systemPrompt,
        selectedTemperature: temperature,
        selectedMaxTokens: maxTokens,
        selectedTopP: topP,
      );
      return;
    }

    state = state.copyWith(
      selectedSystemPrompt: systemPrompt,
      selectedTemperature: temperature,
      selectedMaxTokens: maxTokens,
      selectedTopP: topP,
    );
  }

  Future<void> setAutoFallback(bool enabled) async {
    await _repo.setAppState(_autoFallbackKey, enabled.toString());
    state = state.copyWith(autoFallback: enabled);
  }

  Future<void> setStrictSafety(bool enabled) async {
    await _repo.setAppState(_strictSafetyKey, enabled.toString());
    state = state.copyWith(strictSafety: enabled);
  }

  Future<void> setPreferOffline(bool enabled) async {
    await _repo.setAppState(_preferOfflineKey, enabled.toString());
    if (enabled) {
      final offlineProvider = _offlineProvider();
      if (offlineProvider != null) {
        final offlineModelId = _firstModelIdFor(offlineProvider.id);
        await _repo.setAppState(_providerKey, offlineProvider.id);
        await _repo.setAppState(_modelKey, offlineModelId);
        state = state.copyWith(
          preferOffline: true,
          selectedProviderId: offlineProvider.id,
          selectedModelId: offlineModelId,
        );
        return;
      }
    }

    state = state.copyWith(preferOffline: enabled);
  }

  Future<void> setLongTermMemory(bool enabled) async {
    await _repo.setAppState(_memoryEnabledKey, enabled.toString());
    state = state.copyWith(longTermMemoryEnabled: enabled);
  }

  Future<void> setRagEnabled(bool enabled) async {
    await _repo.setAppState(_ragEnabledKey, enabled.toString());
    state = state.copyWith(ragEnabled: enabled);
  }

  Future<void> setAnalyticsConsent(bool enabled) async {
    await _repo.setAppState(_analyticsConsentKey, enabled.toString());
    await _observability.syncConsent(analyticsConsent: enabled);
    state = state.copyWith(analyticsConsent: enabled);
  }

  Future<void> setAdsConsent(bool enabled) async {
    await _repo.setAppState(_adsConsentKey, enabled.toString());
    state = state.copyWith(adsConsent: enabled);
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    await _repo.setAppState(_darkModeEnabledKey, enabled.toString());
    state = state.copyWith(darkModeEnabled: enabled);
  }

  Future<void> setTtsVoice({
    required String voiceName,
    required String voiceLocale,
  }) async {
    await _repo.setAppState(_ttsVoiceNameKey, voiceName);
    await _repo.setAppState(_ttsVoiceLocaleKey, voiceLocale);
    state = state.copyWith(
      ttsVoiceName: voiceName,
      ttsVoiceLocale: voiceLocale,
    );
  }

  Future<void> setTtsSpeechRate(double value) async {
    await _repo.setAppState(_ttsSpeechRateKey, value.toString());
    state = state.copyWith(ttsSpeechRate: value);
  }

  Future<void> setTtsPitch(double value) async {
    await _repo.setAppState(_ttsPitchKey, value.toString());
    state = state.copyWith(ttsPitch: value);
  }

  Future<void> dismissOnboarding() async {
    await _repo.setAppState(_onboardingSeenKey, 'true');
    state = state.copyWith(shouldShowOnboarding: false);
  }

  Future<void> setPreferredLanguage(String code) async {
    final normalized = _normalizeLanguageCode(code);
    await _repo.setAppState(_languageKey, normalized);
    state = state.copyWith(preferredLanguageCode: normalized);
  }

  Future<void> handleAuthStateChanged() async {
    final currentUid = _authService.currentUser?.uid ?? '';
    final storedUid = await _repo.getAppState(_activeAuthUidKey) ?? '';

    if (storedUid.isEmpty && currentUid.isNotEmpty) {
      await _repo.setAppState(_activeAuthUidKey, currentUid);
      state = state.copyWith(
        profileName: _authService.currentDisplayName,
        profileEmail: _authService.currentEmail ?? '',
        avatarUrl: _authService.currentPhotoUrl,
        clearError: true,
      );
      return;
    }

    if (storedUid == currentUid) {
      state = state.copyWith(
        profileName: state.profileName.isNotEmpty
            ? state.profileName
            : _authService.currentDisplayName,
        profileEmail: _authService.currentEmail ?? '',
        avatarUrl: state.avatarUrl.isNotEmpty
            ? state.avatarUrl
            : _authService.currentPhotoUrl,
        clearError: true,
      );
      return;
    }

    final preservedLanguage = state.preferredLanguageCode;
    final preservedProviderModels = state.providerModels;
    final preservedOnboardingVariant = state.onboardingVariant;
    final defaultProvider = _runtimeDefaultProvider();

    await _repo.clearLocalData(clearAppState: true);

    if (currentUid.isNotEmpty) {
      await _repo.setAppState(_activeAuthUidKey, currentUid);
      await _repo.setAppState(_languageKey, preservedLanguage);
      await _repo.setAppState(_providerKey, defaultProvider.id);
      await _repo.setAppState(
        _modelKey,
        defaultProvider.models.isNotEmpty
            ? defaultProvider.models.first.id
            : 'default',
      );
      if (_authService.currentDisplayName.isNotEmpty) {
        await _repo.setAppState(_profileNameKey, _authService.currentDisplayName);
      }
      if (_authService.currentPhotoUrl.isNotEmpty) {
        await _repo.setAppState(_avatarUrlKey, _authService.currentPhotoUrl);
      }
    }

    state = ChatState.initial(
      defaultProvider: defaultProvider,
      dailyTokenLimit: _dailyLimitForPremium(false),
      nextAdTriggerTokens: _runtimeConfig.adTriggerStep,
      rewardedTokenBonus: _runtimeConfig.rewardedTokenBonus,
      providerModels: preservedProviderModels,
      defaultLanguageCode: preservedLanguage,
    ).copyWith(
      isLoading: false,
      preferredLanguageCode: preservedLanguage,
      profileName: _authService.currentDisplayName,
      profileEmail: _authService.currentEmail ?? '',
      avatarUrl: _authService.currentPhotoUrl,
      onboardingVariant: preservedOnboardingVariant,
      shouldShowOnboarding:
          currentUid.isNotEmpty && _runtimeConfig.onboardingEnabled,
      clearError: true,
    );

    if (currentUid.isNotEmpty) {
      await refreshProviderModels();
    }
  }

  Future<void> updateProfile({
    required String name,
    required String avatarUrl,
  }) async {
    if (_authService.currentUser != null) {
      await _authService.updateProfile(displayName: name, photoUrl: avatarUrl);
    }
    await _repo.setAppState(_profileNameKey, name.trim());
    await _repo.setAppState(_avatarUrlKey, avatarUrl.trim());
    state = state.copyWith(
      profileName: name.trim(),
      profileEmail: _authService.currentEmail ?? '',
      avatarUrl: avatarUrl.trim(),
    );
  }

  Future<void> saveDietProfile(DietProfile profile) async {
    await _repo.setAppState(_dietProfileKey, jsonEncode(profile.toJson()));
    state = state.copyWith(dietProfile: profile);
  }

  Future<void> saveMedicalProfile(MedicalProfile profile) async {
    await _repo.setAppState(_medicalProfileKey, jsonEncode(profile.toJson()));
    state = state.copyWith(medicalProfile: profile);
  }

  Future<void> saveLegalProfile(LegalProfile profile) async {
    await _repo.setAppState(_legalProfileKey, jsonEncode(profile.toJson()));
    state = state.copyWith(legalProfile: profile);
  }

  Future<void> addMemoryEntry({
    required MemoryCategory category,
    required String content,
  }) async {
    final cleaned = content.trim();
    if (cleaned.isEmpty) return;
    final serialized = MemoryEntry(category: category, content: cleaned).serialize();
    final current = <String>[
      for (final item in state.memoryNotes) _normalizeMemoryStorage(item),
    ];
    if (!current.contains(serialized)) {
      current.add(serialized);
    }
    await _repo.setAppState(_memoryNotesKey, jsonEncode(current));
    state = state.copyWith(memoryNotes: current);
  }

  Future<void> updateMemoryEntry({
    required String previousValue,
    required MemoryCategory category,
    required String content,
  }) async {
    final cleaned = content.trim();
    if (cleaned.isEmpty) return;
    final nextValue = MemoryEntry(category: category, content: cleaned).serialize();
    final updated = state.memoryNotes.map((item) {
      final normalized = _normalizeMemoryStorage(item);
      if (normalized == _normalizeMemoryStorage(previousValue)) {
        return nextValue;
      }
      return normalized;
    }).toList(growable: false);
    await _repo.setAppState(_memoryNotesKey, jsonEncode(updated));
    state = state.copyWith(memoryNotes: updated);
  }

  Future<void> deleteMemoryEntry(String rawValue) async {
    final normalizedTarget = _normalizeMemoryStorage(rawValue);
    final updated = state.memoryNotes
        .map(_normalizeMemoryStorage)
        .where((item) => item != normalizedTarget)
        .toList(growable: false);
    await _repo.setAppState(_memoryNotesKey, jsonEncode(updated));
    state = state.copyWith(memoryNotes: updated);
  }

  Future<void> upsertRagDocument({
    required String documentName,
    required String text,
  }) async {
    final updated = _localRag.indexDocuments(
      existing: state.ragDocuments,
      documentName: documentName,
      text: text,
    );
    await _saveRagDocuments(updated);
    state = state.copyWith(ragDocuments: updated);
  }

  Future<void> deleteRagDocument(String documentId) async {
    final updated = state.ragDocuments
        .where((doc) => doc.id != documentId)
        .toList(growable: false);
    await _saveRagDocuments(updated);
    state = state.copyWith(ragDocuments: updated);
  }

  Future<void> clearRagDocuments() async {
    await _saveRagDocuments(const []);
    state = state.copyWith(ragDocuments: const []);
  }

  Future<void> setPremiumStatus(bool enabled) async {
    await _repo.setAppState(_premiumEnabledKey, enabled.toString());
    state = state.copyWith(
      isPremium: enabled,
      dailyTokenLimit: _dailyLimitForPremium(enabled),
      shouldOfferRewardedAd: enabled ? false : state.shouldOfferRewardedAd,
    );
  }

  Future<void> dismissRewardedAdOffer() async {
    state = state.copyWith(shouldOfferRewardedAd: false);
  }

  Future<void> grantRewardedTokens() async {
    final currentUsage = await _loadDailyUsage();
    final updatedUsage = (currentUsage - state.rewardedTokenBonus)
        .clamp(0, 1 << 30)
        .toInt();
    await _repo.setAppState(_dailyUsageTokensKey, updatedUsage.toString());
    await _repo.setAppState(
      _nextAdTriggerKey,
      (updatedUsage + _runtimeConfig.adTriggerStep).toString(),
    );
    state = state.copyWith(
      dailyTokensUsed: updatedUsage,
      nextAdTriggerTokens: updatedUsage + _runtimeConfig.adTriggerStep,
      estimatedCostUsd: estimateUsdFromTokens(updatedUsage),
      shouldOfferRewardedAd: false,
    );
  }

  Future<void> addPromptPreset({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final preset = PromptPreset(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      systemPrompt: state.selectedSystemPrompt,
      temperature: state.selectedTemperature,
      maxTokens: state.selectedMaxTokens,
      topP: state.selectedTopP,
    );

    final updated = [...state.promptPresets, preset];
    await _savePromptPresets(updated);
    state = state.copyWith(promptPresets: updated);
  }

  Future<void> deletePromptPreset(String presetId) async {
    final updated = state.promptPresets
        .where((p) => p.id != presetId)
        .toList(growable: false);
    await _savePromptPresets(updated);
    state = state.copyWith(promptPresets: updated);
  }

  Future<void> applyPromptPreset(String presetId) async {
    PromptPreset? selected;
    for (final preset in state.promptPresets) {
      if (preset.id == presetId) {
        selected = preset;
        break;
      }
    }
    if (selected == null) return;

    await updateCurrentChatSettings(
      systemPrompt: selected.systemPrompt,
      temperature: selected.temperature,
      maxTokens: selected.maxTokens,
      topP: selected.topP,
    );
  }

  Future<String> exportChatsBackup() async {
    final path = await _repo.exportChatsToJsonFile();
    await _observability.logEvent('local_backup_exported');
    return path;
  }

  Future<String?> importChatsBackupFromLatest() async {
    final path = await _repo.latestBackupPath();
    if (path == null) return null;
    await _repo.importChatsFromJsonFile(path: path, replaceLocalData: true);
    await _init();
    await _observability.logEvent('local_backup_imported');
    return path;
  }

  Future<String?> exportCurrentChatMarkdown() async {
    final chatId = state.currentChat?.id;
    if (chatId == null) return null;
    final path = await _repo.exportChatToMarkdown(chatId);
    await _observability.logEvent('chat_markdown_exported');
    return path;
  }

  Future<void> clearLocalChatsAndMessages() async {
    await _repo.clearLocalData(clearAppState: false);
    await _init();
  }

  Future<String> exportUserDataBundle() async {
    final path = await _repo.exportUserDataToJsonFile(
      accountPayload: {
        'name': state.profileName,
        'email': state.profileEmail,
        'avatarUrl': state.avatarUrl,
        'providers': _authService.currentProviderIds,
        'preferredLanguageCode': state.preferredLanguageCode,
        'isPremium': state.isPremium,
        'exportedAt': DateTime.now().toIso8601String(),
      },
    );
    await _observability.logEvent('user_data_exported');
    return path;
  }

  Future<void> pushCloudBackup() async {
    final canSync = await _cloudSync.canSync();
    if (!canSync) {
      throw StateError(_strings.cloudUnavailable);
    }

    final payload = await _repo.exportAppPayload(includeAppState: true);
    payload['account'] = {
      'name': state.profileName,
      'email': state.profileEmail,
      'avatarUrl': state.avatarUrl,
      'preferredLanguageCode': state.preferredLanguageCode,
      'isPremium': state.isPremium,
    };
    await _cloudSync.pushPayload(payload);
    await _observability.logEvent('cloud_backup_uploaded');
  }

  Future<bool> pullCloudBackup() async {
    final canSync = await _cloudSync.canSync();
    if (!canSync) {
      throw StateError(_strings.cloudUnavailable);
    }

    final payload = await _cloudSync.pullPayload();
    if (payload == null) {
      return false;
    }

    await _repo.importAppPayload(
      payload: payload,
      replaceLocalData: true,
      replaceAppState: true,
    );
    await _init();
    await _observability.logEvent('cloud_backup_restored');
    return true;
  }

  Future<void> deleteAccountAndData({String? password}) async {
    try {
      await _cloudSync.deletePayload();
    } catch (_) {
      // Ignore missing remote backup.
    }

    try {
      await _authService.deleteCurrentUser(password: password);
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('requires-recent-login')) {
        throw StateError(_strings.deleteAccountNeedsLogin);
      }
      rethrow;
    }

    await _repo.clearLocalData(clearAppState: true);
    await _init();
  }

  Future<void> sendMessage(String text, {String? displayText}) async {
    final cleaned = text.trim();
    final visibleText = (displayText ?? text).trim();
    if (cleaned.isEmpty || state.isSending) return;
    _cancelRequested = false;
    final isFirstChatMessage = state.messages.isEmpty;

    await _refreshDailyUsage();
    final estimatedUserTokens = estimateTokensFromText(cleaned);
    if (state.dailyTokensUsed + estimatedUserTokens > state.dailyTokenLimit) {
      state = state.copyWith(
        errorMessage:
            '${_strings.dailyLimitLabel} (${state.dailyTokenLimit} token).',
      );
      return;
    }

    if (state.strictSafety) {
      final safety = checkSafety(
        cleaned,
        languageCode: state.preferredLanguageCode,
      );
      if (safety.isBlocked) {
        state = state.copyWith(errorMessage: safety.reason);
        return;
      }
    }

    if (state.currentChat == null) {
      await newChat();
    }

    var chat = state.currentChat!;
    final provider = _safeProviderById(chat.providerId);
    state = state.copyWith(
      isSending: true,
      streamingText: '',
      sendingChatId: chat.id,
      latestRagSourceNames: const [],
      clearError: true,
    );

    await _repo.addMessage(
      chatId: chat.id,
      role: 'user',
      content: visibleText.isEmpty ? cleaned : visibleText,
    );
    await _consumeEstimatedTokens(estimatedUserTokens);

    final userMessage = Message(
      chatId: chat.id,
      role: 'user',
      content: visibleText.isEmpty ? cleaned : visibleText,
      createdAt: DateTime.now(),
    );
    final messages = [...state.messages, userMessage];
    state = state.copyWith(messages: messages);

    await _observability.logEvent(
      'message_sent',
      parameters: {
        'provider_id': chat.providerId,
        'model_id': chat.modelId,
        'message_length': cleaned.length,
        'rag_enabled': state.ragEnabled,
      },
    );
    if (isFirstChatMessage) {
      await _observability.logEvent(
        'first_chat_message',
        parameters: {'provider_id': chat.providerId, 'model_id': chat.modelId},
      );
    }

    await _extractAndPersistMemory(visibleText.isEmpty ? cleaned : visibleText);

    final localTool = runLocalTool(
      cleaned,
      languageCode: state.preferredLanguageCode,
    );
    if (localTool != null) {
      await _repo.addMessage(
        chatId: chat.id,
        role: 'assistant',
        content: localTool.reply,
      );
      if (messages.length == 1 && _isUntitledChat(chat.title)) {
        await _maybeGenerateInitialTitle(
          chat: chat,
          preferredProvider: provider,
          firstMessage: cleaned,
          firstReply: localTool.reply,
        );
      }
      await _consumeEstimatedTokens(estimateTokensFromText(localTool.reply));
      final updatedMessages = await _repo.loadMessages(chat.id);
      state = state.copyWith(
        messages: state.currentChat?.id == chat.id ? updatedMessages : state.messages,
        isSending: false,
        streamingText: '',
        sendingChatId: null,
        latestRagSourceNames: const [],
      );
      return;
    }

    final result = await _generateAssistant(
      chat: chat,
      preferredProvider: provider,
      messages: messages,
    );

    if (!result.isError && result.reply.isNotEmpty) {
      if (messages.length == 1 && _isUntitledChat(chat.title)) {
        await _maybeGenerateInitialTitle(
          chat: chat,
          preferredProvider: provider,
          firstMessage: cleaned,
          firstReply: result.reply,
        );
      }
      await _consumeEstimatedTokens(estimateTokensFromText(result.reply));
    }

    if (result.usedProviderId != null &&
        result.usedProviderId != chat.providerId) {
      chat = chat.copyWith(
        providerId: result.usedProviderId,
        modelId: result.usedModelId,
      );
      if (state.currentChat?.id == chat.id) {
        state = state.copyWith(
          currentChat: chat,
          selectedProviderId: result.usedProviderId,
          selectedModelId: result.usedModelId,
        );
      }
    }
  }

  Future<void> retryLastMessage() async {
    if (state.isSending) return;
    final chat = state.currentChat;
    if (chat == null || state.messages.isEmpty) return;

    final last = state.messages.last;
    if (last.role == 'assistant' && last.id != null) {
      await _repo.deleteMessageById(last.id!);
    }
    await loadChat(chat.id);
    final provider = _safeProviderById(state.currentChat!.providerId);
    final messages = state.messages;
    if (messages.isEmpty || messages.last.role != 'user') return;

    state = state.copyWith(
      isSending: true,
      streamingText: '',
      sendingChatId: chat.id,
      latestRagSourceNames: const [],
      clearError: true,
    );

    await _generateAssistant(
      chat: state.currentChat!,
      preferredProvider: provider,
      messages: messages,
    );
  }

  Future<void> retryFromAssistant(Message message) async {
    if (state.isSending) return;
    final chat = state.currentChat;
    if (chat == null || message.role != 'assistant') return;

    await _repo.deleteMessagesAfter(
      chatId: chat.id,
      createdAt: message.createdAt,
    );
    if (message.id != null) {
      await _repo.deleteMessageById(message.id!);
    }

    await loadChat(chat.id);
    final provider = _safeProviderById(state.currentChat!.providerId);
    final messages = state.messages;
    if (messages.isEmpty || messages.last.role != 'user') return;

    state = state.copyWith(
      isSending: true,
      streamingText: '',
      sendingChatId: chat.id,
      latestRagSourceNames: const [],
      clearError: true,
    );
    await _generateAssistant(
      chat: state.currentChat!,
      preferredProvider: provider,
      messages: messages,
    );
  }

  Future<void> editUserMessage(Message message, String newContent) async {
    final cleaned = newContent.trim();
    if (state.isSending || cleaned.isEmpty) return;
    if (message.role != 'user' || message.id == null) return;

    final chat = state.currentChat;
    if (chat == null) return;

    await _repo.updateMessageContent(message.id!, cleaned);
    await _repo.deleteMessagesAfter(
      chatId: chat.id,
      createdAt: message.createdAt,
    );
    await loadChat(chat.id);

    final provider = _safeProviderById(state.currentChat!.providerId);
    final messages = state.messages;
    state = state.copyWith(
      isSending: true,
      streamingText: '',
      sendingChatId: chat.id,
      latestRagSourceNames: const [],
      clearError: true,
    );

    if (messages.length == 1 && _isUntitledChat(state.currentChat!.title)) {
      final generated = await _generateTitleWithFallback(
        preferredProvider: provider,
        modelId: state.currentChat!.modelId,
        firstMessage: cleaned,
      );
      if (generated != null && generated.isNotEmpty) {
        await _repo.updateChatTitle(chat.id, generated);
        await refreshChats();
      }
    }

    await _generateAssistant(
      chat: state.currentChat!,
      preferredProvider: provider,
      messages: messages,
    );
  }

  Future<void> cancelSending() async {
    if (!state.isSending) return;

    _cancelRequested = true;
    final partial = state.streamingText.trim();
    final sendingChatId = state.sendingChatId;
    final chat = sendingChatId == null
        ? state.currentChat
        : await _chatById(sendingChatId);

    if (chat != null && partial.isNotEmpty) {
      await _repo.addMessage(
        chatId: chat.id,
        role: 'assistant',
        content: partial,
        isError: false,
      );
      await _consumeEstimatedTokens(estimateTokensFromText(partial));
      final updatedMessages = await _repo.loadMessages(chat.id);
      final chats = await _repo.loadChats();
      final current = chats.firstWhere(
        (c) => c.id == chat.id,
        orElse: () => chat,
      );
      state = state.copyWith(
        chats: chats,
        currentChat: state.currentChat?.id == chat.id ? current : state.currentChat,
        messages: state.currentChat?.id == chat.id ? updatedMessages : state.messages,
        isSending: false,
        streamingText: '',
        sendingChatId: null,
        latestRagSourceNames: const [],
      );
      return;
    }

    state = state.copyWith(
      isSending: false,
      streamingText: '',
      sendingChatId: null,
      latestRagSourceNames: const [],
    );
  }

  Future<_AssistantResult> _generateAssistant({
    required Chat chat,
    required LLMProvider preferredProvider,
    required List<Message> messages,
  }) async {
    final resolvedConfig = _buildRuntimeConfig(
      chat,
      latestUserMessage: _latestUserMessage(messages),
    );
    final config = resolvedConfig.config;
    final attempts = _buildAttempts(chat, preferredProvider);

    String reply = '';
    String? usedProviderId;
    String? usedModelId;

    for (final attempt in attempts) {
      final candidateReply = await _requestReply(
        provider: attempt.provider,
        modelId: attempt.modelId,
        messages: messages,
        config: config,
        chatId: chat.id,
      );

      if (_cancelRequested) {
        state = state.copyWith(
          isSending: false,
          streamingText: '',
          sendingChatId: null,
        );
        return const _AssistantResult(
          reply: '',
          isError: false,
          usedProviderId: null,
          usedModelId: null,
        );
      }

      if (!_isProviderError(candidateReply)) {
        reply = candidateReply;
        usedProviderId = attempt.provider.id;
        usedModelId = attempt.modelId;
        break;
      }

      reply = candidateReply;
      state = state.copyWith(streamingText: '');
      if (!state.autoFallback || !_shouldAttemptFallback(candidateReply)) {
        break;
      }
    }

    final usedFallback =
        usedProviderId != null && usedProviderId != chat.providerId;
    final isError = _isProviderError(reply);
    final fallbackProviderId = usedProviderId;
    final fallbackModelId = usedModelId;
    final fallbackProviderLabel = fallbackProviderId == null
        ? ''
        : _safeProviderById(fallbackProviderId).label;

    final savedReply = usedFallback && !isError
        ? _strings.pick(
            it: 'Risposta generata con fallback $fallbackProviderLabel ($fallbackModelId).\n\n$reply',
            en: 'Reply generated with fallback $fallbackProviderLabel ($fallbackModelId).\n\n$reply',
          )
        : reply;

    await _repo.addMessage(
      chatId: chat.id,
      role: 'assistant',
      content: savedReply,
      isError: isError,
    );

    if (usedFallback) {
      await _repo.updateChatModel(
        chatId: chat.id,
        providerId: fallbackProviderId!,
        modelId: fallbackModelId!,
      );
    }

    final updatedMessages = await _repo.loadMessages(chat.id);
    final chats = await _loadNormalizedChats();
    final current = chats.firstWhere(
      (c) => c.id == chat.id,
      orElse: () => chat,
    );

    final isStillViewingSameChat = state.currentChat?.id == chat.id;
    state = state.copyWith(
      chats: chats,
      currentChat: isStillViewingSameChat ? current : state.currentChat,
      messages: isStillViewingSameChat ? updatedMessages : state.messages,
      isSending: false,
      streamingText: '',
      sendingChatId: null,
      latestRagSourceNames: isStillViewingSameChat && !isError
          ? resolvedConfig.ragSourceNames
          : const [],
      errorMessage: isStillViewingSameChat && isError ? savedReply : null,
      selectedProviderId: isStillViewingSameChat
          ? current.providerId
          : state.selectedProviderId,
      selectedModelId: isStillViewingSameChat
          ? current.modelId
          : state.selectedModelId,
      openCircuitProviders: _currentOpenCircuits(),
    );

    await _observability.logEvent(
      isError ? 'assistant_reply_failed' : 'assistant_reply_completed',
      parameters: {
        'provider_id': usedProviderId ?? chat.providerId,
        'model_id': usedModelId ?? chat.modelId,
        'used_fallback': usedFallback,
        'rag_sources': resolvedConfig.ragSourceNames.length,
      },
    );

    return _AssistantResult(
      reply: savedReply,
      isError: isError,
      usedProviderId: usedProviderId,
      usedModelId: usedModelId,
    );
  }

  Future<String> _requestReply({
    required LLMProvider provider,
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
    required String chatId,
  }) async {
    if (_isProviderCircuitOpen(provider.id)) {
      return _strings.pick(
        it: 'Errore ${provider.label}: circuito aperto temporaneamente.',
        en: 'Error ${provider.label}: circuit temporarily open.',
      );
    }

    const maxAttempts = 3;
    final stopwatch = Stopwatch()..start();
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final reply = await _requestReplyOnce(
          provider: provider,
          modelId: modelId,
          messages: messages,
          config: config,
          chatId: chatId,
        ).timeout(const Duration(seconds: 45));

        final cleaned = reply.trim();
        if (cleaned.isNotEmpty && !_isProviderError(cleaned)) {
          _recordProviderSuccess(provider.id, stopwatch.elapsedMilliseconds);
          return cleaned;
        }
        lastError = cleaned.isEmpty
            ? _strings.pick(it: 'Risposta vuota', en: 'Empty reply')
            : cleaned;
      } catch (e) {
        lastError = e;
      }

      if (attempt < maxAttempts) {
        final backoffMs = 300 * attempt * attempt;
        await Future.delayed(Duration(milliseconds: backoffMs));
      }
    }

    _recordProviderFailure(provider.id, stopwatch.elapsedMilliseconds);
    if (lastError is String &&
        (lastError.startsWith('Errore') || lastError.startsWith('Error'))) {
      return lastError;
    }
    return _strings.pick(
      it: 'Errore ${provider.label}: $lastError',
      en: 'Error ${provider.label}: $lastError',
    );
  }

  Future<String> _requestReplyOnce({
    required LLMProvider provider,
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
    required String chatId,
  }) async {
    if (provider.supportsStreaming) {
      final streamReply = await _collectStreamingReply(
        provider: provider,
        modelId: modelId,
        messages: messages,
        config: config,
        chatId: chatId,
      );
      if (streamReply.isNotEmpty) {
        return streamReply;
      }
    }

    return provider.sendMessage(
      modelId: modelId,
      messages: messages,
      config: config,
    );
  }

  Future<String> _collectStreamingReply({
    required LLMProvider provider,
    required String modelId,
    required List<Message> messages,
    required LLMRequestConfig config,
    required String chatId,
  }) async {
    final buffer = StringBuffer();

    await for (final chunk in provider.streamMessage(
      modelId: modelId,
      messages: messages,
      config: config,
    )) {
      if (_cancelRequested) break;
      buffer.write(chunk);
      if (state.currentChat?.id == chatId) {
        state = state.copyWith(streamingText: buffer.toString());
      }
    }

    if (_cancelRequested) return '';
    return buffer.toString().trim();
  }

  Future<String?> _generateTitleWithFallback({
    required LLMProvider preferredProvider,
    required String modelId,
    required String firstMessage,
    String? firstReply,
  }) async {
    if (state.preferOffline) {
      final localTitle = _deriveLocalTitle(
        firstMessage: firstMessage,
        firstReply: firstReply,
      );
      if (localTitle != null && localTitle.isNotEmpty) {
        return localTitle;
      }
      final offlineProvider = _offlineProvider();
      if (offlineProvider == null) return null;
      final offlineTitle = await offlineProvider.generateTitle(
        modelId: _firstModelIdFor(offlineProvider.id),
        firstMessage: _titleSeed(
          firstMessage: firstMessage,
          firstReply: firstReply,
        ),
      );
      if (offlineTitle != null && offlineTitle.trim().isNotEmpty) {
        return offlineTitle.trim();
      }
      return null;
    }

    Future<String?> safeGenerateTitle(
      LLMProvider provider,
      String candidateModelId,
    ) async {
      try {
        return await provider
            .generateTitle(
              modelId: candidateModelId,
              firstMessage: _titleSeed(
                firstMessage: firstMessage,
                firstReply: firstReply,
              ),
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        return null;
      }
    }

    final preferred = await safeGenerateTitle(
      preferredProvider,
      _titleModelIdFor(preferredProvider, modelId),
    );
    final normalizedPreferred = _normalizeGeneratedTitle(preferred);
    if (normalizedPreferred != null && normalizedPreferred.isNotEmpty) {
      return normalizedPreferred;
    }

    if (!state.autoFallback) return null;

    for (final provider in _registry.providers) {
      if (provider.id == preferredProvider.id) continue;
      final fallback = await safeGenerateTitle(
        provider,
        _firstModelIdFor(provider.id),
      );
      final normalizedFallback = _normalizeGeneratedTitle(fallback);
      if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
        return normalizedFallback;
      }
    }
    return _deriveLocalTitle(
      firstMessage: firstMessage,
      firstReply: firstReply,
    );
  }

  List<_ProviderAttempt> _buildAttempts(
    Chat chat,
    LLMProvider preferredProvider,
  ) {
    final attempts = <_ProviderAttempt>[];
    final seen = <String>{};

    void addProvider(LLMProvider provider, String modelId) {
      if (_isProviderCircuitOpen(provider.id)) return;
      if (seen.contains(provider.id)) return;
      seen.add(provider.id);
      attempts.add(_ProviderAttempt(provider, modelId));
    }

    if (state.preferOffline) {
      final offlineProvider = _offlineProvider();
      if (offlineProvider != null) {
        addProvider(offlineProvider, _firstModelIdFor(offlineProvider.id));
        return attempts;
      }
    }

    addProvider(preferredProvider, chat.modelId);

    if (!state.autoFallback) {
      return attempts;
    }

    for (final provider in _registry.providers) {
      addProvider(provider, _firstModelIdFor(provider.id));
    }

    return attempts;
  }

  Future<void> _maybeGenerateInitialTitle({
    required Chat chat,
    required LLMProvider preferredProvider,
    required String firstMessage,
    required String firstReply,
  }) async {
    final generated = await _generateTitleWithFallback(
      preferredProvider: preferredProvider,
      modelId: chat.modelId,
      firstMessage: firstMessage,
      firstReply: firstReply,
    );
    if (generated == null || generated.isEmpty) return;

    await _repo.updateChatTitle(chat.id, generated);
    await refreshChats();
  }

  String _titleSeed({
    required String firstMessage,
    String? firstReply,
  }) {
    final reply = (firstReply ?? '').trim();
    if (reply.isEmpty) {
      return 'Prima richiesta: $firstMessage';
    }
    return 'Prima richiesta: $firstMessage\nPrima risposta: $reply';
  }

  String _titleModelIdFor(LLMProvider provider, String currentModelId) {
    final models = state.providerModels[provider.id] ?? provider.models;
    final ids = models.map((model) => model.id).toList(growable: false);

    String? prefer(List<String> candidates) {
      for (final candidate in candidates) {
        if (ids.contains(candidate)) return candidate;
      }
      return null;
    }

    final preferred = switch (provider.id) {
      'groq' => prefer([
          'llama-3.3-70b-versatile',
          'qwen/qwen3-32b',
          'openai/gpt-oss-120b',
        ]),
      'openai' => prefer(['gpt-4o', 'gpt-4o-mini']),
      'proxy' => currentModelId,
      _ => null,
    };

    return preferred ?? currentModelId;
  }

  LLMProvider? _offlineProvider() {
    for (final provider in _registry.providers) {
      if (provider.id == 'ollama') {
        return provider;
      }
    }
    return null;
  }

  bool _isProviderError(String reply) {
    final trimmed = reply.trimLeft();
    return trimmed.startsWith('Errore') ||
        trimmed.startsWith('Error') ||
        trimmed.startsWith('Nessuna API key') ||
        trimmed.startsWith('No API key') ||
        trimmed.startsWith('Configura LLM_PROXY_URL') ||
        trimmed.startsWith('Configure LLM_PROXY_URL') ||
        trimmed.startsWith('Richiesta bloccata') ||
        trimmed.startsWith('Request blocked');
  }

  bool _shouldAttemptFallback(String reply) {
    final normalized = reply.toLowerCase();
    if (normalized.contains('errore di rete') ||
        normalized.contains('network error') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('connection refused') ||
        normalized.contains('connection reset') ||
        normalized.contains('timed out') ||
        normalized.contains('timeoutexception') ||
        normalized.contains('timeout')) {
      return false;
    }
    return true;
  }

  LLMProvider _safeProviderById(String id) {
    try {
      return _registry.byId(id);
    } catch (_) {
      return _registry.defaultProvider;
    }
  }

  Future<List<Chat>> _loadNormalizedChats() async {
    var chats = await _repo.loadChats();
    var changed = false;
    final fallbackProvider = _runtimeDefaultProvider();
    final fallbackProviderId = fallbackProvider.id;
    final fallbackModelId = _firstModelIdFor(fallbackProviderId);

    for (var i = 0; i < chats.length; i++) {
      final chat = chats[i];
      final normalized = _normalizeChatConfig(
        chat,
        fallbackProviderId: fallbackProviderId,
        fallbackModelId: fallbackModelId,
      );
      if (normalized.providerId != chat.providerId ||
          normalized.modelId != chat.modelId) {
        await _repo.updateChatModel(
          chatId: chat.id,
          providerId: normalized.providerId,
          modelId: normalized.modelId,
        );
        chats[i] = normalized;
        changed = true;
      }
    }

    if (changed) {
      chats = await _repo.loadChats();
    }
    return chats;
  }

  Chat _normalizeChatConfig(
    Chat chat, {
    required String fallbackProviderId,
    required String fallbackModelId,
  }) {
    var providerId = chat.providerId;
    var modelId = chat.modelId;

    LLMProvider provider;
    try {
      provider = _registry.byId(providerId);
    } catch (_) {
      providerId = fallbackProviderId;
      modelId = fallbackModelId;
      provider = _safeProviderById(providerId);
    }

    final models = state.providerModels[providerId] ?? provider.models;
    final hasValidModel = models.any((m) => m.id == modelId);
    if (!hasValidModel) {
      modelId = models.isNotEmpty ? models.first.id : fallbackModelId;
    }

    return chat.copyWith(providerId: providerId, modelId: modelId);
  }

  Future<Chat?> _chatById(String chatId) async {
    final chats = await _loadNormalizedChats();
    for (final chat in chats) {
      if (chat.id == chatId) return chat;
    }
    return null;
  }

  String? _normalizeGeneratedTitle(String? rawTitle) {
    if (rawTitle == null) return null;
    var title = rawTitle.trim();
    if (title.isEmpty) return null;

    title = title
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'^(titolo|title)\s*:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[.!?;:]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    title = title
        .replaceFirst(RegExp("^[\"'`]+"), '')
        .replaceFirst(RegExp("[\"'`]+\$"), '')
        .trim();

    if (title.isEmpty) return null;

    final words = title.split(' ');
    if (words.length > 5) {
      title = words.take(5).join(' ');
    }

    if (title.length > 50) {
      title = title.substring(0, 50).trimRight();
    }

    return title.isEmpty ? null : title;
  }

  String? _deriveLocalTitle({
    required String firstMessage,
    String? firstReply,
  }) {
    final normalizedPrompt = firstMessage
        .toLowerCase()
        .replaceAll(RegExp(r'https?://\S+'), ' ')
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final normalizedReply = (firstReply ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'https?://\S+'), ' ')
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalizedPrompt.isEmpty && normalizedReply.isEmpty) return null;

    const stopwords = {
      'a',
      'ad',
      'al',
      'alla',
      'alle',
      'anche',
      'che',
      'chi',
      'come',
      'con',
      'cosa',
      'da',
      'dal',
      'dalla',
      'del',
      'della',
      'delle',
      'di',
      'e',
      'ed',
      'fare',
      'for',
      'gli',
      'ho',
      'i',
      'il',
      'in',
      'io',
      'la',
      'le',
      'lo',
      'ma',
      'mi',
      'my',
      'nel',
      'nella',
      'no',
      'non',
      'of',
      'per',
      'puoi',
      'puo',
      'quale',
      'quali',
      'questo',
      'sei',
      'su',
      'the',
      'to',
      'un',
      'una',
      'uno',
      'vorrei',
      'dimmi',
      'parlami',
      'raccontami',
      'spiegami',
      'interessante',
      'qualcosa',
      'richiesta',
      'iniziale',
      'prima',
      'risposta',
      'fatto',
      'ecco',
      'curioso',
      'curiosa',
      'curiosita',
      'interessanti',
      'sorprendente',
      'sorprendenti',
    };

    String? extractTopic(String text) {
      if (text.isEmpty) return null;
      final words = text.split(' ');
      const anchors = {
        'su',
        'sul',
        'sulla',
        'sulle',
        'sui',
        'sugli',
        'del',
        'della',
        'delle',
        'dei',
        'degli',
        'nel',
        'nella',
        'nelle',
        'nei',
      };

      for (var i = 0; i < words.length; i++) {
        if (!anchors.contains(words[i])) continue;
        final topic = <String>[];
        for (var j = i + 1; j < words.length && topic.length < 3; j++) {
          final word = words[j];
          if (word.length <= 2 || stopwords.contains(word)) continue;
          topic.add(word);
        }
        if (topic.isNotEmpty) {
          return topic
              .map((token) => '${token[0].toUpperCase()}${token.substring(1)}')
              .join(' ');
        }
      }
      return null;
    }

    final replyTopic = extractTopic(normalizedReply);
    if (replyTopic != null && replyTopic.isNotEmpty) {
      return _normalizeGeneratedTitle('Curiosita su $replyTopic');
    }

    final promptTokens = normalizedPrompt
        .split(' ')
        .where((token) => token.length > 2 && !stopwords.contains(token))
        .take(5)
        .toList();

    final replyTokens = normalizedReply
        .split(' ')
        .where((token) => token.length > 3 && !stopwords.contains(token))
        .take(8)
        .toList();

    final tokens = <String>[
      ...replyTokens.take(3),
      ...promptTokens.where((token) => !replyTokens.contains(token)).take(2),
    ];

    if (tokens.isEmpty) return null;

    final title = tokens
        .map((token) => '${token[0].toUpperCase()}${token.substring(1)}')
        .join(' ');

    return _normalizeGeneratedTitle(title);
  }

  Future<void> _persistDefaultSettings({
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    required double topP,
  }) async {
    await _repo.setAppState(_systemPromptKey, systemPrompt);
    await _repo.setAppState(_temperatureKey, temperature.toString());
    await _repo.setAppState(_maxTokensKey, maxTokens.toString());
    await _repo.setAppState(_topPKey, topP.toString());
  }

  Future<void> _refreshDailyUsage() async {
    final usage = await _loadDailyUsage();
    state = state.copyWith(
      dailyTokensUsed: usage,
      nextAdTriggerTokens: _parseInt(
        await _repo.getAppState(_nextAdTriggerKey),
        fallback: state.nextAdTriggerTokens,
      ),
      estimatedCostUsd: estimateUsdFromTokens(usage),
    );
  }

  Future<int> _loadDailyUsage() async {
    final today = _todayKey();
    final savedDate = await _repo.getAppState(_dailyUsageDateKey);

    if (savedDate != today) {
      await _repo.setAppState(_dailyUsageDateKey, today);
      await _repo.setAppState(_dailyUsageTokensKey, '0');
      await _repo.setAppState(
        _nextAdTriggerKey,
        _runtimeConfig.adTriggerStep.toString(),
      );
      return 0;
    }

    final tokensRaw = await _repo.getAppState(_dailyUsageTokensKey);
    return _parseInt(tokensRaw, fallback: 0);
  }

  Future<void> _consumeEstimatedTokens(int tokens) async {
    if (tokens <= 0) return;

    final currentUsage = await _loadDailyUsage();
    final updatedUsage = currentUsage + tokens;
    final shouldOfferRewardedAd =
        _runtimeConfig.adsEnabled &&
        state.adsConsent &&
        !state.isPremium &&
        updatedUsage >= state.nextAdTriggerTokens;
    final nextTrigger = shouldOfferRewardedAd
        ? updatedUsage + _runtimeConfig.adTriggerStep
        : state.nextAdTriggerTokens;

    await _repo.setAppState(_dailyUsageTokensKey, updatedUsage.toString());
    if (shouldOfferRewardedAd) {
      await _repo.setAppState(_nextAdTriggerKey, nextTrigger.toString());
    }
    state = state.copyWith(
      dailyTokensUsed: updatedUsage,
      nextAdTriggerTokens: nextTrigger,
      shouldOfferRewardedAd: shouldOfferRewardedAd,
      estimatedCostUsd: estimateUsdFromTokens(updatedUsage),
    );
  }

  Future<void> _extractAndPersistMemory(String userMessage) async {
    if (!state.longTermMemoryEnabled) return;

    final extracted = _extractMemoryNote(userMessage);
    if (extracted == null) return;

    final serialized = extracted.serialize();
    final notes = <String>[
      for (final item in state.memoryNotes) _normalizeMemoryStorage(item),
    ];
    if (!notes.contains(serialized)) {
      notes.add(serialized);
    }

    if (notes.length > 20) {
      notes.removeAt(0);
    }

    await _repo.setAppState(_memoryNotesKey, jsonEncode(notes));
    state = state.copyWith(memoryNotes: notes);
  }

  MemoryEntry? _extractMemoryNote(String message) {
    final cleaned = message.trim();
    final lower = cleaned.toLowerCase();

    if (lower.contains('mi chiamo ') ||
        lower.contains('sono ') ||
        lower.contains('il mio lavoro') ||
        lower.contains('lavoro come ')) {
      return MemoryEntry(category: MemoryCategory.profile, content: cleaned);
    }
    if (lower.contains('preferisco ') ||
        lower.contains('mi piace ') ||
        lower.contains('di solito uso ') ||
        lower.contains('lingua preferita')) {
      return MemoryEntry(category: MemoryCategory.preference, content: cleaned);
    }
    if (lower.contains('non posso ') ||
        lower.contains('sono allergico') ||
        lower.contains('evita ') ||
        lower.contains('non voglio ')) {
      return MemoryEntry(category: MemoryCategory.constraint, content: cleaned);
    }
    if (lower.contains('il mio obiettivo') ||
        lower.contains('voglio ') ||
        lower.contains('devo ') ||
        lower.contains('sto cercando di ')) {
      return MemoryEntry(category: MemoryCategory.goal, content: cleaned);
    }
    return null;
  }

  _ResolvedRuntimeConfig _buildRuntimeConfig(
    Chat chat, {
    String? latestUserMessage,
  }) {
    var prompt = chat.systemPrompt;
    var ragSourceNames = const <String>[];

    if (state.longTermMemoryEnabled && state.memoryNotes.isNotEmpty) {
      final memory = state.memoryNotes
          .map((item) => MemoryEntry.parse(_normalizeMemoryStorage(item)))
          .map(
            (entry) =>
                '- [${entry.category.label(state.preferredLanguageCode)}] ${entry.content}',
          )
          .join('\n');
      prompt =
          '$prompt\n\n${_strings.pick(it: 'Memoria utente (usa solo se rilevante):', en: 'User memory (use only when relevant):')}\n$memory';
    }

    if (state.ragEnabled &&
        latestUserMessage != null &&
        latestUserMessage.trim().isNotEmpty &&
        state.ragDocuments.isNotEmpty) {
      final retrieval = _localRag.retrieve(
        query: latestUserMessage,
        documents: state.ragDocuments,
      );
      if (retrieval.context.isNotEmpty) {
        ragSourceNames = retrieval.sourceNames;
        prompt =
            '$prompt\n\n${_strings.pick(it: 'Contesto da documenti locali (usa solo se rilevante):', en: 'Context from local documents (use only if relevant):')}\n${retrieval.context}';
      }
    }

    prompt =
        '$prompt\n\n${_strings.pick(it: 'Rispondi sempre in ${_strings.languageLabel(state.preferredLanguageCode)}.', en: 'Always reply in ${_strings.modelLanguageName(state.preferredLanguageCode)}.')}';

    return _ResolvedRuntimeConfig(
      config: LLMRequestConfig(
        systemPrompt: prompt,
        temperature: chat.temperature,
        maxTokens: chat.maxTokens,
        topP: chat.topP,
      ),
      ragSourceNames: ragSourceNames,
    );
  }

  Future<void> _savePromptPresets(List<PromptPreset> presets) async {
    final payload = presets.map((p) => p.toJson()).toList();
    await _repo.setAppState(_promptPresetsKey, jsonEncode(payload));
  }

  Future<void> _saveRagDocuments(List<RagDocument> documents) async {
    final payload = documents.map((doc) => doc.toJson()).toList();
    await _repo.setAppState(_ragDocumentsKey, jsonEncode(payload));
  }

  String _normalizeMemoryStorage(String raw) {
    final parsed = MemoryEntry.parse(raw);
    return parsed.serialize();
  }

  List<String> _dietProfileSections(DietProfile profile) {
    return [
      if (profile.goal.trim().isNotEmpty) 'Obiettivo: ${profile.goal.trim()}',
      if (profile.age.trim().isNotEmpty || profile.sex.trim().isNotEmpty)
        'Dati base: ${[
          if (profile.age.trim().isNotEmpty) 'eta ${profile.age.trim()}',
          if (profile.sex.trim().isNotEmpty) 'sesso ${profile.sex.trim()}',
        ].join(', ')}',
      if (profile.heightCm.trim().isNotEmpty || profile.weightKg.trim().isNotEmpty)
        'Misure: ${[
          if (profile.heightCm.trim().isNotEmpty) 'altezza ${profile.heightCm.trim()} cm',
          if (profile.weightKg.trim().isNotEmpty) 'peso ${profile.weightKg.trim()} kg',
        ].join(', ')}',
      if (profile.activityLevel.trim().isNotEmpty)
        'Attivita: ${profile.activityLevel.trim()}',
      if (profile.dietStyle.trim().isNotEmpty)
        'Stile alimentare: ${profile.dietStyle.trim()}',
      if (profile.constraints.trim().isNotEmpty)
        'Vincoli: ${profile.constraints.trim()}',
      if (profile.foodsToAvoid.trim().isNotEmpty)
        'Cibi da evitare: ${profile.foodsToAvoid.trim()}',
      if (profile.mealRoutine.trim().isNotEmpty)
        'Routine pasti: ${profile.mealRoutine.trim()}',
      if (profile.budget.trim().isNotEmpty) 'Budget: ${profile.budget.trim()}',
      if (profile.cookingSetup.trim().isNotEmpty)
        'Cucina disponibile: ${profile.cookingSetup.trim()}',
      if (profile.notes.trim().isNotEmpty)
        'Note operative: ${profile.notes.trim()}',
    ];
  }

  List<String> _medicalProfileSections(MedicalProfile profile) {
    return [
      if (profile.primaryQuestion.trim().isNotEmpty)
        'Richiesta principale: ${profile.primaryQuestion.trim()}',
      if (profile.age.trim().isNotEmpty || profile.sex.trim().isNotEmpty)
        'Dati base: ${[
          if (profile.age.trim().isNotEmpty) 'eta ${profile.age.trim()}',
          if (profile.sex.trim().isNotEmpty) 'sesso ${profile.sex.trim()}',
        ].join(', ')}',
      if (profile.symptoms.trim().isNotEmpty)
        'Sintomi o tema: ${profile.symptoms.trim()}',
      if (profile.duration.trim().isNotEmpty)
        'Durata o decorso: ${profile.duration.trim()}',
      if (profile.conditions.trim().isNotEmpty)
        'Patologie o condizioni note: ${profile.conditions.trim()}',
      if (profile.medications.trim().isNotEmpty)
        'Farmaci o integratori: ${profile.medications.trim()}',
      if (profile.allergies.trim().isNotEmpty)
        'Allergie o intolleranze: ${profile.allergies.trim()}',
      if (profile.context.trim().isNotEmpty)
        'Contesto pratico: ${profile.context.trim()}',
      if (profile.notes.trim().isNotEmpty)
        'Note aggiuntive: ${profile.notes.trim()}',
    ];
  }

  List<String> _legalProfileSections(LegalProfile profile) {
    return [
      if (profile.primaryQuestion.trim().isNotEmpty)
        'Richiesta principale: ${profile.primaryQuestion.trim()}',
      if (profile.topic.trim().isNotEmpty) 'Area legale: ${profile.topic.trim()}',
      if (profile.jurisdiction.trim().isNotEmpty)
        'Paese o giurisdizione: ${profile.jurisdiction.trim()}',
      if (profile.userRole.trim().isNotEmpty)
        'Ruolo dell\'utente: ${profile.userRole.trim()}',
      if (profile.scenario.trim().isNotEmpty)
        'Scenario o fatti: ${profile.scenario.trim()}',
      if (profile.documentsAvailable.trim().isNotEmpty)
        'Documenti disponibili: ${profile.documentsAvailable.trim()}',
      if (profile.deadlines.trim().isNotEmpty)
        'Scadenze o urgenze: ${profile.deadlines.trim()}',
      if (profile.goal.trim().isNotEmpty) 'Obiettivo: ${profile.goal.trim()}',
      if (profile.notes.trim().isNotEmpty)
        'Note aggiuntive: ${profile.notes.trim()}',
    ];
  }

  String _buildDietAgentPrompt(List<String> sections) {
    final profileBlock = sections.isEmpty
        ? 'Nessun profilo strutturato fornito.'
        : sections.map((item) => '- $item').join('\n');
    return '''
Sei Mimir Diet Agent, un assistente nutrizionale pratico e prudente.

Obiettivo:
- aiutare l'utente con organizzazione alimentare, idee pasti, struttura giornaliera, lista spesa e aderenza pratica
- fare domande chiarificatrici se mancano dati importanti
- restare concreto, sintetico e operativo

Vincoli:
- non presentarti come medico
- non fare diagnosi
- se emergono temi clinici, patologici o farmacologici invita a confrontarsi con un professionista
- rispetta sempre preferenze, allergie, intolleranze, restrizioni e cibi da evitare

Stile risposta:
- prima chiarisci l'obiettivo reale
- poi proponi un piano semplice e realistico
- usa sezioni brevi
- evita teoria inutile
- se utile, produci: menu giornaliero, alternative, lista spesa, consigli di aderenza
- quando l'utente chiede un piano o un menu, prova a rispondere con questo formato:
  1. Obiettivo
  2. Piano proposto
  3. Alternative rapide
  4. Lista spesa
  5. Prossimo passo

Profilo utente per questo agente:
$profileBlock
''';
  }

  String _buildMedicalAgentPrompt(List<String> sections) {
    final profileBlock = sections.isEmpty
        ? 'Nessun profilo medico strutturato fornito.'
        : sections.map((item) => '- $item').join('\n');
    return '''
Sei Mimir Medico di Base, un assistente informativo sanitario prudente.

Obiettivo:
- aiutare l'utente a capire meglio sintomi, domande mediche comuni, possibili scenari da discutere con un medico e prossimi passi ragionevoli
- distinguere ciò che sembra benigno da ciò che merita attenzione professionale
- organizzare le informazioni in modo chiaro e non allarmistico

Vincoli non negoziabili:
- non sei un medico reale
- non fai diagnosi
- non prescrivi farmaci o dosaggi
- dichiara chiaramente che le informazioni sono generali e non sostituiscono un professionista sanitario
- se emergono red flags, invita subito a sentire medico, guardia medica o pronto soccorso a seconda della gravita

Stile risposta:
- apri con un breve disclaimer se la richiesta tocca salute reale
- poi dai una lettura prudente e strutturata
- usa sezioni brevi
- se utile usa questo formato:
  1. Cosa potrebbe significare in generale
  2. Cose da monitorare
  3. Quando sentire un medico
  4. Cosa preparare o chiedere alla visita

Profilo utente per questo agente:
$profileBlock
''';
  }

  String _buildLegalAgentPrompt(List<String> sections) {
    final profileBlock = sections.isEmpty
        ? 'Nessun profilo legale strutturato fornito.'
        : sections.map((item) => '- $item').join('\n');
    return '''
Sei Mimir Avvocato, un assistente informativo legale prudente e operativo.

Obiettivo:
- aiutare l'utente a capire in termini generali il problema legale
- organizzare fatti, opzioni, documenti utili e prossimi passi
- rendere piu chiaro cosa chiedere poi a un professionista vero

Vincoli non negoziabili:
- non sei un avvocato reale
- non stai fornendo consulenza legale professionale
- dichiara chiaramente che le informazioni sono generali e a scopo informativo
- se il caso dipende da giurisdizione, atti formali, termini o rischio elevato, invita a sentire un professionista qualificato

Stile risposta:
- apri con un breve disclaimer se la richiesta tocca un caso reale
- poi organizza il ragionamento in modo operativo
- usa sezioni brevi
- se utile usa questo formato:
  1. Inquadramento generale
  2. Punti critici
  3. Documenti o prove utili
  4. Prossimi passi
  5. Quando rivolgersi a un avvocato

Profilo utente per questo agente:
$profileBlock
''';
  }

  String _buildDietAgentWelcome(List<String> sections) {
    final summary = sections.isEmpty
        ? 'Profilo ancora vuoto.'
        : sections.map((item) => '- $item').join('\n');
    return '''
Agente dieta pronto.

Profilo letto:
$summary

Puoi chiedermi da subito cose come:
- giornata alimentare semplice
- menu per 3-7 giorni
- lista spesa coerente con i tuoi vincoli
- alternative per colazione, pranzo o cena
- piano pasti compatibile con lavoro/allenamento
''';
  }

  String _buildMedicalAgentWelcome(List<String> sections) {
    final summary = sections.isEmpty
        ? 'Profilo ancora vuoto.'
        : sections.map((item) => '- $item').join('\n');
    return '''
Medico di base pronto.

Nota importante:
Questa chat fornisce solo informazioni generali e non sostituisce un medico reale.

Profilo letto:
$summary

Puoi chiedermi da subito cose come:
- aiutami a capire questi sintomi in modo generale
- quali segnali dovrei monitorare
- come prepararmi a una visita
- quali domande fare al medico
''';
  }

  String _buildLegalAgentWelcome(List<String> sections) {
    final summary = sections.isEmpty
        ? 'Profilo ancora vuoto.'
        : sections.map((item) => '- $item').join('\n');
    return '''
Avvocato pronto.

Nota importante:
Questa chat fornisce solo informazioni generali e non sostituisce un avvocato reale.

Profilo letto:
$summary

Puoi chiedermi da subito cose come:
- aiutami a capire il problema in termini generali
- che documenti dovrei raccogliere
- quali prossimi passi sono ragionevoli
- come preparare le domande per un professionista
''';
  }

  DietProfile _parseDietProfile(String? raw) {
    if (raw == null || raw.trim().isEmpty) return DietProfile.empty;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) return DietProfile.empty;
      return DietProfile.fromJson(parsed);
    } catch (_) {
      return DietProfile.empty;
    }
  }

  MedicalProfile _parseMedicalProfile(String? raw) {
    if (raw == null || raw.trim().isEmpty) return MedicalProfile.empty;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) return MedicalProfile.empty;
      return MedicalProfile.fromJson(parsed);
    } catch (_) {
      return MedicalProfile.empty;
    }
  }

  LegalProfile _parseLegalProfile(String? raw) {
    if (raw == null || raw.trim().isEmpty) return LegalProfile.empty;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) return LegalProfile.empty;
      return LegalProfile.fromJson(parsed);
    } catch (_) {
      return LegalProfile.empty;
    }
  }

  List<PromptPreset> _parsePromptPresets(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed
          .whereType<Map<String, dynamic>>()
          .map(PromptPreset.fromJson)
          .where((preset) => preset.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<String> _parseStringList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<RagDocument> _parseRagDocuments(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return parsed
          .whereType<Map<String, dynamic>>()
          .map(RagDocument.fromJson)
          .where((doc) => doc.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<String> _resolveOnboardingVariant() async {
    final stored = await _repo.getAppState(_onboardingVariantKey);
    if (stored == 'A' || stored == 'B') return stored!;

    final variant = DateTime.now().microsecond.isEven ? 'A' : 'B';
    await _repo.setAppState(_onboardingVariantKey, variant);
    return variant;
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  String _latestUserMessage(List<Message> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == 'user') {
        return messages[i].content;
      }
    }
    return '';
  }

  int _parseInt(String? value, {required int fallback}) {
    if (value == null) return fallback;
    return int.tryParse(value) ?? fallback;
  }

  double _parseDouble(String? value, {required double fallback}) {
    if (value == null) return fallback;
    return double.tryParse(value) ?? fallback;
  }

  bool _parseBool(String? value, {required bool fallback}) {
    if (value == null) return fallback;
    final lower = value.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    return fallback;
  }

  bool _isUntitledChat(String title) {
    return title == AppStrings.ofCode('it').newChat ||
        title == AppStrings.ofCode('en').newChat;
  }

  int _dailyLimitForPremium(bool enabled) {
    return enabled
        ? _runtimeConfig.premiumDailyTokenLimit
        : _runtimeConfig.baseDailyTokenLimit;
  }

  String _normalizeLanguageCode(String code) {
    return AppStrings.supportedLanguageCodes.contains(code) ? code : 'it';
  }

  static String _deviceLanguageCode() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode;
    return AppStrings.supportedLanguageCodes.contains(code) ? code : 'it';
  }

  static LLMProvider _initialDefaultProvider(
    LLMRegistry registry,
    AppRuntimeConfig runtimeConfig,
  ) {
    final configuredId = runtimeConfig.defaultProviderId.trim();
    for (final provider in registry.providers) {
      if (provider.id == configuredId) {
        return provider;
      }
    }
    return registry.defaultProvider;
  }

  LLMProvider _runtimeDefaultProvider() {
    return _initialDefaultProvider(_registry, _runtimeConfig);
  }

  AppStrings get _strings => AppStrings.ofCode(state.preferredLanguageCode);

  String _firstModelIdFor(String providerId) {
    final loaded = state.providerModels[providerId];
    if (loaded != null && loaded.isNotEmpty) {
      return loaded.first.id;
    }

    final provider = _safeProviderById(providerId);
    if (provider.models.isEmpty) return 'default';
    return provider.models.first.id;
  }

  void _recordProviderSuccess(String providerId, int latencyMs) {
    _providerFailureCounts[providerId] = 0;
    _providerBlockedUntil.remove(providerId);
    // ignore: discarded_futures
    _incrementMetrics(success: true, latencyMs: latencyMs);
    // ignore: discarded_futures
    _observability.recordProviderResult(
      providerId: providerId,
      success: true,
      latencyMs: latencyMs,
    );
  }

  void _recordProviderFailure(String providerId, int latencyMs) {
    final current = _providerFailureCounts[providerId] ?? 0;
    final next = current + 1;
    _providerFailureCounts[providerId] = next;

    if (next >= 3) {
      _providerBlockedUntil[providerId] = DateTime.now().add(
        const Duration(minutes: 2),
      );
    }

    // ignore: discarded_futures
    _incrementMetrics(success: false, latencyMs: latencyMs);
    // ignore: discarded_futures
    _observability.recordProviderResult(
      providerId: providerId,
      success: false,
      latencyMs: latencyMs,
    );
    state = state.copyWith(openCircuitProviders: _currentOpenCircuits());
  }

  bool _isProviderCircuitOpen(String providerId) {
    final until = _providerBlockedUntil[providerId];
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _providerBlockedUntil.remove(providerId);
      _providerFailureCounts[providerId] = 0;
      return false;
    }
    return true;
  }

  List<String> _currentOpenCircuits() {
    final now = DateTime.now();
    final open = <String>[];
    for (final entry in _providerBlockedUntil.entries) {
      if (entry.value.isAfter(now)) {
        open.add(entry.key);
      }
    }
    return open;
  }

  Future<void> _incrementMetrics({
    required bool success,
    required int latencyMs,
  }) async {
    final currentSuccess = state.successRequests;
    final currentFailed = state.failedRequests;
    final currentTotalLatency = currentSuccess * state.averageLatencyMs;

    final nextSuccess = success ? currentSuccess + 1 : currentSuccess;
    final nextFailed = success ? currentFailed : currentFailed + 1;
    final nextTotalLatency = success
        ? (currentTotalLatency + latencyMs.toDouble())
        : currentTotalLatency;
    final nextAvg = nextSuccess == 0 ? 0.0 : nextTotalLatency / nextSuccess;

    state = state.copyWith(
      successRequests: nextSuccess,
      failedRequests: nextFailed,
      averageLatencyMs: nextAvg,
    );

    await _repo.setAppState(_metricsSuccessKey, nextSuccess.toString());
    await _repo.setAppState(_metricsFailedKey, nextFailed.toString());
    await _repo.setAppState(
      _metricsLatencyTotalKey,
      nextTotalLatency.toString(),
    );
  }
}

class _ResolvedRuntimeConfig {
  const _ResolvedRuntimeConfig({
    required this.config,
    required this.ragSourceNames,
  });

  final LLMRequestConfig config;
  final List<String> ragSourceNames;
}

class _ProviderAttempt {
  const _ProviderAttempt(this.provider, this.modelId);

  final LLMProvider provider;
  final String modelId;
}

class _AssistantResult {
  const _AssistantResult({
    required this.reply,
    required this.isError,
    required this.usedProviderId,
    required this.usedModelId,
  });

  final String reply;
  final bool isError;
  final String? usedProviderId;
  final String? usedModelId;
}
