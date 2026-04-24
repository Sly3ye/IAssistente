class DietProfile {
  const DietProfile({
    required this.goal,
    required this.age,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.dietStyle,
    required this.constraints,
    required this.foodsToAvoid,
    required this.mealRoutine,
    required this.budget,
    required this.cookingSetup,
    required this.notes,
  });

  final String goal;
  final String age;
  final String sex;
  final String heightCm;
  final String weightKg;
  final String activityLevel;
  final String dietStyle;
  final String constraints;
  final String foodsToAvoid;
  final String mealRoutine;
  final String budget;
  final String cookingSetup;
  final String notes;

  bool get isEmpty =>
      goal.trim().isEmpty &&
      age.trim().isEmpty &&
      sex.trim().isEmpty &&
      heightCm.trim().isEmpty &&
      weightKg.trim().isEmpty &&
      activityLevel.trim().isEmpty &&
      dietStyle.trim().isEmpty &&
      constraints.trim().isEmpty &&
      foodsToAvoid.trim().isEmpty &&
      mealRoutine.trim().isEmpty &&
      budget.trim().isEmpty &&
      cookingSetup.trim().isEmpty &&
      notes.trim().isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'age': age,
      'sex': sex,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel,
      'dietStyle': dietStyle,
      'constraints': constraints,
      'foodsToAvoid': foodsToAvoid,
      'mealRoutine': mealRoutine,
      'budget': budget,
      'cookingSetup': cookingSetup,
      'notes': notes,
    };
  }

  factory DietProfile.fromJson(Map<String, dynamic> json) {
    return DietProfile(
      goal: (json['goal'] ?? '').toString(),
      age: (json['age'] ?? '').toString(),
      sex: (json['sex'] ?? '').toString(),
      heightCm: (json['heightCm'] ?? '').toString(),
      weightKg: (json['weightKg'] ?? '').toString(),
      activityLevel: (json['activityLevel'] ?? '').toString(),
      dietStyle: (json['dietStyle'] ?? '').toString(),
      constraints: (json['constraints'] ?? '').toString(),
      foodsToAvoid: (json['foodsToAvoid'] ?? '').toString(),
      mealRoutine: (json['mealRoutine'] ?? '').toString(),
      budget: (json['budget'] ?? '').toString(),
      cookingSetup: (json['cookingSetup'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
    );
  }

  DietProfile copyWith({
    String? goal,
    String? age,
    String? sex,
    String? heightCm,
    String? weightKg,
    String? activityLevel,
    String? dietStyle,
    String? constraints,
    String? foodsToAvoid,
    String? mealRoutine,
    String? budget,
    String? cookingSetup,
    String? notes,
  }) {
    return DietProfile(
      goal: goal ?? this.goal,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      dietStyle: dietStyle ?? this.dietStyle,
      constraints: constraints ?? this.constraints,
      foodsToAvoid: foodsToAvoid ?? this.foodsToAvoid,
      mealRoutine: mealRoutine ?? this.mealRoutine,
      budget: budget ?? this.budget,
      cookingSetup: cookingSetup ?? this.cookingSetup,
      notes: notes ?? this.notes,
    );
  }

  static const empty = DietProfile(
    goal: '',
    age: '',
    sex: '',
    heightCm: '',
    weightKg: '',
    activityLevel: '',
    dietStyle: '',
    constraints: '',
    foodsToAvoid: '',
    mealRoutine: '',
    budget: '',
    cookingSetup: '',
    notes: '',
  );
}
