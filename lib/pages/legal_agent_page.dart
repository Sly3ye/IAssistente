import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../models/legal_profile.dart';
import '../providers/app_providers.dart';
import '../widgets/agent_disclaimer_banner.dart';

class LegalAgentPage extends ConsumerStatefulWidget {
  const LegalAgentPage({super.key});

  @override
  ConsumerState<LegalAgentPage> createState() => _LegalAgentPageState();
}

class _LegalAgentPageState extends ConsumerState<LegalAgentPage> {
  bool _isStarting = false;

  late final TextEditingController _questionController;
  late final TextEditingController _topicController;
  late final TextEditingController _jurisdictionController;
  late final TextEditingController _roleController;
  late final TextEditingController _scenarioController;
  late final TextEditingController _documentsController;
  late final TextEditingController _deadlinesController;
  late final TextEditingController _goalController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(chatControllerProvider).legalProfile;
    _questionController = TextEditingController(text: profile.primaryQuestion);
    _topicController = TextEditingController(text: profile.topic);
    _jurisdictionController = TextEditingController(text: profile.jurisdiction);
    _roleController = TextEditingController(text: profile.userRole);
    _scenarioController = TextEditingController(text: profile.scenario);
    _documentsController = TextEditingController(
      text: profile.documentsAvailable,
    );
    _deadlinesController = TextEditingController(text: profile.deadlines);
    _goalController = TextEditingController(text: profile.goal);
    _notesController = TextEditingController(text: profile.notes);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _topicController.dispose();
    _jurisdictionController.dispose();
    _roleController.dispose();
    _scenarioController.dispose();
    _documentsController.dispose();
    _deadlinesController.dispose();
    _goalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final isItalian = state.preferredLanguageCode == 'it';
    final lastCase = _lastChatForKind(state.chats, Chat.kindLegal);

    return Scaffold(
      appBar: AppBar(title: Text(isItalian ? 'Avvocato' : 'Lawyer')),
      body: Column(
        children: [
          AgentDisclaimerBanner(
            text: isItalian
                ? 'Percorso informativo: compila almeno domanda o scenario. Non sostituisce un avvocato reale e non costituisce consulenza legale.'
                : 'Informational workflow: fill at least question or scenario. It does not replace a real lawyer and does not constitute legal advice.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
          if (lastCase != null) ...[
            const SizedBox(height: 12),
            _LastCaseCard(
              title: isItalian ? 'Ultimo caso legale' : 'Last legal case',
              chat: lastCase,
              onTap: () async {
                await ref
                    .read(chatControllerProvider.notifier)
                    .loadChat(lastCase.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
          const SizedBox(height: 16),
          const _AgentSectionTitle(title: 'Caso'),
          TextField(
            controller: _questionController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: isItalian
                  ? 'Domanda o problema principale'
                  : 'Main question or issue',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicController,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: isItalian ? 'Area legale' : 'Legal area',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _jurisdictionController,
                  decoration: InputDecoration(
                    labelText: isItalian
                        ? 'Paese o giurisdizione'
                        : 'Country or jurisdiction',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _roleController,
                  decoration: InputDecoration(
                    labelText: isItalian ? 'Ruolo' : 'Role',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _AgentSectionTitle(title: 'Scenario'),
          TextField(
            controller: _scenarioController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: isItalian ? 'Fatti e scenario' : 'Facts and scenario',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _documentsController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isItalian
                  ? 'Documenti disponibili'
                  : 'Available documents',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deadlinesController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isItalian
                  ? 'Scadenze o urgenze'
                  : 'Deadlines or urgency',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isItalian ? 'Obiettivo pratico' : 'Practical goal',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: isItalian ? 'Note extra' : 'Extra notes',
            ),
          ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _isStarting
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (_questionController.text.trim().isEmpty &&
                        _scenarioController.text.trim().isEmpty) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isItalian
                                ? 'Inserisci almeno domanda principale o scenario.'
                                : 'Enter at least the main question or scenario.',
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() => _isStarting = true);
                    try {
                      final profile = LegalProfile(
                        primaryQuestion: _questionController.text.trim(),
                        topic: _topicController.text.trim(),
                        jurisdiction: _jurisdictionController.text.trim(),
                        userRole: _roleController.text.trim(),
                        scenario: _scenarioController.text.trim(),
                        documentsAvailable: _documentsController.text.trim(),
                        deadlines: _deadlinesController.text.trim(),
                        goal: _goalController.text.trim(),
                        notes: _notesController.text.trim(),
                      );
                      await ref
                          .read(chatControllerProvider.notifier)
                          .startLegalAgent(profile: profile);
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    } catch (_) {
                      if (!context.mounted) return;
                      setState(() => _isStarting = false);
                    }
                  },
            icon: _isStarting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.gavel_rounded),
            label: Text(isItalian ? 'Avvia avvocato' : 'Start lawyer'),
          ),
        ),
      ),
    );
  }

  Chat? _lastChatForKind(List<Chat> chats, String kind) {
    for (final chat in chats) {
      if (chat.kind == kind) return chat;
    }
    return null;
  }
}

class _LastCaseCard extends StatelessWidget {
  const _LastCaseCard({
    required this.title,
    required this.chat,
    required this.onTap,
  });

  final String title;
  final Chat chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history_rounded),
        title: Text(title),
        subtitle: Text(
          chat.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _AgentSectionTitle extends StatelessWidget {
  const _AgentSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
