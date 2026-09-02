class RecipeStep {
  final int stepNumber;
  final String instruction;
  final String? instructionEn;
  final bool isSectionHeader;

  const RecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.instructionEn,
    this.isSectionHeader = false,
  });

  RecipeStep copyWith({
    int? stepNumber,
    String? instruction,
    String? instructionEn,
    bool? isSectionHeader,
  }) {
    return RecipeStep(
      stepNumber: stepNumber ?? this.stepNumber,
      instruction: instruction ?? this.instruction,
      instructionEn: instructionEn ?? this.instructionEn,
      isSectionHeader: isSectionHeader ?? this.isSectionHeader,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'instruction': instruction,
      'instructionEn': instructionEn,
      'isSectionHeader': isSectionHeader ? 1 : 0,
    };
  }

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      stepNumber: (map['stepNumber'] is num) ? (map['stepNumber'] as num).toInt() : 1,
      instruction: map['instruction']?.toString() ?? '',
      instructionEn: map['instructionEn']?.toString(),
      isSectionHeader: map['isSectionHeader'] == 1 || map['isSectionHeader'] == true || (map['instruction'] != null && map['instruction'].toString().trim().endsWith(':')),
    );
  }
}
