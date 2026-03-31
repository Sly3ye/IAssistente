import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../controllers/chat_controller.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../services/llm_provider.dart';
import '../widgets/chat_drawer.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_list.dart';
import '../widgets/monetization_banner.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController inputController = TextEditingController();
  final FocusNode inputFocus = FocusNode();

  late final stt.SpeechToText _speech;
  late final FlutterTts _tts;
  bool _isListening = false;
  bool _speechReady = false;
  bool _onboardingShown = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final runtimeConfig = ref.read(appRuntimeConfigProvider);
      ref
          .read(monetizationServiceProvider)
          .initialize(
            premiumEnabled: ref.read(chatControllerProvider).isPremium,
            adsEnabled:
                runtimeConfig.adsEnabled &&
                ref.read(chatControllerProvider).adsConsent,
          );
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    inputController.dispose();
    inputFocus.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> send() async {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    inputController.clear();
    await ref.read(chatControllerProvider.notifier).sendMessage(text);
    inputFocus.requestFocus();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleMic() async {
    final strings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
    if (!_speechReady) {
      _speechReady = await _speech.initialize();
      if (!_speechReady) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.localTimeUnavailable)));
        return;
      }
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        final spoken = result.recognizedWords.trim();
        if (spoken.isEmpty) return;
        setState(() {
          final current = inputController.text.trim();
          inputController.text = current.isEmpty ? spoken : '$current $spoken';
          inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: inputController.text.length),
          );
        });
      },
      onSoundLevelChange: (_) {},
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );

    Future<void>.delayed(const Duration(seconds: 12), () async {
      if (!_isListening) return;
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    });
  }

  Future<void> _pickAttachment() async {
    final chatState = ref.read(chatControllerProvider);
    final strings = AppStrings.ofCode(chatState.preferredLanguageCode);
    final controller = ref.read(chatControllerProvider.notifier);
    final extractor = ref.read(attachmentExtractionServiceProvider);
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: [
        'txt',
        'md',
        'json',
        'csv',
        'yaml',
        'yml',
        'pdf',
        'png',
        'jpg',
        'jpeg',
        'webp',
        'bmp',
      ],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final ext = (file.extension ?? '').toLowerCase();

    final extraction = await extractor.extractTextFromFile(
      fileName: file.name,
      filePath: file.path,
      bytes: file.bytes,
    );

    String attachmentPrompt;
    final extractedText = extraction.text.trim();
    if (extractedText.isNotEmpty) {
      var truncated = extractedText;
      if (truncated.length > 5000) {
        truncated = '${truncated.substring(0, 5000)}\n...[truncated]';
      }
      attachmentPrompt = strings.analyzeAttachment(file.name, truncated);

      if (chatState.ragEnabled) {
        await controller.upsertRagDocument(
          documentName: file.name,
          text: extractedText,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.ragIndexed(file.name))));
      }
    } else if (ext == 'pdf') {
      attachmentPrompt = strings.pdfManualFallback(file.name);
    } else if (ext == 'png' ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'webp' ||
        ext == 'bmp') {
      attachmentPrompt = strings.imageManualFallback(file.name);
    } else if (ext == 'txt' ||
        ext == 'md' ||
        ext == 'json' ||
        ext == 'csv' ||
        ext == 'yaml' ||
        ext == 'yml') {
      attachmentPrompt = strings.emptyTextAttachment(file.name);
    } else {
      attachmentPrompt = strings.attachmentType(file.name, ext);
    }

    final current = inputController.text.trim();
    inputController.text = current.isEmpty
        ? attachmentPrompt
        : '$current\n\n$attachmentPrompt';
    inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: inputController.text.length),
    );
    inputFocus.requestFocus();
  }

  Future<void> _speakLastAssistant(ChatState state) async {
    String? text;
    for (var i = state.messages.length - 1; i >= 0; i--) {
      final message = state.messages[i];
      if (message.role == 'assistant' && message.content.trim().isNotEmpty) {
        text = message.content;
        break;
      }
    }
    if (text == null) return;

    await _tts.stop();
    await _tts.setLanguage(
      state.preferredLanguageCode == 'en' ? 'en-US' : 'it-IT',
    );
    await _tts.setSpeechRate(0.46);
    await _tts.speak(text);
  }

  void _showModelPicker(
    BuildContext context,
    LLMRegistry registry,
    ChatState state,
  ) {
    final controller = ref.read(chatControllerProvider.notifier);
    final strings = AppStrings.ofCode(state.preferredLanguageCode);

    var providerId = state.selectedProviderId;
    var modelId = state.selectedModelId;
    var systemPrompt = state.selectedSystemPrompt;
    var temperature = state.selectedTemperature;
    var maxTokens = state.selectedMaxTokens;
    var topP = state.selectedTopP;
    var autoFallback = state.autoFallback;
    var strictSafety = state.strictSafety;
    var preferOffline = state.preferOffline;
    var memoryEnabled = state.longTermMemoryEnabled;
    var ragEnabled = state.ragEnabled;
    var analyticsConsent = state.analyticsConsent;
    var adsConsent = state.adsConsent;

    final promptController = TextEditingController(
      text: state.selectedSystemPrompt,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedProvider = _safeProvider(registry, providerId);
            final liveState = ref.read(chatControllerProvider);
            final models =
                liveState.providerModels[providerId] ?? selectedProvider.models;

            if (models.isNotEmpty && !models.any((m) => m.id == modelId)) {
              modelId = models.first.id;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.chooseModel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: registry.providers.map((provider) {
                        final isSelected = provider.id == providerId;
                        return ChoiceChip(
                          label: Text(provider.label),
                          selected: isSelected,
                          onSelected: (_) async {
                            final providerModels =
                                liveState.providerModels[provider.id] ??
                                provider.models;
                            final firstModel = providerModels.isEmpty
                                ? provider.models.first.id
                                : providerModels.first.id;
                            await controller.updateCurrentChatModel(
                              providerId: provider.id,
                              modelId: firstModel,
                            );
                            await controller.updateDefaultModel(
                              providerId: provider.id,
                              modelId: firstModel,
                            );
                            setModalState(() {
                              providerId = provider.id;
                              modelId = firstModel;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.providerModels(selectedProvider.label),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await controller.refreshProviderModels(providerId);
                            if (!mounted) return;
                            final refreshed = ref.read(chatControllerProvider);
                            final refreshedModels =
                                refreshed.providerModels[providerId] ??
                                selectedProvider.models;
                            if (refreshedModels.isNotEmpty) {
                              setModalState(() {
                                modelId = refreshedModels.first.id;
                              });
                            }
                          },
                          icon: const Icon(Icons.sync, size: 16),
                          label: Text(strings.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: models.map((model) {
                        final isSelected = model.id == modelId;
                        return ChoiceChip(
                          label: Text(model.label),
                          selected: isSelected,
                          onSelected: (_) async {
                            await controller.updateCurrentChatModel(
                              providerId: selectedProvider.id,
                              modelId: model.id,
                            );
                            await controller.updateDefaultModel(
                              providerId: selectedProvider.id,
                              modelId: model.id,
                            );
                            setModalState(() {
                              modelId = model.id;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.promptPresets,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final name = await _askPresetName(context);
                            if (name == null || name.trim().isEmpty) return;
                            await controller.addPromptPreset(name: name);
                            if (mounted) {
                              setModalState(() {});
                            }
                          },
                          icon: const Icon(
                            Icons.bookmark_add_outlined,
                            size: 16,
                          ),
                          label: Text(strings.save),
                        ),
                      ],
                    ),
                    if (liveState.promptPresets.isEmpty)
                      Text(
                        strings.noSavedPresets,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (liveState.promptPresets.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: liveState.promptPresets.map((preset) {
                          return InputChip(
                            label: Text(preset.name),
                            onPressed: () async {
                              await controller.applyPromptPreset(preset.id);
                              final latest = ref.read(chatControllerProvider);
                              setModalState(() {
                                systemPrompt = latest.selectedSystemPrompt;
                                temperature = latest.selectedTemperature;
                                maxTokens = latest.selectedMaxTokens;
                                topP = latest.selectedTopP;
                                promptController.text = systemPrompt;
                              });
                            },
                            onDeleted: () =>
                                controller.deletePromptPreset(preset.id),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      strings.systemPrompt,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: promptController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: strings.systemPromptHint,
                      ),
                      onChanged: (value) => systemPrompt = value,
                    ),
                    const SizedBox(height: 12),
                    Text(strings.temperatureLabel(temperature)),
                    Slider(
                      value: temperature,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      onChanged: (value) {
                        setModalState(() => temperature = value);
                      },
                    ),
                    Text(strings.topPLabel(topP)),
                    Slider(
                      value: topP,
                      min: 0.1,
                      max: 1,
                      divisions: 18,
                      onChanged: (value) {
                        setModalState(() => topP = value);
                      },
                    ),
                    Text(strings.maxTokensLabel(maxTokens)),
                    Slider(
                      value: maxTokens.toDouble(),
                      min: 128,
                      max: 4096,
                      divisions: 62,
                      onChanged: (value) {
                        setModalState(() => maxTokens = value.round());
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.autoFallback),
                      value: autoFallback,
                      onChanged: (value) {
                        setModalState(() => autoFallback = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.inputSafety),
                      value: strictSafety,
                      onChanged: (value) {
                        setModalState(() => strictSafety = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.preferOffline),
                      value: preferOffline,
                      onChanged: (value) {
                        setModalState(() => preferOffline = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.longTermMemory),
                      value: memoryEnabled,
                      onChanged: (value) {
                        setModalState(() => memoryEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.localRag),
                      subtitle: Text(
                        strings.ragDocumentsLabel(
                          liveState.ragDocuments.length,
                        ),
                      ),
                      value: ragEnabled,
                      onChanged: (value) {
                        setModalState(() => ragEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.analyticsConsent),
                      value: analyticsConsent,
                      onChanged: (value) {
                        setModalState(() => analyticsConsent = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.adsConsent),
                      value: adsConsent,
                      onChanged: (value) {
                        setModalState(() => adsConsent = value);
                      },
                    ),
                    if (liveState.openCircuitProviders.isNotEmpty)
                      Text(
                        strings.circuitBreakerActive(
                          liveState.openCircuitProviders,
                        ),
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await controller.updateCurrentChatSettings(
                            systemPrompt: systemPrompt,
                            temperature: temperature,
                            maxTokens: maxTokens,
                            topP: topP,
                          );
                          await controller.setAutoFallback(autoFallback);
                          await controller.setStrictSafety(strictSafety);
                          await controller.setPreferOffline(preferOffline);
                          await controller.setLongTermMemory(memoryEnabled);
                          await controller.setRagEnabled(ragEnabled);
                          await controller.setAnalyticsConsent(
                            analyticsConsent,
                          );
                          await controller.setAdsConsent(adsConsent);
                          await ref
                              .read(monetizationServiceProvider)
                              .updateAdsConsent(
                                ref.read(appRuntimeConfigProvider).adsEnabled &&
                                    adsConsent,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(strings.saveSettings),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(promptController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final registry = ref.watch(llmRegistryProvider);
    ref.watch(monetizationServiceProvider);
    final strings = AppStrings.ofCode(state.preferredLanguageCode);

    ref.listen<ChatState>(chatControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        scrollToBottom();
      }
      if (prev?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
      if (next.shouldShowOnboarding && !_onboardingShown) {
        _onboardingShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOnboardingDialog(next.onboardingVariant);
        });
      }
      if (prev?.isPremium != next.isPremium) {
        ref
            .read(monetizationServiceProvider)
            .updatePremiumEntitlement(next.isPremium);
      }
      if (next.shouldOfferRewardedAd && prev?.shouldOfferRewardedAd != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _promptRewardedAd(next);
        });
      }
    });

    return Scaffold(
      drawer: const ChatDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade200, Colors.indigo.shade50],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.appTitle),
            Text(
              state.currentChat?.title ?? strings.newChat,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              strings.providerAndModel(
                _providerLabel(registry, state.selectedProviderId),
                state.selectedModelId,
              ),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              strings.tokensToday(state.dailyTokensUsed, state.dailyTokenLimit),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: strings.readLastReply,
            icon: const Icon(Icons.volume_up_outlined),
            onPressed: state.messages.isEmpty
                ? null
                : () => _speakLastAssistant(state),
          ),
          IconButton(
            tooltip: strings.regenerate,
            icon: const Icon(Icons.refresh),
            onPressed: state.isSending || state.messages.isEmpty
                ? null
                : () => ref
                      .read(chatControllerProvider.notifier)
                      .retryLastMessage(),
          ),
          IconButton(
            tooltip: strings.modelSettings,
            icon: const Icon(Icons.tune),
            onPressed: () => _showModelPicker(context, registry, state),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () =>
                ref.read(chatControllerProvider.notifier).newChat(),
            tooltip: strings.newChat,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade100,
                    Colors.grey.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  if (state.currentChat == null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.indigo.shade300,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strings.chooseModelAndWrite,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
              child: ChatList(
                messages: state.messages,
                controller: scrollController,
                isSending: state.isSending,
                streamingText: state.streamingText,
                latestAssistantSources: state.latestRagSourceNames,
              ),
                  ),
                  const MonetizationBanner(),
                  ChatInputBar(
                    controller: inputController,
                    focusNode: inputFocus,
                    onSend: send,
                    onCancel: () => ref
                        .read(chatControllerProvider.notifier)
                        .cancelSending(),
                    onAttach: _pickAttachment,
                    onMic: _toggleMic,
                    isSending: state.isSending,
                    isListening: _isListening,
                    attachTooltip: strings.attach,
                    micTooltip: strings.microphone,
                    stopMicTooltip: strings.stopMic,
                    hintText: strings.writeMessage,
                  ),
                ],
              ),
            ),
    );
  }

  LLMProvider _safeProvider(LLMRegistry registry, String providerId) {
    try {
      return registry.byId(providerId);
    } catch (_) {
      return registry.defaultProvider;
    }
  }

  String _providerLabel(LLMRegistry registry, String providerId) {
    try {
      return registry.byId(providerId).label;
    } catch (_) {
      return providerId;
    }
  }

  Future<String?> _askPresetName(BuildContext context) async {
    final controller = TextEditingController();
    final strings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.presetName),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: strings.presetNameHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(strings.save),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<void> _showOnboardingDialog(String variant) async {
    if (!mounted) return;

    final strings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
    final title = variant == 'A'
        ? strings.onboardingTitleA
        : strings.onboardingTitleB;
    final body = variant == 'A'
        ? strings.onboardingBodyA
        : strings.onboardingBodyB;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.start),
          ),
        ],
      ),
    );

    if (!mounted) return;
    await ref.read(chatControllerProvider.notifier).dismissOnboarding();
  }

  Future<void> _promptRewardedAd(ChatState state) async {
    final runtimeConfig = ref.read(appRuntimeConfigProvider);
    if (!mounted ||
        !runtimeConfig.adsEnabled ||
        !state.adsConsent ||
        state.isPremium) {
      await ref.read(chatControllerProvider.notifier).dismissRewardedAdOffer();
      return;
    }

    final strings = AppStrings.ofCode(state.preferredLanguageCode);
    final messenger = ScaffoldMessenger.of(context);
    final action = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.rewardedAdTitle(state.rewardedTokenBonus)),
        content: Text(strings.rewardedAdBody(state.rewardedTokenBonus)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.watchAd),
          ),
        ],
      ),
    );

    if (action != true) {
      await ref.read(chatControllerProvider.notifier).dismissRewardedAdOffer();
      return;
    }

    final monetization = ref.read(monetizationServiceProvider);
    await ref.read(observabilityServiceProvider).logEvent('rewarded_ad_open');
    final shown = await monetization.showRewardedAd(
      onReward: () {
        ref.read(chatControllerProvider.notifier).grantRewardedTokens();
      },
    );

    if (!mounted) return;
    if (!shown) {
      await ref.read(chatControllerProvider.notifier).dismissRewardedAdOffer();
      await ref
          .read(observabilityServiceProvider)
          .logEvent('rewarded_ad_unavailable');
      messenger.showSnackBar(
        SnackBar(content: Text(strings.rewardedAdUnavailable)),
      );
      return;
    }

    await ref
        .read(observabilityServiceProvider)
        .logEvent('rewarded_ad_reward_granted');
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.rewardedTokensGranted(state.rewardedTokenBonus)),
      ),
    );
  }
}
