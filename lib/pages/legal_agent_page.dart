import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/legal_profile.dart';
import '../providers/app_providers.dart';

class LegalAgentPage extends ConsumerStatefulWidget {
  const LegalAgentPage({super.key});

  @override
  ConsumerState<LegalAgentPage> createState() => _LegalAgentPageState();
}

class _LegalAgentPageState extends ConsumerState<LegalAgentPage> {
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
    _documentsController = TextEditingController(text: profile.documentsAvailable);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isItalian ? 'Avvocato' : 'Lawyer'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          Text(
            isItalian
                ? 'Questa sezione e solo informativa. Non sostituisce un avvocato reale e non costituisce consulenza legale.'
                : 'This section is informational only. It does not replace a real lawyer and does not constitute legal advice.',
          ),
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
                    labelText: isItalian ? 'Paese o giurisdizione' : 'Country or jurisdiction',
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
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
              await ref.read(chatControllerProvider.notifier).startLegalAgent(
                    profile: profile,
                  );
              if (!context.mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    isItalian
                        ? 'Avvocato pronto nella nuova chat.'
                        : 'Lawyer ready in the new chat.',
                  ),
                ),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.gavel_rounded),
            label: Text(isItalian ? 'Avvia avvocato' : 'Start lawyer'),
          ),
        ),
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
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
