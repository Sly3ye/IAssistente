import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../models/medical_profile.dart';
import '../providers/app_providers.dart';
import '../widgets/agent_disclaimer_banner.dart';

class MedicalAgentPage extends ConsumerStatefulWidget {
  const MedicalAgentPage({super.key});

  @override
  ConsumerState<MedicalAgentPage> createState() => _MedicalAgentPageState();
}

class _MedicalAgentPageState extends ConsumerState<MedicalAgentPage> {
  bool _isStarting = false;

  late final TextEditingController _questionController;
  late final TextEditingController _ageController;
  late final TextEditingController _sexController;
  late final TextEditingController _symptomsController;
  late final TextEditingController _durationController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _contextController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(chatControllerProvider).medicalProfile;
    _questionController = TextEditingController(text: profile.primaryQuestion);
    _ageController = TextEditingController(text: profile.age);
    _sexController = TextEditingController(text: profile.sex);
    _symptomsController = TextEditingController(text: profile.symptoms);
    _durationController = TextEditingController(text: profile.duration);
    _conditionsController = TextEditingController(text: profile.conditions);
    _medicationsController = TextEditingController(text: profile.medications);
    _allergiesController = TextEditingController(text: profile.allergies);
    _contextController = TextEditingController(text: profile.context);
    _notesController = TextEditingController(text: profile.notes);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _ageController.dispose();
    _sexController.dispose();
    _symptomsController.dispose();
    _durationController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _contextController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final isItalian = state.preferredLanguageCode == 'it';
    final lastCase = _lastChatForKind(state.chats, Chat.kindMedical);

    return Scaffold(
      appBar: AppBar(
        title: Text(isItalian ? 'Medico di base' : 'General practitioner'),
      ),
      body: Column(
        children: [
          AgentDisclaimerBanner(
            text: isItalian
                ? 'Percorso informativo: compila almeno domanda o sintomi. Non sostituisce un medico reale e non fornisce diagnosi.'
                : 'Informational workflow: fill at least question or symptoms. It does not replace a real doctor and does not provide diagnoses.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
          if (lastCase != null) ...[
            const SizedBox(height: 12),
            _LastCaseCard(
              title: isItalian ? 'Ultimo caso medico' : 'Last medical case',
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
                  : 'Main question or concern',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isItalian ? 'Eta' : 'Age',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _sexController,
                  decoration: InputDecoration(
                    labelText: isItalian ? 'Sesso' : 'Sex',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _AgentSectionTitle(title: 'Contesto sanitario'),
          TextField(
            controller: _symptomsController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: isItalian ? 'Sintomi o tema' : 'Symptoms or topic',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isItalian ? 'Da quanto tempo' : 'How long / timeline',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _conditionsController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isItalian
                  ? 'Patologie o condizioni note'
                  : 'Known conditions',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _medicationsController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isItalian
                  ? 'Farmaci o integratori'
                  : 'Medications or supplements',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _allergiesController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isItalian
                  ? 'Allergie o intolleranze'
                  : 'Allergies or intolerances',
            ),
          ),
          const SizedBox(height: 14),
          const _AgentSectionTitle(title: 'Dettagli pratici'),
          TextField(
            controller: _contextController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: isItalian ? 'Contesto utile' : 'Helpful context',
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
                        _symptomsController.text.trim().isEmpty) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isItalian
                                ? 'Inserisci almeno domanda principale o sintomi.'
                                : 'Enter at least the main question or symptoms.',
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() => _isStarting = true);
                    try {
                      final profile = MedicalProfile(
                        primaryQuestion: _questionController.text.trim(),
                        age: _ageController.text.trim(),
                        sex: _sexController.text.trim(),
                        symptoms: _symptomsController.text.trim(),
                        duration: _durationController.text.trim(),
                        conditions: _conditionsController.text.trim(),
                        medications: _medicationsController.text.trim(),
                        allergies: _allergiesController.text.trim(),
                        context: _contextController.text.trim(),
                        notes: _notesController.text.trim(),
                      );
                      await ref
                          .read(chatControllerProvider.notifier)
                          .startMedicalAgent(profile: profile);
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
                : const Icon(Icons.medical_services_outlined),
            label: Text(
              isItalian ? 'Avvia medico di base' : 'Start general practitioner',
            ),
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
