class RecipeStep {
  final int stepNumber;
  final String instruction;
  final String? instructionEn;

  const RecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.instructionEn,
  });

  RecipeStep copyWith({
    int? stepNumber,
    String? instruction,
    String? instructionEn,
  }) {
    return RecipeStep(
      stepNumber: stepNumber ?? this.stepNumber,
      instruction: instruction ?? this.instruction,
      instructionEn: instructionEn ?? this.instructionEn,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'instruction': instruction,
      'instructionEn': instructionEn,
    };
  }

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      stepNumber: (map['stepNumber'] is num) ? (map['stepNumber'] as num).toInt() : 1,
      instruction: map['instruction']?.toString() ?? '',
      instructionEn: map['instructionEn']?.toString(),
    );
  }
}
