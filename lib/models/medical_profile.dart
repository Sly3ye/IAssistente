class MedicalProfile {
  const MedicalProfile({
    required this.primaryQuestion,
    required this.age,
    required this.sex,
    required this.symptoms,
    required this.duration,
    required this.conditions,
    required this.medications,
    required this.allergies,
    required this.context,
    required this.notes,
  });

  final String primaryQuestion;
  final String age;
  final String sex;
  final String symptoms;
  final String duration;
  final String conditions;
  final String medications;
  final String allergies;
  final String context;
  final String notes;

  bool get isEmpty =>
      primaryQuestion.trim().isEmpty &&
      age.trim().isEmpty &&
      sex.trim().isEmpty &&
      symptoms.trim().isEmpty &&
      duration.trim().isEmpty &&
      conditions.trim().isEmpty &&
      medications.trim().isEmpty &&
      allergies.trim().isEmpty &&
      context.trim().isEmpty &&
      notes.trim().isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'primaryQuestion': primaryQuestion,
      'age': age,
      'sex': sex,
      'symptoms': symptoms,
      'duration': duration,
      'conditions': conditions,
      'medications': medications,
      'allergies': allergies,
      'context': context,
      'notes': notes,
    };
  }

  factory MedicalProfile.fromJson(Map<String, dynamic> json) {
    return MedicalProfile(
      primaryQuestion: (json['primaryQuestion'] ?? '').toString(),
      age: (json['age'] ?? '').toString(),
      sex: (json['sex'] ?? '').toString(),
      symptoms: (json['symptoms'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
      conditions: (json['conditions'] ?? '').toString(),
      medications: (json['medications'] ?? '').toString(),
      allergies: (json['allergies'] ?? '').toString(),
      context: (json['context'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
    );
  }

  static const empty = MedicalProfile(
    primaryQuestion: '',
    age: '',
    sex: '',
    symptoms: '',
    duration: '',
    conditions: '',
    medications: '',
    allergies: '',
    context: '',
    notes: '',
  );
}
