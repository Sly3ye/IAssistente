import 'package:flutter/material.dart';

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

class ModelSettingsSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final provider = providers.firstWhere((item) => item.id == providerId);
    final currentModel = models.firstWhere(
      (item) => item.id == modelId,
      orElse: () => models.first,
    );

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
                          'Model Settings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure active provider and operational parameters.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onCloseRequested,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ACTIVE MODEL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  _FlagChip(label: 'Auto-Switch: ${autoFallback ? 'ON' : 'OFF'}'),
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
                      _MetaChip(_contextLabel(maxTokens)),
                      if (item.id == currentModel.id)
                        _MetaChip(_speedLabel(temperature)),
                    ],
                    selected: item.id == modelId,
                    onTap: () => onModelChanged(item.id),
                  ),
                ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 14),
                title: const Text(
                  'Provider Routing',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Current provider: ${provider.label}',
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
                            onSelected: (_) => onProviderChanged(item.id),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'REASONING MODE',
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
                  color: isDark ? const Color(0xFF1F2825) : const Color(0xFFF0ECE3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Standard',
                        selected: maxTokens < 1800,
                        onTap: () {
                          onMaxTokensChanged(1024);
                          onTemperatureChanged(0.2);
                        },
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        label: 'Deep',
                        selected: maxTokens >= 1800,
                        onTap: () {
                          onMaxTokensChanged(2048);
                          onTemperatureChanged(0.35);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                maxTokens >= 1800
                    ? 'Deep mode increases context and reasoning depth. Latency will increase.'
                    : 'Standard mode balances speed and reliability for everyday tasks.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'PARAMETERS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 10),
              _ToggleRow(
                icon: Icons.history_toggle_off_rounded,
                title: 'Cross-Session Memory',
                subtitle: 'Retain context across conversations',
                value: memoryEnabled,
                onChanged: onMemoryChanged,
              ),
              _ToggleRow(
                icon: Icons.shield_outlined,
                title: 'Safety Controls',
                subtitle: 'Filter risky prompts and unsupported requests',
                value: strictSafety,
                onChanged: onStrictSafetyChanged,
              ),
              _ToggleRow(
                icon: Icons.link_rounded,
                title: 'Provider Auto-Switch',
                subtitle: 'Switch model provider automatically when needed',
                value: autoFallback,
                onChanged: onAutoFallbackChanged,
              ),
              _ToggleRow(
                icon: Icons.offline_bolt_rounded,
                title: 'Offline Preference',
                subtitle: 'Prefer local-compatible execution paths',
                value: preferOffline,
                onChanged: onPreferOfflineChanged,
              ),
              _ToggleRow(
                icon: Icons.dataset_linked_outlined,
                title: 'Local RAG',
                subtitle: 'Indexed documents: $ragDocumentsCount',
                value: ragEnabled,
                onChanged: onRagChanged,
              ),
              _ToggleRow(
                icon: Icons.dark_mode_outlined,
                title: 'Night Mode',
                subtitle: 'Switch to the dark version of the current palette',
                value: darkModeEnabled,
                onChanged: onDarkModeChanged,
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                title: const Text(
                  'Voice & Playback',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  ttsVoices.isEmpty
                      ? 'Use the device default voice'
                      : 'Select a TTS voice and tune playback',
                  style: theme.textTheme.bodySmall,
                ),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: ttsVoices.any((item) => item.id == selectedTtsVoiceId)
                        ? selectedTtsVoiceId
                        : '',
                    decoration: const InputDecoration(
                      labelText: 'Voice',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('System default'),
                      ),
                      ...ttsVoices.map(
                        (voice) => DropdownMenuItem<String>(
                          value: voice.id,
                          child: Text(voice.label),
                        ),
                      ),
                    ],
                    onChanged: (value) => onTtsVoiceChanged(value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  Text('Speech rate: ${ttsSpeechRate.toStringAsFixed(2)}'),
                  Slider(
                    value: ttsSpeechRate,
                    min: 0.35,
                    max: 0.65,
                    divisions: 12,
                    onChanged: onTtsSpeechRateChanged,
                  ),
                  Text('Voice tone: ${ttsPitch.toStringAsFixed(2)}'),
                  Slider(
                    value: ttsPitch,
                    min: 0.8,
                    max: 1.2,
                    divisions: 8,
                    onChanged: onTtsPitchChanged,
                  ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                title: const Text(
                  'Advanced Controls',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Temp ${temperature.toStringAsFixed(2)} • Top P ${topP.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
                children: [
                  TextField(
                    controller: TextEditingController(text: systemPrompt)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: systemPrompt.length),
                      ),
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Base instructions for the model',
                    ),
                    onChanged: onSystemPromptChanged,
                  ),
                  const SizedBox(height: 12),
                  Text('Temperature: ${temperature.toStringAsFixed(2)}'),
                  Slider(
                    value: temperature,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: onTemperatureChanged,
                  ),
                  Text('Top P: ${topP.toStringAsFixed(2)}'),
                  Slider(
                    value: topP,
                    min: 0.1,
                    max: 1,
                    divisions: 18,
                    onChanged: onTopPChanged,
                  ),
                  Text('Max tokens: $maxTokens'),
                  Slider(
                    value: maxTokens.toDouble(),
                    min: 128,
                    max: 4096,
                    divisions: 62,
                    onChanged: (value) => onMaxTokensChanged(value.round()),
                  ),
                  _ToggleRow(
                    icon: Icons.analytics_outlined,
                    title: 'Analytics Consent',
                    subtitle: 'Allow diagnostics and product analytics',
                    value: analyticsConsent,
                    onChanged: onAnalyticsChanged,
                  ),
                  _ToggleRow(
                    icon: Icons.campaign_outlined,
                    title: 'Ads Consent',
                    subtitle: 'Allow advertising personalization',
                    value: adsConsent,
                    onChanged: onAdsChanged,
                  ),
                ],
              ),
              if (openCircuitProviders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Circuit breaker active: ${openCircuitProviders.join(', ')}',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFD7B06E) : const Color(0xFF8A5A00),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onResetDefaults,
                      child: const Text('Reset Defaults'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApply,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                      ),
                      child: const Text('Apply Settings'),
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

  String _contextLabel(int maxTokens) {
    if (maxTokens >= 4096) return 'Long Context';
    if (maxTokens >= 2048) return 'Expanded Context';
    return 'Standard Context';
  }

  String _speedLabel(double temperature) {
    if (temperature <= 0.2) return 'Fastest';
    if (temperature <= 0.45) return 'Balanced';
    return 'Creative';
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
