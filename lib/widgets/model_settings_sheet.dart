import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/llm_provider.dart';

class TtsVoiceOption {
  const TtsVoiceOption({
    required this.name,
    required this.locale,
    required this.label,
  });

  final String name;
  final String locale;
  final String label;

  String get id => '$name|$locale';
}

class ModelSettingsSheet extends StatefulWidget {
  const ModelSettingsSheet({
    super.key,
    required this.providers,
    required this.models,
    required this.providerId,
    required this.modelId,
    required this.autoFallback,
    required this.strictSafety,
    required this.preferOffline,
    required this.memoryEnabled,
    required this.ragEnabled,
    required this.analyticsConsent,
    required this.adsConsent,
    required this.darkModeEnabled,
    required this.ttsVoices,
    required this.selectedTtsVoiceId,
    required this.ttsSpeechRate,
    required this.ttsPitch,
    required this.temperature,
    required this.topP,
    required this.maxTokens,
    required this.systemPrompt,
    required this.ragDocumentsCount,
    required this.openCircuitProviders,
    required this.languageCode,
    required this.onProviderChanged,
    required this.onModelChanged,
    required this.onAutoFallbackChanged,
    required this.onStrictSafetyChanged,
    required this.onPreferOfflineChanged,
    required this.onMemoryChanged,
    required this.onRagChanged,
    required this.onAnalyticsChanged,
    required this.onAdsChanged,
    required this.onDarkModeChanged,
    required this.onTtsVoiceChanged,
    required this.onTtsSpeechRateChanged,
    required this.onTtsPitchChanged,
    required this.onTemperatureChanged,
    required this.onTopPChanged,
    required this.onMaxTokensChanged,
    required this.onSystemPromptChanged,
    required this.onResetDefaults,
    required this.onApply,
    required this.onCloseRequested,
  });

  final List<LLMProvider> providers;
  final List<LLMModelOption> models;
  final String providerId;
  final String modelId;
  final bool autoFallback;
  final bool strictSafety;
  final bool preferOffline;
  final bool memoryEnabled;
  final bool ragEnabled;
  final bool analyticsConsent;
  final bool adsConsent;
  final bool darkModeEnabled;
  final List<TtsVoiceOption> ttsVoices;
  final String selectedTtsVoiceId;
  final double ttsSpeechRate;
  final double ttsPitch;
  final double temperature;
  final double topP;
  final int maxTokens;
  final String systemPrompt;
  final int ragDocumentsCount;
  final List<String> openCircuitProviders;
  final String languageCode;
  final ValueChanged<String> onProviderChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<bool> onAutoFallbackChanged;
  final ValueChanged<bool> onStrictSafetyChanged;
  final ValueChanged<bool> onPreferOfflineChanged;
  final ValueChanged<bool> onMemoryChanged;
  final ValueChanged<bool> onRagChanged;
  final ValueChanged<bool> onAnalyticsChanged;
  final ValueChanged<bool> onAdsChanged;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<String> onTtsVoiceChanged;
  final ValueChanged<double> onTtsSpeechRateChanged;
  final ValueChanged<double> onTtsPitchChanged;
  final ValueChanged<double> onTemperatureChanged;
  final ValueChanged<double> onTopPChanged;
  final ValueChanged<int> onMaxTokensChanged;
  final ValueChanged<String> onSystemPromptChanged;
  final VoidCallback onResetDefaults;
  final VoidCallback onApply;
  final VoidCallback onCloseRequested;

  @override
  State<ModelSettingsSheet> createState() => _ModelSettingsSheetState();
}

class _ModelSettingsSheetState extends State<ModelSettingsSheet> {
  final ExpansibleController _providerTileController = ExpansibleController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final providers = widget.providers;
    final models = widget.models;
    final providerId = widget.providerId;
    final modelId = widget.modelId;
    final provider = providers.firstWhere((item) => item.id == providerId);
    final currentModel = models.firstWhere(
      (item) => item.id == modelId,
      orElse: () => models.first,
    );
    final strings = AppStrings.ofCode(widget.languageCode);

    return Container(
      margin: EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.modelSettingsTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.modelSettingsSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCloseRequested,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.activeModelLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  _FlagChip(
                    label: strings.autoSwitchLabel(widget.autoFallback),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final item in models)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ModelCard(
                    title: item.label,
                    subtitle:
                        '${provider.label} • ${_modelDescriptionFor(item.id)}',
                    meta: [
                      _MetaChip(_contextLabel(widget.maxTokens, strings)),
                      if (item.id == currentModel.id)
                        _MetaChip(_speedLabel(widget.temperature, strings)),
                    ],
                    selected: item.id == modelId,
                    onTap: () => widget.onModelChanged(item.id),
                  ),
                ),
              ExpansionTile(
                controller: _providerTileController,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 14),
                title: Text(
                  strings.providerRoutingTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  strings.currentProvider(provider.label),
                  style: theme.textTheme.bodySmall,
                ),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: providers
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item.label),
                            selected: item.id == providerId,
                            selectedColor: isDark
                                ? colorScheme.surfaceContainerHighest
                                : const Color(0xFFEAE5DA),
                            onSelected: (_) =>
                                widget.onProviderChanged(item.id),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                strings.reasoningModeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2825)
                      : const Color(0xFFF0ECE3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: strings.modeStandard,
                        selected: widget.maxTokens < 1800,
                        onTap: () {
                          widget.onMaxTokensChanged(1024);
                          widget.onTemperatureChanged(0.2);
                        },
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        label: strings.modeDeep,
                        selected: widget.maxTokens >= 1800,
                        onTap: () {
                          widget.onMaxTokensChanged(2048);
                          widget.onTemperatureChanged(0.35);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.maxTokens >= 1800
                    ? strings.modeDeepDescription
                    : strings.modeStandardDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                strings.parametersLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 10),
              _ToggleRow(
                icon: Icons.history_toggle_off_rounded,
                title: strings.crossSessionMemoryTitle,
                subtitle: strings.crossSessionMemorySubtitle,
                value: widget.memoryEnabled,
                onChanged: widget.onMemoryChanged,
              ),
              _ToggleRow(
                icon: Icons.shield_outlined,
                title: strings.safetyControlsTitle,
                subtitle: strings.safetyControlsSubtitle,
                value: widget.strictSafety,
                onChanged: widget.onStrictSafetyChanged,
              ),
              _ToggleRow(
                icon: Icons.link_rounded,
                title: strings.providerAutoSwitchTitle,
                subtitle: strings.providerAutoSwitchSubtitle,
                value: widget.autoFallback,
                onChanged: widget.onAutoFallbackChanged,
              ),
              _ToggleRow(
                icon: Icons.offline_bolt_rounded,
                title: strings.offlinePreferenceTitle,
                subtitle: strings.offlinePreferenceSubtitle,
                value: widget.preferOffline,
                onChanged: widget.onPreferOfflineChanged,
              ),
              _ToggleRow(
                icon: Icons.dataset_linked_outlined,
                title: strings.personalDocumentsTitle,
                subtitle: strings.indexedDocumentsSubtitle(widget.ragDocumentsCount),
                value: widget.ragEnabled,
                onChanged: widget.onRagChanged,
              ),
              _ToggleRow(
                icon: Icons.dark_mode_outlined,
                title: strings.nightModeTitle,
                subtitle: strings.nightModeSubtitle,
                value: widget.darkModeEnabled,
                onChanged: widget.onDarkModeChanged,
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                title: Text(
                  strings.voicePlaybackTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  widget.ttsVoices.isEmpty
                      ? strings.voiceDefaultSubtitle
                      : strings.voiceSelectSubtitle,
                  style: theme.textTheme.bodySmall,
                ),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: widget.ttsVoices.any(
                          (item) => item.id == widget.selectedTtsVoiceId,
                        )
                        ? widget.selectedTtsVoiceId
                        : '',
                    decoration: InputDecoration(labelText: strings.voiceDropdownLabel),
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(strings.voiceSystemDefault),
                      ),
                      ...widget.ttsVoices.map(
                        (voice) => DropdownMenuItem<String>(
                          value: voice.id,
                          child: Text(voice.label),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        widget.onTtsVoiceChanged(value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  Text(strings.speechRateLabel(widget.ttsSpeechRate)),
                  Slider(
                    value: widget.ttsSpeechRate,
                    min: 0.35,
                    max: 0.65,
                    divisions: 12,
                    onChanged: widget.onTtsSpeechRateChanged,
                  ),
                  Text(strings.voiceToneLabel(widget.ttsPitch)),
                  Slider(
                    value: widget.ttsPitch,
                    min: 0.8,
                    max: 1.2,
                    divisions: 8,
                    onChanged: widget.onTtsPitchChanged,
                  ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                title: Text(
                  strings.advancedControlsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  strings.advancedControlsSubtitle(widget.temperature, widget.topP),
                  style: theme.textTheme.bodySmall,
                ),
                children: [
                  TextField(
                    controller: TextEditingController(text: widget.systemPrompt)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: widget.systemPrompt.length),
                      ),
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: strings.systemPromptHint,
                    ),
                    onChanged: widget.onSystemPromptChanged,
                  ),
                  const SizedBox(height: 12),
                  Text(strings.temperatureSliderLabel(widget.temperature)),
                  Slider(
                    value: widget.temperature,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: widget.onTemperatureChanged,
                  ),
                  Text(strings.topPSliderLabel(widget.topP)),
                  Slider(
                    value: widget.topP,
                    min: 0.1,
                    max: 1,
                    divisions: 18,
                    onChanged: widget.onTopPChanged,
                  ),
                  Text(strings.maxTokensSliderLabel(widget.maxTokens)),
                  Slider(
                    value: widget.maxTokens.toDouble(),
                    min: 128,
                    max: 4096,
                    divisions: 62,
                    onChanged: (value) =>
                        widget.onMaxTokensChanged(value.round()),
                  ),
                  _ToggleRow(
                    icon: Icons.analytics_outlined,
                    title: strings.analyticsConsentTitle,
                    subtitle: strings.analyticsConsentSubtitle,
                    value: widget.analyticsConsent,
                    onChanged: widget.onAnalyticsChanged,
                  ),
                  _ToggleRow(
                    icon: Icons.campaign_outlined,
                    title: strings.adsConsentTitle,
                    subtitle: strings.adsConsentSubtitle,
                    value: widget.adsConsent,
                    onChanged: widget.onAdsChanged,
                  ),
                ],
              ),
              if (widget.openCircuitProviders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2E2210)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF7A5500)
                            : const Color(0xFFFFB300),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFFD7B06E)
                                  : const Color(0xFF8A5A00),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                strings.circuitBreakerActive(
                                  widget.openCircuitProviders,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFFD7B06E)
                                      : const Color(0xFF8A5A00),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strings.circuitBreakerExplanation(
                            widget.openCircuitProviders,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark
                                ? const Color(0xFFB8935A)
                                : const Color(0xFF6D4700),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () =>
                                _providerTileController.expand(),
                            icon: const Icon(Icons.swap_horiz_rounded,
                                size: 18),
                            label: Text(strings.switchProvider),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onResetDefaults,
                      child: Text(strings.resetDefaults),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: widget.onApply,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                      ),
                      child: Text(strings.applySettings),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _modelDescriptionFor(String modelId) {
    final normalized = modelId.toLowerCase();
    if (normalized.contains('gpt-4')) {
      return 'High capability reasoning and deep contextual understanding.';
    }
    if (normalized.contains('claude')) {
      return 'Advanced coding, nuanced writing, and complex analysis.';
    }
    if (normalized.contains('gemini')) {
      return 'Balanced multimodal assistance for research and productivity.';
    }
    if (normalized.contains('mistral')) {
      return 'Efficient drafting and lightweight reasoning tasks.';
    }
    if (normalized.contains('llama')) {
      return 'General assistance optimized for versatile dialogue.';
    }
    if (normalized.contains('qwen')) {
      return 'Broad reasoning and multilingual answers for general use.';
    }
    if (normalized.contains('gpt-oss')) {
      return 'Open-weights reasoning model tuned for flexible responses.';
    }
    return 'Balanced performance for everyday tasks, drafting, and general queries.';
  }

  String _contextLabel(int maxTokens, AppStrings strings) {
    if (maxTokens >= 4096) return strings.longContext;
    if (maxTokens >= 2048) return strings.expandedContext;
    return strings.standardContext;
  }

  String _speedLabel(double temperature, AppStrings strings) {
    if (temperature <= 0.2) return strings.speedFastest;
    if (temperature <= 0.45) return strings.speedBalanced;
    return strings.speedCreative;
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF4A4331) : const Color(0xFFF2E4AF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? theme.colorScheme.onSurface : const Color(0xFF7A6A35),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202927) : const Color(0xFFF2EFE8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.selected,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final List<Widget> meta;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.disabledColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodySmall?.color,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: meta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF2A3431) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected
                ? theme.colorScheme.onSurface
                : theme.textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.iconTheme.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
