import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
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
import '../widgets/model_settings_sheet.dart';
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
  double _micLevel = 0;
  double _minMicLevel = 50000;
  double _maxMicLevel = -50000;
  String _micBaseText = '';
  final List<_PendingAttachment> _pendingAttachments = [];
  List<TtsVoiceOption> _ttsVoices = const [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _loadTtsVoices();
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
    final strings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
    final text = inputController.text.trim();
    final attachments = List<_PendingAttachment>.from(_pendingAttachments);
    final attachmentPrompts = attachments
        .map((item) => item.prompt.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (text.isEmpty && attachmentPrompts.isEmpty) return;

    final payload = [
      if (text.isNotEmpty) text,
      ...attachmentPrompts,
    ].join('\n\n');
    final displayText = [
      if (text.isNotEmpty) text,
      ...attachments.map((item) => _buildAttachmentDisplayText(item, strings)),
    ].join('\n\n');

    inputController.clear();
    setState(_pendingAttachments.clear);
    await ref
        .read(chatControllerProvider.notifier)
        .sendMessage(payload, displayText: displayText);
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
      _speechReady = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == stt.SpeechToText.notListeningStatus ||
              status == stt.SpeechToText.doneStatus) {
            setState(() {
              _isListening = false;
              _micLevel = 0;
            });
          }
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _micLevel = 0;
          });
        },
      );
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
        setState(() {
          _isListening = false;
          _micLevel = 0;
        });
      }
      return;
    }

    _micBaseText = inputController.text.trim();
    _minMicLevel = 50000;
    _maxMicLevel = -50000;
    setState(() {
      _isListening = true;
      _micLevel = 0;
    });
    await _speech.listen(
      onResult: (result) {
        final spoken = result.recognizedWords.trim();
        setState(() {
          inputController.text = _composeSpeechDraft(_micBaseText, spoken);
          inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: inputController.text.length),
          );
        });
      },
      onSoundLevelChange: (level) {
        _minMicLevel = level < _minMicLevel ? level : _minMicLevel;
        _maxMicLevel = level > _maxMicLevel ? level : _maxMicLevel;
        final range = (_maxMicLevel - _minMicLevel).abs();
        final normalized = range < 0.001
            ? 0.12
            : ((level - _minMicLevel) / range).clamp(0.0, 1.0);
        if (!mounted) return;
        setState(() => _micLevel = normalized.toDouble());
      },
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    Future<void>.delayed(const Duration(seconds: 12), () async {
      if (!_isListening) return;
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _micLevel = 0;
        });
      }
    });
  }

  Future<void> _readAssistantMessage(String text) async {
    final strings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    try {
      final chatState = ref.read(chatControllerProvider);
      await _tts.stop();
      final fallbackLanguage = chatState.preferredLanguageCode == 'it'
          ? 'it-IT'
          : 'en-US';
      await _tts.setLanguage(
        chatState.ttsVoiceLocale.isNotEmpty
            ? chatState.ttsVoiceLocale
            : fallbackLanguage,
      );
      await _tts.setSpeechRate(chatState.ttsSpeechRate);
      await _tts.setPitch(chatState.ttsPitch);
      if (chatState.ttsVoiceName.isNotEmpty &&
          chatState.ttsVoiceLocale.isNotEmpty) {
        await _tts.setVoice({
          'name': chatState.ttsVoiceName,
          'locale': chatState.ttsVoiceLocale,
        });
      }
      await _tts.speak(cleaned);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.localTimeUnavailable)));
    }
  }

  String _composeSpeechDraft(String baseText, String spoken) {
    final cleanBase = baseText.trim();
    final cleanSpoken = spoken.trim();
    if (cleanSpoken.isEmpty) return cleanBase;
    if (cleanBase.isEmpty) return cleanSpoken;
    return '$cleanBase $cleanSpoken';
  }

  Future<void> _loadTtsVoices() async {
    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices is! List) return;
      final chatState = ref.read(chatControllerProvider);
      final languageCode = chatState.preferredLanguageCode;
      final voices = rawVoices
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map((item) {
            final name = (item['name'] ?? '').toString().trim();
            final locale = (item['locale'] ?? '').toString().trim();
            if (name.isEmpty ||
                locale.isEmpty ||
                !_isUsefulTtsVoice(name, locale)) {
              return null;
            }
            return TtsVoiceOption(
              name: name,
              locale: locale,
              label: _ttsVoiceLabel(name, locale),
            );
          })
          .whereType<TtsVoiceOption>()
          .toList(growable: false);

      int score(TtsVoiceOption voice) {
        final normalizedName = voice.name.toLowerCase();
        final localeMatch = voice.locale.toLowerCase().startsWith(
          languageCode.toLowerCase(),
        );
        var result = localeMatch ? 100 : 0;
        if (normalizedName.contains('neural')) result += 40;
        if (normalizedName.contains('natural')) result += 24;
        if (normalizedName.contains('wavenet')) result += 20;
        if (normalizedName.contains('premium')) result += 16;
        if (normalizedName.contains('enhanced')) result += 12;
        if (normalizedName.contains('offline')) result -= 8;
        if (normalizedName.contains('legacy')) result -= 18;
        if (normalizedName.contains('default')) result -= 10;
        return result;
      }

      final unique = <String, TtsVoiceOption>{};
      for (final voice in voices) {
        unique[voice.id] = voice;
      }
      final sorted = unique.values.toList()
        ..sort((a, b) {
          final scoreCompare = score(b).compareTo(score(a));
          if (scoreCompare != 0) return scoreCompare;
          return a.label.toLowerCase().compareTo(b.label.toLowerCase());
        });
      final shortlist = <TtsVoiceOption>[];
      final localePrefixes = <String>[
        languageCode.toLowerCase(),
        if (languageCode.toLowerCase() != 'en') 'en',
      ];
      for (final prefix in localePrefixes) {
        shortlist.addAll(
          sorted
              .where((voice) => voice.locale.toLowerCase().startsWith(prefix))
              .take(prefix == languageCode.toLowerCase() ? 6 : 2),
        );
      }
      if (chatState.ttsVoiceName.isNotEmpty && chatState.ttsVoiceLocale.isNotEmpty) {
        final selectedId = '${chatState.ttsVoiceName}|${chatState.ttsVoiceLocale}';
        final selectedVoice = sorted.where((voice) => voice.id == selectedId);
        shortlist.addAll(selectedVoice);
      }
      final finalVoices = <String, TtsVoiceOption>{};
      for (final voice in shortlist) {
        finalVoices[voice.id] = voice;
      }
      if (!mounted) return;
      setState(() => _ttsVoices = finalVoices.values.toList(growable: false));
    } catch (_) {
      if (!mounted) return;
      setState(() => _ttsVoices = const []);
    }
  }

  bool _isUsefulTtsVoice(String name, String locale) {
    final normalizedName = name.toLowerCase();
    final normalizedLocale = locale.toLowerCase();
    if (!normalizedLocale.contains('-') && !normalizedLocale.contains('_')) {
      return false;
    }
    const rejectedTokens = [
      'espeak',
      'pico',
      'embedded',
      'legacy',
      'dummy',
      'sample',
      'test',
    ];
    return !rejectedTokens.any(normalizedName.contains);
  }

  String _ttsVoiceLabel(String name, String locale) {
    final cleanedName = name
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final localeLabel = locale.replaceAll('_', '-');
    return '$cleanedName · $localeLabel';
  }

  Future<void> _pickAttachment() async {
    final sheetStrings = AppStrings.ofCode(
      ref.read(chatControllerProvider).preferredLanguageCode,
    );
    final choice = await showModalBottomSheet<_AttachmentPickerKind>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  sheetStrings.pick(
                    it: 'Scegli allegato',
                    en: 'Choose attachment',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _AttachmentOptionTile(
                  icon: Icons.description_outlined,
                  title: sheetStrings.pick(it: 'Documento', en: 'Document'),
                  subtitle: sheetStrings.pick(
                    it: 'TXT, MD, JSON, CSV, YAML, PDF',
                    en: 'TXT, MD, JSON, CSV, YAML, PDF',
                  ),
                  onTap: () => Navigator.pop(
                    context,
                    _AttachmentPickerKind.document,
                  ),
                ),
                const SizedBox(height: 10),
                _AttachmentOptionTile(
                  icon: Icons.image_outlined,
                  title: sheetStrings.pick(it: 'Immagine', en: 'Image'),
                  subtitle: sheetStrings.pick(
                    it: 'PNG, JPG, JPEG, WEBP, BMP',
                    en: 'PNG, JPG, JPEG, WEBP, BMP',
                  ),
                  onTap: () =>
                      Navigator.pop(context, _AttachmentPickerKind.image),
                ),
                const SizedBox(height: 10),
                _AttachmentOptionTile(
                  icon: Icons.videocam_outlined,
                  title: sheetStrings.pick(it: 'Video', en: 'Video'),
                  subtitle: sheetStrings.pick(
                    it: 'MP4, MOV, WEBM, MKV',
                    en: 'MP4, MOV, WEBM, MKV',
                  ),
                  onTap: () =>
                      Navigator.pop(context, _AttachmentPickerKind.video),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null) return;

    final chatState = ref.read(chatControllerProvider);
    final strings = AppStrings.ofCode(chatState.preferredLanguageCode);
    final controller = ref.read(chatControllerProvider.notifier);
    final extractor = ref.read(attachmentExtractionServiceProvider);
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: switch (choice) {
        _AttachmentPickerKind.document => [
            'txt',
            'md',
            'json',
            'csv',
            'yaml',
            'yml',
            'pdf',
          ],
        _AttachmentPickerKind.image => [
            'png',
            'jpg',
            'jpeg',
            'webp',
            'bmp',
          ],
        _AttachmentPickerKind.video => [
            'mp4',
            'mov',
            'webm',
            'mkv',
          ],
      },
    );
    if (result == null || result.files.isEmpty) return;

    final nextAttachments = <_PendingAttachment>[];
    for (final file in result.files) {
      final ext = (file.extension ?? '').toLowerCase();
      final isImage = extractor.isImageFile(file.name);
      final isVideo = choice == _AttachmentPickerKind.video;

      final extraction = isImage || isVideo
          ? null
          : await extractor.extractTextFromFile(
              fileName: file.name,
              filePath: file.path,
              bytes: file.bytes,
            );

      String attachmentPrompt;
      final extractedText = extraction?.text.trim() ?? '';
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
        }
    } else if (isImage) {
      attachmentPrompt = strings.imageManualFallback(file.name);
    } else if (isVideo) {
      attachmentPrompt = strings.pick(
        it: 'Ho allegato un video `${file.name}`. Se il provider non supporta l’analisi video diretta, chiedimi un frame, una trascrizione o una descrizione per analizzarlo.',
        en: 'I attached a video `${file.name}`. If the provider does not support direct video analysis, ask me for a frame, transcript, or description to analyze it.',
      );
    } else if (ext == 'pdf') {
      attachmentPrompt = strings.pdfManualFallback(file.name);
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

      nextAttachments.add(
        _PendingAttachment(
          fileName: file.name,
          kind: isImage
              ? 'image'
              : (isVideo ? 'video' : (extraction?.kind ?? ext)),
          prompt: attachmentPrompt,
          previewPath: file.path,
          previewBytes: isImage ? file.bytes : null,
        ),
      );
    }
    setState(() {
      _pendingAttachments.addAll(nextAttachments);
    });
    if (!mounted) return;
    final snackText = nextAttachments.length == 1
        ? strings.pick(
            it: 'Allegato pronto: ${nextAttachments.first.fileName}',
            en: 'Attachment ready: ${nextAttachments.first.fileName}',
          )
        : strings.pick(
            it: 'Allegati pronti: ${nextAttachments.length}',
            en: 'Attachments ready: ${nextAttachments.length}',
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(snackText)),
    );
    inputFocus.requestFocus();
  }

  String _buildAttachmentDisplayText(
    _PendingAttachment attachment,
    AppStrings strings,
  ) {
    if (attachment.kind == 'image' && attachment.previewPath != null) {
      return '[[attachment:image|${attachment.previewPath}|${attachment.fileName}]]';
    }
    if (attachment.kind == 'video' && attachment.previewPath != null) {
      return '[[attachment:video|${attachment.previewPath}|${attachment.fileName}]]';
    }
    return strings.pick(
      it: '[Allegato: ${attachment.fileName}]',
      en: '[Attachment: ${attachment.fileName}]',
    );
  }

  Future<void> _showModelPicker(
    BuildContext context,
    LLMRegistry registry,
    ChatState state,
  ) async {
    await _loadTtsVoices();
    if (!context.mounted) return;
    final controller = ref.read(chatControllerProvider.notifier);

    final initialProviderId = state.selectedProviderId;
    final initialModelId = state.selectedModelId;
    final initialSystemPrompt = state.selectedSystemPrompt;
    final initialTemperature = state.selectedTemperature;
    final initialMaxTokens = state.selectedMaxTokens;
    final initialTopP = state.selectedTopP;
    final initialAutoFallback = state.autoFallback;
    final initialStrictSafety = state.strictSafety;
    final initialPreferOffline = state.preferOffline;
    final initialMemoryEnabled = state.longTermMemoryEnabled;
    final initialRagEnabled = state.ragEnabled;
    final initialAnalyticsConsent = state.analyticsConsent;
    final initialAdsConsent = state.adsConsent;
    final initialDarkModeEnabled = state.darkModeEnabled;
    final initialTtsVoiceName = state.ttsVoiceName;
    final initialTtsVoiceLocale = state.ttsVoiceLocale;
    final initialTtsSpeechRate = state.ttsSpeechRate;
    final initialTtsPitch = state.ttsPitch;

    var providerId = initialProviderId;
    var modelId = initialModelId;
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
    var darkModeEnabled = state.darkModeEnabled;
    var ttsVoiceName = state.ttsVoiceName;
    var ttsVoiceLocale = state.ttsVoiceLocale;
    var ttsSpeechRate = state.ttsSpeechRate;
    var ttsPitch = state.ttsPitch;

    bool hasDraftChanges() {
      return providerId != initialProviderId ||
          modelId != initialModelId ||
          systemPrompt != initialSystemPrompt ||
          temperature != initialTemperature ||
          maxTokens != initialMaxTokens ||
          topP != initialTopP ||
          autoFallback != initialAutoFallback ||
          strictSafety != initialStrictSafety ||
          preferOffline != initialPreferOffline ||
          memoryEnabled != initialMemoryEnabled ||
          ragEnabled != initialRagEnabled ||
          analyticsConsent != initialAnalyticsConsent ||
          adsConsent != initialAdsConsent ||
          darkModeEnabled != initialDarkModeEnabled ||
          ttsVoiceName != initialTtsVoiceName ||
          ttsVoiceLocale != initialTtsVoiceLocale ||
          ttsSpeechRate != initialTtsSpeechRate ||
          ttsPitch != initialTtsPitch;
    }

    Future<void> applyDraftSettings() async {
      await controller.updateCurrentChatModel(
        providerId: providerId,
        modelId: modelId,
      );
      await controller.updateDefaultModel(
        providerId: providerId,
        modelId: modelId,
      );
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
      await controller.setAnalyticsConsent(analyticsConsent);
      await controller.setAdsConsent(adsConsent);
      await controller.setDarkModeEnabled(darkModeEnabled);
      await controller.setTtsVoice(
        voiceName: ttsVoiceName,
        voiceLocale: ttsVoiceLocale,
      );
      await controller.setTtsSpeechRate(ttsSpeechRate);
      await controller.setTtsPitch(ttsPitch);
      await ref.read(monetizationServiceProvider).updateAdsConsent(
        ref.read(appRuntimeConfigProvider).adsEnabled && adsConsent,
      );
    }

    Future<bool> confirmDiscardDrafts(BuildContext modalContext) async {
      if (!hasDraftChanges()) return true;
      final decision = await showDialog<String>(
        context: modalContext,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unsaved changes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Provider, model and settings have unsaved changes. Apply them before closing, or discard the draft.',
                        style: TextStyle(height: 1.45),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, 'discard'),
                              child: const Text('Discard'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, 'apply'),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    onPressed: () => Navigator.pop(dialogContext, 'cancel'),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ),
              ],
            ),
          );
        },
      );
      if (decision == 'apply') {
        await applyDraftSettings();
        return true;
      }
      return decision == 'discard';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
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

            return ModelSettingsSheet(
              providers: registry.providers,
              models: models,
              providerId: providerId,
              modelId: modelId,
              autoFallback: autoFallback,
              strictSafety: strictSafety,
              preferOffline: preferOffline,
              memoryEnabled: memoryEnabled,
              ragEnabled: ragEnabled,
              analyticsConsent: analyticsConsent,
              adsConsent: adsConsent,
              darkModeEnabled: darkModeEnabled,
              ttsVoices: _ttsVoices,
              selectedTtsVoiceId: ttsVoiceName.isNotEmpty && ttsVoiceLocale.isNotEmpty
                  ? '$ttsVoiceName|$ttsVoiceLocale'
                  : '',
              ttsSpeechRate: ttsSpeechRate,
              ttsPitch: ttsPitch,
              temperature: temperature,
              topP: topP,
              maxTokens: maxTokens,
              systemPrompt: systemPrompt,
              ragDocumentsCount: liveState.ragDocuments.length,
              openCircuitProviders: liveState.openCircuitProviders,
              onProviderChanged: (nextProviderId) {
                final providerModels =
                    liveState.providerModels[nextProviderId] ??
                    _safeProvider(registry, nextProviderId).models;
                final firstModel = providerModels.first.id;
                setModalState(() {
                  providerId = nextProviderId;
                  modelId = firstModel;
                });
              },
              onModelChanged: (nextModelId) {
                setModalState(() => modelId = nextModelId);
              },
              onAutoFallbackChanged: (value) =>
                  setModalState(() => autoFallback = value),
              onStrictSafetyChanged: (value) =>
                  setModalState(() => strictSafety = value),
              onPreferOfflineChanged: (value) =>
                  setModalState(() => preferOffline = value),
              onMemoryChanged: (value) =>
                  setModalState(() => memoryEnabled = value),
              onRagChanged: (value) => setModalState(() => ragEnabled = value),
              onAnalyticsChanged: (value) =>
                  setModalState(() => analyticsConsent = value),
              onAdsChanged: (value) => setModalState(() => adsConsent = value),
              onDarkModeChanged: (value) =>
                  setModalState(() => darkModeEnabled = value),
              onTtsVoiceChanged: (value) => setModalState(() {
                if (value.isEmpty) {
                  ttsVoiceName = '';
                  ttsVoiceLocale = '';
                  return;
                }
                final selectedVoice = _ttsVoices.firstWhere(
                  (item) => item.id == value,
                );
                ttsVoiceName = selectedVoice.name;
                ttsVoiceLocale = selectedVoice.locale;
              }),
              onTtsSpeechRateChanged: (value) =>
                  setModalState(() => ttsSpeechRate = value),
              onTtsPitchChanged: (value) =>
                  setModalState(() => ttsPitch = value),
              onTemperatureChanged: (value) =>
                  setModalState(() => temperature = value),
              onTopPChanged: (value) => setModalState(() => topP = value),
              onMaxTokensChanged: (value) =>
                  setModalState(() => maxTokens = value),
              onSystemPromptChanged: (value) =>
                  setModalState(() => systemPrompt = value),
              onResetDefaults: () {
                setModalState(() {
                  providerId = initialProviderId;
                  modelId = initialModelId;
                  systemPrompt = LLMRequestConfig.defaults.systemPrompt;
                  temperature = LLMRequestConfig.defaults.temperature;
                  topP = LLMRequestConfig.defaults.topP;
                  maxTokens = LLMRequestConfig.defaults.maxTokens;
                  autoFallback = true;
                  strictSafety = true;
                  preferOffline = false;
                  memoryEnabled = false;
                  ragEnabled = false;
                  darkModeEnabled = false;
                  ttsVoiceName = '';
                  ttsVoiceLocale = '';
                  ttsSpeechRate = 0.5;
                  ttsPitch = 1.0;
                });
              },
              onCloseRequested: () async {
                final canClose = await confirmDiscardDrafts(context);
                if (canClose && context.mounted) {
                  Navigator.pop(context);
                }
              },
              onApply: () async {
                await applyDraftSettings();
                if (context.mounted) Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final registry = ref.watch(llmRegistryProvider);
    ref.watch(monetizationServiceProvider);
    final strings = AppStrings.ofCode(state.preferredLanguageCode);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCurrentChatSending =
        state.isSending && state.sendingChatId == state.currentChat?.id;

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
        backgroundColor: theme.scaffoldBackgroundColor,
        toolbarHeight: 76,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.currentChat?.title ?? strings.newChat,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_providerLabel(registry, state.selectedProviderId)} • ${state.selectedModelId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                letterSpacing: 0.55,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showModelPicker(context, registry, state),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF274B44), Color(0xFF3C6B62)]
                          : const [Color(0xFF0E2D1D), Color(0xFF214536)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0x33000000)
                            : const Color(0x14000000),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFFE8D5AC),
                    size: 18,
                  ),
                ),
              ),
            ),
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
                  colors: isDark
                      ? const [
                          Color(0xFF0E1312),
                          Color(0xFF121917),
                          Color(0xFF161E1B),
                        ]
                      : const [
                          Color(0xFFF3E9D9),
                          Color(0xFFF8F3EA),
                          Colors.white,
                        ],
                ),
              ),
              child: Column(
                children: [
                  if (state.messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF202927)
                              : const Color(0xFFF0ECE3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _conversationTimeChip(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.7,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ),
                  if (state.currentChat == null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? const Color(0x55000000)
                                : const Color(0x12000000),
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2B5A52)
                                  : const Color(0xFFEAD8B6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: isDark
                                  ? const Color(0xFFE7F7F2)
                                  : const Color(0xFF12322D),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strings.chooseModelAndWrite,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ChatList(
                        messages: state.messages,
                        controller: scrollController,
                        isSending: isCurrentChatSending,
                        streamingText: state.streamingText,
                        latestAssistantSources: state.latestRagSourceNames,
                        onReadAloud: (message) =>
                            _readAssistantMessage(message.content),
                      ),
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
                    micLevel: _micLevel,
                    attachTooltip: strings.attach,
                    micTooltip: strings.microphone,
                    stopMicTooltip: strings.stopMic,
                    hintText: strings.writeMessage,
                    attachments: _pendingAttachments
                        .asMap()
                        .entries
                        .map(
                          (entry) => AttachmentPreviewItem(
                            kind: entry.value.kind,
                            label: entry.value.fileName,
                            subtitle: strings.pick(
                              it: 'Pronto per l\'invio - ${entry.value.kind}',
                              en: 'Ready to send - ${entry.value.kind}',
                            ),
                            previewPath: entry.value.previewPath,
                            previewBytes: entry.value.previewBytes,
                            onRemove: () => setState(
                              () => _pendingAttachments.removeAt(entry.key),
                            ),
                          ),
                        )
                        .toList(growable: false),
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

  String _conversationTimeChip() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return 'TODAY, $hour:$minute';
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

enum _AttachmentPickerKind { document, image, video }

class _PendingAttachment {
  const _PendingAttachment({
    required this.fileName,
    required this.kind,
    required this.prompt,
    this.previewPath,
    this.previewBytes,
  });

  final String fileName;
  final String kind;
  final String prompt;
  final String? previewPath;
  final Uint8List? previewBytes;
}

class _AttachmentOptionTile extends StatelessWidget {
  const _AttachmentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF202927)
                    : const Color(0xFFF3ECE0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: theme.iconTheme.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

