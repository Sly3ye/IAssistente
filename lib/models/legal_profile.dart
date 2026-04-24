class LegalProfile {
  const LegalProfile({
    required this.primaryQuestion,
    required this.topic,
    required this.jurisdiction,
    required this.userRole,
    required this.scenario,
    required this.documentsAvailable,
    required this.deadlines,
    required this.goal,
    required this.notes,
  });

  final String primaryQuestion;
  final String topic;
  final String jurisdiction;
  final String userRole;
  final String scenario;
  final String documentsAvailable;
  final String deadlines;
  final String goal;
  final String notes;

  bool get isEmpty =>
      primaryQuestion.trim().isEmpty &&
      topic.trim().isEmpty &&
      jurisdiction.trim().isEmpty &&
      userRole.trim().isEmpty &&
      scenario.trim().isEmpty &&
      documentsAvailable.trim().isEmpty &&
      deadlines.trim().isEmpty &&
      goal.trim().isEmpty &&
      notes.trim().isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'primaryQuestion': primaryQuestion,
      'topic': topic,
      'jurisdiction': jurisdiction,
      'userRole': userRole,
      'scenario': scenario,
      'documentsAvailable': documentsAvailable,
      'deadlines': deadlines,
      'goal': goal,
      'notes': notes,
    };
  }

  factory LegalProfile.fromJson(Map<String, dynamic> json) {
    return LegalProfile(
      primaryQuestion: (json['primaryQuestion'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      jurisdiction: (json['jurisdiction'] ?? '').toString(),
      userRole: (json['userRole'] ?? '').toString(),
      scenario: (json['scenario'] ?? '').toString(),
      documentsAvailable: (json['documentsAvailable'] ?? '').toString(),
      deadlines: (json['deadlines'] ?? '').toString(),
      goal: (json['goal'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
    );
  }

  static const empty = LegalProfile(
    primaryQuestion: '',
    topic: '',
    jurisdiction: '',
    userRole: '',
    scenario: '',
    documentsAvailable: '',
    deadlines: '',
    goal: '',
    notes: '',
  );
}
