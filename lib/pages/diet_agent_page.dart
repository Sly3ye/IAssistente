import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/diet_profile.dart';
import '../providers/app_providers.dart';

class DietAgentPage extends ConsumerStatefulWidget {
  const DietAgentPage({super.key});

  @override
  ConsumerState<DietAgentPage> createState() => _DietAgentPageState();
}

class _DietAgentPageState extends ConsumerState<DietAgentPage> {
  late final TextEditingController _goalController;
  late final TextEditingController _ageController;
  late final TextEditingController _sexController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _activityController;
  late final TextEditingController _dietStyleController;
  late final TextEditingController _constraintsController;
  late final TextEditingController _foodsToAvoidController;
  late final TextEditingController _mealRoutineController;
  late final TextEditingController _budgetController;
  late final TextEditingController _cookingSetupController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(chatControllerProvider).dietProfile;
    _goalController = TextEditingController(text: profile.goal);
    _ageController = TextEditingController(text: profile.age);
    _sexController = TextEditingController(text: profile.sex);
    _heightController = TextEditingController(text: profile.heightCm);
    _weightController = TextEditingController(text: profile.weightKg);
    _activityController = TextEditingController(text: profile.activityLevel);
    _dietStyleController = TextEditingController(text: profile.dietStyle);
    _constraintsController = TextEditingController(text: profile.constraints);
    _foodsToAvoidController = TextEditingController(text: profile.foodsToAvoid);
    _mealRoutineController = TextEditingController(text: profile.mealRoutine);
    _budgetController = TextEditingController(text: profile.budget);
    _cookingSetupController = TextEditingController(text: profile.cookingSetup);
    _notesController = TextEditingController(text: profile.notes);
  }

  @override
  void dispose() {
    _goalController.dispose();
    _ageController.dispose();
    _sexController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _activityController.dispose();
    _dietStyleController.dispose();
    _constraintsController.dispose();
    _foodsToAvoidController.dispose();
    _mealRoutineController.dispose();
    _budgetController.dispose();
    _cookingSetupController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final isItalian = state.preferredLanguageCode == 'it';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isItalian ? 'Agente dieta' : 'Diet agent'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          Text(
            isItalian
                ? 'Questo profilo vale solo per il verticale dieta. Non finisce nella memoria utente generale.'
                : 'This profile is only for the diet vertical. It does not go into general user memory.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: isItalian ? 'Obiettivo e contesto' : 'Goal and context',
            child: Column(
              children: [
                TextField(
                  controller: _goalController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isItalian
                        ? 'Obiettivo principale'
                        : 'Primary goal',
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
                          labelText: isItalian ? 'Età' : 'Age',
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isItalian ? 'Altezza (cm)' : 'Height (cm)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isItalian ? 'Peso (kg)' : 'Weight (kg)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _activityController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isItalian
                        ? 'Livello attività'
                        : 'Activity level',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: isItalian ? 'Alimentazione' : 'Nutrition',
            child: Column(
              children: [
                TextField(
                  controller: _dietStyleController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isItalian
                        ? 'Stile alimentare'
                        : 'Diet style',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _constraintsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: isItalian
                        ? 'Allergie, intolleranze, vincoli'
                        : 'Allergies, intolerances, constraints',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _foodsToAvoidController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isItalian
                        ? 'Cibi da evitare'
                        : 'Foods to avoid',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: isItalian ? 'Routine pratica' : 'Practical routine',
            child: Column(
              children: [
                TextField(
                  controller: _mealRoutineController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: isItalian
                        ? 'Routine pasti e orari'
                        : 'Meal routine and schedule',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _budgetController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isItalian ? 'Budget' : 'Budget',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cookingSetupController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isItalian
                        ? 'Tempo e cucina disponibile'
                        : 'Time and cooking setup',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: isItalian ? 'Note finali' : 'Final notes',
            child: TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: isItalian
                    ? 'Dettagli extra utili'
                    : 'Additional useful details',
              ),
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
              final profile = DietProfile(
                goal: _goalController.text.trim(),
                age: _ageController.text.trim(),
                sex: _sexController.text.trim(),
                heightCm: _heightController.text.trim(),
                weightKg: _weightController.text.trim(),
                activityLevel: _activityController.text.trim(),
                dietStyle: _dietStyleController.text.trim(),
                constraints: _constraintsController.text.trim(),
                foodsToAvoid: _foodsToAvoidController.text.trim(),
                mealRoutine: _mealRoutineController.text.trim(),
                budget: _budgetController.text.trim(),
                cookingSetup: _cookingSetupController.text.trim(),
                notes: _notesController.text.trim(),
              );
              await ref
                  .read(chatControllerProvider.notifier)
                  .startDietAgent(profile: profile);
              if (!context.mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    isItalian
                        ? 'Agente dieta pronto nella nuova chat.'
                        : 'Diet agent ready in the new chat.',
                  ),
                ),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.restaurant_menu_rounded),
            label: Text(
              isItalian ? 'Avvia agente dieta' : 'Start diet agent',
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
