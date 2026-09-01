class MealPlanItem {
  final String id;
  final String dateString; // YYYY-MM-DD
  final String mealType; // breakfast, lunch, snack, dinner
  final String? recipeId;
  final String recipeTitle;
  final String? recipeCategory;
  final int servings;
  final String customNote;

  MealPlanItem({
    required this.id,
    required this.dateString,
    required this.mealType,
    this.recipeId,
    required this.recipeTitle,
    this.recipeCategory,
    this.servings = 2,
    this.customNote = '',
  });

  MealPlanItem copyWith({
    String? id,
    String? dateString,
    String? mealType,
    String? recipeId,
    String? recipeTitle,
    String? recipeCategory,
    int? servings,
    String? customNote,
  }) {
    return MealPlanItem(
      id: id ?? this.id,
      dateString: dateString ?? this.dateString,
      mealType: mealType ?? this.mealType,
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      recipeCategory: recipeCategory ?? this.recipeCategory,
      servings: servings ?? this.servings,
      customNote: customNote ?? this.customNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateString': dateString,
      'mealType': mealType,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'recipeCategory': recipeCategory,
      'servings': servings,
      'customNote': customNote,
    };
  }

  factory MealPlanItem.fromMap(Map<String, dynamic> map) {
    return MealPlanItem(
      id: map['id']?.toString() ?? '',
      dateString: map['dateString']?.toString() ?? '',
      mealType: map['mealType']?.toString() ?? 'lunch',
      recipeId: map['recipeId']?.toString(),
      recipeTitle: map['recipeTitle']?.toString() ?? '',
      recipeCategory: map['recipeCategory']?.toString(),
      servings: (map['servings'] is num) ? (map['servings'] as num).toInt() : 2,
      customNote: map['customNote']?.toString() ?? '',
    );
  }
}
